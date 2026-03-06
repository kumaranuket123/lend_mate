import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../models/payment_model.dart';

abstract class LoanDetailState {}

class LoanDetailInitial extends LoanDetailState {}

class LoanDetailLoading extends LoanDetailState {}

class LoanDetailError extends LoanDetailState {
  final String msg;
  LoanDetailError(this.msg);
}

class LoanDetailLoaded extends LoanDetailState {
  final LoanModel              loan;
  final List<EmiScheduleModel> schedule;
  final List<PaymentModel>     payments;

  LoanDetailLoaded({
    required this.loan,
    required this.schedule,
    required this.payments,
  });

  int get paidCount =>
      schedule.where((e) => e.isApproved).length;
  int get pendingCount =>
      schedule.where((e) => e.status == 'pending' || e.isOverdue).length;
}

class LoanDetailActionLoading extends LoanDetailState {}

class LoanDetailActionSuccess extends LoanDetailState {
  final String msg;
  LoanDetailActionSuccess(this.msg);
}

class LoanDetailActionError extends LoanDetailState {
  final String msg;
  LoanDetailActionError(this.msg);
}

class LoanDetailDeleted extends LoanDetailState {}
