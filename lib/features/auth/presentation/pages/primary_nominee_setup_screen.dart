import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/country_code.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/country_code_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../../../legacy/presentation/bloc/legacy_bloc.dart';

class PrimaryNomineeSetupScreen extends StatefulWidget {
  const PrimaryNomineeSetupScreen({super.key});

  @override
  State<PrimaryNomineeSetupScreen> createState() => _PrimaryNomineeSetupScreenState();
}

class _PrimaryNomineeSetupScreenState extends State<PrimaryNomineeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<String> _relationships = [
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Friend',
    'Lawyer',
    'Executor',
    'Business Partner',
    'Other',
  ];

  String? _selectedRelationship;
  CountryCode _selectedCountry = CountryCode.defaultCountry;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _finishAndGoHome() {
    context.read<AuthBloc>().add(CheckAuthStatus());
    if (mounted) {
      context.go('/home');
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Enter a valid phone number',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final fullPhone = '${_selectedCountry.dialCode}$phone';
    final data = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': fullPhone,
      'relationship': _selectedRelationship ?? 'Other',
      'is_primary': true,
    };

    context.read<LegacyBloc>().add(AddLegacyContact(data));
  }

  InputDecoration _inputDecoration(String hint, bool isDark, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.textMuted.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<LegacyBloc, LegacyState>(
      listener: (context, state) {
        if (state is LegacyActionLoading && state.action == 'adding') {
          setState(() => _isSubmitting = true);
        } else if (state is LegacyContactAdded) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Primary nominee added! Verification email sent to ${state.contact.email}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryVariant,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          _finishAndGoHome();
        } else if (state is LegacyError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _finishAndGoHome,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'OPTIONAL STEP',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 16),

                  // Header Title
                  Text(
                    'Add Primary Nominee',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideX(begin: -0.05, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Designate a trusted next-of-kin or representative to securely access your CreditBook records in case of an emergency.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                      height: 1.45,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 150.ms),

                  const SizedBox(height: 20),

                  // Safeguard Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Safeguard',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Primary nominees are contacted first. They will receive an email to verify their details before any access is granted.',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),

                  const SizedBox(height: 20),

                  // Primary Nominee Highlight Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Designated as Primary Nominee',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'You can add secondary nominees or update this later in Settings.',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 250.ms),

                  const SizedBox(height: 24),

                  // Full Legal Name Field
                  _buildFieldLabel('Full Legal Name *', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      'e.g. Sarah Johnson',
                      isDark,
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                  ),

                  const SizedBox(height: 18),

                  // Relationship Field
                  _buildFieldLabel('Relationship *', isDark),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelationship,
                    decoration: _inputDecoration(
                      'Select relationship',
                      isDark,
                      prefixIcon: Icon(
                        Icons.people_outline_rounded,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    items: _relationships
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRelationship = v),
                    validator: (v) => v == null ? 'Please select a relationship' : null,
                  ),

                  const SizedBox(height: 18),

                  // Email Field
                  _buildFieldLabel('Email Address *', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      'sarah@example.com',
                      isDark,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Phone Number Field
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number *',
                    hintText: '801 234 5678',
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

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Primary Nominee',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 350.ms),

                  const SizedBox(height: 12),

                  // Skip / Later Text Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _finishAndGoHome,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "I'll add a nominee later",
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textDark.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
      ),
    );
  }
}
