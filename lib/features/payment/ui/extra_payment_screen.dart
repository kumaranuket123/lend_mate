import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../shared/widgets/lm_button.dart';
import '../../../shared/widgets/lm_text_field.dart';
import '../../../utils/loan_recalculator.dart';
import '../bloc/extra_payment_cubit.dart';
import '../bloc/extra_payment_state.dart';
import '../data/extra_payment_repository.dart';
import 'widgets/recalc_preview_card.dart';

class ExtraPaymentScreen extends StatelessWidget {
  final String loanId;
  const ExtraPaymentScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ExtraPaymentCubit(ExtraPaymentRepository(), loanId)..loadLoan(),
      child: const _ExtraPaymentView(),
    );
  }
}

class _ExtraPaymentView extends StatefulWidget {
  const _ExtraPaymentView();
  @override
  State<_ExtraPaymentView> createState() => _ExtraPaymentViewState();
}

class _ExtraPaymentViewState extends State<_ExtraPaymentView> {
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  File?  _proofFile;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  void _preview(LoanModel loan, List<EmiScheduleModel> pendingSchedule,
      ExtraPaymentCubit cubit) {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    cubit.previewRecalc(
      loan:            loan,
      extraAmount:     amount,
      pendingSchedule: pendingSchedule,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Extra Payment'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<ExtraPaymentCubit, ExtraPaymentState>(
        listener: (ctx, state) {
          if (state is ExtraPaymentSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.loanClosed
                    ? 'Full payment submitted! Awaiting lender approval to close the loan.'
                    : 'Extra payment submitted! Loan recalculated.'),
                backgroundColor: Colors.green,
              ),
            );
            ctx.pop(true);
          }
          if (state is ExtraPaymentError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: cs.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          final cubit = ctx.read<ExtraPaymentCubit>();

          if (state is ExtraPaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ExtraPaymentInitial || state is ExtraPaymentError) {
            return Center(
              child: TextButton.icon(
                onPressed: cubit.loadLoan,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          late LoanModel              loan;
          late List<EmiScheduleModel> pendingSchedule;
          RecalcResult?               recalc;
          double?                     previewAmount;
          bool                        isClosurePreview = false;

          if (state is ExtraPaymentLoanLoaded) {
            loan            = state.loan;
            pendingSchedule = state.pendingSchedule;
          } else if (state is ExtraPaymentPreviewReady) {
            loan            = state.loan;
            pendingSchedule = state.pendingSchedule;
            recalc          = state.recalc;
            previewAmount   = state.extraAmount;
          } else if (state is ExtraPaymentClosurePreview) {
            loan            = state.loan;
            pendingSchedule = const [];
            isClosurePreview = true;
          } else {
            return const SizedBox.shrink();
          }

          final fmt = NumberFormat('#,##,##0', 'en_IN');

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── Loan info banner ────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: cs.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      (loan.borrowerName ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan to ${loan.borrowerName ?? 'borrower'}',
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Remaining: ₹${fmt.format(loan.remainingPrincipal)}  '
                          '•  Mode: ${loan.modeOnExtraPayment == 'reduce_tenure' ? 'Reduce Tenure' : 'Reduce EMI'}',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Amount input (hidden in closure mode) ───────
              if (!isClosurePreview) ...[
                Text('Extra Amount (₹)',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    )),
                const SizedBox(height: 4),
                Text('Must be less than remaining principal',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 10),

                Form(
                  key: _formKey,
                  child: LmTextField(
                    label: 'Amount',
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: const Icon(Icons.currency_rupee),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      if (n >= loan.remainingPrincipal) {
                        return 'Must be less than ₹${fmt.format(loan.remainingPrincipal)}';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Quick amount chips ─────────────────
                Wrap(
                  spacing: 8,
                  children: [
                    _QuickChip(
                        label: '₹5,000',
                        onTap: () => _amountCtrl.text = '5000'),
                    _QuickChip(
                        label: '₹10,000',
                        onTap: () => _amountCtrl.text = '10000'),
                    _QuickChip(
                        label: '₹25,000',
                        onTap: () => _amountCtrl.text = '25000'),
                    _QuickChip(
                      label: '50%',
                      onTap: () => _amountCtrl.text =
                          (loan.remainingPrincipal / 2).toStringAsFixed(0),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Close loan option ──────────────────
                OutlinedButton.icon(
                  onPressed: () => cubit.previewClosure(loan),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    loan.remainingPrincipal > 0
                        ? 'Pay Full & Close Loan  •  ₹${fmt.format(loan.remainingPrincipal)}'
                        : 'Close Loan  •  All EMIs Paid',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade300),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Proof upload ─────────────────────────
              Text('Payment Proof (optional)',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  )),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickProof,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _proofFile != null
                          ? cs.primary
                          : cs.outlineVariant,
                    ),
                  ),
                  child: _proofFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child:
                              Stack(fit: StackFit.expand, children: [
                            Image.file(_proofFile!, fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _proofFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ]),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                color: cs.onSurfaceVariant),
                            const SizedBox(height: 6),
                            Text('Upload screenshot',
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Closure preview card ─────────────────
              if (isClosurePreview) ...[
                _ClosurePreviewCard(loan: loan, fmt: fmt),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => cubit.reset(loan,pendingSchedule),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => cubit.confirmClosure(
                        loan:      loan,
                        proofFile: _proofFile,
                      ),
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: const Text('Close Loan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              ],

              // ── Preview button ───────────────────────
              if (!isClosurePreview && recalc == null)
                OutlinedButton.icon(
                  onPressed: () => _preview(loan, pendingSchedule, cubit),
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Preview Recalculation'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              // ── Recalculation preview ────────────────
              if (!isClosurePreview && recalc != null && previewAmount != null) ...[
                RecalcPreviewCard(
                  loan:        loan,
                  extraAmount: previewAmount,
                  recalc:      recalc,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => cubit.reset(loan, pendingSchedule),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Edit Amount'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LmButton(
                      label: 'Confirm & Pay',
                      onPressed: () => cubit.confirmPayment(
                        loan:        loan,
                        extraAmount: previewAmount!,
                        recalc:      recalc!,
                        proofFile:   _proofFile,
                      ),
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _ClosurePreviewCard extends StatelessWidget {
  final LoanModel        loan;
  final NumberFormat     fmt;
  const _ClosurePreviewCard({required this.loan, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Close Loan',
                style: tt.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _Row(
            label: 'Payment Amount',
            value: loan.remainingPrincipal > 0
                ? '₹${fmt.format(loan.remainingPrincipal)}'
                : 'All EMIs already paid',
          ),
          const SizedBox(height: 8),
          _Row(label: 'Remaining EMIs Cancelled', value: 'All cleared'),
          const SizedBox(height: 8),
          _Row(label: 'Loan Status', value: 'CLOSED'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The lender will need to approve this payment before the loan is officially marked as closed.',
                  style: tt.labelSmall?.copyWith(color: Colors.white70),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.labelMedium?.copyWith(color: Colors.white70)),
        Text(value,
            style: tt.labelMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: cs.primaryContainer.withOpacity(0.4),
      labelStyle:
          TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
    );
  }
}
