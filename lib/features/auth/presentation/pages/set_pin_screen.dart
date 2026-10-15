import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submitPin() {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 6) {
      _showError('PIN must be exactly 6 digits.');
      return;
    }

    if (pin != confirmPin) {
      _showError('PINs do not match. Please try again.');
      return;
    }

    context.read<AuthBloc>().add(SetPinRequested(pin: pin));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showError(state.message);
        } else if (state is PinSetSuccess) {
          context.go('/setup-photo');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppTheme.onBackground,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            
                            // Header
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 32, color: AppTheme.textDark),
                                const SizedBox(width: 8),
                                Text(
                                  'Secure Account',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                              
                            const SizedBox(height: 12),
                            
                            Text(
                              'Create a 6-digit PIN to securely access your ledger.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                              
                            const SizedBox(height: 32),

                            // Main Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.textMuted.withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    controller: _pinController,
                                    label: '6-Digit PIN',
                                    hintText: 'Enter 6-Digit PIN',
                                    prefix: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Icon(Icons.lock_outline_rounded),
                                    ),
                                    isPassword: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  
                                  CustomTextField(
                                    controller: _confirmPinController,
                                    label: 'Confirm PIN',
                                    hintText: 'Confirm PIN',
                                    prefix: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Icon(Icons.lock_outline_rounded),
                                    ),
                                    isPassword: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Main Action Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _submitPin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.textDark,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: AppTheme.textDark.withValues(alpha: 0.5),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Text(
                                                  'Save PIN & Continue',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),

                            const Spacer(),

                            // Footer Badges
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(Icons.lock, size: 14, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                                const SizedBox(width: 6),
                                Text(
                                  'Your PIN is safely encrypted',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 300.ms),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
