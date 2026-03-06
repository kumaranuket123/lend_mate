import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/supabase_client.dart';
import '../../../models/emi_schedule_model.dart';
import '../../../models/payment_model.dart';
import '../bloc/loan_detail_cubit.dart';
import '../bloc/loan_detail_state.dart';
import '../data/loan_detail_repository.dart';
import 'widgets/emi_schedule_row.dart';
import 'widgets/loan_summary_header.dart';
import 'widgets/payment_action_sheet.dart';

class LoanDetailScreen extends StatelessWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoanDetailCubit(LoanDetailRepository(), loanId)..load(),
      child: _LoanDetailView(loanId: loanId),
    );
  }
}

class _LoanDetailView extends StatefulWidget {
  final String loanId;
  const _LoanDetailView({required this.loanId});

  @override
  State<_LoanDetailView> createState() => _LoanDetailViewState();
}

class _LoanDetailViewState extends State<_LoanDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showPaySheet(
      BuildContext ctx, EmiScheduleModel emi, LoanDetailCubit cubit) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PaymentActionSheet(
        emi: emi,
        onConfirm: (File? proof) {
          cubit.markEmiPaid(
            emiScheduleId: emi.id,
            amount:        emi.emiAmount,
            proofFile:     proof,
          );
        },
      ),
    );
  }

  void _showApproveDialog(
      BuildContext ctx, PaymentModel pmt, LoanDetailCubit cubit) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Approve Payment?'),
        content: Text(
          'Confirm receipt of ₹${pmt.amount.toStringAsFixed(0)} from borrower.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.approvePayment(pmt.id);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: const Text(
          'This will permanently delete the loan and all its EMI schedule and payment records. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<LoanDetailCubit>().deleteLoan();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext ctx, PaymentModel pmt, LoanDetailCubit cubit) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Reject Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Screenshot not visible',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              cubit.rejectPayment(pmt.id, ctrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final tt    = Theme.of(context).textTheme;
    final myUid = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<LoanDetailCubit>().load(),
          ),
          BlocBuilder<LoanDetailCubit, LoanDetailState>(
            builder: (ctx, state) {
              if (state is! LoanDetailLoaded) return const SizedBox.shrink();
              final isBorrower = state.loan.borrowerId == myUid;
              if (!isBorrower) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Extra Payment',
                onPressed: () async {
                  final result = await context
                      .push('/extra-payment/${widget.loanId}');
                  if (result == true && ctx.mounted) {
                    ctx.read<LoanDetailCubit>().load();
                  }
                },
              );
            },
          ),
          BlocBuilder<LoanDetailCubit, LoanDetailState>(
            builder: (ctx, state) {
              if (state is! LoanDetailLoaded) return const SizedBox.shrink();
              if (state.loan.lenderId != myUid) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                tooltip: 'Delete Loan',
                onPressed: () => _showDeleteDialog(ctx),
              );
            },
          ),
        ],
      ),

      body: BlocConsumer<LoanDetailCubit, LoanDetailState>(
        listener: (ctx, state) {
          if (state is LoanDetailActionSuccess) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.msg)));
          }
          if (state is LoanDetailActionError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.msg),
              backgroundColor: cs.error,
            ));
          }
          if (state is LoanDetailDeleted) {
            context.pop(true); // return true so home refreshes
          }
        },
        builder: (ctx, state) {
          if (state is LoanDetailLoading ||
              state is LoanDetailInitial ||
              state is LoanDetailActionLoading ||
              state is LoanDetailDeleted) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LoanDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.msg),
                  TextButton(
                    onPressed: () => ctx.read<LoanDetailCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded   = state as LoanDetailLoaded;
          final loan     = loaded.loan;
          final isLender = loan.lenderId == myUid;
          final cubit    = ctx.read<LoanDetailCubit>();

          final pendingPayments = loaded.payments
              .where((p) => !p.lenderApproved && p.borrowerApproved)
              .toList();

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: LoanSummaryHeader(loan: loan, isLender: isLender),
              ),

              // Progress chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _StatChip(
                        icon: Icons.check_circle_outline,
                        label: '${loaded.paidCount} Paid',
                        color: Colors.green),
                    const SizedBox(width: 8),
                    _StatChip(
                        icon: Icons.pending_outlined,
                        label: '${loaded.pendingCount} Pending',
                        color: cs.primary),
                    const SizedBox(width: 8),
                    _StatChip(
                        icon: Icons.calendar_month_outlined,
                        label: '${loaded.schedule.length} Total',
                        color: cs.onSurfaceVariant),
                  ]),
                ),
              ),

              // Lender: approval banner
              if (isLender && pendingPayments.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${pendingPayments.length} payment(s) awaiting your approval',
                          style: tt.bodySmall
                              ?.copyWith(color: Colors.orange.shade800),
                        ),
                      ),
                    ]),
                  ),
                ),

              // Sticky tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBar(
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'EMI Schedule'),
                      Tab(text: 'Payment History'),
                    ],
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            body: TabBarView(
              controller: _tabs,
              children: [

                // ── Tab 1: EMI Schedule ──────────────────
                Builder(builder: (ctx) {
                  // Only the earliest unpaid EMI (lowest emi_number) is payable
                  final nextPayable = loaded.schedule
                      .where((e) => e.status == 'pending' || e.isOverdue)
                      .toList()
                    ..sort((a, b) => a.emiNumber.compareTo(b.emiNumber));
                  final nextPayableId =
                      nextPayable.isNotEmpty ? nextPayable.first.id : null;

                  return RefreshIndicator(
                    onRefresh: () => cubit.load(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: loaded.schedule.length,
                      itemBuilder: (_, i) {
                        final emi = loaded.schedule[i];
                        final pmt = loaded.payments
                            .where((p) => p.emiScheduleId == emi.id)
                            .firstOrNull;

                        return EmiScheduleRow(
                          emi:      emi,
                          isLender: isLender,
                          onPay: (!isLender && emi.id == nextPayableId)
                              ? () => _showPaySheet(ctx, emi, cubit)
                              : null,
                          onApprove:
                              (isLender && emi.isPaid && pmt != null)
                                  ? () => _showApproveDialog(ctx, pmt, cubit)
                                  : null,
                        );
                      },
                    ),
                  );
                }),

                // ── Tab 2: Payment History ───────────────
                loaded.payments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: cs.outlineVariant),
                            const SizedBox(height: 12),
                            Text('No payments yet',
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: loaded.payments.length,
                        itemBuilder: (_, i) => _PaymentHistoryTile(
                          payment:   loaded.payments[i],
                          isLender:  isLender,
                          onApprove: (isLender &&
                                  !loaded.payments[i].lenderApproved)
                              ? () => _showApproveDialog(
                                    ctx, loaded.payments[i], cubit)
                              : null,
                          onReject: (isLender &&
                                  !loaded.payments[i].lenderApproved)
                              ? () => _showRejectDialog(
                                    ctx, loaded.payments[i], cubit)
                              : null,
                        ),
                      ),
              ],
            ),
          );
        },
      ),

      // FAB: Borrower quick-pay next EMI
      floatingActionButton: BlocBuilder<LoanDetailCubit, LoanDetailState>(
        builder: (ctx, state) {
          if (state is! LoanDetailLoaded) return const SizedBox.shrink();
          final isLender = state.loan.lenderId == myUid;
          if (isLender) return const SizedBox.shrink();

          final nextEmi = state.schedule
              .where((e) => e.status == 'pending' || e.isOverdue)
              .firstOrNull;
          if (nextEmi == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showPaySheet(
                ctx, nextEmi, ctx.read<LoanDetailCubit>()),
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Pay Next EMI'),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          );
        },
      ),
    );
  }
}

