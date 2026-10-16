import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/legacy_contact_entity.dart';
import '../bloc/legacy_bloc.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/country_code_dropdown.dart';
import '../../../auth/data/models/country_code.dart';

class AddLegacyContactScreen extends StatefulWidget {
  final LegacyContactEntity? existingContact;
  final bool isPrimary;

  const AddLegacyContactScreen({super.key, this.existingContact, required this.isPrimary});

  @override
  State<AddLegacyContactScreen> createState() => _AddLegacyContactScreenState();
}

class _AddLegacyContactScreenState extends State<AddLegacyContactScreen> {
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
  bool _isPrimary = true;
  bool _isSaving = false;
  CountryCode _selectedCountry = CountryCode.defaultCountry;

  bool get _isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    _isPrimary = widget.isPrimary;
    final c = widget.existingContact;
    if (c != null) {
      _nameController.text = c.fullName;
      _emailController.text = c.email;
      
      String phone = c.phone;
      for (final country in CountryCode.all) {
        if (phone.startsWith(country.dialCode)) {
          _selectedCountry = country;
          phone = phone.substring(country.dialCode.length).trim();
          break;
        }
      }
      _phoneController.text = phone;
      _selectedRelationship = _relationships.contains(c.relationship) ? c.relationship : 'Other';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid phone number', style: TextStyle(color: Colors.white)),
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
      'is_primary': _isPrimary,
    };

    if (_isEditing) {
      context.read<LegacyBloc>().add(
            UpdateLegacyContact(id: widget.existingContact!.id, data: data),
          );
    } else {
      context.read<LegacyBloc>().add(AddLegacyContact(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LegacyBloc, LegacyState>(
      listener: (context, state) {
        if (state is LegacyContactAdded || state is LegacyLoaded) {
          if (!_isSaving) return;
          context.pop();
        } else if (state is LegacyActionLoading) {
          setState(() => _isSaving = true);
        } else if (state is LegacyError) {
          setState(() => _isSaving = false);
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
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.onBackground,
            appBar: CustomAppBar(title: _isEditing ? 'Edit Nominee' : 'Add Nominee'),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Info Banner ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryVariant, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isEditing
                                  ? 'Changes will be saved immediately. Verification status is unaffected by edits.'
                                  : 'A verification email will be sent to this person. They must verify to become an active nominee.',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Full Name ────────────────────────────────────
                    const _FieldLabel('Full Legal Name *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration('e.g. Sarah Johnson', isDark),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Relationship ─────────────────────────────────
                    const _FieldLabel('Relationship *'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRelationship,
                      decoration: _inputDecoration('Select relationship', isDark),
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
                    const SizedBox(height: 20),

                    // ── Email ────────────────────────────────────────
                    const _FieldLabel('Email Address *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('sarah@example.com', isDark),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+').hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Phone ────────────────────────────────────────
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
                    const SizedBox(height: 24),

                    // ── Is Primary ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primary Nominee',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Primary nominees are contacted first',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPrimary,
                            onChanged: (v) => setState(() => _isPrimary = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppTheme.primaryVariant,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: isDark
                                ? AppTheme.darkBorder
                                : AppTheme.textMuted.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Submit ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isEditing ? 'Save Changes' : 'Add Nominee',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
            : AppTheme.textMuted.withValues(alpha: 0.8),
      ),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.textMuted.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.textMuted.withValues(alpha: 0.3),
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
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}
