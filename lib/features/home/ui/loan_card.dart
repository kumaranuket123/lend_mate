import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/loan_model.dart';

class LoanCard extends StatelessWidget {
  final LoanModel loan;
  final bool isLender;
  final VoidCallback? onTap;

  const LoanCard({
    super.key,
    required this.loan,
    required this.isLender,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final fmt     = NumberFormat('#,##,##0', 'en_IN');
    final fmtDate = DateFormat('dd MMM yyyy');

    final partyName = isLender ? loan.borrowerName : loan.lenderName;
    final role      = isLender ? 'You lent' : 'You borrowed';
    final color     = isLender ? cs.tertiary : cs.error;

    final statusColor = switch (loan.status) {
      'active'  => Colors.green,
      'pending' => Colors.orange,
      'closed'  => Colors.grey,
      _         => cs.outline,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + status chip
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      (partyName ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partyName ?? 'Unknown',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(role,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amounts row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _AmountChip(
                      label: 'Principal',
                      value: '₹${fmt.format(loan.amount)}',
                      color: cs.onSurfaceVariant),
                  _AmountChip(
                      label: 'Remaining',
                      value: '₹${fmt.format(loan.remainingPrincipal)}',
                      color: color),
                  _AmountChip(
                      label: 'EMI',
                      value: '₹${fmt.format(loan.emiAmount)}',
                      color: cs.onSurfaceVariant),
                ],
              ),

              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: loan.progressPercent,
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),

              const SizedBox(height: 10),

              // Footer: next due
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(loan.progressPercent * 100).toStringAsFixed(0)}% paid',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Next: ${fmtDate.format(loan.nextEmiDate)}',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            )),
      ],
    );
  }
}