// ── Payment history tile ──────────────────────────────────
class _PaymentHistoryTile extends StatelessWidget {
  final PaymentModel  payment;
  final bool          isLender;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _PaymentHistoryTile({
    required this.payment,
    required this.isLender,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final fmt     = NumberFormat('#,##,##0', 'en_IN');
    final fmtDate = DateFormat('dd MMM yyyy, hh:mm a');

    final approved = payment.fullyApproved;
    final color    = approved ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  payment.type == 'closure'
                      ? Icons.lock_outline_rounded
                      : payment.type == 'extra'
                          ? Icons.add_circle_outline
                          : Icons.receipt_outlined,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${fmt.format(payment.amount)}  •  '
                      '${payment.type == 'closure' ? 'Closure Payment' : payment.type == 'extra' ? 'Extra Payment' : 'EMI Payment'}',
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(fmtDate.format(payment.paymentDate),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              // Approval dots
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ApprovalDot(label: 'B', approved: payment.borrowerApproved),
                  const SizedBox(height: 4),
                  _ApprovalDot(label: 'L', approved: payment.lenderApproved),
                ],
              ),
            ]),

            // Proof thumbnail
            if (payment.proofUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  payment.proofUrl!,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 40,
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],

            // Rejection reason
            if (payment.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: cs.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(payment.rejectionReason!,
                        style:
                            tt.labelSmall?.copyWith(color: cs.error)),
                  ),
                ]),
              ),
            ],

            // Lender action buttons
            if (isLender && !payment.lenderApproved) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withOpacity(0.4)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApprovalDot extends StatelessWidget {
  final String label;
  final bool   approved;
  const _ApprovalDot({required this.label, required this.approved});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        Icon(
          approved ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: approved ? Colors.green : Colors.grey,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }
}

// Sticky tab bar delegate
class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBar(this.tabBar);

  @override
  Widget build(BuildContext ctx, double shrink, bool overlaps) =>
      Container(
        color: Theme.of(ctx).colorScheme.surface,
        child: tabBar,
      );

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_) => false;
}
