import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class TwoFactorModal extends StatefulWidget {
  final User user;

  const TwoFactorModal({super.key, required this.user});

  @override
  State<TwoFactorModal> createState() => _TwoFactorModalState();
}

class _TwoFactorModalState extends State<TwoFactorModal> {
  late String _selectedMethod;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isStepVerify = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _secret;
  String? _otpauthUrl;
  String? _qrCodeUrl;
  String? _debugCode;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Default to authenticator
    _selectedMethod = widget.user.twoFactorMethod.isNotEmpty ? widget.user.twoFactorMethod : 'authenticator';
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _requestAuthenticatorSetup() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    context.read<AuthBloc>().add(
      const SendTwoFactorSetupCodeRequested(method: 'authenticator'),
    );
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _handleSendSetupCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_selectedMethod == 'email') {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid email address.';
        });
        return;
      }
      context.read<AuthBloc>().add(
        SendTwoFactorSetupCodeRequested(method: 'email', email: email),
      );
    } else if (_selectedMethod == 'phone') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty || phone.length < 7) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid phone number.';
        });
        return;
      }
      context.read<AuthBloc>().add(
        SendTwoFactorSetupCodeRequested(method: 'phone', phoneNumber: phone),
      );
    } else {
      _requestAuthenticatorSetup();
    }
  }

  Future<void> _handleVerifyCode() async {
    final code = _codeControllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    context.read<AuthBloc>().add(
      EnableTwoFactorRequested(code: code, method: _selectedMethod),
    );
  }

  void _handleDisable() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable Two-Factor Auth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your 6-digit login PIN to confirm disabling Two-Factor Authentication:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '••••••',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              final pin = pinController.text.trim();
              if (pin.length == 6) {
                Navigator.of(dialogContext).pop();
                setState(() => _isLoading = true);
                context.read<AuthBloc>().add(DisableTwoFactorRequested(pin: pin));
              }
            },
            child: const Text('Disable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.user.twoFactorEnabled;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is TwoFactorSetupDataLoaded) {
          setState(() {
            _isLoading = false;
            _selectedMethod = state.method;
            _secret = state.secret;
            _otpauthUrl = state.otpauthUrl;
            _qrCodeUrl = state.qrCodeUrl;
            _debugCode = state.debugCode;
            _errorMessage = null;
            if (state.method != 'authenticator') {
              _isStepVerify = true;
              _startCountdown();
            }
          });
        } else if (state is TwoFactorSetupCodeSent) {
          setState(() {
            _isLoading = false;
            _isStepVerify = true;
            _debugCode = state.debugCode;
            _errorMessage = null;
          });
          _startCountdown();
        } else if (state is AuthSuccess) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryColor,
              content: Text(
                state.successMessage ?? 'Two-factor authentication updated.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
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
              if (isEnabled)
                _buildEnabledView(isDark)
              else if (_isStepVerify)
                _buildVerifyStep(isDark)
              else
                _buildSetupStep(isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnabledView(bool isDark) {
    String methodLabel;
    IconData methodIcon;
    switch (widget.user.twoFactorMethod) {
      case 'email':
        methodLabel = 'Email Verification';
        methodIcon = Icons.email_rounded;
        break;
      case 'phone':
        methodLabel = 'SMS / Phone Verification';
        methodIcon = Icons.sms_rounded;
        break;
      case 'authenticator':
      default:
        methodLabel = 'Authenticator App (Default)';
        methodIcon = Icons.qr_code_scanner_rounded;
        break;
    }

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          '2FA is Active',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your CreditBook account is secured with Two-Factor Authentication. Whenever you log in, verification is required via:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(methodIcon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                methodLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleDisable,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Disable Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Two-Factor Authentication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Enhanced account security', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Choose your preferred verification method to protect your financial ledger. Authenticator App is the recommended default.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Method Selector Cards
        // 1. Authenticator App (Default)
        _buildMethodCard(
          isDark: isDark,
          method: 'authenticator',
          title: 'Authenticator App',
          subtitle: 'Google Authenticator, Authy, Apple Passwords',
          badge: 'RECOMMENDED / DEFAULT',
          icon: Icons.qr_code_scanner_rounded,
        ),
        const SizedBox(height: 10),
        // 2. Email Verification
        _buildMethodCard(
          isDark: isDark,
          method: 'email',
          title: 'Email Verification',
          subtitle: 'Receive a 6-digit one-time code in your email',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 10),
        // 3. SMS / Phone
        _buildMethodCard(
          isDark: isDark,
          method: 'phone',
          title: 'SMS / Phone Number',
          subtitle: 'Receive a 6-digit code via SMS text message',
          icon: Icons.sms_outlined,
        ),

        const SizedBox(height: 20),

        // Method-specific input details
        if (_selectedMethod == 'email') ...[
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email address',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              filled: true,
              fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_selectedMethod == 'phone') ...[
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +2348012345678',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              filled: true,
              fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_selectedMethod == 'authenticator') ...[
          if (_secret != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (_qrCodeUrl != null) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _qrCodeUrl!,
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.qr_code_2_rounded,
                            size: 100,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Secret Setup Key:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _secret!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Copy key',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _secret!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Secret key copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],

        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
          const SizedBox(height: 12),
        ],

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_selectedMethod == 'authenticator') {
                      if (_secret == null) {
                        _requestAuthenticatorSetup();
                      } else {
                        setState(() => _isStepVerify = true);
                      }
                    } else {
                      _handleSendSetupCode();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _selectedMethod == 'authenticator'
                        ? (_secret == null ? 'Set Up Authenticator' : 'Next: Enter 6-Digit Code')
                        : 'Send Verification Code',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required bool isDark,
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.darkSurface : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyStep(bool isDark) {
    String verifyInstruction;
    if (_selectedMethod == 'authenticator') {
      verifyInstruction = 'Enter the 6-digit code currently displayed in your Authenticator app:';
    } else if (_selectedMethod == 'email') {
      verifyInstruction = 'Enter the 6-digit code sent to ${_emailController.text.trim()}:';
    } else {
      verifyInstruction = 'Enter the 6-digit code sent to ${_phoneController.text.trim()}:';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                setState(() => _isStepVerify = false);
              },
            ),
            const Expanded(
              child: Text(
                'Confirm Verification Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          verifyInstruction,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        if (_selectedMethod == 'authenticator' && _secret != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    'Key: $_secret',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _secret!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secret key copied!'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_debugCode != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Text(
                  'Test Code: $_debugCode',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // 6-digit PIN entry
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                  if (index == 5 && value.isNotEmpty) {
                    _handleVerifyCode();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        if (_selectedMethod != 'authenticator') ...[
          Center(
            child: TextButton(
              onPressed: _resendCountdown == 0 && !_isLoading ? _handleSendSetupCode : null,
              child: Text(
                _resendCountdown > 0
                    ? 'Resend code in ${_resendCountdown}s'
                    : 'Resend Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _resendCountdown == 0 && !_isLoading
                      ? AppTheme.primaryColor
                      : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enable 2FA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
