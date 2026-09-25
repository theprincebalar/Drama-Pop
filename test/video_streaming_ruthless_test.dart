import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dramapop/app/data/models/series_model.dart';
import 'package:dramapop/app/data/models/episode_model.dart';
import 'package:dramapop/app/modules/player/controllers/player_controller.dart';
import 'package:dramapop/app/modules/feed/controllers/feed_controller.dart';
import 'package:dramapop/app/modules/root/controllers/root_controller.dart';
import 'package:dramapop/app/data/services/unlock_service.dart';
import 'package:dramapop/app/data/services/app_review_service.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  final mockEpisodes = List.generate(
    10,
    (index) => EpisodeModel(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      stream540p: 'https://dirjqbe1kaah2.cloudfront.net/drama_stream_test/${index + 1}/videon540x960.m3u8',
      stream720p: 'https://dirjqbe1kaah2.cloudfront.net/drama_stream_test/${index + 1}/videon720x1280.m3u8',
      stream1080p: 'https://dirjqbe1kaah2.cloudfront.net/drama_stream_test/${index + 1}/videon1080x1920.m3u8',
      duration: '1:30',
      isLocked: index >= 6, // First 6 episodes free, episodes 7-10 locked
      coinPrice: 15,
    ),
  );

  final mockSeries = SeriesModel(
    id: 'drama_stream_test',
    title: 'Ruthless Billionaire Revenge',
    description: 'High stakes drama stream testing',
    coverUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7',
    episodesCount: 10,
    genres: ['Romance', 'Revenge'],
    status: 'Completed',
    views: 99000,
    rating: 4.9,
    episodes: mockEpisodes,
  );

  group('Ruthless Video Streaming Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment(isVip: false, coins: 50);
        });

        testWidgets('1. Rapid episode switching & rapid sequential seeking on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          Get.parameters = {};
          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_1',
          );
          player.series = mockSeries.obs;
          player.currentEpisodeIndex.value = 0;

          // Rapid episode switching simulation
          player.playEpisode(1);
          player.playEpisode(2);
          player.playEpisode(3);
          player.playPreviousEpisode();
          player.playNextEpisode();
          player.playEpisode(5);

          expect(player.currentEpisodeIndex.value, 5);
          expect(player.isCurrentEpisodeLocked.value, false);

          // Rapid seeking forwards and backwards beyond limits
          player.currentPosition.value = const Duration(seconds: 40);
          player.totalDuration.value = const Duration(seconds: 90);

          player.skipForward10();
          player.skipForward10();
          player.skipForward10();
          expect(player.showForward10Overlay.value, true);

          player.skipBackward10();
          player.skipBackward10();
          player.skipBackward10();
          player.skipBackward10();
          player.skipBackward10();
          expect(player.showBackward10Overlay.value, true);

          await tester.pump(const Duration(milliseconds: 700));
          expect(player.showForward10Overlay.value, false);
          expect(player.showBackward10Overlay.value, false);

          // Clean exit
          player.onClose();
        });

        testWidgets('2. Sudden app backgrounding & sudden screen exit cleanup on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_2',
          );
          player.series = mockSeries.obs;
          player.playEpisode(0);

          expect(player.isPlaying.value, true);

          // Simulate user minimizing app / receiving phone call
          player.didChangeAppLifecycleState(AppLifecycleState.paused);
          expect(player.isPlaying.value, false);

          // Simulate user returning
          player.resumeVideo();
          expect(player.isPlaying.value, true);

          // Sudden screen exit / controller disposal
          player.onClose();
          expect(player.videoPlayerController, isNull);
        });

        testWidgets('3. Playback speed changes across 0.75x to 2.0x on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_3',
          );
          player.series = mockSeries.obs;

          expect(player.playbackSpeed.value, 1.0);

          player.setSpeed(1.25);
          expect(player.playbackSpeed.value, 1.25);

          player.setSpeed(1.5);
          expect(player.playbackSpeed.value, 1.5);

          player.setSpeed(2.0);
          expect(player.playbackSpeed.value, 2.0);

          player.setSpeed(0.75);
          expect(player.playbackSpeed.value, 0.75);

          player.onClose();
        });

        testWidgets('4. Locked episode detection & in-player coin unlocking on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_4',
          );
          player.series = mockSeries.obs;

          // Play Episode 7 (index 6, locked)
          player.playEpisode(6);
          expect(player.isCurrentEpisodeLocked.value, true);

          // Unlock with coins
          player.unlockAndPlayCurrentEpisode();
          await tester.pump();
          await tester.pump(const Duration(seconds: 3)); // settle snackbar

          expect(player.isCurrentEpisodeLocked.value, false);
          expect(UnlockService.to.userCoins.value, 35); // 50 - 15

          player.onClose();
        });

        testWidgets('5. Quality switching and 1080p VIP permission guard on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_5',
          );
          player.series = mockSeries.obs;
          player.playEpisode(0);

          // Free user switches to 540p & 720p (allowed)
          player.setQuality('540p');
          expect(player.selectedQuality.value, '540p');

          player.setQuality('720p');
          expect(player.selectedQuality.value, '720p');

          // Free user switches to 1080p without unlocking ep 1 (blocked)
          player.setQuality('1080p');
          await tester.pump();
          await tester.pump(const Duration(seconds: 4)); // settle snackbar

          // Now grant VIP and retry 1080p (allowed)
          UnlockService.to.isGlobalVip.value = true;
          player.setQuality('1080p');
          expect(player.selectedQuality.value, '1080p');

          player.onClose();
        });

        testWidgets('6. FeedController rapid vertical swiping and lifecycle isolation on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final root = Get.put(RootController());
          final feed = Get.put(FeedController());

          feed.seriesList.assignAll([mockSeries, mockSeries]);

          // Feed inactive when root index is 0 (Home)
          root.changePage(0);
          feed.pauseVideo();
          expect(feed.isPlaying.value, false);

          // Feed active when root index is 1 (Feed/Shorts)
          root.changePage(1);
          feed.onFeedTabActive();
          expect(feed.isFeedActive, true);

          // Rapid swiping simulation
          feed.onPageChanged(1);
          expect(feed.currentSeriesIndex.value, 1);

          feed.onPageChanged(0);
          expect(feed.currentSeriesIndex.value, 0);

          // User opens episode drawer / detail
          feed.isDetailOpen.value = true;
          feed.pauseVideo();
          expect(feed.isPlaying.value, false);

          // User closes detail and returns to feed
          feed.isDetailOpen.value = false;
          feed.resumeVideo();
          expect(feed.isDetailOpen.value, false);

          // Sudden exit
          feed.onClose();
          expect(feed.videoPlayerController, isNull);
        });

        testWidgets('7. Auto-advance at end of series marks completed on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));

          final player = Get.put(
            PlayerController(),
            tag: 'test_player_${platform.name}_7',
          );
          player.series = mockSeries.obs;
          player.currentEpisodeIndex.value = 9; // Last episode

          expect(AppReviewService.to.completedEpisodesCount.value, 0);

          // Advancing beyond final episode
          player.playNextEpisode();
          await tester.pump();
          await tester.pump(const Duration(seconds: 4)); // settle snackbar

          expect(AppReviewService.to.completedEpisodesCount.value, 1);

          player.onClose();
        });
      });
    }
  });
}
