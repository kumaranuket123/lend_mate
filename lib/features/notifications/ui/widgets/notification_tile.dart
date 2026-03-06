import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback?     onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final fmtDate = DateFormat('dd MMM, hh:mm a');
    final isRead  = notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead
            ? Colors.transparent
            : cs.primaryContainer.withOpacity(0.15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(notification.type, cs),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(notification.type),
                size: 18,
                color: _iconColor(notification.type, cs),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight:
                          isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  if (notification.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    fmtDate.format(notification.createdAt),
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Right side: unread dot + loan arrow
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (notification.loanId != null) ...[
                  if (!isRead) const SizedBox(height: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: cs.onSurfaceVariant),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'payment_received':  return Icons.payments_outlined;
      case 'payment_approved':  return Icons.check_circle_outline;
      case 'payment_rejected':  return Icons.cancel_outlined;
      case 'loan_created':      return Icons.handshake_outlined;
      case 'emi_due':           return Icons.calendar_today_outlined;
      case 'extra_payment':     return Icons.add_circle_outline;
      default:                  return Icons.notifications_outlined;
    }
  }

  Color _iconBg(String? type, ColorScheme cs) {
    switch (type) {
      case 'payment_received':  return Colors.green.withOpacity(0.12);
      case 'payment_approved':  return Colors.green.withOpacity(0.12);
      case 'payment_rejected':  return cs.errorContainer.withOpacity(0.4);
      case 'emi_due':           return Colors.orange.withOpacity(0.12);
      default:                  return cs.primaryContainer.withOpacity(0.5);
    }
  }

  Color _iconColor(String? type, ColorScheme cs) {
    switch (type) {
      case 'payment_received':  return Colors.green;
      case 'payment_approved':  return Colors.green;
      case 'payment_rejected':  return cs.error;
      case 'emi_due':           return Colors.orange;
      default:                  return cs.primary;
    }
  }
}
