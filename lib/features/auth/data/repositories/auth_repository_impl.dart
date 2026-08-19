import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<User> login(String phoneNumber, String pin) async {
    return await remoteDataSource.login(phoneNumber, pin);
  }

  @override
  Future<User> register(String name, String phoneNumber, {String? currency}) async {
    return await remoteDataSource.register(name, phoneNumber, currency: currency);
  }

  @override
  Future<void> setLoginPin(String pin) async {
    await remoteDataSource.setLoginPin(pin);
  }

  @override
  Future<User> getCurrentUser() async {
    return await remoteDataSource.getUser();
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(AuthRemoteDataSourceImpl.tokenKey);
  }
}
