import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class Verify2faScreen extends StatefulWidget {
  final String twoFactorToken;
  final String phoneNumber;
  final String? email;
  final String? debugCode;
  final String initialMethod;
  final List<String> availableMethods;
  final String? maskedPhone;
  final String? initialMessage;

  const Verify2faScreen({
    super.key,
    required this.twoFactorToken,
    required this.phoneNumber,
    this.email,
    this.debugCode,
    this.initialMethod = 'authenticator',
    this.availableMethods = const ['authenticator', 'email', 'phone'],
    this.maskedPhone,
    this.initialMessage,
  });

  @override
  State<Verify2faScreen> createState() => _Verify2faScreenState();
}

class _Verify2faScreenState extends State<Verify2faScreen> {
  final _codeController = TextEditingController();
  late String _activeMethod;
  late List<String> _availableMethods;
  int _countdown = 60;
  Timer? _timer;
  String? _currentDebugCode;

  @override
  void initState() {
    super.initState();
    _activeMethod = widget.initialMethod;
    _availableMethods = widget.availableMethods;
    _currentDebugCode = widget.debugCode;
    if (_activeMethod != 'authenticator') {
      _startCountdown();
    }
    if (_currentDebugCode != null && _currentDebugCode!.isNotEmpty) {
      _codeController.text = _currentDebugCode!;
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
      VerifyTwoFactorRequested(
        twoFactorToken: widget.twoFactorToken,
        code: code,
        method: _activeMethod,
      ),
    );
  }

  void _resendCode() {
    if (_countdown > 0) return;
    context.read<AuthBloc>().add(
      ResendTwoFactorRequested(
        twoFactorToken: widget.twoFactorToken,
        method: _activeMethod,
      ),
    );
    _startCountdown();
  }

  void _switchMethod(String method) {
    if (method == _activeMethod) return;
    Navigator.of(context).pop(); // Close switch modal
    _codeController.clear();
    context.read<AuthBloc>().add(
      SwitchTwoFactorMethodRequested(
        twoFactorToken: widget.twoFactorToken,
        method: method,
      ),
    );
  }

  void _showMethodSelector(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Verification Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select how you would like to receive or verify your code:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              // Option 1: Authenticator App (Default)
              _buildMethodTile(
                isDark: isDark,
                method: 'authenticator',
                title: 'Authenticator App',
                subtitle: 'Code from Google Authenticator, Authy, or Apple',
                icon: Icons.qr_code_scanner_rounded,
                isRecommended: true,
                isSelected: _activeMethod == 'authenticator',
                onTap: () => _switchMethod('authenticator'),
              ),
              const SizedBox(height: 12),
              // Option 2: Email
              _buildMethodTile(
                isDark: isDark,
                method: 'email',
                title: 'Email Address',
                subtitle: widget.email != null && widget.email!.isNotEmpty
                    ? widget.email!
                    : 'Send 6-digit code to registered email',
                icon: Icons.email_outlined,
                isSelected: _activeMethod == 'email',
                onTap: () => _switchMethod('email'),
              ),
              const SizedBox(height: 12),
              // Option 3: Phone / SMS
              _buildMethodTile(
                isDark: isDark,
                method: 'phone',
                title: 'SMS / Phone Number',
                subtitle: widget.maskedPhone ?? widget.phoneNumber,
                icon: Icons.sms_outlined,
                isSelected: _activeMethod == 'phone',
                onTap: () => _switchMethod('phone'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMethodTile({
    required bool isDark,
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isRecommended = false,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.darkSurface : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthSuccess) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_phone_number', widget.phoneNumber);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Authentication successful! Welcome back.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppTheme.successColor,
              ),
            );
            context.go('/home');
          }
        } else if (state is AuthRequires2FA) {
          setState(() {
            _activeMethod = state.method;
            _currentDebugCode = state.debugCode;
            if (state.debugCode != null && state.debugCode!.isNotEmpty) {
              _codeController.text = state.debugCode!;
            }
          });
          if (_activeMethod != 'authenticator') {
            _startCountdown();
          }
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          }
        } else if (state is TwoFactorCodeResent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppTheme.successColor,
            ),
          );
          if (state.debugCode != null && state.debugCode!.isNotEmpty) {
            setState(() {
              _codeController.text = state.debugCode!;
            });
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        // Dynamic strings based on active method
        String title;
        String subtitle;
        IconData heroIcon;

        switch (_activeMethod) {
          case 'email':
            title = 'Email Verification';
            subtitle = widget.email != null && widget.email!.isNotEmpty
                ? 'We sent a 6-digit code to your email (${widget.email}).'
                : 'We sent a 6-digit code to your registered email address.';
            heroIcon = Icons.email_rounded;
            break;
          case 'phone':
            title = 'SMS Verification';
            subtitle = 'We sent a 6-digit code via SMS to ${widget.maskedPhone ?? widget.phoneNumber}.';
            heroIcon = Icons.sms_rounded;
            break;
          case 'authenticator':
          default:
            title = 'Authenticator App';
            subtitle = 'Enter the 6-digit code generated by your Authenticator app (e.g. Google Authenticator, Authy, Apple).';
            heroIcon = Icons.security_rounded;
            break;
        }

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
                  const SizedBox(height: 8),
                  // Hero Icon
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          heroIcon,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 20),

                  // Method badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _activeMethod == 'authenticator'
                                ? Icons.verified_user_rounded
                                : (_activeMethod == 'email' ? Icons.email_outlined : Icons.sms_outlined),
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _activeMethod == 'authenticator'
                                ? 'AUTHENTICATOR (DEFAULT)'
                                : (_activeMethod == 'email' ? 'EMAIL VERIFICATION' : 'SMS VERIFICATION'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Title & Subtitle
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 10),

                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 32),

                  // Code Input Card
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
                          label: '6-Digit Security Code',
                          hintText: '••••••',
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (val) {
                            if (val.trim().length == 6) {
                              _submit();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_activeMethod != 'authenticator') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _countdown > 0
                                    ? 'Resend code in ${_countdown}s'
                                    : 'Didn\'t receive code?',
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
                                    color: _countdown == 0 && !isLoading
                                        ? AppTheme.primaryColor
                                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Codes refresh automatically every 30 seconds.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 16),

                  // Switch verification method button
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => _showMethodSelector(isDark),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Try another verification method'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      side: BorderSide(
                        color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Back to Login link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
