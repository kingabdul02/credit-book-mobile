import 'dart:io';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String phoneNumber, String pin);
  Future<User> register(String name, String phoneNumber, {String? currency});
  Future<void> setLoginPin(String pin);
  Future<User> getCurrentUser();
  Future<User?> getCachedUser();
  Future<User> updateProfile({String? name, String? email, String? defaultCurrency});
  Future<User> uploadAvatar(File imageFile);
  Future<User> deleteAvatar();
  Future<void> logout();
  Future<bool> refreshToken();
}
