import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creditbook/core/widgets/app_error_view.dart';

void main() {
  group('AppErrorView Widget Tests', () {
    testWidgets('renders network error with wifi_off icon and friendly copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: 'ClientException: Connection closed before full header was received',
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text('Unable to connect to the server. Please check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('renders retry button and triggers callback when tapped', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              error: 'Failed to load details',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('supports custom title, message and icon override', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorView(
              title: 'Custom Title',
              message: 'Custom error explanation',
              icon: Icons.cloud_off,
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom error explanation'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      // No retry button when onRetry is null
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
