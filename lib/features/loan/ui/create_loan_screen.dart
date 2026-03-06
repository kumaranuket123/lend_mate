import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/profile_model.dart';
import '../../../shared/widgets/lm_button.dart';
import '../../../shared/widgets/lm_text_field.dart';
import '../bloc/create_loan_cubit.dart';
import '../bloc/create_loan_state.dart';
import '../data/loan_repository.dart';
import 'widgets/borrower_search_sheet.dart';
import 'widgets/emi_preview_card.dart';
import 'widgets/section_header.dart';

class CreateLoanScreen extends StatelessWidget {
  const CreateLoanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateLoanCubit(LoanRepository()),
      child: const _CreateLoanView(),
    );
  }
}

class _CreateLoanView extends StatefulWidget {
  const _CreateLoanView();
  @override
  State<_CreateLoanView> createState() => _CreateLoanViewState();
}

class _CreateLoanViewState extends State<_CreateLoanView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amount      = TextEditingController();
  final _rate        = TextEditingController();
  final _tenure      = TextEditingController();
  final _emiDay      = TextEditingController(text: '1');
  final _lenderUpi   = TextEditingController();
  final _borrowerUpi = TextEditingController();
  final _notes       = TextEditingController();

  // State
  ProfileModel? _borrower;
  DateTime      _startDate  = DateTime.now();
  String        _extraMode  = 'reduce_tenure';
  bool          _showPreview = false;

  @override
  void dispose() {
    for (final c in [
      _amount, _rate, _tenure, _emiDay, _lenderUpi, _borrowerUpi, _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Derived values for preview ──
  double? get _parsedAmount => double.tryParse(_amount.text.replaceAll(',', ''));
  double? get _parsedRate   => double.tryParse(_rate.text);
  int?    get _parsedTenure => int.tryParse(_tenure.text);
  int     get _parsedEmiDay => int.tryParse(_emiDay.text) ?? 1;

  bool get _canPreview =>
      _parsedAmount != null &&
      _parsedRate   != null &&
      _parsedTenure != null &&
      _borrower     != null;

  void _pickBorrower() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CreateLoanCubit>(),
        child: BorrowerSearchSheet(
          onSelected: (p) => setState(() => _borrower = p),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _submit(CreateLoanCubit cubit) {
    if (!_formKey.currentState!.validate()) return;
    if (_borrower == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a borrower')),
      );
      return;
    }
    cubit.createLoan(
      borrowerId:         _borrower!.id,
      amount:             _parsedAmount!,
      interestRate:       _parsedRate!,
      tenureMonths:       _parsedTenure!,
      startDate:          _startDate,
      emiDate:            _parsedEmiDay,
      lenderUpi:  _lenderUpi.text.trim().isEmpty ? null : _lenderUpi.text.trim(),
      borrowerUpi: _borrowerUpi.text.trim().isEmpty ? null : _borrowerUpi.text.trim(),
      notes:      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      modeOnExtraPayment: _extraMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final tt    = Theme.of(context).textTheme;
    final cubit = context.read<CreateLoanCubit>();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('New Loan'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocListener<CreateLoanCubit, CreateLoanState>(
        listener: (ctx, state) {
          if (state is CreateLoanSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Loan created successfully!')),
            );
            ctx.pop(true); // return true → triggers home refresh
          }
          if (state is CreateLoanError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: cs.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── BORROWER ──────────────────────────
              const SectionHeader(
                title: 'Borrower',
                subtitle: 'Search registered users by name or phone',
              ),
              InkWell(
                onTap: _pickBorrower,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _borrower != null
                          ? cs.primary
                          : cs.outlineVariant,
                    ),
                  ),
                  child: _borrower == null
                      ? Row(children: [
                          Icon(Icons.person_search_outlined,
                              color: cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text('Tap to select borrower',
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ])
                      : Row(children: [
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            radius: 18,
                            child: Text(
                              _borrower!.name[0].toUpperCase(),
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
                                Text(_borrower!.name,
                                    style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600)),
                                if (_borrower!.phone != null)
                                  Text(_borrower!.phone!,
                                      style: tt.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_outlined,
                              color: cs.primary, size: 18),
                        ]),
                ),
              ),

              const SizedBox(height: 28),

              // ── LOAN DETAILS ───────────────────────
              const SectionHeader(title: 'Loan Details'),

              LmTextField(
                label: 'Principal Amount (₹)',
                controller: _amount,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.currency_rupee),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter valid amount';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                  child: LmTextField(
                    label: 'Interest Rate (% p.a.)',
                    controller: _rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.percent),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0 || n > 100) return 'Enter 0–100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LmTextField(
                    label: 'Tenure (months)',
                    controller: _tenure,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.date_range_outlined),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter months';
                      return null;
                    },
                  ),
                ),
              ]),

              const SizedBox(height: 14),

              Row(children: [
                // Start Date picker
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.calendar_month_outlined),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
                        style: tt.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // EMI day
                Expanded(
                  child: LmTextField(
                    label: 'EMI Day (1–28)',
                    controller: _emiDay,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.event_repeat_outlined),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 28) return 'Enter 1–28';
                      return null;
                    },
                  ),
                ),
              ]),

              const SizedBox(height: 28),

              // ── EXTRA PAYMENT MODE ─────────────────
              const SectionHeader(
                title: 'Extra Payment Mode',
                subtitle: 'When borrower pays extra, what should reduce?',
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'reduce_tenure',
                    label: Text('Reduce Tenure'),
                    icon: Icon(Icons.compress_outlined),
                  ),
                  ButtonSegment(
                    value: 'reduce_interest',
                    label: Text('Reduce Interest'),
                    icon: Icon(Icons.trending_down_outlined),
                  ),
                ],
                selected: {_extraMode},
                onSelectionChanged: (s) =>
                    setState(() => _extraMode = s.first),
              ),

              const SizedBox(height: 28),

              // ── UPI IDs ────────────────────────────
              const SectionHeader(
                title: 'UPI IDs (Optional)',
                subtitle: 'Helps track where payments should be sent',
              ),
              LmTextField(
                label: 'Your UPI ID (Lender)',
                controller: _lenderUpi,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              const SizedBox(height: 14),
              LmTextField(
                label: "Borrower's UPI ID",
                controller: _borrowerUpi,
                keyboardType: TextInputType.emailAddress,
                prefixIcon:
                    const Icon(Icons.account_balance_wallet_outlined),
              ),

              const SizedBox(height: 28),

              // ── NOTES ─────────────────────────────
              const SectionHeader(title: 'Notes (Optional)'),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Purpose of loan, any terms agreed…',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── EMI PREVIEW ────────────────────────
              if (_canPreview) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(title: 'EMI Preview'),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showPreview = !_showPreview),
                      icon: Icon(_showPreview
                          ? Icons.expand_less
                          : Icons.expand_more),
                      label: Text(_showPreview ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                if (_showPreview)
                  EmiPreviewCard(
                    principal: _parsedAmount!,
                    annualRate: _parsedRate!,
                    months:    _parsedTenure!,
                    startDate: _startDate,
                    emiDay:    _parsedEmiDay,
                  ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        color: cs.onSurfaceVariant, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fill in amount, interest, tenure & select a borrower to see EMI preview.',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
              ],

              // ── SUBMIT ─────────────────────────────
              BlocBuilder<CreateLoanCubit, CreateLoanState>(
                builder: (_, state) => LmButton(
                  label: 'Create Loan',
                  loading: state is CreateLoanLoading,
                  onPressed: () => _submit(cubit),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
