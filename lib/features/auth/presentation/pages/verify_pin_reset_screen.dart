import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class VerifyPinResetScreen extends StatefulWidget {
  final String phoneNumber;
  final bool hasEmail;
  final String? debugCode;

  const VerifyPinResetScreen({
    super.key,
    required this.phoneNumber,
    this.hasEmail = false,
    this.debugCode,
  });

  @override
  State<VerifyPinResetScreen> createState() => _VerifyPinResetScreenState();
}

class _VerifyPinResetScreenState extends State<VerifyPinResetScreen> {
  final _codeController = TextEditingController();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    if (widget.debugCode != null) {
      _codeController.text = widget.debugCode!;
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the 6-digit verification code.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      VerifyPinResetCodeRequested(
        phoneNumber: widget.phoneNumber,
        code: code,
      ),
    );
  }

  void _resendCode() {
    if (_countdown > 0) return;
    context.read<AuthBloc>().add(
      ForgotPinRequested(phoneNumber: widget.phoneNumber),
    );
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PinResetCodeVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Code verified! Now create your new PIN.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.push(
            '/reset-pin',
            extra: {
              'phone_number': state.phoneNumber,
              'reset_token': state.resetToken,
            },
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } else if (state is ForgotPinCodeSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New verification code sent!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppTheme.successColor,
            ),
          );
          if (state.debugCode != null) {
            setState(() {
              _codeController.text = state.debugCode!;
            });
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
          appBar: const CustomAppBar(
            title: '',
            showBackButton: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // ── Hero Icon ─────────────────────────────────────
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mark_email_read_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 24),

                  // ── Title & Subtitle ──────────────────────────────
                  Text(
                    'Verify Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 10),

                  Text(
                    widget.hasEmail
                        ? 'We sent a 6-digit recovery code to ${widget.phoneNumber} and your registered email address.'
                        : 'We sent a 6-digit recovery code to ${widget.phoneNumber}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 36),

                  // ── Code Input Card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _codeController,
                          label: '6-Digit Code',
                          hintText: '••••••',
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _countdown > 0
                                  ? 'Resend code in ${_countdown}s'
                                  : 'Didn\'t get the code?',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              ),
                            ),
                            TextButton(
                              onPressed: _countdown == 0 && !isLoading ? _resendCode : null,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _countdown == 0 ? AppTheme.primaryColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 32),

                  // ── Verify Code Button ────────────────────────────
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Verify Code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.check_circle_outline_rounded, size: 20),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
