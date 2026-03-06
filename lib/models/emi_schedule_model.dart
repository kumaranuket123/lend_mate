class EmiScheduleModel {
  final String   id;
  final String   loanId;
  final int      emiNumber;
  final DateTime dueDate;
  final double   emiAmount;
  final double   principalComponent;
  final double   interestComponent;
  final double   openingBalance;
  final double   closingBalance;
  final String   status; // pending | paid | approved | overdue

  const EmiScheduleModel({
    required this.id,
    required this.loanId,
    required this.emiNumber,
    required this.dueDate,
    required this.emiAmount,
    required this.principalComponent,
    required this.interestComponent,
    required this.openingBalance,
    required this.closingBalance,
    required this.status,
  });

  factory EmiScheduleModel.fromMap(Map<String, dynamic> m) => EmiScheduleModel(
        id:                 m['id'] as String,
        loanId:             m['loan_id'] as String,
        emiNumber:          m['emi_number'] as int,
        dueDate:            DateTime.parse(m['due_date'] as String),
        emiAmount:          (m['emi_amount'] as num).toDouble(),
        principalComponent: (m['principal_component'] as num).toDouble(),
        interestComponent:  (m['interest_component'] as num).toDouble(),
        openingBalance:     (m['opening_balance'] as num).toDouble(),
        closingBalance:     (m['closing_balance'] as num).toDouble(),
        status:             m['status'] as String,
      );

  bool get isOverdue  => status == 'pending' && dueDate.isBefore(DateTime.now());
  bool get isPaid     => status == 'paid';
  bool get isApproved => status == 'approved';
}
