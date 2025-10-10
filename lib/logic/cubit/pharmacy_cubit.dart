import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api/pharmacy_api_data_source.dart';
import '../../data/models/expiry_summary_model.dart';
import '../../data/models/expiry_item_model.dart';

// States
abstract class PharmacyState extends Equatable {
  const PharmacyState();

  @override
  List<Object?> get props => [];
}

class PharmacyInitial extends PharmacyState {}

class PharmacyLoading extends PharmacyState {}

class PharmacyLoaded extends PharmacyState {
  final ExpirySummaryModel summary;
  final List<ExpiryItemModel> expiredItems;
  final List<ExpiryItemModel> expiringSoonItems;
  final int selectedDays;
  final bool hasMoreExpired;
  final bool hasMoreExpiringSoon;
  final bool isLoadingMore;

  const PharmacyLoaded({
    required this.summary,
    required this.expiredItems,
    required this.expiringSoonItems,
    required this.selectedDays,
    this.hasMoreExpired = true,
    this.hasMoreExpiringSoon = true,
    this.isLoadingMore = false,
  });

  PharmacyLoaded copyWith({
    ExpirySummaryModel? summary,
    List<ExpiryItemModel>? expiredItems,
    List<ExpiryItemModel>? expiringSoonItems,
    int? selectedDays,
    bool? hasMoreExpired,
    bool? hasMoreExpiringSoon,
    bool? isLoadingMore,
  }) {
    return PharmacyLoaded(
      summary: summary ?? this.summary,
      expiredItems: expiredItems ?? this.expiredItems,
      expiringSoonItems: expiringSoonItems ?? this.expiringSoonItems,
      selectedDays: selectedDays ?? this.selectedDays,
      hasMoreExpired: hasMoreExpired != null ? hasMoreExpired : this.hasMoreExpired,
      hasMoreExpiringSoon: hasMoreExpiringSoon != null ? hasMoreExpiringSoon : this.hasMoreExpiringSoon,
      isLoadingMore: isLoadingMore != null ? isLoadingMore : this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        expiredItems,
        expiringSoonItems,
        selectedDays,
        hasMoreExpired,
        hasMoreExpiringSoon,
        isLoadingMore,
      ];
}

class PharmacyError extends PharmacyState {
  final String message;

  const PharmacyError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class PharmacyCubit extends Cubit<PharmacyState> {
  final PharmacyApiDataSource _pharmacyApiDataSource;
  static const int _pageSize = 20;

  PharmacyCubit(this._pharmacyApiDataSource) : super(PharmacyInitial());

  Future<void> fetchExpiryData(int days) async {
    try {
      emit(PharmacyLoading());

      final summary = await _pharmacyApiDataSource.getExpirySummary(days);
      final lists = await _pharmacyApiDataSource.getExpiryList(days, page: 0, size: _pageSize);

      final expiredItems = lists['expired'] ?? [];
      final expiringSoonItems = lists['expiringSoon'] ?? [];

      emit(PharmacyLoaded(
        summary: summary,
        expiredItems: expiredItems,
        expiringSoonItems: expiringSoonItems,
        selectedDays: days,
        hasMoreExpired: expiredItems.length >= _pageSize,
        hasMoreExpiringSoon: expiringSoonItems.length >= _pageSize,
      ));
    } catch (e) {
      emit(PharmacyError(e.toString()));
    }
  }

  Future<void> loadMoreExpired() async {
    final currentState = state;
    if (currentState is! PharmacyLoaded || 
        !currentState.hasMoreExpired || 
        currentState.isLoadingMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final currentPage = (currentState.expiredItems.length / _pageSize).floor();
      final lists = await _pharmacyApiDataSource.getExpiryList(
        currentState.selectedDays,
        page: currentPage,
        size: _pageSize,
      );

      final newExpiredItems = lists['expired'] ?? [];

      emit(currentState.copyWith(
        expiredItems: [...currentState.expiredItems, ...newExpiredItems],
        hasMoreExpired: newExpiredItems.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMoreExpiringSoon() async {
    final currentState = state;
    if (currentState is! PharmacyLoaded || 
        !currentState.hasMoreExpiringSoon || 
        currentState.isLoadingMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final currentPage = (currentState.expiringSoonItems.length / _pageSize).floor();
      final lists = await _pharmacyApiDataSource.getExpiryList(
        currentState.selectedDays,
        page: currentPage,
        size: _pageSize,
      );

      final newExpiringSoonItems = lists['expiringSoon'] ?? [];

      emit(currentState.copyWith(
        expiringSoonItems: [...currentState.expiringSoonItems, ...newExpiringSoonItems],
        hasMoreExpiringSoon: newExpiringSoonItems.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void refresh() {
    if (state is PharmacyLoaded) {
      fetchExpiryData((state as PharmacyLoaded).selectedDays);
    } else {
      fetchExpiryData(7);
    }
  }

  Future<void> deleteItem(int itemId) async {
    final currentState = state;
    if (currentState is! PharmacyLoaded) {
      return;
    }

    try {
      await _pharmacyApiDataSource.deleteItem(itemId);

      final updatedExpiredItems = currentState.expiredItems
          .where((item) => item.id != itemId)
          .toList();
      final updatedExpiringSoonItems = currentState.expiringSoonItems
          .where((item) => item.id != itemId)
          .toList();
      final newExpiredCount = currentState.summary.expiredCount - 
          (currentState.expiredItems.length - updatedExpiredItems.length);
      final newExpiringSoonCount = currentState.summary.expiringSoonCount - 
          (currentState.expiringSoonItems.length - updatedExpiringSoonItems.length);
      final updatedSummary = ExpirySummaryModel(
        expiredCount: newExpiredCount > 0 ? newExpiredCount : 0,
        expiringSoonCount: newExpiringSoonCount > 0 ? newExpiringSoonCount : 0,
      );

      emit(currentState.copyWith(
        summary: updatedSummary,
        expiredItems: updatedExpiredItems,
        expiringSoonItems: updatedExpiringSoonItems,
      ));
    } catch (e) {
      rethrow;
    }
  }
}
