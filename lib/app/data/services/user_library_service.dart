import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/series_model.dart';
import '../../theme/app_colors.dart';
import 'meta_events_service.dart';
import 'firebase_analytics_service.dart';

class SavedEpisodeItem {
  final String seriesId;
  final String seriesTitle;
  final String coverUrl;
  final int episodeNumber;
  final String episodeTitle;
  final String duration;
  final List<String> genres;
  final DateTime savedAt;

  SavedEpisodeItem({
    required this.seriesId,
    required this.seriesTitle,
    required this.coverUrl,
    required this.episodeNumber,
    required this.episodeTitle,
    this.duration = '1:30',
    this.genres = const [],
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  String get key => '${seriesId}_$episodeNumber';

  factory SavedEpisodeItem.fromJson(Map<String, dynamic> json) {
    return SavedEpisodeItem(
      seriesId: json['seriesId']?.toString() ?? '',
      seriesTitle: json['seriesTitle'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      episodeNumber: json['episodeNumber'] is int
          ? json['episodeNumber']
          : (int.tryParse(json['episodeNumber']?.toString() ?? '1') ?? 1),
      episodeTitle: json['episodeTitle'] ?? 'Episode 1',
      duration: json['duration'] ?? '1:30',
      genres: json['genres'] is List
          ? (json['genres'] as List).map((e) => e.toString()).toList()
          : [],
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seriesId': seriesId,
      'seriesTitle': seriesTitle,
      'coverUrl': coverUrl,
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
      'duration': duration,
      'genres': genres,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}

class UserLibraryService extends GetxService {
  static UserLibraryService get to {
    if (!Get.isRegistered<UserLibraryService>()) {
      Get.put<UserLibraryService>(UserLibraryService(), permanent: true);
    }
    return Get.find<UserLibraryService>();
  }

  static const String _keySavedEpisodes = 'dramapop_saved_episodes_v1';
  static const String _keyWatchlist = 'dramapop_watchlist_v1';
  static const String _keyProgress = 'dramapop_watch_progress_v1';
  static const String _keyDefaultQuality = 'dramapop_default_quality_v1';

  final RxList<SavedEpisodeItem> savedEpisodes = <SavedEpisodeItem>[].obs;
  final RxList<SeriesModel> watchlist = <SeriesModel>[].obs;
  final RxMap<String, int> seriesProgress = <String, int>{}.obs;
  final RxString defaultQuality = '720p'.obs;

  SharedPreferences? _prefs;

  static Future<void> init() async {
    final service = UserLibraryService();
    Get.put<UserLibraryService>(service, permanent: true);
    await service._loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 1. Load Saved Episodes
      final savedStr = _prefs?.getString(_keySavedEpisodes);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List list = jsonDecode(savedStr);
        final items = list
            .map((e) => SavedEpisodeItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        savedEpisodes.assignAll(items);
      }

      // 2. Load Watchlist
      final watchlistStr = _prefs?.getString(_keyWatchlist);
      if (watchlistStr != null && watchlistStr.isNotEmpty) {
        final List list = jsonDecode(watchlistStr);
        final items = list
            .map((e) => SeriesModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        watchlist.assignAll(items);
      }

      // 3. Load Watch Progress
      final progressStr = _prefs?.getString(_keyProgress);
      if (progressStr != null && progressStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(progressStr);
        final parsed = map.map((k, v) =>
            MapEntry(k, v is int ? v : (int.tryParse(v.toString()) ?? 0)));
        seriesProgress.assignAll(parsed);
      }

      // 4. Load Default Quality
      final q = _prefs?.getString(_keyDefaultQuality);
      if (q != null && q.isNotEmpty) {
        defaultQuality.value = q;
      }
    } catch (e) {
      debugPrint('UserLibraryService: Error loading saved state: $e');
    }
  }

  Future<void> _saveSavedEpisodesToDisk() async {
    try {
      final jsonList = savedEpisodes.map((e) => e.toJson()).toList();
      await _prefs?.setString(_keySavedEpisodes, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('UserLibraryService: Error saving episodes to disk: $e');
    }
  }

  Future<void> _saveWatchlistToDisk() async {
    try {
      final jsonList = watchlist.map((e) => e.toJson()).toList();
      await _prefs?.setString(_keyWatchlist, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('UserLibraryService: Error saving watchlist to disk: $e');
    }
  }

  Future<void> _saveProgressToDisk() async {
    try {
      await _prefs?.setString(_keyProgress, jsonEncode(seriesProgress));
    } catch (e) {
      debugPrint('UserLibraryService: Error saving progress to disk: $e');
    }
  }

  void setDefaultQuality(String q) {
    defaultQuality.value = q.toLowerCase();
    _prefs?.setString(_keyDefaultQuality, defaultQuality.value);
  }

  // ==================== SAVED EPISODES ====================

  bool isEpisodeSaved(String seriesId, int episodeNumber) {
    return savedEpisodes
        .any((e) => e.seriesId == seriesId && e.episodeNumber == episodeNumber);
  }

  void toggleSaveEpisode({
    required SeriesModel series,
    required int episodeNumber,
    String? episodeTitle,
    String? duration,
    bool showToast = true,
  }) {
    final existingIndex = savedEpisodes.indexWhere(
      (e) => e.seriesId == series.id && e.episodeNumber == episodeNumber,
    );

    if (existingIndex >= 0) {
      savedEpisodes.removeAt(existingIndex);
      _saveSavedEpisodesToDisk();
      if (showToast) {
        Get.snackbar(
          'Removed from Saved',
          'Episode $episodeNumber removed from your saved list.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: Colors.white70,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } else {
      final item = SavedEpisodeItem(
        seriesId: series.id,
        seriesTitle: series.title,
        coverUrl: series.coverUrl,
        episodeNumber: episodeNumber,
        episodeTitle: episodeTitle ?? 'Episode $episodeNumber',
        duration: duration ?? '1:30',
        genres: series.genres,
      );
      savedEpisodes.insert(0, item);
      _saveSavedEpisodesToDisk();
      if (showToast) {
        Get.snackbar(
          'Episode Saved',
          'Episode $episodeNumber saved to your profile!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accent,
          icon: const Icon(Icons.bookmark_added_rounded, color: AppColors.accent),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    }
  }

  void removeSavedEpisode(String seriesId, int episodeNumber) {
    savedEpisodes.removeWhere(
        (e) => e.seriesId == seriesId && e.episodeNumber == episodeNumber);
    _saveSavedEpisodesToDisk();
  }

  // ==================== WATCHLIST (SERIES) ====================

  bool isSeriesInWatchlist(String seriesId) {
    return watchlist.any((s) => s.id == seriesId);
  }

  void toggleWatchlist(SeriesModel series, {bool showToast = true}) {
    final idx = watchlist.indexWhere((s) => s.id == series.id);
    if (idx >= 0) {
      watchlist.removeAt(idx);
      _saveWatchlistToDisk();
      if (showToast) {
        Get.snackbar(
          'Removed from Watchlist',
          '${series.title} has been removed from your watchlist.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: Colors.white70,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } else {
      watchlist.insert(0, series);
      _saveWatchlistToDisk();
      MetaEventsService.to.logAddToWatchlist(
        dramaId: series.id,
        dramaTitle: series.title,
      );
      FirebaseAnalyticsService.to.logAddToWatchlist(
        dramaId: series.id,
        dramaTitle: series.title,
      );
      if (showToast) {
        Get.snackbar(
          'Added to Watchlist',
          '${series.title} added to your Watchlist tab.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accent,
          icon: const Icon(Icons.bookmark_added_rounded, color: AppColors.accent),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    }
  }

  void removeFromWatchlist(String seriesId) {
    watchlist.removeWhere((s) => s.id == seriesId);
    _saveWatchlistToDisk();
  }

  // ==================== WATCH PROGRESS ====================

  void recordWatchProgress(String seriesId, int episodeIndex) {
    if (seriesId.isEmpty || episodeIndex < 0) return;
    if (seriesProgress[seriesId] == episodeIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (seriesProgress[seriesId] != episodeIndex) {
        seriesProgress[seriesId] = episodeIndex;
        _saveProgressToDisk();
      }
    });
  }

  int getReachedEpisodeIndex(String seriesId) {
    return seriesProgress[seriesId] ?? 0;
  }

  int getReachedEpisodeNumber(String seriesId) {
    return getReachedEpisodeIndex(seriesId) + 1;
  }

  // ==================== SOCIAL SHARING ====================

  Future<void> shareDrama(SeriesModel series, {int? episodeNumber}) async {
    final epText = (episodeNumber != null && episodeNumber > 0)
        ? ' (Episode $episodeNumber)'
        : '';
    final isIOS = Platform.isIOS;
    final appLink = isIOS
        ? 'https://apps.apple.com/app/id6742517855'
        : 'https://play.google.com/store/apps/details?id=com.dramapop.app.series.shorts.dramas';

    final shareText =
        'Hey! Watch "${series.title}"$epText on DramaPop!\n\n'
        'Download the DramaPop app to stream thousands of viral short dramas and exclusive episodes:\n'
        '$appLink';

    try {
      FirebaseAnalyticsService.to.logShare(
        dramaId: series.id,
        dramaTitle: series.title,
      );
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Watch ${series.title} on DramaPop!',
          title: 'Share ${series.title}',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing drama with SharePlus: $e');
      await Clipboard.setData(ClipboardData(text: shareText));
      Get.snackbar(
        'App Link Copied',
        'DramaPop app link copied to clipboard! Share it with your friends.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accent,
        icon: const Icon(Icons.copy_rounded, color: AppColors.accent),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> shareApp() async {
    final isIOS = Platform.isIOS;
    final appLink = isIOS
        ? 'https://apps.apple.com/app/id6742517855'
        : 'https://play.google.com/store/apps/details?id=com.dramapop.app.series.shorts.dramas';

    final shareText =
        'Watch binge-worthy trending short dramas and mini-series in full HD on DramaPop!\n\n'
        'Download DramaPop now:\n'
        '$appLink';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Download DramaPop App',
          title: 'Share DramaPop',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing app with SharePlus: $e');
      await Clipboard.setData(ClipboardData(text: shareText));
      Get.snackbar(
        'App Link Copied',
        'DramaPop download link copied to clipboard!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accent,
        icon: const Icon(Icons.copy_rounded, color: AppColors.accent),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Clears all local user data and resets preferences (GDPR/CCPA compliance)
  Future<void> clearAllUserData() async {
    savedEpisodes.clear();
    watchlist.clear();
    seriesProgress.clear();
    await _prefs?.remove(_keySavedEpisodes);
    await _prefs?.remove(_keyWatchlist);
    await _prefs?.remove(_keyProgress);
  }
}
