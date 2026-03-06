class PaymentModel {
  final String   id;
  final String   loanId;
  final String?  emiScheduleId;
  final String   paidBy;
  final String   receivedBy;
  final double   amount;
  final String   type; // emi | extra
  final DateTime paymentDate;
  final String?  proofUrl;
  final bool     borrowerApproved;
  final bool     lenderApproved;
  final String?  rejectionReason;

  const PaymentModel({
    required this.id,
    required this.loanId,
    this.emiScheduleId,
    required this.paidBy,
    required this.receivedBy,
    required this.amount,
    required this.type,
    required this.paymentDate,
    this.proofUrl,
    required this.borrowerApproved,
    required this.lenderApproved,
    this.rejectionReason,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> m) => PaymentModel(
        id:               m['id'] as String,
        loanId:           m['loan_id'] as String,
        emiScheduleId:    m['emi_schedule_id'] as String?,
        paidBy:           m['paid_by'] as String,
        receivedBy:       m['received_by'] as String,
        amount:           (m['amount'] as num).toDouble(),
        type:             m['type'] as String,
        paymentDate:      DateTime.parse(m['payment_date'] as String).toLocal(),
        proofUrl:         m['proof_url'] as String?,
        borrowerApproved: m['borrower_approved'] as bool? ?? false,
        lenderApproved:   m['lender_approved'] as bool? ?? false,
        rejectionReason:  m['rejection_reason'] as String?,
      );

  bool get fullyApproved => borrowerApproved && lenderApproved;
}
