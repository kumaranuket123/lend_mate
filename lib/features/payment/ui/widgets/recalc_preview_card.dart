import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/loan_model.dart';
import '../../../../utils/emi_calculator.dart';
import '../../../../utils/loan_recalculator.dart';

class RecalcPreviewCard extends StatelessWidget {
  final LoanModel    loan;
  final double       extraAmount;
  final RecalcResult recalc;

  const RecalcPreviewCard({
    super.key,
    required this.loan,
    required this.extraAmount,
    required this.recalc,
  });

  @override
  Widget build(BuildContext context) {
    final cs              = Theme.of(context).colorScheme;
    final tt              = Theme.of(context).textTheme;
    final fmt             = NumberFormat('#,##,##0.##', 'en_IN');
    final isReduceTenure  = loan.modeOnExtraPayment == 'reduce_tenure';

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_graph_rounded,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Recalculation Preview',
                  style: tt.titleSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ),

          // Before / After comparison
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: _CompareColumn(
                  label: 'BEFORE',
                  color: cs.error,
                  rows: [
                    ('Principal', '₹${fmt.format(loan.remainingPrincipal)}'),
                    ('EMI', '₹${fmt.format(loan.emiAmount)}'),
                    if (isReduceTenure)
                      ('Months Left',
                          '${recalc.newSchedule.length + _extraMonths(recalc)}')
                    else
                      ('Months Left', '${recalc.newSchedule.length}'),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: cs.onSurfaceVariant),
              Expanded(
                child: _CompareColumn(
                  label: 'AFTER',
                  color: Colors.green,
                  rows: [
                    ('Principal',
                        '₹${fmt.format(recalc.newRemainingPrincipal)}'),
                    if (isReduceTenure)
                      ('EMI', '₹${fmt.format(loan.emiAmount)}')
                    else
                      ('EMI',
                          '₹${fmt.format(recalc.newEmiAmount ?? loan.emiAmount)}'),
                    if (isReduceTenure)
                      ('Months Left', '${recalc.newTenureMonths}')
                    else
                      ('Months Left', '${recalc.newSchedule.length}'),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.green.withOpacity(0.2)),

          // Savings highlight
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.savings_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interest Saved',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    Text('₹${fmt.format(recalc.interestSaved)}',
                        style: tt.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
              if (isReduceTenure && recalc.newTenureMonths != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Months Saved',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    Text('${_extraMonths(recalc)} months',
                        style: tt.titleMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
            ]),
          ),

          // Mini schedule preview (next 3 rows)
          if (recalc.newSchedule.isNotEmpty) ...[
            Divider(height: 1, color: Colors.green.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Schedule (next 3 EMIs)',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FixedColumnWidth(30),
                      1: FlexColumnWidth(),
                      2: FlexColumnWidth(),
                      3: FlexColumnWidth(),
                    },
                    children: [
                      _headerRow(context),
                      ...recalc.newSchedule
                          .take(3)
                          .map((r) => _dataRow(context, r, fmt)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _extraMonths(RecalcResult recalc) {
    if (recalc.newTenureMonths == null) return 0;
    return recalc.newSchedule.length - recalc.newTenureMonths!;
  }

  TableRow _headerRow(BuildContext ctx) {
    final style = Theme.of(ctx).textTheme.labelSmall?.copyWith(
          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    return TableRow(children: [
      Text('#',       style: style),
      Text('Due',     style: style),
      Text('EMI',     style: style, textAlign: TextAlign.right),
      Text('Balance', style: style, textAlign: TextAlign.right),
    ]);
  }

  TableRow _dataRow(BuildContext ctx, EmiRow r, NumberFormat fmt) {
    final tt = Theme.of(ctx).textTheme;
    cell(String v, {TextAlign align = TextAlign.right}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(v, style: tt.labelSmall, textAlign: align),
        );
    return TableRow(children: [
      cell('${r.number}',                          align: TextAlign.left),
      cell(DateFormat('dd MMM').format(r.dueDate), align: TextAlign.left),
      cell('₹${fmt.format(r.emiAmount)}'),
      cell('₹${fmt.format(r.closing)}'),
    ]);
  }
}

class _CompareColumn extends StatelessWidget {
  final String                 label;
  final Color                  color;
  final List<(String, String)> rows;

  const _CompareColumn({
    required this.label,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
        ),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.$1,
                      style: tt.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                  Text(r.$2,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            )),
      ],
    );
  }
}
