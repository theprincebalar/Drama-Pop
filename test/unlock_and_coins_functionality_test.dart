import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dramapop/app/data/services/unlock_service.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  group('Unlock & Coins Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment(isVip: false, coins: 50);
        });

        testWidgets('1. Coin Package Purchase correctly credits balance on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final unlock = UnlockService.to;

          expect(unlock.userCoins.value, 50);

          const package = CoinPackage(
            id: 'coins_550',
            coins: 500,
            bonusCoins: 50,
            price: 4.99,
            priceFormatted: '\$4.99',
          );

          unlock.buyCoins(package);
          await tester.pump();
          await tester.pump(const Duration(seconds: 4)); // Settle snackbar animation

          expect(unlock.userCoins.value, 600); // 50 + 550
          expect(unlock.purchasedCoins.value, 550);
        });

        testWidgets('2. Episode unlock with sufficient coins succeeds on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final unlock = UnlockService.to;

          expect(unlock.isEpisodeUnlocked('drama_101', 3), false);

          final success = unlock.unlockEpisodeWithCoins('drama_101', 3, coinPrice: 15, seriesTitle: 'CEO Secret Lover');
          await tester.pump();

          expect(success, true);
          expect(unlock.userCoins.value, 35); // 50 - 15
          expect(unlock.usedCoins.value, 15);
          expect(unlock.isEpisodeUnlocked('drama_101', 3), true);

          // Re-unlocking same episode must return true without deducting coins again
          final successRecheck = unlock.unlockEpisodeWithCoins('drama_101', 3, coinPrice: 15);
          expect(successRecheck, true);
          expect(unlock.userCoins.value, 35);
          expect(unlock.usedCoins.value, 15);
        });

        testWidgets('3. Episode unlock with insufficient coins fails cleanly on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final unlock = UnlockService.to;

          unlock.userCoins.value = 5;

          final success = unlock.unlockEpisodeWithCoins('drama_102', 5, coinPrice: 15);
          await tester.pump();

          expect(success, false);
          expect(unlock.userCoins.value, 5); // Unchanged
          expect(unlock.isEpisodeUnlocked('drama_102', 5), false);
        });

        testWidgets('4. Direct episode and series-wide unlocks on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final unlock = UnlockService.to;

          unlock.unlockEpisodeDirect('drama_103', 1);
          expect(unlock.isEpisodeUnlocked('drama_103', 1), true);
          expect(unlock.isEpisodeUnlocked('drama_103', 2), false);

          unlock.unlockSeries('drama_103', 5);
          expect(unlock.isEpisodeUnlocked('drama_103', 1), true);
          expect(unlock.isEpisodeUnlocked('drama_103', 2), true);
          expect(unlock.isEpisodeUnlocked('drama_103', 5), true);
          expect(unlock.isEpisodeUnlocked('drama_103', 6), true); // Unlocked series allows all episodes
        });

        testWidgets('5. Subscription activation grants unlimited VIP access on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final unlock = UnlockService.to;

          expect(unlock.hasUnlimitedAccess, false);
          expect(unlock.isEpisodeUnlocked('any_drama_id', 99), false);

          const weeklyPlan = SubscriptionPlan(
            period: SubscriptionPeriod.weekly,
            title: 'Weekly Pass',
            durationLabel: '7 Days',
            price: 4.99,
            priceFormatted: '\$4.99',
            periodDescription: 'Billed weekly',
          );

          unlock.subscribe(weeklyPlan);
          await tester.pump();
          await tester.pump(const Duration(seconds: 4)); // Settle snackbar animation

          expect(unlock.hasUnlimitedAccess, true);
          expect(unlock.activeSubscription.value?.period, SubscriptionPeriod.weekly);
          expect(unlock.subscriptionExpiry.value, isNotNull);
          expect(unlock.isEpisodeUnlocked('any_drama_id', 99), true);
        });
      });
    }
  });
}
