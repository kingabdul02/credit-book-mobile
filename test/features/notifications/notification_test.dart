import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/home/domain/entities/dashboard_entities.dart';
import 'package:creditbook/features/notifications/domain/entities/app_notification.dart';
import 'package:creditbook/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:creditbook/features/notifications/presentation/bloc/notification_cubit.dart';
import 'package:creditbook/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:creditbook/features/notifications/presentation/pages/notifications_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late NotificationRepositoryImpl repository;
  late NotificationCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = NotificationRepositoryImpl(sharedPreferences: prefs);
    cubit = NotificationCubit(repository: repository);
    await cubit.loadNotifications();
  });

  tearDown(() {
    cubit.close();
  });

  group('Notification System - Unit Tests', () {
    test('initializes with seed notifications when empty', () async {
      expect(cubit.state.notifications.isNotEmpty, isTrue);
      expect(cubit.state.unreadCount, equals(cubit.state.notifications.length));
    });

    test('marks single notification as read', () async {
      final firstId = cubit.state.notifications.first.id;
      final initialUnread = cubit.state.unreadCount;

      await cubit.markAsRead(firstId);

      expect(cubit.state.unreadCount, equals(initialUnread - 1));
      final updated = cubit.state.notifications.firstWhere((n) => n.id == firstId);
      expect(updated.isRead, isTrue);
    });

    test('marks all notifications as read', () async {
      expect(cubit.state.unreadCount, greaterThan(0));

      await cubit.markAllAsRead();

      expect(cubit.state.unreadCount, equals(0));
      for (final n in cubit.state.notifications) {
        expect(n.isRead, isTrue);
      }
    });

    test('deletes a notification', () async {
      final countBefore = cubit.state.notifications.length;
      final toDeleteId = cubit.state.notifications.first.id;

      await cubit.deleteNotification(toDeleteId);

      expect(cubit.state.notifications.length, equals(countBefore - 1));
      expect(cubit.state.notifications.any((n) => n.id == toDeleteId), isFalse);
    });

    test('clears all notifications', () async {
      expect(cubit.state.notifications.isNotEmpty, isTrue);

      await cubit.clearAll();

      expect(cubit.state.notifications, isEmpty);
      expect(cubit.state.unreadCount, equals(0));
    });

    test('filters notifications by active filter', () async {
      // Mark first as read
      await cubit.markAsRead(cubit.state.notifications.first.id);

      cubit.setFilter('Unread');
      expect(cubit.state.filteredNotifications.every((n) => !n.isRead), isTrue);

      cubit.setFilter('All');
      expect(cubit.state.filteredNotifications.length, equals(cubit.state.notifications.length));
    });

    test('syncs notifications from dashboard metrics and reminders', () async {
      const dashboard = DashboardData(
        metrics: DashboardMetrics(
          totalOwedToMe: '100000',
          totalIOwe: '20000',
          netBalance: '80000',
          activeDebtsCount: 5,
          overdueCount: 2,
        ),
        upcomingReminders: [
          Reminder(
            id: 'test_rem_1',
            debt: Debt(
              id: 'debt_1',
              contact: Contact(id: 'c_1', fullName: 'Alice Johnson'),
              transactionType: 'they_owe_me',
              statusLabel: 'Unpaid',
            ),
            remindAt: '2026-10-18T10:00:00Z',
            typeLabel: 'SMS reminder',
          ),
        ],
        recentTransactions: [],
      );

      await cubit.syncDashboard(dashboard);

      final hasOverdueNotification = cubit.state.notifications.any(
        (n) => n.category == NotificationCategory.overdue,
      );
      final hasReminderNotification = cubit.state.notifications.any(
        (n) => n.id == 'rem_test_rem_1',
      );

      expect(hasOverdueNotification, isTrue);
      expect(hasReminderNotification, isTrue);
    });
  });

  group('Notification System - Widget Tests', () {
    testWidgets('NotificationBellButton shows unread badge when unreadCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: NotificationBellButton(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NotificationBellButton), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.text('${cubit.state.unreadCount}'), findsOneWidget);
    });

    testWidgets('NotificationsScreen displays notifications and filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: const NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All (${cubit.state.notifications.length})'), findsOneWidget);
      expect(find.text('Welcome to CreditBook! 🎉'), findsOneWidget);
    });

    testWidgets('NotificationsScreen shows empty state when notifications cleared', (tester) async {
      await cubit.clearAll();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationCubit>.value(
            value: cubit,
            child: const NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('All Caught Up! 🎉'), findsOneWidget);
    });

    testWidgets('Tapping Welcome notification navigates to /notification-detail instead of /home', (tester) async {
      var navigatedToDetail = false;
      var navigatedToHome = false;

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/notification-detail',
            builder: (context, state) {
              navigatedToDetail = true;
              return const Scaffold(body: Text('Detail Screen'));
            },
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<NotificationCubit>.value(
          value: cubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final welcomeFinder = find.text('Welcome to CreditBook! 🎉');
      expect(welcomeFinder, findsOneWidget);

      await tester.tap(welcomeFinder);
      await tester.pumpAndSettle();

      expect(navigatedToDetail, isTrue);
      expect(navigatedToHome, isFalse);
    });
  });
}
