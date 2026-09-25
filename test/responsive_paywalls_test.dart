import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/modules/paywall/views/subscription_view.dart';
import 'package:dramapop/app/modules/paywall/views/coin_store_view.dart';
import 'test_helper.dart';

void main() {
  final List<Size> testDeviceSizes = [
    const Size(320, 568),   // iPhone SE 1st gen / Small budget Android
    const Size(360, 640),   // Compact budget Android (Galaxy A03, Moto G)
    const Size(375, 667),   // iPhone 8 / iPhone SE 2022
    const Size(390, 844),   // Standard iPhone 12/13/14/15
    const Size(412, 915),   // Standard Android (Pixel 8, Galaxy S24)
    const Size(430, 932),   // Large iPhone Pro Max
    const Size(600, 960),   // 7-inch Mini Tablet / Foldable screen
    const Size(768, 1024),  // iPad Standard
    const Size(1024, 1366), // iPad Pro 12.9 inch
  ];

  final List<TargetPlatform> testPlatforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestEnvironment();
  });

  group('SubscriptionView Multi-Device Responsive & Overflow Tests', () {
    for (final size in testDeviceSizes) {
      for (final platform in testPlatforms) {
        testWidgets(
          'SubscriptionView renders without overflow on ${platform.name} (${size.width.toInt()}x${size.height.toInt()})',
          (WidgetTester tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() => tester.view.resetPhysicalSize());

            await setupTestEnvironment(
              isVip: false,
              isAndroidInReview: false,
              isIosInReview: false,
            );

            await tester.pumpWidget(
              createTestApp(
                const SubscriptionView(),
                platform: platform,
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            // Verify essential headline and perks render
            expect(find.text('Unlimited Access to 20,000+ Episodes'), findsOneWidget);
            expect(find.text('20,000+ Episodes'), findsOneWidget);
            expect(find.text('100% Ad-Free'), findsOneWidget);
            expect(find.text('Daily Early Access'), findsOneWidget);
            expect(find.text('1080P Ultra HD'), findsOneWidget);
            expect(find.text('Restore'), findsOneWidget);

            // Test scrollability without overflow
            await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
            await tester.pump(const Duration(milliseconds: 300));
          },
        );

        testWidgets(
          'SubscriptionView with Active VIP renders correctly on ${platform.name} (${size.width.toInt()}x${size.height.toInt()})',
          (WidgetTester tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() => tester.view.resetPhysicalSize());

            await setupTestEnvironment(
              isVip: true,
              isAndroidInReview: false,
              isIosInReview: false,
            );

            await tester.pumpWidget(
              createTestApp(
                const SubscriptionView(),
                platform: platform,
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            expect(find.text('CURRENT ACTIVE PLAN'), findsOneWidget);
          },
        );
      }
    }
  });

  group('CoinStoreView Multi-Device Responsive & Overflow Tests', () {
    for (final size in testDeviceSizes) {
      for (final platform in testPlatforms) {
        testWidgets(
          'CoinStoreView renders without overflow on ${platform.name} (${size.width.toInt()}x${size.height.toInt()})',
          (WidgetTester tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() => tester.view.resetPhysicalSize());

            await setupTestEnvironment(
              isVip: false,
              coins: 500,
            );

            await tester.pumpWidget(
              createTestApp(
                const CoinStoreView(),
                platform: platform,
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            expect(find.text('Choose Coin Package'), findsOneWidget);
            expect(find.text('INSTANT REFILL'), findsOneWidget);

            // Test vertical scrolling
            await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
            await tester.pump(const Duration(milliseconds: 300));
          },
        );
      }
    }
  });
}
