import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  static const String cachedUserKey = 'cached_user';

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  Future<void> _cacheUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await sharedPreferences.setString(cachedUserKey, jsonEncode(userModel.toJson()));
    } catch (_) {
      // Graceful degradation if local serialization fails
    }
  }

  @override
  Future<User> login(String phoneNumber, String pin) async {
    final user = await remoteDataSource.login(phoneNumber, pin);
    await _cacheUser(user);
    return user;
  }

  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async {
    final user = await remoteDataSource.register(name, phoneNumber, currency: currency);
    await _cacheUser(user);
    return user;
  }

  @override
  Future<void> setLoginPin(String pin) async {
    await remoteDataSource.setLoginPin(pin);
  }

  @override
  Future<User> getCurrentUser() async {
    final user = await remoteDataSource.getUser();
    await _cacheUser(user);
    return user;
  }

  @override
  Future<User?> getCachedUser() async {
    final jsonStr = sharedPreferences.getString(cachedUserKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        return UserModel.fromJson(jsonMap);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency}) async {
    final user = await remoteDataSource.updateProfile(
      name: name,
      email: email,
      defaultCurrency: defaultCurrency,
    );
    await _cacheUser(user);
    return user;
  }

  @override
  Future<User> uploadAvatar(File imageFile) async {
    final user = await remoteDataSource.uploadAvatar(imageFile);
    await _cacheUser(user);
    return user;
  }

  @override
  Future<User> deleteAvatar() async {
    final user = await remoteDataSource.deleteAvatar();
    await _cacheUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await sharedPreferences.remove(cachedUserKey);
      await sharedPreferences.remove('app_notifications_list');
    }
  }

  @override
  Future<bool> refreshToken() async {
    return await remoteDataSource.refreshToken();
  }

  @override
  Future<Map<String, dynamic>> forgotPin(String phoneNumber) async {
    return await remoteDataSource.forgotPin(phoneNumber);
  }

  @override
  Future<String> verifyPinResetCode(String phoneNumber, String code) async {
    return await remoteDataSource.verifyPinResetCode(phoneNumber, code);
  }

  @override
  Future<User> resetPin(String phoneNumber, String resetToken, String newPin) async {
    final user = await remoteDataSource.resetPin(phoneNumber, resetToken, newPin);
    await _cacheUser(user);
    return user;
  }
}
