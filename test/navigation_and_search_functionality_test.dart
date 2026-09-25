import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dramapop/app/data/models/series_model.dart';
import 'package:dramapop/app/modules/root/controllers/root_controller.dart';
import 'package:dramapop/app/modules/search/controllers/search_controller.dart';
import 'package:dramapop/app/modules/watchlist/controllers/watchlist_controller.dart';
import 'package:dramapop/app/data/services/user_library_service.dart';
import 'test_helper.dart';

void main() {
  final List<TargetPlatform> platforms = [
    TargetPlatform.android,
    TargetPlatform.iOS,
  ];

  group('Navigation, Search & Watchlist Functional Tests across Android and iOS', () {
    for (final platform in platforms) {
      group('Platform: ${platform.name}', () {
        setUp(() async {
          TestWidgetsFlutterBinding.ensureInitialized();
          await setupTestEnvironment();
        });

        testWidgets('1. RootController tab switching functions on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final root = Get.put(RootController());

          expect(root.currentIndex.value, 0);

          root.changePage(1);
          expect(root.currentIndex.value, 1);

          root.changePage(2);
          expect(root.currentIndex.value, 2);

          root.changePage(3);
          expect(root.currentIndex.value, 3);

          root.changePage(0);
          expect(root.currentIndex.value, 0);
        });

        testWidgets('2. DramaSearchController filtering and query handling on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final search = Get.put(DramaSearchController());

          final mockDramas = <SeriesModel>[
            SeriesModel(
              id: '1',
              title: 'Revenge of the Heiress',
              description: 'Romance story',
              coverUrl: '',
              episodesCount: 30,
              genres: ['Drama'],
              status: 'Completed',
              views: 50000,
              rating: 4.8,
              episodes: [],
            ),
            SeriesModel(
              id: '2',
              title: 'Billionaire Undercover Husband',
              description: 'Billionaire CEO drama',
              coverUrl: '',
              episodesCount: 40,
              genres: ['Romance'],
              status: 'Ongoing',
              views: 100000,
              rating: 4.9,
              episodes: [],
            ),
          ];

          search.allDramas.assignAll(mockDramas);

          // Search "Heiress"
          search.onQueryChanged('Heiress');
          await tester.pump(const Duration(milliseconds: 250));
          expect(search.searchResults.length, 1);
          expect(search.searchResults.first.title, 'Revenge of the Heiress');

          // Search "Billionaire"
          search.onQueryChanged('Billionaire');
          await tester.pump(const Duration(milliseconds: 250));
          expect(search.searchResults.length, 1);
          expect(search.searchResults.first.title, 'Billionaire Undercover Husband');

          // Clear search
          search.clearSearch();
          expect(search.searchQuery.value, '');
          expect(search.searchResults.length, 0);
        });

        testWidgets('3. WatchlistController methods work seamlessly on ${platform.name}', (WidgetTester tester) async {
          await tester.pumpWidget(createTestApp(const SizedBox(), platform: platform));
          final root = Get.put(RootController());
          final watchlistCtrl = Get.put(WatchlistController());

          final sample = SeriesModel(
            id: 'sample_1',
            title: 'Sample Drama',
            description: '',
            coverUrl: '',
            episodesCount: 20,
            genres: [],
            status: '',
            views: 100,
            rating: 4.5,
            episodes: [],
          );

          UserLibraryService.to.watchlist.add(sample);
          expect(watchlistCtrl.watchlist.length, 1);

          watchlistCtrl.removeSeries(sample);
          expect(watchlistCtrl.watchlist.length, 0);

          root.changePage(2);
          watchlistCtrl.exploreDramas();
          expect(root.currentIndex.value, 0);
        });
      });
    }
  });
}
