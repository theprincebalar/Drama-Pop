import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/modules/paywall/views/subscription_view.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestEnvironment();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('Independent Platform In-Review Tests', () {
    testWidgets('Social proof is hidden on Android when isAndroidInReview is true', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await setupTestEnvironment(
        isAndroidInReview: true,
        isIosInReview: false,
      );

      await tester.pumpWidget(
        createTestApp(
          const SubscriptionView(),
          platform: TargetPlatform.android,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('4.9/5 • Joined by 100,000+ Drama Lovers'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Social proof is displayed on Android when isAndroidInReview is false', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await setupTestEnvironment(
        isAndroidInReview: false,
        isIosInReview: true, // iOS is in review, but Android is not
      );

      await tester.pumpWidget(
        createTestApp(
          const SubscriptionView(),
          platform: TargetPlatform.android,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('4.9/5 • Joined by 100,000+ Drama Lovers'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Social proof is hidden on iOS when isIosInReview is true', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await setupTestEnvironment(
        isAndroidInReview: false,
        isIosInReview: true,
      );

      await tester.pumpWidget(
        createTestApp(
          const SubscriptionView(),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('4.9/5 • Joined by 100,000+ Drama Lovers'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Social proof is displayed on iOS when isIosInReview is false', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await setupTestEnvironment(
        isAndroidInReview: true, // Android is in review, but iOS is not
        isIosInReview: false,
      );

      await tester.pumpWidget(
        createTestApp(
          const SubscriptionView(),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('4.9/5 • Joined by 100,000+ Drama Lovers'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
