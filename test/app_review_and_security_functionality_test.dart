import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/data/services/app_review_service.dart';
import 'package:dramapop/app/data/services/security_service.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  group('App Review & Security Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment();
        });

        testWidgets('1. App Review episode completion tracking functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final reviewService = AppReviewService.to;

          expect(reviewService.completedEpisodesCount.value, 0);

          await reviewService.recordEpisodeCompleted();
          expect(reviewService.completedEpisodesCount.value, 1);

          await reviewService.recordEpisodeCompleted();
          expect(reviewService.completedEpisodesCount.value, 2);
        });

        testWidgets('2. Platform-specific In-Review flag isolation on ${platform.name}', (WidgetTester tester) async {
          debugDefaultTargetPlatformOverride = platform;
          try {
            await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
            final reviewService = AppReviewService.to;

            if (platform == TargetPlatform.android) {
              reviewService.isAndroidInReview.value = true;
              reviewService.isIosInReview.value = false;
              expect(reviewService.isCurrentPlatformInReview, true);

              reviewService.isAndroidInReview.value = false;
              expect(reviewService.isCurrentPlatformInReview, false);
            } else if (platform == TargetPlatform.iOS) {
              reviewService.isAndroidInReview.value = true;
              reviewService.isIosInReview.value = false;
              expect(reviewService.isCurrentPlatformInReview, false);

              reviewService.isIosInReview.value = true;
              expect(reviewService.isCurrentPlatformInReview, true);
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });

        testWidgets('3. SecurityService safe execution on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          
          // Must execute safely across platforms
          await SecurityService.enableScreenshotProtection();
          final isCaptured = await SecurityService.isScreenCaptured();
          expect(isCaptured, false);
        });
      });
    }
  });
}
