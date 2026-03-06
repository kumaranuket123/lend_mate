import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/emi_calculator.dart';

class EmiPreviewCard extends StatelessWidget {
  final double   principal;
  final double   annualRate;
  final int      months;
  final DateTime startDate;
  final int      emiDay;

  const EmiPreviewCard({
    super.key,
    required this.principal,
    required this.annualRate,
    required this.months,
    required this.startDate,
    required this.emiDay,
  });

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;
    final fmt      = NumberFormat('#,##,##0.##', 'en_IN');
    final emiAmt   = EmiCalculator.emi(principal, annualRate, months);
    final total    = EmiCalculator.totalPayable(emiAmt, months);
    final interest = EmiCalculator.totalInterest(principal, emiAmt, months);
    final schedule = EmiCalculator.schedule(
        principal, annualRate, months, startDate, emiDay);
    final showRows = schedule.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_outlined, color: cs.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('EMI Preview',
                        style: tt.titleSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(
                        label: 'Monthly EMI',
                        value: '₹${fmt.format(emiAmt)}',
                        highlight: true),
                    _Stat(
                        label: 'Total Interest',
                        value: '₹${fmt.format(interest)}'),
                    _Stat(
                        label: 'Total Payable',
                        value: '₹${fmt.format(total)}'),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cs.primary.withOpacity(0.1)),

          // Mini schedule (first 3 rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amortisation (first 3 EMIs)',
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Table(
                  columnWidths: const {
                    0: FixedColumnWidth(30),
                    1: FlexColumnWidth(),
                    2: FlexColumnWidth(),
                    3: FlexColumnWidth(),
                    4: FlexColumnWidth(),
                  },
                  children: [
                    _headerRow(context),
                    ...showRows.map((r) => _dataRow(context, r, fmt)),
                  ],
                ),
                if (schedule.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${schedule.length - 3} more EMIs',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _headerRow(BuildContext ctx) {
    final style = Theme.of(ctx).textTheme.labelSmall?.copyWith(
          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    return TableRow(children: [
      Text('#',         style: style),
      Text('Due Date',  style: style),
      Text('Principal', style: style, textAlign: TextAlign.right),
      Text('Interest',  style: style, textAlign: TextAlign.right),
      Text('Balance',   style: style, textAlign: TextAlign.right),
    ]);
  }

  TableRow _dataRow(BuildContext ctx, EmiRow r, NumberFormat fmt) {
    final tt = Theme.of(ctx).textTheme;
    cell(String v, {TextAlign align = TextAlign.right}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(v, style: tt.labelSmall, textAlign: align),
        );
    return TableRow(children: [
      cell('${r.number}',                          align: TextAlign.left),
      cell(DateFormat('dd MMM').format(r.dueDate), align: TextAlign.left),
      cell('₹${fmt.format(r.principal)}'),
      cell('₹${fmt.format(r.interest)}'),
      cell('₹${fmt.format(r.closing)}'),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool   highlight;
  const _Stat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: (highlight ? tt.titleMedium : tt.titleSmall)?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? cs.primary : cs.onSurface,
            )),
      ],
    );
  }
}
