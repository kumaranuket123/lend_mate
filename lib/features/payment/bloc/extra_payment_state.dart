import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../utils/loan_recalculator.dart';

abstract class ExtraPaymentState {}

class ExtraPaymentInitial extends ExtraPaymentState {}

class ExtraPaymentLoading extends ExtraPaymentState {}

class ExtraPaymentError extends ExtraPaymentState {
  final String msg;
  ExtraPaymentError(this.msg);
}

class ExtraPaymentSuccess extends ExtraPaymentState {
  final bool loanClosed;
  ExtraPaymentSuccess({this.loanClosed = false});
}

class ExtraPaymentClosurePreview extends ExtraPaymentState {
  final LoanModel loan;
  ExtraPaymentClosurePreview(this.loan);
}

class ExtraPaymentLoanLoaded extends ExtraPaymentState {
  final LoanModel              loan;
  final List<EmiScheduleModel> pendingSchedule;
  ExtraPaymentLoanLoaded(this.loan, this.pendingSchedule);
}

/// Preview state — shown before user confirms
class ExtraPaymentPreviewReady extends ExtraPaymentState {
  final LoanModel              loan;
  final List<EmiScheduleModel> pendingSchedule;
  final double                 extraAmount;
  final RecalcResult           recalc;
  ExtraPaymentPreviewReady({
    required this.loan,
    required this.pendingSchedule,
    required this.extraAmount,
    required this.recalc,
  });
}
