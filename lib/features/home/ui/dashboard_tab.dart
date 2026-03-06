import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bloc/home_state.dart';

class DashboardTab extends StatelessWidget {
  final HomeLoaded state;
  const DashboardTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Lent',
                amount: '₹${fmt.format(state.totalLent)}',
                sub: '₹${fmt.format(state.lentOutstanding)} remaining',
                icon: Icons.trending_up_rounded,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Total Borrowed',
                amount: '₹${fmt.format(state.totalBorrowed)}',
                sub: '₹${fmt.format(state.borrowedOutstanding)} remaining',
                icon: Icons.trending_down_rounded,
                color: cs.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Net position card
        _NetPositionCard(state: state, fmt: fmt),

        const SizedBox(height: 20),

        Text('Active Loans',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),

        const SizedBox(height: 12),

        // Active loans summary list
        ..._buildActiveSummary(context, state),
      ],
    );
  }

  List<Widget> _buildActiveSummary(BuildContext context, HomeLoaded state) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final all = [
      ...state.lentLoans.where((l) => l.status == 'active').map(
            (l) => (loan: l, isLender: true)),
      ...state.borrowedLoans.where((l) => l.status == 'active').map(
            (l) => (loan: l, isLender: false)),
    ];

    if (all.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.handshake_outlined,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('No active loans',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        )
      ];
    }

    return all.map((item) {
      final color = item.isLender ? cs.tertiary : cs.error;
      final party = item.isLender
          ? item.loan.borrowerName ?? 'Unknown'
          : item.loan.lenderName ?? 'Unknown';
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              party[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(party, style: tt.titleSmall),
          subtitle: Text(
            item.isLender ? 'Lending' : 'Borrowing',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          trailing: Text(
            '₹${fmt.format(item.loan.remainingPrincipal)}',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final String sub;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: tt.labelMedium?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              )),
          const SizedBox(height: 4),
          Text(sub,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

class _NetPositionCard extends StatelessWidget {
  final HomeLoaded state;
  final NumberFormat fmt;

  const _NetPositionCard({required this.state, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final tt       = Theme.of(context).textTheme;
    final net      = state.lentOutstanding - state.borrowedOutstanding;
    final positive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: positive
              ? [const Color(0xFF4F6AF5), const Color(0xFF7C3AED)]
              : [const Color(0xFFEF4444), const Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Position',
                    style: tt.labelLarge?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '${positive ? '+' : '-'}₹${fmt.format(net.abs())}',
                  style: tt.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  positive
                      ? 'You are owed more than you owe'
                      : 'You owe more than you are owed',
                  style: tt.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Icon(
            positive
                ? Icons.account_balance_wallet_rounded
                : Icons.warning_amber_rounded,
            color: Colors.white30,
            size: 48,
          ),
        ],
      ),
    );
  }
}
