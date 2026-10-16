import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:creditbook/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:creditbook/features/notifications/domain/entities/app_notification.dart';
import 'package:creditbook/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:creditbook/features/notifications/presentation/pages/notification_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.creditbook.test/api/v1');
  });

  group('NotificationRemoteDataSource Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'auth_token': 'test_token_123'});
      prefs = await SharedPreferences.getInstance();
    });

    test('getNotifications parses server JSON response correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.creditbook.test/api/v1/notifications');
        expect(request.headers['Authorization'], 'Bearer test_token_123');

        return http.Response(
          json.encode({
            'data': [
              {
                'id': 'srv_notif_1',
                'title': 'Overdue Notice',
                'message': 'You have 1 overdue debt',
                'category': 'overdue',
                'action_route': '/all-debts',
                'action_data': {'overdue_count': 1},
                'read_at': null,
                'created_at': '2026-10-16T12:00:00Z',
              },
              {
                'id': 'srv_notif_2',
                'title': 'System Notice',
                'message': 'Welcome to the platform',
                'category': 'system',
                'action_route': null,
                'action_data': null,
                'read_at': '2026-10-16T12:10:00Z',
                'created_at': '2026-10-16T12:05:00Z',
              }
            ],
            'unread_count': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = NotificationRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final list = await dataSource.getNotifications();

      expect(list.length, equals(2));
      expect(list[0].id, equals('srv_notif_1'));
      expect(list[0].category, equals(NotificationCategory.overdue));
      expect(list[0].isRead, isFalse);
      expect(list[0].actionRoute, equals('/all-debts'));
      expect(list[1].isRead, isTrue);
      expect(list[1].actionRoute, isNull);
    });

    test('markAsRead calls server PATCH endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.creditbook.test/api/v1/notifications/notif_99/read');
        expect(request.method, 'PATCH');
        return http.Response(
          json.encode({
            'message': 'Notification marked as read.',
            'data': {
              'id': 'notif_99',
              'title': 'Test',
              'message': 'Body',
              'category': 'system',
              'read_at': '2026-10-16T13:00:00Z',
              'is_read': true,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = NotificationRemoteDataSourceImpl(
        client: mockClient,
        sharedPreferences: prefs,
      );

      final result = await dataSource.markAsRead('notif_99');
      expect(result, isNotNull);
      expect(result!.isRead, isTrue);
    });
  });

  group('NotificationDetailScreen Widget Tests', () {
    late SharedPreferences prefs;
    late NotificationRepositoryImpl repository;
    late NotificationCubit cubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = NotificationRepositoryImpl(sharedPreferences: prefs);
      cubit = NotificationCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders detail screen for informational notification without action route', (tester) async {
      final notification = AppNotification(
        id: 'info_1',
        title: 'System Maintenance Scheduled',
        message: 'The servers will undergo brief maintenance on Sunday at 2 AM UTC.',
        category: NotificationCategory.system,
        timestamp: DateTime(2026, 10, 16, 14, 30),
        actionRoute: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: NotificationDetailScreen(notification: notification),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and title
      expect(find.text('Notification Details'), findsOneWidget);
      expect(find.text('System Maintenance Scheduled'), findsOneWidget);
      expect(find.text('SYSTEM NOTICE'), findsOneWidget);

      // Body message
      expect(
        find.text('The servers will undergo brief maintenance on Sunday at 2 AM UTC.'),
        findsOneWidget,
      );

      // Informational banner since actionRoute is null
      expect(
        find.text('This is an informational notice. No additional action is required.'),
        findsOneWidget,
      );

      // Copy text button
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('renders detail screen with action button when actionRoute is present', (tester) async {
      final notification = AppNotification(
        id: 'action_1',
        title: 'Payment Reminder',
        message: 'John Doe has an upcoming due payment of ₦25,000.',
        category: NotificationCategory.dueSoon,
        timestamp: DateTime(2026, 10, 16, 14, 30),
        actionRoute: '/ledger/contact_123',
        actionData: {'contact_id': 'contact_123', 'amount': '25,000'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: NotificationDetailScreen(notification: notification),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UPCOMING DUE DATE'), findsOneWidget);
      expect(find.text('Payment Reminder'), findsOneWidget);
      expect(find.text('View Ledger & Transactions'), findsOneWidget);
      expect(find.text('Additional Information'), findsOneWidget);
      expect(find.text('Contact Id'), findsOneWidget);
    });
  });
}
