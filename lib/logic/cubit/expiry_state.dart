import 'package:equatable/equatable.dart';
import '../../data/models/expiry_summary_model.dart';
import '../../data/models/expiry_item_model.dart';

abstract class ExpiryState extends Equatable {
  const ExpiryState();

  @override
  List<Object?> get props => [];
}

class ExpiryInitial extends ExpiryState {}

class ExpiryLoading extends ExpiryState {}

class ExpiryLoaded extends ExpiryState {
  final ExpirySummaryModel summary;
  final List<ExpiryItemModel> expiredItems;
  final List<ExpiryItemModel> expiringSoonItems;
  final int selectedDays;

  const ExpiryLoaded({
    required this.summary,
    required this.expiredItems,
    required this.expiringSoonItems,
    required this.selectedDays,
  });

  @override
  List<Object?> get props => [summary, expiredItems, expiringSoonItems, selectedDays];
}

class ExpiryError extends ExpiryState {
  final String message;

  const ExpiryError(this.message);

  @override
  List<Object?> get props => [message];
}
