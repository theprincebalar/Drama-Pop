import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/data/models/series_model.dart';
import 'package:dramapop/app/data/services/unlock_service.dart';
import 'package:dramapop/app/widgets/report_modal.dart';
import 'package:dramapop/app/widgets/in_app_review_dialog.dart';
import 'package:dramapop/app/widgets/subscription_success_dialog.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  final sampleSeries = SeriesModel(
    id: 'series_modal_test',
    title: 'Alpha CEO Romance',
    description: 'Drama series test description',
    coverUrl: '',
    episodesCount: 30,
    genres: ['Romance'],
    status: 'Completed',
    views: 88000,
    rating: 4.9,
    episodes: [],
  );

  group('Modals and Dialogs Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment();
        });

        testWidgets('1. ReportModal renders and allows reason selection on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestApp(
              Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => ReportModal.show(ctx, series: sampleSeries, episodeNumber: 2),
                    child: const Text('Open Report'),
                  ),
                ),
              ),
              platform: platform,
            ),
          );

          await tester.tap(find.text('Open Report'));
          await tester.pumpAndSettle();

          expect(find.text('Report an Issue'), findsOneWidget);
          expect(find.text('Playback Error'), findsOneWidget);
          expect(find.text('Audio Issue'), findsOneWidget);
          expect(find.text('Subtitle Error'), findsOneWidget);

          // Select reason
          await tester.tap(find.text('Playback Error'));
          await tester.pumpAndSettle();

          expect(find.text('Submit Report'), findsOneWidget);
        });

        testWidgets('2. SubscriptionSuccessDialog renders VIP benefits on ${platform.name}', (WidgetTester tester) async {
          const plan = SubscriptionPlan(
            period: SubscriptionPeriod.yearly,
            title: 'Annual VIP',
            durationLabel: '1 Year',
            price: 149.99,
            priceFormatted: '\$149.99',
            periodDescription: 'Billed annually',
          );

          await tester.pumpWidget(
            createTestApp(
              SubscriptionSuccessDialog(
                plan: plan,
                expiryDate: DateTime(2027, 9, 24),
              ),
              platform: platform,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('🎉 VIP Access Unlocked!'), findsOneWidget);
          expect(find.text('Active Plan'), findsOneWidget);
          expect(find.text('Annual VIP'), findsOneWidget);
          expect(find.text('Start Watching Now'), findsOneWidget);
        });

        testWidgets('3. InAppReviewDialog renders stars and rating on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestApp(
              const Scaffold(body: InAppReviewDialog()),
              platform: platform,
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text('Enjoying DramaPop?'), findsOneWidget);
          expect(find.byIcon(Icons.star_rounded), findsNWidgets(6));
          expect(find.text('Maybe Later'), findsOneWidget);
        });
      });
    }
  });
}
