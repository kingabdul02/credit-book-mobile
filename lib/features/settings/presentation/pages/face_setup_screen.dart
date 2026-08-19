import 'package:flutter/material.dart';
import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/face_auth_service.dart';

class FaceSetupScreen extends StatelessWidget {
  const FaceSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Biometric Setup',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: FlutterFaceLiveness(
        actions: const [
          LivenessAction.blink,
          LivenessAction.turnLeft,
          LivenessAction.turnRight,
        ],
        config: LivenessConfig(
          enableFaceId: true,
          faceIdMode: FaceIdMode.registrationOnly,
          enableAntiSpoof: true,
          randomizeActions: true,
        ),
        onSuccess: (LivenessResult result) async {
          if (result.faceId != null) {
            await FaceAuthService.storeFaceId(result.faceId!);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Face ID registered successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
              context.pop(true);
            }
          }
        },
        onFailed: (String reason) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Setup Failed'),
                content: Text(reason),
                actions: [
                  TextButton(
                    onPressed: () => ctx.pop(),
                    child: const Text('Try Again', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                  TextButton(
                    onPressed: () {
                      ctx.pop();
                      context.pop(false);
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
