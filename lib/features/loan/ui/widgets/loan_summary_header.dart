import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/loan_model.dart';

class LoanSummaryHeader extends StatelessWidget {
  final LoanModel loan;
  final bool      isLender;

  const LoanSummaryHeader({
    super.key,
    required this.loan,
    required this.isLender,
  });

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final fmt     = NumberFormat('#,##,##0', 'en_IN');
    final fmtDate = DateFormat('dd MMM yyyy');
    final party   = isLender ? loan.borrowerName : loan.lenderName;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLender
              ? [const Color(0xFF4F6AF5), const Color(0xFF06B6D4)]
              : [const Color(0xFFEF4444), const Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role badge + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Badge(isLender ? '💸 YOU LENT' : '📥 YOU BORROWED'),
              _Badge(loan.status.toUpperCase()),
            ],
          ),

          const SizedBox(height: 16),

          // Party + amount
          Text(party ?? 'Unknown',
              style: tt.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text('₹${fmt.format(loan.amount)} @ ${loan.interestRate}% p.a.',
              style: tt.bodyMedium?.copyWith(color: Colors.white70)),

          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStat(
                  label: 'Remaining',
                  value: '₹${fmt.format(loan.remainingPrincipal)}'),
              _HeaderStat(
                  label: 'EMI',
                  value: '₹${fmt.format(loan.emiAmount)}'),
              _HeaderStat(
                  label: 'Tenure',
                  value: '${loan.tenureMonths} months'),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: loan.progressPercent,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(loan.progressPercent * 100).toStringAsFixed(1)}% repaid  •  '
            'EMI on ${loan.emiDate}${_ordinal(loan.emiDate)} of every month',
            style: tt.labelSmall?.copyWith(color: Colors.white70),
          ),
          if (loan.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Created on ${fmtDate.format(loan.createdAt!)}',
              style: tt.labelSmall?.copyWith(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          )),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value,
            style: tt.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
