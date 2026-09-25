import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dramapop/app/data/models/series_model.dart';
import 'package:dramapop/app/data/services/user_library_service.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  final testSeries = SeriesModel(
    id: 'drama_test_1',
    title: 'The Billionaire Hidden Secret',
    description: 'A romantic thriller about billionaire romance.',
    coverUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7',
    episodesCount: 50,
    genres: ['Romance', 'Drama'],
    status: 'Ongoing',
    views: 125000,
    rating: 4.9,
    episodes: [],
  );

  group('User Library & Bookmarks Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment();
        });

        testWidgets('1. Watchlist add/remove toggle functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final lib = UserLibraryService.to;

          expect(lib.isSeriesInWatchlist(testSeries.id), false);
          expect(lib.watchlist.length, 0);

          // Add to watchlist
          lib.toggleWatchlist(testSeries, showToast: false);
          expect(lib.isSeriesInWatchlist(testSeries.id), true);
          expect(lib.watchlist.length, 1);
          expect(lib.watchlist.first.title, 'The Billionaire Hidden Secret');

          // Remove from watchlist
          lib.toggleWatchlist(testSeries, showToast: false);
          expect(lib.isSeriesInWatchlist(testSeries.id), false);
          expect(lib.watchlist.length, 0);
        });

        testWidgets('2. Saved Episodes bookmarking functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final lib = UserLibraryService.to;

          expect(lib.isEpisodeSaved(testSeries.id, 4), false);
          expect(lib.savedEpisodes.length, 0);

          // Save Episode 4
          lib.toggleSaveEpisode(
            series: testSeries,
            episodeNumber: 4,
            episodeTitle: 'The Secret Revealed',
            duration: '2:15',
            showToast: false,
          );

          expect(lib.isEpisodeSaved(testSeries.id, 4), true);
          expect(lib.savedEpisodes.length, 1);
          expect(lib.savedEpisodes.first.episodeTitle, 'The Secret Revealed');
          expect(lib.savedEpisodes.first.duration, '2:15');

          // Remove Episode 4
          lib.removeSavedEpisode(testSeries.id, 4);
          expect(lib.isEpisodeSaved(testSeries.id, 4), false);
          expect(lib.savedEpisodes.length, 0);
        });

        testWidgets('3. Watch progress recording & retrieval functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final lib = UserLibraryService.to;

          expect(lib.getReachedEpisodeIndex(testSeries.id), 0);

          lib.recordWatchProgress(testSeries.id, 7);
          await tester.pump();

          expect(lib.getReachedEpisodeIndex(testSeries.id), 7);
        });

        testWidgets('4. Default video quality preference update functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final lib = UserLibraryService.to;

          expect(lib.defaultQuality.value, '720p');

          lib.setDefaultQuality('1080p');
          expect(lib.defaultQuality.value, '1080p');

          lib.setDefaultQuality('540p');
          expect(lib.defaultQuality.value, '540p');
        });
      });
    }
  });
}
