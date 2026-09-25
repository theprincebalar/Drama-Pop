import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/modules/profile/views/profile_view.dart';
import 'package:dramapop/app/modules/profile/views/saved_episodes_view.dart';
import 'test_helper.dart';

void main() {
  final List<Size> testDeviceSizes = [
    const Size(320, 568),   // iPhone SE 1st Gen
    const Size(360, 640),   // Compact Android
    const Size(375, 667),   // iPhone 8
    const Size(390, 844),   // iPhone 14
    const Size(412, 915),   // Pixel 8
    const Size(430, 932),   // iPhone 15 Pro Max
    const Size(600, 960),   // Foldable / 7" Tablet
    const Size(768, 1024),  // iPad
    const Size(1024, 1366), // iPad Pro 12.9
  ];

  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestEnvironment();
  });

  group('ProfileView Multi-Device Layout Tests', () {
    for (final size in testDeviceSizes) {
      for (final platform in platforms) {
        testWidgets('ProfileView renders on ${platform.name} (${size.width.toInt()}x${size.height.toInt()}) without overflow', (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createTestApp(
              const ProfileView(),
              platform: platform,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('My Profile'), findsOneWidget);
          expect(find.text('Drama Fan #8821'), findsOneWidget);

          // Test vertical scrolling
          await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 300));
        });
      }
    }
  });

  group('SavedEpisodesView Multi-Device Layout Tests', () {
    for (final size in testDeviceSizes) {
      for (final platform in platforms) {
        testWidgets('SavedEpisodesView renders on ${platform.name} (${size.width.toInt()}x${size.height.toInt()}) without overflow', (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createTestApp(
              const SavedEpisodesView(),
              platform: platform,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Saved'), findsOneWidget);
        });
      }
    }
  });
}
