import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/emi_schedule_model.dart';

class EmiScheduleRow extends StatelessWidget {
  final EmiScheduleModel emi;
  final bool             isLender;
  final VoidCallback?    onPay;     // borrower action
  final VoidCallback?    onApprove; // lender action

  const EmiScheduleRow({
    super.key,
    required this.emi,
    required this.isLender,
    this.onPay,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final fmt     = NumberFormat('#,##,##0', 'en_IN');
    final fmtDate = DateFormat('dd MMM yy');

    final Color    statusColor;
    final IconData statusIcon;
    final String   statusLabel;

    if (emi.isApproved) {
      statusColor = Colors.green;
      statusIcon  = Icons.check_circle_rounded;
      statusLabel = 'Approved';
    } else if (emi.isPaid) {
      statusColor = Colors.orange;
      statusIcon  = Icons.hourglass_top_rounded;
      statusLabel = 'Awaiting Approval';
    } else if (emi.isOverdue) {
      statusColor = cs.error;
      statusIcon  = Icons.warning_amber_rounded;
      statusLabel = 'Overdue';
    } else {
      statusColor = cs.onSurfaceVariant;
      statusIcon  = Icons.radio_button_unchecked;
      statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: emi.isApproved
            ? Colors.green.withOpacity(0.04)
            : emi.isOverdue
                ? cs.errorContainer.withOpacity(0.3)
                : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emi.isApproved
              ? Colors.green.withOpacity(0.2)
              : emi.isOverdue
                  ? cs.error.withOpacity(0.3)
                  : cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // EMI number circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${emi.emiNumber}',
                  style: tt.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('₹${fmt.format(emi.emiAmount)}',
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: tt.labelSmall
                            ?.copyWith(color: statusColor)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(fmtDate.format(emi.dueDate),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Text(
                      '₹${fmt.format(emi.principalComponent)} + '
                      '₹${fmt.format(emi.interestComponent)}',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ]),
                ],
              ),
            ),

            // Action button
            if (!emi.isApproved) ...[
              const SizedBox(width: 8),
              if (!isLender && (emi.status == 'pending' || emi.isOverdue))
                _ActionBtn(
                  label: 'Pay',
                  color: cs.primary,
                  onTap: onPay,
                )
              else if (isLender && emi.isPaid)
                _ActionBtn(
                  label: 'Approve',
                  color: Colors.green,
                  onTap: onApprove,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String        label;
  final Color         color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled    = onTap == null;
    final effectColor = disabled ? Colors.grey : color;

    return Tooltip(
      message: disabled ? 'Pay previous EMI first' : '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: effectColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: effectColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (disabled)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock_outline_rounded,
                      size: 11, color: effectColor),
                ),
              Text(label,
                  style: TextStyle(
                    color: effectColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
