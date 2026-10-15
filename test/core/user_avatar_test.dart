import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creditbook/core/widgets/user_avatar.dart';

void main() {
  group('UserAvatar.resolveUrl', () {
    test('returns null for null or empty input', () {
      expect(UserAvatar.resolveUrl(null), isNull);
      expect(UserAvatar.resolveUrl(''), isNull);
      expect(UserAvatar.resolveUrl('   '), isNull);
    });

    test('rewrites /storage/avatars/ to /api/v1/avatars/', () {
      const input = 'https://creditbook.smartapps.com.ng/storage/avatars/abc1234.jpg';
      final resolved = UserAvatar.resolveUrl(input);
      expect(resolved, equals('https://creditbook.smartapps.com.ng/api/v1/avatars/abc1234.jpg'));
    });

    test('replaces localhost and rewrites storage to api avatars', () {
      const input = 'http://localhost/storage/avatars/photo.png';
      final resolved = UserAvatar.resolveUrl(input);
      expect(resolved, equals('https://creditbook.smartapps.com.ng/api/v1/avatars/photo.png'));
    });

    test('replaces 127.0.0.1 and upgrades http to https', () {
      const input = 'http://127.0.0.1/storage/avatars/avatar.webp';
      final resolved = UserAvatar.resolveUrl(input);
      expect(resolved, equals('https://creditbook.smartapps.com.ng/api/v1/avatars/avatar.webp'));
    });

    test('handles relative storage path', () {
      const input = '/storage/avatars/my_pic.jpg';
      final resolved = UserAvatar.resolveUrl(input);
      expect(resolved, equals('https://creditbook.smartapps.com.ng/api/v1/avatars/my_pic.jpg'));
    });

    test('upgrades plain HTTP to HTTPS for creditbook domain', () {
      const input = 'http://creditbook.smartapps.com.ng/api/v1/avatars/my_pic.jpg';
      final resolved = UserAvatar.resolveUrl(input);
      expect(resolved, equals('https://creditbook.smartapps.com.ng/api/v1/avatars/my_pic.jpg'));
    });
  });

  group('UserAvatar Widget Tests', () {
    testWidgets('renders default avatar icon when avatarUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(avatarUrl: null, radius: 24),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatarUrl: null,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserAvatar));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
