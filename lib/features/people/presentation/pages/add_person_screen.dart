import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/country_code.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../auth/presentation/widgets/country_code_dropdown.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/add_person_bloc.dart';
import 'package:dotted_border/dotted_border.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  CountryCode _selectedCountry = CountryCode.defaultCountry;
  bool _isFavorite = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AddPersonBloc>().add(
            SubmitAddPerson(
              fullName: _fullNameController.text.trim(),
              nickname: _nicknameController.text.trim(),
              phoneNumber: '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
              isFavorite: _isFavorite,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddPersonBloc, AddPersonState>(
      listener: (context, state) {
        if (state is AddPersonSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact saved successfully!'), backgroundColor: AppTheme.primaryColor),
          );
          context.pop(true); // Return true to signal refresh needed
        } else if (state is AddPersonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
          );
        } else if (state is ContactImported) {
          setState(() {
            _fullNameController.text = state.fullName;
            _phoneController.text = state.phoneNumber;
          });
          final msg = state.phoneNumber.isNotEmpty
              ? 'Contact imported!'
              : 'Contact imported — no phone number found.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryColor),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.onBackground,
        appBar: const CustomAppBar(
          title: 'Add New Person',
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            DottedBorder(
                              options: CircularDottedBorderOptions(
                                color: AppTheme.textMuted.withValues(alpha: 0.5),
                                strokeWidth: 2,
                                dashPattern: const [6, 4],
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.camera_alt_outlined, size: 32, color: AppTheme.textDark),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryVariant,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Add Profile Picture',
                          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Optional but recommended',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  const Text('Full Name *', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. Johnathan Smith',
                      hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 20),

                  // Nickname
                  const Text('Nickname (Optional)', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nicknameController,
                    style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. Johnny',
                      hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: 'Mobile Number',
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

                  // Add to Favorites
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_border_rounded, size: 28, color: AppTheme.textDark),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Add to Favorites', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark, fontSize: 15)),
                              Text('Pin this person to the top of your lists', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isFavorite,
                          onChanged: (val) => setState(() => _isFavorite = val),
                          activeColor: Colors.white,
                          activeTrackColor: AppTheme.primaryVariant,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AddPersonBloc>().add(ImportContactRequested());
                      },
                      icon: const Icon(Icons.contact_phone_outlined, color: AppTheme.primaryVariant),
                      label: const Text('Import from Contacts', style: TextStyle(color: AppTheme.primaryVariant, fontWeight: FontWeight.w700, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.primaryVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Save Button
                  BlocBuilder<AddPersonBloc, AddPersonState>(
                    builder: (context, state) {
                      final isLoading = state is AddPersonLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Save Contact', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                ],
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
