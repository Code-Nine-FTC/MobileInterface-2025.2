import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/api/pharmacy_api_data_source.dart';
import 'expiry_state.dart';

class ExpiryCubit extends Cubit<ExpiryState> {
  final PharmacyApiDataSource _pharmacyApiDataSource;

  ExpiryCubit(this._pharmacyApiDataSource) : super(ExpiryInitial());

  Future<void> fetchExpiryData(int days) async {
    try {
      emit(ExpiryLoading());

      final summary = await _pharmacyApiDataSource.getExpirySummary(days);
      final lists = await _pharmacyApiDataSource.getExpiryList(days);

      emit(ExpiryLoaded(
        summary: summary,
        expiredItems: lists['expired'] ?? [],
        expiringSoonItems: lists['expiringSoon'] ?? [],
        selectedDays: days,
      ));
    } catch (e) {
      emit(ExpiryError(e.toString()));
    }
  }

  void refresh() {
    if (state is ExpiryLoaded) {
      fetchExpiryData((state as ExpiryLoaded).selectedDays);
    } else {
      fetchExpiryData(7);
    }
  }
}
