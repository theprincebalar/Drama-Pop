import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/api_service.dart';

class HomeController extends GetxController {
  final seriesList = <SeriesModel>[].obs;
  final isLoading = true.obs;
  final isBackgroundLoading = false.obs;
  final selectedGenre = 'All'.obs;
  final searchQuery = ''.obs;
  final displayedGridCount = 30.obs;

  void loadMoreGrid() {
    displayedGridCount.value += 30;
  }

  final genres = <String>[
    'All',
    'Billionaire',
    'Romance',
    'Revenge',
    'CEO',
    'Urban',
    'Contract Marriage',
    'Drama',
    'Action',
  ].obs;

  final homeSections = <Map<String, String>>[
    {'title': 'Trending Now', 'genre': 'Trending', 'icon': '🔥', 'subtitle': 'Most watched this week'},
    {'title': 'Billionaire Romance', 'genre': 'Billionaire', 'icon': '💎', 'subtitle': 'Power, passion & wealth'},
    {'title': 'Sweet Romance', 'genre': 'Romance', 'icon': '❤️', 'subtitle': 'Love stories & second chances'},
    {'title': 'Revenge & Retribution', 'genre': 'Revenge', 'icon': '⚡', 'subtitle': 'Payback is best served cold'},
    {'title': 'CEO & Dominant', 'genre': 'CEO', 'icon': '👔', 'subtitle': 'Bosses, contracts & intrigue'},
    {'title': 'Urban Drama', 'genre': 'Urban', 'icon': '🏙️', 'subtitle': 'Modern city lives & struggles'},
    {'title': 'Contract Marriage', 'genre': 'Contract Marriage', 'icon': '💍', 'subtitle': 'Fake nuptials turned real'},
    {'title': 'Action & Thriller', 'genre': 'Action', 'icon': '⚔️', 'subtitle': 'High adrenaline & suspense'},
  ];

  List<SeriesModel> getDramasForGenre(String genre) {
    if (genre == 'Trending' || genre == 'All') {
      final sorted = List<SeriesModel>.from(seriesList)
        ..sort((a, b) => b.views.compareTo(a.views));
      return sorted;
    }

    final gLower = genre.toLowerCase();
    final matches = seriesList.where((s) {
      final inGenres = s.genres.any((g) => g.toLowerCase().contains(gLower));
      final inTitle = s.title.toLowerCase().contains(gLower);
      final inDesc = s.description.toLowerCase().contains(gLower);
      return inGenres || inTitle || inDesc;
    }).toList();

    return matches;
  }

  List<SeriesModel> getTop15ForGenre(String genre) {
    final allInGenre = getDramasForGenre(genre);
    return allInGenre.take(15).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchSeriesProgressively();
  }

  // Instant First Batch (24 shows) + Background Full Catalog Sync
  Future<void> fetchSeries() => fetchSeriesProgressively();

  Future<void> fetchSeriesProgressively() async {
    isLoading.value = seriesList.isEmpty;
    try {
      // 1. Instant First Batch in < 30ms
      final initialBatch = await ApiService.getSeries(
        genre: selectedGenre.value,
        search: searchQuery.value,
        page: 1,
        limit: 24,
      );
      if (initialBatch.isNotEmpty) {
        seriesList.assignAll(initialBatch);
      }
      isLoading.value = false;

      // 2. Background Full Pre-fetch without blocking UI
      isBackgroundLoading.value = true;
      final fullCatalog = await ApiService.getSeries(
        genre: selectedGenre.value,
        search: searchQuery.value,
        page: 1,
        limit: 500,
      );
      if (fullCatalog.isNotEmpty) {
        seriesList.assignAll(fullCatalog);
      }
    } catch (e) {
      Get.snackbar('Notice', 'Using fast local catalogue cache');
    } finally {
      isLoading.value = false;
      isBackgroundLoading.value = false;
    }
  }

  void selectGenre(String genre) {
    if (selectedGenre.value == genre) return;
    selectedGenre.value = genre;
    fetchSeriesProgressively();
  }

  void onSearch(String query) {
    searchQuery.value = query;
    fetchSeriesProgressively();
  }
}