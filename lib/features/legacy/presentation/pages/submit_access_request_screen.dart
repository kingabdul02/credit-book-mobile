import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../bloc/legacy_bloc.dart';

class SubmitAccessRequestScreen extends StatefulWidget {
  const SubmitAccessRequestScreen({super.key});

  @override
  State<SubmitAccessRequestScreen> createState() => _SubmitAccessRequestScreenState();
}

class _SubmitAccessRequestScreenState extends State<SubmitAccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactIdController = TextEditingController();
  final _recoveryCodeController = TextEditingController();

  final List<Map<String, String>> _reasons = [
    {'value': 'deceased', 'label': 'Deceased', 'icon': '🕊️'},
    {'value': 'permanent_incapacity', 'label': 'Permanent Incapacity', 'icon': '🏥'},
    {'value': 'medical_emergency', 'label': 'Medical Emergency', 'icon': '🚑'},
  ];
  String? _selectedReason;
  bool _hasRecoveryCode = false;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _contactIdController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedReason == null) return false;
    
    if (_hasRecoveryCode) {
      return _recoveryCodeController.text.trim().isNotEmpty;
    } else {
      return _contactIdController.text.trim().isNotEmpty && 
             _contactIdController.text.trim().length == 8;
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = {
      'reason': _selectedReason,
    };

    if (_hasRecoveryCode) {
      data['recovery_code'] = _recoveryCodeController.text.trim();
    } else {
      data['access_code'] = _contactIdController.text.trim().toUpperCase();
    }

    context.read<LegacyBloc>().add(SubmitAccessRequest(data));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LegacyBloc, LegacyState>(
      listener: (context, state) {
        if (state is AccessRequestSubmitted) {
          setState(() {
            _isSubmitting = false;
            _submitted = true;
          });
        } else if (state is AccessRequestActionLoading) {
          setState(() => _isSubmitting = true);
        } else if (state is AccessRequestError) {
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
        backgroundColor: AppTheme.onBackground,
        appBar: const CustomAppBar(title: 'Request Access'),
        body: _submitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Success icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppTheme.primaryVariant,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Request Submitted',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your access request has been submitted successfully. The account owner has been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Info cards
          _InfoCard(
            icon: Icons.timer_outlined,
            title: 'Waiting Period',
            description:
                'The account owner has a waiting period to respond. If they do not respond, access will be granted automatically.',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.notifications_active_outlined,
            title: 'Owner Notified',
            description:
                'The account owner has been notified via push notification and email about your request.',
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.visibility_outlined,
            title: 'Read-Only Access',
            description:
                'Once approved, you will receive read-only access to view debts, credits, and financial records.',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryVariant,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Legacy Access\nRequest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit a request to access the financial records of someone who has designated you as a trusted contact.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Access Code ──────────────────────────────────────
            if (!_hasRecoveryCode) ...[
              const _FieldLabel('Your Access Code *'),
              const SizedBox(height: 4),
              Text(
                'This 8-character code was shared with you in your verification email.',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactIdController,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('e.g. ABC2XYZ9'),
                validator: (v) {
                  if (!_hasRecoveryCode && (v == null || v.trim().isEmpty)) {
                    return 'Access code is required';
                  }
                  if (!_hasRecoveryCode && v != null && v.trim().isNotEmpty && v.trim().length != 8) {
                    return 'Access code must be 8 characters';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),

            // ── Reason ──────────────────────────────────────────
            const _FieldLabel('Reason for Request *'),
            const SizedBox(height: 8),
            ...List.generate(_reasons.length, (i) {
              final reason = _reasons[i];
              final isSelected = _selectedReason == reason['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReason = reason['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : AppTheme.textMuted.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(reason['icon']!, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            reason['label']!,
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textMuted.withValues(alpha: 0.4),
                              width: isSelected ? 0 : 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_selectedReason == null)
              const Padding(
                padding: EdgeInsets.only(left: 12, bottom: 8),
                child: SizedBox.shrink(),
              ),
            const SizedBox(height: 16),

            // ── Recovery Code (Optional) ────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I have a Recovery Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _hasRecoveryCode 
                              ? 'Access code not required when using recovery code'
                              : 'Providing a valid code may expedite your request',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _hasRecoveryCode,
                    onChanged: (v) => setState(() => _hasRecoveryCode = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.primaryVariant,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            if (_hasRecoveryCode) ...[
              const SizedBox(height: 12),
              const _FieldLabel('Recovery Code *'),
              const SizedBox(height: 4),
              Text(
                'Enter the recovery code provided by the account owner.',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recoveryCodeController,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('ABX9-2KF7-PQ11'),
                validator: (v) {
                  if (_hasRecoveryCode && (v == null || v.trim().isEmpty)) {
                    return 'Recovery code is required';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),

            // ── Warning ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Submitting a false access request is a serious matter. The account owner will be notified and can deny your request.',
                      style: TextStyle(
                        color: AppTheme.textDark.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || !_canSubmit ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryVariant,
                  disabledBackgroundColor: AppTheme.textMuted.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Access Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6)),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
