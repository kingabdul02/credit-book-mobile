import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/transaction_pin_service.dart';
import '../../../../core/services/face_auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';

class ConfirmTransactionPinModal extends StatefulWidget {
  final String contactName;
  final double amount;

  const ConfirmTransactionPinModal({
    super.key,
    required this.contactName,
    required this.amount,
  });

  @override
  State<ConfirmTransactionPinModal> createState() => _ConfirmTransactionPinModalState();
}

class _ConfirmTransactionPinModalState extends State<ConfirmTransactionPinModal>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _hasError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _onKeyPress(String key) async {
    if (key == 'DEL') {
      setState(() {
        _hasError = false;
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      });
      return;
    }

    if (_pin.length >= 4) return;

    setState(() {
      _hasError = false;
      _pin += key;
    });

    if (_pin.length == 4) {
      await Future.delayed(const Duration(milliseconds: 150));
      final valid = await TransactionPinService.verifyPin(_pin);
      if (!mounted) return;

      if (valid) {
        Navigator.of(context).pop(true);
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _hasError = true;
          _pin = '';
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final hasBiometricsSetup = await FaceAuthService.isFaceRegistered();
    if (!hasBiometricsSetup) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Biometrics not enabled. Enable it in settings.', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.errorColor,
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/settings/face-setup');
            },
          ),
        ),
      );
      return;
    }

    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometrics not supported on this device', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.errorColor),
        );
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to confirm transaction',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Transaction summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.payments_outlined, size: 26, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 12),
                Text('Sending to', style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  widget.contactName,
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                Text('TOTAL AMOUNT', style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  formatCurrency.format(widget.amount),
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          const SizedBox(height: 28),

          Text('Enter your 4-digit PIN', style: TextStyle(color: AppTheme.textDark.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // Dot indicators
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shake = math.sin(_shakeController.value * math.pi * 4) * 8;
              return Transform.translate(offset: Offset(shake, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError ? AppTheme.errorColor : filled ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: _hasError ? AppTheme.errorColor : filled ? AppTheme.primaryColor : AppTheme.textMuted.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 8),
            Text('Incorrect PIN. Try again.', style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w600))
                .animate().fadeIn(duration: 200.ms),
          ],
          const SizedBox(height: 32),

          // Keypad
          _buildKeypad(),
          const SizedBox(height: 16),

          // Security badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text('Secure 256-bit Encryption', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel Transaction',
              style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('', icon: Icons.fingerprint, iconColor: AppTheme.primaryColor),
            const SizedBox(width: 24),
            _buildKey('0'),
            const SizedBox(width: 24),
            _buildKey('DEL', icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.asMap().entries.map((e) {
        return Row(children: [if (e.key > 0) const SizedBox(width: 24), _buildKey(e.value)]);
      }).toList(),
    );
  }

  Widget _buildKey(String value, {IconData? icon, Color? iconColor}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => icon == Icons.fingerprint ? _authenticateWithBiometrics() : _onKeyPress(icon != null ? 'DEL' : value),
      child: Container(
        width: 72,
        height: 68,
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 28, color: iconColor ?? AppTheme.textMuted)
            : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      ),
    );
  }
}
