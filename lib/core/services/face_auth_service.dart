import 'package:shared_preferences/shared_preferences.dart';

class FaceAuthService {
  static const String _faceIdKey = 'user_face_id';
  
  // Default threshold is 50,000. Can be changed.
  static const double largeTransactionThreshold = 50000.0;

  /// Checks if the user has a registered Face ID
  static Future<bool> isFaceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_faceIdKey);
  }

  /// Gets the currently registered Face ID, if any
  static Future<String?> getStoredFaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_faceIdKey);
  }

  /// Stores a newly registered Face ID
  static Future<void> storeFaceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_faceIdKey, id);
  }

  /// Clears the registered Face ID
  static Future<void> clearFaceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceIdKey);
  }
}
