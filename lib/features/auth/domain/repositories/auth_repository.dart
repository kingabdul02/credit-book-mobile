import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String phoneNumber, String pin);
  Future<User> register(String name, String phoneNumber, {String? currency});
  Future<void> setLoginPin(String pin);
  Future<User> getCurrentUser();
  Future<void> logout();
}
