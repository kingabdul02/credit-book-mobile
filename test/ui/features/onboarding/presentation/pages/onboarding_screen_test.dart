import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creditbook/features/onboarding/presentation/pages/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: OnboardingScreen(),
    );
  }

  testWidgets('OnboardingScreen renders correctly on normal screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(createWidgetUnderTest());
    
    // We don't use pumpAndSettle because flutter_animate might have looping animations (like shimmer)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Track Every Penny'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('OnboardingScreen handles responsiveness and has no overflow on a very short screen', (WidgetTester tester) async {
    // Simulate a very short screen (e.g., landscape on a small device)
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 2.0;

    // Flutter test framework automatically catches layout overflow errors and fails the test
    // if any render box overflows.
    await tester.pumpWidget(createWidgetUnderTest());
    
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify it still renders without throwing layout exceptions
    expect(find.text('Track Every Penny'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
