class NotificationModel {
  final String   id;
  final String   userId;
  final String   title;
  final String?  body;
  final String?  type;
  final String?  loanId;
  final String?  paymentId;
  final bool     isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.type,
    this.loanId,
    this.paymentId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> m) =>
      NotificationModel(
        id:        m['id'] as String,
        userId:    m['user_id'] as String,
        title:     m['title'] as String,
        body:      m['body'] as String?,
        type:      m['type'] as String?,
        loanId:    m['loan_id'] as String?,
        paymentId: m['payment_id'] as String?,
        isRead:    m['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id:        id,
        userId:    userId,
        title:     title,
        body:      body,
        type:      type,
        loanId:    loanId,
        paymentId: paymentId,
        isRead:    isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
