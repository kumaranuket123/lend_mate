class LoanModel {
  final String id;
  final String lenderId;
  final String borrowerId;
  final double amount;
  final double interestRate;
  final int tenureMonths;
  final DateTime startDate;
  final int emiDate;
  final double emiAmount;
  final double totalInterest;
  final double totalPayable;
  final double remainingPrincipal;
  final double paidPrincipal;
  final String status; // pending | active | closed
  final String modeOnExtraPayment;
  final String? lenderUpi;
  final String? borrowerUpi;
  final String? notes;

  // Joined fields (from profile lookup)
  final String? lenderName;
  final String? borrowerName;

  // Audit
  final DateTime? createdAt;

  const LoanModel({
    required this.id,
    required this.lenderId,
    required this.borrowerId,
    required this.amount,
    required this.interestRate,
    required this.tenureMonths,
    required this.startDate,
    required this.emiDate,
    required this.emiAmount,
    required this.totalInterest,
    required this.totalPayable,
    required this.remainingPrincipal,
    required this.paidPrincipal,
    required this.status,
    required this.modeOnExtraPayment,
    this.lenderUpi,
    this.borrowerUpi,
    this.notes,
    this.lenderName,
    this.borrowerName,
    this.createdAt,
  });

  factory LoanModel.fromMap(Map<String, dynamic> m) => LoanModel(
        id:                 m['id'] as String,
        lenderId:           m['lender_id'] as String,
        borrowerId:         m['borrower_id'] as String,
        amount:             (m['amount'] as num).toDouble(),
        interestRate:       (m['interest_rate'] as num).toDouble(),
        tenureMonths:       m['tenure_months'] as int,
        startDate:          DateTime.parse(m['start_date'] as String),
        emiDate:            m['emi_date'] as int,
        emiAmount:          (m['emi_amount'] as num).toDouble(),
        totalInterest:      (m['total_interest'] as num).toDouble(),
        totalPayable:       (m['total_payable'] as num).toDouble(),
        remainingPrincipal: (m['remaining_principal'] as num).toDouble(),
        paidPrincipal:      (m['paid_principal'] as num?)?.toDouble() ?? 0,
        status:             m['status'] as String,
        modeOnExtraPayment: m['mode_on_extra_payment'] as String,
        lenderUpi:          m['lender_upi'] as String?,
        borrowerUpi:        m['borrower_upi'] as String?,
        notes:              m['notes'] as String?,
        lenderName:         m['lender_name'] as String?,
        borrowerName:       m['borrower_name'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String).toLocal()
            : null,
      );

  // Next EMI due date calculation
  DateTime get nextEmiDate {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, emiDate);
    if (due.isBefore(now)) {
      due = DateTime(now.year, now.month + 1, emiDate);
    }
    return due;
  }

  double get progressPercent => paidPrincipal / amount;
}
