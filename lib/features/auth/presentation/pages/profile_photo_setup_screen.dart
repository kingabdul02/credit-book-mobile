import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ProfilePhotoSetupScreen extends StatefulWidget {
  const ProfilePhotoSetupScreen({super.key});

  @override
  State<ProfilePhotoSetupScreen> createState() => _ProfilePhotoSetupScreenState();
}

class _ProfilePhotoSetupScreenState extends State<ProfilePhotoSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _localImageFile;
  bool _isUploading = false;

  void _finishAndGoHome() {
    context.read<AuthBloc>().add(CheckAuthStatus());
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close bottom sheet if open

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final int fileSize = await file.length();

      // Check 5MB limit
      if (fileSize > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected photo is too large. Maximum size is 5MB.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _localImageFile = file;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPhotoOptions(bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you want to add your profile photo',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Use your device camera', style: TextStyle(fontSize: 12)),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select a picture from your library', style: TextStyle(fontSize: 12)),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(modalCtx).pop();
                      setState(() {
                        _localImageFile = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _uploadAndContinue() {
    if (_localImageFile == null) {
      _finishAndGoHome();
      return;
    }

    setState(() {
      _isUploading = true;
    });

    context.read<AuthBloc>().add(UploadAvatarRequested(_localImageFile!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && _isUploading) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo set up successfully!'),
              backgroundColor: AppTheme.primaryColor,
              duration: Duration(seconds: 2),
            ),
          );
          _finishAndGoHome();
        } else if (state is AuthError && _isUploading) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        final user = state is AuthSuccess
            ? state.user
            : (state is PinSetSuccess ? state.user : null);

        final hasSelectedPhoto = _localImageFile != null;
        final hasExistingAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
        final hasAnyPhoto = hasSelectedPhoto || hasExistingAvatar;

        return Scaffold(
          backgroundColor: AppTheme.onBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: _isUploading ? null : _finishAndGoHome,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Step badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'OPTIONAL STEP',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),
                          const SizedBox(height: 18),
                          Text(
                            'Add a Profile Photo',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.5,
                                ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 100.ms)
                              .slideY(begin: 0.2, curve: Curves.easeOut),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Help your clients, suppliers, and contacts easily identify and recognize you on CreditBook.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMuted,
                                    height: 1.45,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 200.ms),
                          const SizedBox(height: 48),

                          // Avatar container with tap action & camera badge
                          Center(
                            child: GestureDetector(
                              onTap: _isUploading ? null : () => _showPhotoOptions(hasAnyPhoto),
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // Avatar Circle
                                  Container(
                                    width: 144,
                                    height: 144,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: UserAvatar(
                                      avatarUrl: _localImageFile?.path ?? user?.avatarUrl,
                                      radius: 68,
                                      isLoading: _isUploading,
                                    ),
                                  ),

                                  // Floating Camera Icon Badge
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),

                          const SizedBox(height: 24),

                          // Text helper button
                          TextButton.icon(
                            onPressed: _isUploading ? null : () => _showPhotoOptions(hasAnyPhoto),
                            icon: Icon(
                              hasAnyPhoto ? Icons.edit_rounded : Icons.add_photo_alternate_outlined,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            label: Text(
                              hasAnyPhoto ? 'Change Photo' : 'Choose Photo',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(height: 32),

                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isUploading
                                  ? null
                                  : (hasSelectedPhoto ? _uploadAndContinue : () => _showPhotoOptions(hasAnyPhoto)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      hasSelectedPhoto ? 'Save & Continue' : 'Upload Photo',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms),

                          const SizedBox(height: 12),

                          // Secondary "Skip for now" Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _isUploading ? null : _finishAndGoHome,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                hasSelectedPhoto ? 'Skip photo for now' : 'I\'ll do this later',
                                style: TextStyle(
                                  color: AppTheme.textDark.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 450.ms),

                          const SizedBox(height: 24),
                        ],
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
