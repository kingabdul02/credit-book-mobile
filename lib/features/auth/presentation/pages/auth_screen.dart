import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/country_code_dropdown.dart';
import '../../data/models/country_code.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  CountryCode _selectedCountry = CountryCode.defaultCountry;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('saved_phone_number');
    final savedCountryCode = prefs.getString('saved_country_code');
    
    if (mounted && savedPhone != null && savedPhone.isNotEmpty) {
      setState(() {
        _phoneController.text = savedPhone;
        if (savedCountryCode != null) {
          final country = CountryCode.all.firstWhere(
            (c) => c.dialCode == savedCountryCode,
            orElse: () => CountryCode.defaultCountry,
          );
          _selectedCountry = country;
        }
      });
      // Focus pin if phone is loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isLogin) {
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _continueOffline() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthError) {
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
                        state.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
        } else if (state is AuthNeedsPinSet) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_phone_number', _phoneController.text.trim());
          await prefs.setString('saved_country_code', _selectedCountry.dialCode);
          if (mounted) context.go('/set-pin');
        } else if (state is AuthSuccess) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_phone_number', _phoneController.text.trim());
          await prefs.setString('saved_country_code', _selectedCountry.dialCode);
          if (mounted) context.go('/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
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
                      children: [
                        const SizedBox(height: 48),
                        
                        // Header
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(_isLogin),
                            children: [
                              if (_isLogin)
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(Icons.account_balance_wallet, size: 32, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CreditBook',
                                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'CreditBook',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                _isLogin 
                                    ? 'Welcome back to clarity.' 
                                    : 'Financial clarity for your business.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                          
                        const SizedBox(height: 32),

                        // Main Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: Column(
                              key: ValueKey<bool>(_isLogin),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isLogin) ...[
                                  Text(
                                    'Create Account',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Join thousands of entrepreneurs today.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  CustomTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    hintText: 'John Doe',
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                CustomTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  hintText: '300 1234567',
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(RegExp(r'^0')),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefix: CountryCodeDropdown(
                                    selectedCountry: _selectedCountry,
                                    onChanged: (country) {
                                      setState(() {
                                        _selectedCountry = country;
                                      });
                                    },
                                  ),
                                ),
                                
                                if (_isLogin) ...[
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _pinController,
                                    focusNode: _pinFocusNode,
                                    label: '6-Digit PIN',
                                    hintText: '••••••',
                                    isPassword: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    trailingLabel: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        ' Forgot PIN?',
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 32),

                                // Main Action Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      final fullPhone = '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
                                      if (_isLogin) {
                                        context.read<AuthBloc>().add(
                                          LoginRequested(
                                            phoneNumber: fullPhone,
                                            pin: _pinController.text.trim(),
                                          ),
                                        );
                                      } else {
                                        context.read<AuthBloc>().add(
                                          SignupRequested(
                                            name: _nameController.text.trim(),
                                            phoneNumber: fullPhone,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppTheme.primaryColor : AppTheme.textDark,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: (isDark ? AppTheme.primaryColor : AppTheme.textDark).withValues(alpha: 0.5),
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
                                            children: [
                                              Text(
                                                _isLogin ? 'Login' : 'Get Started',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Footer Badges
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(Icons.verified_user_outlined, size: 16, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SECURE',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text('•', style: TextStyle(color: AppTheme.textMuted)),
                                    ),
                                    Icon(Icons.cloud_off_outlined, size: 16, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'OFFLINE-FIRST',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                        const Spacer(),

                        // Bottom Section
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey(_isLogin),
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _isLogin ? "New to CreditBook? " : "Already have an account? ",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _toggleAuthMode,
                                    child: Text(
                                      _isLogin ? 'Create Account' : 'Login',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => context.push('/submit-access-request'),
                                icon: const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primaryVariant),
                                label: const Text(
                                  'I am a Nominee / Next of Kin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              if (_isLogin) ...[
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(Icons.lock, size: 14, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '256-bit End-to-End Encryption Enabled',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              Text(
                                _isLogin 
                                    ? '© 2024 CreditBook FinTech Solutions. All rights reserved.'
                                    : '© 2024 CreditBook Systems Inc. Your data is encrypted locally and never leaves your device without permission.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),

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
