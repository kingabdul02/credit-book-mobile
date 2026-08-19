import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/transaction_pin_service.dart';

class ResetTransactionPinModal extends StatefulWidget {
  const ResetTransactionPinModal({super.key});

  @override
  State<ResetTransactionPinModal> createState() => _ResetTransactionPinModalState();
}

enum _ResetStep { enterCurrent, enterNew, confirmNew }

class _ResetTransactionPinModalState extends State<ResetTransactionPinModal>
    with SingleTickerProviderStateMixin {
  _ResetStep _step = _ResetStep.enterCurrent;
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _hasError = false;
  String _errorMessage = '';
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

  String get _activePin {
    switch (_step) {
      case _ResetStep.enterCurrent: return _currentPin;
      case _ResetStep.enterNew: return _newPin;
      case _ResetStep.confirmNew: return _confirmPin;
    }
  }

  void _onKeyPress(String key) {
    if (key == 'DEL') {
      setState(() {
        _hasError = false;
        switch (_step) {
          case _ResetStep.enterCurrent: if (_currentPin.isNotEmpty) _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          case _ResetStep.enterNew: if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
          case _ResetStep.confirmNew: if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      });
      return;
    }

    setState(() {
      _hasError = false;
      switch (_step) {
        case _ResetStep.enterCurrent:
          if (_currentPin.length < 4) _currentPin += key;
          if (_currentPin.length == 4) _verifyCurrentPin();
        case _ResetStep.enterNew:
          if (_newPin.length < 4) _newPin += key;
          if (_newPin.length == 4) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) setState(() => _step = _ResetStep.confirmNew);
            });
          }
        case _ResetStep.confirmNew:
          if (_confirmPin.length < 4) _confirmPin += key;
          if (_confirmPin.length == 4) _saveNewPin();
      }
    });
  }

  Future<void> _verifyCurrentPin() async {
    final valid = await TransactionPinService.verifyPin(_currentPin);
    if (valid) {
      if (mounted) setState(() => _step = _ResetStep.enterNew);
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Try again.';
        _currentPin = '';
      });
    }
  }

  Future<void> _saveNewPin() async {
    if (_newPin == _confirmPin) {
      await TransactionPinService.setPin(_newPin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      _shakeController.forward(from: 0);
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs don\'t match. Try again.';
        _confirmPin = '';
      });
    }
  }

  (String, String) get _stepText {
    switch (_step) {
      case _ResetStep.enterCurrent: return ('Enter Current PIN', 'Verify your existing PIN first');
      case _ResetStep.enterNew: return ('Enter New PIN', 'Create your new 4-digit PIN');
      case _ResetStep.confirmNew: return ('Confirm New PIN', 'Re-enter your new PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _stepText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lock_reset, size: 28, color: AppTheme.primaryColor),
          ).animate(key: ValueKey(_step)).scale(duration: 300.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),

          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: AppTheme.textDark.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),

          // Step indicator
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _ResetStep.values.map((s) {
              final active = s.index <= _step.index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryColor : AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

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
                final filled = i < _activePin.length;
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
            Text(_errorMessage, style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.w600))
                .animate().fadeIn(duration: 200.ms),
          ],
          const SizedBox(height: 40),

          _buildKeypad(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 16),
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
      onTap: () => icon == Icons.fingerprint ? null : _onKeyPress(icon != null ? 'DEL' : value),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 28, color: iconColor ?? AppTheme.textMuted)
            : Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      ),
    );
  }
}
