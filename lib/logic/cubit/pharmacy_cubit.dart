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
      print('[PharmacyCubit] Iniciando busca de dados de validade para $days dias');
      emit(PharmacyLoading());

      print('[PharmacyCubit] Buscando resumo de vencimentos...');
      final summary = await _pharmacyApiDataSource.getExpirySummary(days);
      print('[PharmacyCubit] Resumo recebido: Vencidos=${summary.expiredCount}, A vencer=${summary.expiringSoonCount}');

      print('[PharmacyCubit] Buscando primeira página de vencimentos...');
      final lists = await _pharmacyApiDataSource.getExpiryList(days, page: 0, size: _pageSize);
      print('[PharmacyCubit] Lista recebida - Vencidos: ${lists['expired']?.length ?? 0}, A vencer: ${lists['expiringSoon']?.length ?? 0}');

      final expiredItems = lists['expired'] ?? [];
      final expiringSoonItems = lists['expiringSoon'] ?? [];

      print('[PharmacyCubit] DEBUG - Itens vencidos:');
      for (var item in expiredItems.take(3)) {
        print('  - ${item.name}: ${item.expireDate}');
      }
      
      print('[PharmacyCubit] DEBUG - Itens a vencer:');
      for (var item in expiringSoonItems.take(3)) {
        print('  - ${item.name}: ${item.expireDate}');
      }

      emit(PharmacyLoaded(
        summary: summary,
        expiredItems: expiredItems,
        expiringSoonItems: expiringSoonItems,
        selectedDays: days,
        hasMoreExpired: expiredItems.length >= _pageSize,
        hasMoreExpiringSoon: expiringSoonItems.length >= _pageSize,
      ));
      print('[PharmacyCubit] Estado PharmacyLoaded emitido - Vencidos: ${expiredItems.length}, A vencer: ${expiringSoonItems.length}');
    } catch (e) {
      print('[PharmacyCubit] ERRO ao buscar dados: $e');
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
      print('[PharmacyCubit] Carregando mais itens vencidos...');
      emit(currentState.copyWith(isLoadingMore: true));

      final currentPage = (currentState.expiredItems.length / _pageSize).floor();
      final lists = await _pharmacyApiDataSource.getExpiryList(
        currentState.selectedDays,
        page: currentPage,
        size: _pageSize,
      );

      final newExpiredItems = lists['expired'] ?? [];
      print('[PharmacyCubit] ${newExpiredItems.length} novos itens vencidos carregados');

      emit(currentState.copyWith(
        expiredItems: [...currentState.expiredItems, ...newExpiredItems],
        hasMoreExpired: newExpiredItems.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('[PharmacyCubit] ERRO ao carregar mais vencidos: $e');
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
      print('[PharmacyCubit] Carregando mais itens a vencer...');
      emit(currentState.copyWith(isLoadingMore: true));

      final currentPage = (currentState.expiringSoonItems.length / _pageSize).floor();
      final lists = await _pharmacyApiDataSource.getExpiryList(
        currentState.selectedDays,
        page: currentPage,
        size: _pageSize,
      );

      final newExpiringSoonItems = lists['expiringSoon'] ?? [];
      print('[PharmacyCubit] ${newExpiringSoonItems.length} novos itens a vencer carregados');

      emit(currentState.copyWith(
        expiringSoonItems: [...currentState.expiringSoonItems, ...newExpiringSoonItems],
        hasMoreExpiringSoon: newExpiringSoonItems.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('[PharmacyCubit] ERRO ao carregar mais a vencer: $e');
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
}
