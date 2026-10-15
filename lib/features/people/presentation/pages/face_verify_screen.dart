import 'package:flutter/material.dart';
import 'package:flutter_face_liveness/flutter_face_liveness.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/services/face_auth_service.dart';

class FaceVerifyScreen extends StatefulWidget {
  final double amount;
  final String contactName;

  const FaceVerifyScreen({
    super.key,
    required this.amount,
    required this.contactName,
  });

  @override
  State<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends State<FaceVerifyScreen> {
  String? _storedFaceId;
  final _currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadStoredFaceId();
  }

  Future<void> _loadStoredFaceId() async {
    final id = await FaceAuthService.getStoredFaceId();
    if (mounted) {
      setState(() => _storedFaceId = id);
    }
  }

  void _handleSuccess(LivenessResult result) {
    if (result.faceId == _storedFaceId) {
      // Identity confirmed
      context.pop(true);
    } else {
      // Someone else's face
      if (mounted) {
        _showError('Face not recognized. Please try again or use PIN.');
      }
    }
  }

  void _handleFailed(String reason) {
    if (mounted) {
      _showError(reason);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Try Again', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              ctx.pop();
              context.pop(null); // Cancel
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_storedFaceId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // F8FAFC like the screenshot? The screenshot looks white/light gray
      appBar: CustomAppBar(
        title: 'Identity Verification',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterFaceLiveness(
              actions: const [
                LivenessAction.blink,
                LivenessAction.turnLeft,
                LivenessAction.smile,
              ],
              config: LivenessConfig(
                enableFaceId: true,
                faceIdMode: FaceIdMode.verificationOnly,
                enableAntiSpoof: true,
                faceIdSimilarityThreshold: 0.70, // Lowered threshold to prevent false negatives
              ),
              onSuccess: _handleSuccess,
              onFailed: _handleFailed,
            ),
          ),
          
          Positioned(
            top: 85,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Confirming transaction of ${_currencyFormat.format(widget.amount)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket(bool isLeft, bool isTop) {
    const double length = 30;
    const double thickness = 4;
    const color = Color(0xFF0F7A4A);

    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: 0,
            right: 0,
            child: Container(height: thickness, color: color),
          ),
          Positioned(
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            top: 0,
            bottom: 0,
            child: Container(width: thickness, color: color),
          ),
        ],
      ),
    );
  }
}
