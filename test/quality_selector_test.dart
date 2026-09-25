import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dramapop/app/widgets/quality_selector_modal.dart';
import 'package:dramapop/app/routes/app_routes.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestEnvironment();
  });

  tearDown(() {
    Get.closeAllSnackbars();
  });

  group('Quality Selector 1080P Access Tests', () {
    testWidgets('Free user tapping 1080P shows VIP notice and redirects', (WidgetTester tester) async {
      await setupTestEnvironment(isVip: false);

      String selectedQuality = '720p';

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      QualitySelectorModal.show(
                        context,
                        currentQuality: selectedQuality,
                        onQualitySelected: (q) => selectedQuality = q,
                        seriesId: 'series_1',
                        episodeNumber: 5,
                      );
                    },
                    child: const Text('Open Quality Modal'),
                  ),
                ),
              ),
            ),
            GetPage(
              name: Routes.SUBSCRIPTION,
              page: () => const Scaffold(body: Text('Subscription Screen')),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open Quality Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Video Streaming Quality'), findsOneWidget);
      expect(find.text('1080P Ultra Full HD'), findsOneWidget);
      expect(find.text('Exclusive to VIP Pass or Coin-Unlocked Episodes'), findsOneWidget);

      // Tap 1080P as free user
      await tester.tap(find.text('1080P Ultra Full HD'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      // Verify redirection
      expect(find.text('Subscription Screen'), findsOneWidget);
      expect(selectedQuality, '720p'); // Quality remains 720p
    });

    testWidgets('VIP user tapping 1080P unlocks resolution without redirection', (WidgetTester tester) async {
      await setupTestEnvironment(isVip: true);

      String selectedQuality = '720p';

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      QualitySelectorModal.show(
                        context,
                        currentQuality: selectedQuality,
                        onQualitySelected: (q) => selectedQuality = q,
                        seriesId: 'series_1',
                        episodeNumber: 5,
                      );
                    },
                    child: const Text('Open Quality Modal'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open Quality Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Crystal clear cinema bitrate (Unlocked)'), findsOneWidget);

      // Tap 1080P as VIP user
      await tester.tap(find.text('1080P Ultra Full HD'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(selectedQuality, '1080p');
    });

    testWidgets('Selecting 540P or 720P works for any user', (WidgetTester tester) async {
      await setupTestEnvironment(isVip: false);

      String selectedQuality = '720p';

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      QualitySelectorModal.show(
                        context,
                        currentQuality: selectedQuality,
                        onQualitySelected: (q) => selectedQuality = q,
                      );
                    },
                    child: const Text('Open Quality Modal'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open Quality Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('540P Smooth HD'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(selectedQuality, '540p');
    });
  });
}
