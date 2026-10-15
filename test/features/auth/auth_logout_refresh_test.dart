import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:creditbook/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:creditbook/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_event.dart';
import 'package:creditbook/features/auth/presentation/bloc/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.creditbook.test/api/v1');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AuthRemoteDataSourceImpl.tokenKey: 'access-token-123',
      AuthRemoteDataSourceImpl.refreshTokenKey: 'refresh-token-456',
      AuthRepositoryImpl.cachedUserKey: jsonEncode({
        'id': '1',
        'name': 'Test User',
        'phone_number': '+1234567890',
        'has_pin': true,
      }),
    });
  });

  group('AuthRemoteDataSourceImpl - Logout & Refresh Token', () {
    test('logout clears tokens and posts refresh_token to server', () async {
      final prefs = await SharedPreferences.getInstance();
      var requestMade = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/logout') {
          requestMade = true;
          expect(request.headers['Authorization'], 'Bearer access-token-123');
          final body = jsonDecode(request.body);
          expect(body['refresh_token'], 'refresh-token-456');
          return http.Response(jsonEncode({'message': 'Logged out successfully'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      await dataSource.logout();

      expect(requestMade, isTrue);
      expect(prefs.getString(AuthRemoteDataSourceImpl.tokenKey), isNull);
      expect(prefs.getString(AuthRemoteDataSourceImpl.refreshTokenKey), isNull);
    });

    test('refreshToken updates both tokens on 200 response', () async {
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/refresh') {
          final body = jsonDecode(request.body);
          expect(body['refresh_token'], 'refresh-token-456');
          return http.Response(
            jsonEncode({
              'token': 'new-access-token-789',
              'access_token': 'new-access-token-789',
              'refresh_token': 'new-refresh-token-999',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final success = await dataSource.refreshToken();

      expect(success, isTrue);
      expect(prefs.getString(AuthRemoteDataSourceImpl.tokenKey), 'new-access-token-789');
      expect(prefs.getString(AuthRemoteDataSourceImpl.refreshTokenKey), 'new-refresh-token-999');
    });

    test('refreshToken removes tokens when refresh token is expired or invalid', () async {
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Invalid refresh token.'}), 401);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final success = await dataSource.refreshToken();

      expect(success, isFalse);
      expect(prefs.getString(AuthRemoteDataSourceImpl.tokenKey), isNull);
      expect(prefs.getString(AuthRemoteDataSourceImpl.refreshTokenKey), isNull);
    });
  });

  group('AuthRepositoryImpl - Logout', () {
    test('clears cachedUserKey upon logout', () async {
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Logged out'}), 200);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        sharedPreferences: prefs,
      );

      expect(prefs.getString(AuthRepositoryImpl.cachedUserKey), isNotNull);

      await repository.logout();

      expect(prefs.getString(AuthRepositoryImpl.cachedUserKey), isNull);
      expect(prefs.getString(AuthRemoteDataSourceImpl.tokenKey), isNull);
    });
  });

  group('AuthBloc - LogoutRequested', () {
    test('emits [AuthLoading, AuthInitial] on LogoutRequested', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Logged out'}), 200);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );
      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        sharedPreferences: prefs,
      );
      final bloc = AuthBloc(authRepository: repository);

      final states = <AuthState>[];
      bloc.stream.listen(states.add);

      bloc.add(LogoutRequested());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthInitial>());
    });
  });
}
