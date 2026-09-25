import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/firebase_analytics_service.dart';
import '../../../routes/app_routes.dart';

class DramaSearchController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final allDramas = <SeriesModel>[].obs;
  final searchResults = <SeriesModel>[].obs;
  final trendingDramas = <SeriesModel>[].obs;

  final searchQuery = ''.obs;
  final isLoading = true.obs;

  Timer? _debounceTimer;

  final popularKeywords = <String>[
    'Billionaire',
    'Revenge',
    'Romance',
    'CEO',
    'Drama',
    'Secret',
    'Love',
    'Marriage',
    'Family',
    'Mystery',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadCatalog();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> _loadCatalog() async {
    isLoading.value = true;
    try {
      final catalog = await ApiService.loadBundledCatalog();
      allDramas.assignAll(catalog);

      // Pick top trending dramas for empty state suggestions
      if (catalog.isNotEmpty) {
        final sorted = List<SeriesModel>.from(catalog)
          ..sort((a, b) => b.views.compareTo(a.views));
        trendingDramas.assignAll(sorted.take(10).toList());
      }
    } catch (e) {
      debugPrint('Error loading catalog for search: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onQueryChanged(String val) {
    searchQuery.value = val;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _executeSearch(val);
    });
  }

  void _executeSearch(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      searchResults.clear();
      return;
    }

    FirebaseAnalyticsService.to.logSearch(query.trim());

    final matches = allDramas.where((series) {
      final titleMatch = series.title.toLowerCase().contains(clean);
      final genreMatch = series.genres.any((g) => g.toLowerCase().contains(clean));
      final descMatch = series.description.toLowerCase().contains(clean);
      return titleMatch || genreMatch || descMatch;
    }).toList();

    // Sort exact or beginning title matches first
    matches.sort((a, b) {
      final aStarts = a.title.toLowerCase().startsWith(clean);
      final bStarts = b.title.toLowerCase().startsWith(clean);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return b.views.compareTo(a.views);
    });

    searchResults.assignAll(matches);
  }

  void selectTag(String tag) {
    textController.text = tag;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: tag.length),
    );
    onQueryChanged(tag);
  }

  void clearSearch() {
    textController.clear();
    searchQuery.value = '';
    searchResults.clear();
  }

  void openDrama(SeriesModel series) {
    Get.toNamed(Routes.DETAIL, arguments: series);
  }
}
