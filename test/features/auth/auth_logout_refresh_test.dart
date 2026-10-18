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
import 'package:creditbook/features/people/data/datasources/people_local_data_source.dart';
import 'package:creditbook/features/people/domain/entities/contact_entity.dart';
import 'package:creditbook/features/auth/domain/entities/user.dart';

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

    test('preserves locally stored contacts and records lastLoggedInUserId across logout', () async {
      final prefs = await SharedPreferences.getInstance();
      final peopleLocal = PeopleLocalDataSourceImpl(sharedPreferences: prefs);

      // Seed User 1's local contacts
      await peopleLocal.savePeopleData('1', const PeopleDataEntity(
        favorites: [],
        frequentlyContacted: [],
        allContacts: [
          ContactEntity(
            id: 'c-1',
            fullName: 'User 1 Contact',
            isFavorite: false,
            totalOwedToUser: 0,
            totalUserOwes: 0,
            updatedAt: '2026-10-18T10:00:00Z',
          ),
        ],
      ));

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'user': {
            'id': '1',
            'name': 'Test User',
            'phone_number': '+1234567890',
            'has_pin': true,
          },
          'token': 'new-token',
        }), 200);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        sharedPreferences: prefs,
        peopleLocalDataSource: peopleLocal,
      );

      // User 1 logs in
      await repository.login('+1234567890', '1234');
      expect(repository.getLastLoggedInUserId(), '1');
      expect(peopleLocal.getPeopleData('1'), isNotNull);

      // User 1 logs out
      await repository.logout();

      // Tokens and session user are cleared, but lastLoggedInUserId and User 1 contacts are PRESERVED
      expect(prefs.getString(AuthRepositoryImpl.cachedUserKey), isNull);
      expect(prefs.getString(AuthRepositoryImpl.currentUserIdKey), isNull);
      expect(repository.getLastLoggedInUserId(), '1');
      expect(peopleLocal.getPeopleData('1')!.allContacts.first.fullName, 'User 1 Contact');

      // Same User 1 logs back in
      await repository.login('+1234567890', '1234');
      expect(repository.isSameAsPreviousUser('1'), isTrue);
      // needsLoginSync remains false because same user logged in, retaining local storage without server fetch
      expect(peopleLocal.needsLoginSync('1'), isFalse);
      expect(peopleLocal.getPeopleData('1')!.allContacts.first.fullName, 'User 1 Contact');
    });

    test('flags needsLoginSync and clears previous memory cache when a different user logs in', () async {
      final prefs = await SharedPreferences.getInstance();
      final peopleLocal = PeopleLocalDataSourceImpl(sharedPreferences: prefs);

      // User 1 was previously logged in
      await prefs.setString(AuthRepositoryImpl.lastLoggedInUserIdKey, 'user-1');
      await peopleLocal.savePeopleData('user-1', const PeopleDataEntity(
        favorites: [],
        frequentlyContacted: [],
        allContacts: [
          ContactEntity(
            id: 'c-1',
            fullName: 'User 1 Contact',
            isFavorite: false,
            totalOwedToUser: 0,
            totalUserOwes: 0,
            updatedAt: '2026-10-18T10:00:00Z',
          ),
        ],
      ));

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'user': {
            'id': 'user-2',
            'name': 'User Two',
            'phone_number': '+9876543210',
            'has_pin': true,
          },
          'token': 'user-2-token',
        }), 200);
      });

      final dataSource = AuthRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: dataSource,
        sharedPreferences: prefs,
        peopleLocalDataSource: peopleLocal,
      );

      // User 2 logs in
      final user2 = await repository.login('+9876543210', '1234');
      expect(user2.id, 'user-2');

      // Identify that User 2 is DIFFERENT from previous user (user-1)
      expect(repository.isSameAsPreviousUser('user-1'), isFalse);
      expect(repository.getLastLoggedInUserId(), 'user-2');

      // User 2 is flagged to fetch contacts from server
      expect(peopleLocal.needsLoginSync('user-2'), isTrue);

      // User 2 partition has NO contacts yet (MUST NOT see User 1 contacts!)
      expect(peopleLocal.getPeopleData('user-2'), isNull);

      // User 1 contacts remain intact in user-1 partition
      expect(peopleLocal.getPeopleData('user-1')!.allContacts.first.fullName, 'User 1 Contact');
    });
  });

  group('AuthBloc - LogoutRequested and SessionExpired', () {
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

      await bloc.close();
    });

    test('emits AuthSessionExpired on SessionExpiredEvent and clears cached user', () async {
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

      bloc.add(const SessionExpiredEvent());

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states.length, 1);
      expect(states[0], isA<AuthSessionExpired>());
      expect(prefs.getString(AuthRepositoryImpl.cachedUserKey), isNull);

      await bloc.close();
    });

    test('emits AuthSessionExpired during CheckAuthStatus if remote returns 401 unauthenticated', () async {
      final prefs = await SharedPreferences.getInstance();
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/user')) {
          return http.Response(jsonEncode({'message': 'Unauthenticated.'}), 401);
        }
        return http.Response('{}', 200);
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

      bloc.add(CheckAuthStatus());

      await Future.delayed(const Duration(milliseconds: 100));

      // Should emit AuthSuccess(cached) first, then AuthSessionExpired when 401 returned
      expect(states.any((s) => s is AuthSessionExpired), isTrue);
      expect(prefs.getString(AuthRepositoryImpl.cachedUserKey), isNull);

      await bloc.close();
    });
  });
}

