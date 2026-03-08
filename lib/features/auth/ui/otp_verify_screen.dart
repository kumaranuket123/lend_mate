import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../shared/widgets/lm_button.dart';
import '../../../shared/widgets/lm_text_field.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _repo        = AuthRepository();
  static const _otpLength = 6;
  final _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
  final _otpFocusNodes  = List.generate(_otpLength, (_) => FocusNode());
  final _newPassword    = TextEditingController();
  final _confirmPass    = TextEditingController();
  final _formKey        = GlobalKey<FormState>();
  bool _loading         = false;
  bool _showPass        = false;

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPassword.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  String get _otp =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete $_otpLength-digit OTP'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.verifyOtpAndResetPassword(
        email:       widget.email,
        otp:         _otp,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful!')),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await _repo.sendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: BackButton(color: cs.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.mark_email_read_outlined,
                      color: cs.primary, size: 32),
                ),

                const SizedBox(height: 24),

                Text('Enter OTP',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── 6-box OTP input ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (i) => _OtpBox(
                    controller: _otpControllers[i],
                    focusNode:  _otpFocusNodes[i],
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _otpFocusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _otpFocusNodes[i - 1].requestFocus();
                      }
                    },
                  )),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resendOtp,
                    child: Text('Resend OTP',
                        style: TextStyle(color: cs.primary)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── New password ─────────────────────────────────────
                Text('New Password',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 10),

                LmTextField(
                  label: 'New Password',
                  controller: _newPassword,
                  obscure: !_showPass,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Min 6 characters'
                      : null,
                ),

                const SizedBox(height: 16),

                LmTextField(
                  label: 'Confirm Password',
                  controller: _confirmPass,
                  obscure: !_showPass,
                  prefixIcon: const Icon(Icons.lock_outline),
                  validator: (v) => v != _newPassword.text
                      ? 'Passwords do not match'
                      : null,
                ),

                const SizedBox(height: 32),

                LmButton(
                  label: 'Reset Password',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single OTP digit box ────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 52,
      height: 52,
      child: TextFormField(
        controller:    controller,
        focusNode:     focusNode,
        keyboardType:  TextInputType.number,
        textAlign:     TextAlign.center,
        maxLength:     1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}