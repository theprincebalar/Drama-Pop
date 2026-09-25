import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'firebase_analytics_service.dart';
import '../../widgets/in_app_review_dialog.dart';

class AppReviewService extends GetxService {
  static AppReviewService get to {
    if (!Get.isRegistered<AppReviewService>()) {
      Get.put<AppReviewService>(AppReviewService(), permanent: true);
    }
    return Get.find<AppReviewService>();
  }

  static const String _keyCompletedEpisodesCount = 'dramapop_completed_episodes_count_v1';
  static const String _keyLastPromptEpisodesCount = 'dramapop_last_prompt_episodes_count_v1';
  static const String _keyHasUserRated = 'dramapop_has_user_rated_v1';

  final InAppReview _inAppReview = InAppReview.instance;
  SharedPreferences? _prefs;

  // Configuration (Defaults, overridden live by Admin Panel API)
  final RxBool inAppReviewEnabled = true.obs;
  final RxInt reviewEpisodeInterval = 4.obs;
  final RxString iosAppStoreId = '6742517855'.obs;
  final RxString androidPackageName = 'com.dramapop.app.series.shorts.dramas'.obs;
  final RxBool isAndroidInReview = false.obs;
  final RxBool isIosInReview = false.obs;

  bool get isCurrentPlatformInReview {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) return isAndroidInReview.value;
    if (defaultTargetPlatform == TargetPlatform.iOS) return isIosInReview.value;
    if (Platform.isAndroid) return isAndroidInReview.value;
    if (Platform.isIOS) return isIosInReview.value;
    return false;
  }

  // Local State
  final RxInt completedEpisodesCount = 0.obs;
  final RxInt lastPromptEpisodesCount = 0.obs;
  final RxBool hasUserRated = false.obs;

  static Future<void> init() async {
    final service = AppReviewService();
    Get.put<AppReviewService>(service, permanent: true);
    await service._loadLocalState();
    // Fetch remote configuration from Admin Panel asynchronously
    service.fetchRemoteSettings();
  }

  Future<void> _loadLocalState() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      completedEpisodesCount.value = _prefs?.getInt(_keyCompletedEpisodesCount) ?? 0;
      lastPromptEpisodesCount.value = _prefs?.getInt(_keyLastPromptEpisodesCount) ?? 0;
      hasUserRated.value = _prefs?.getBool(_keyHasUserRated) ?? false;
      debugPrint('⭐ AppReviewService: Initialized with $completedEpisodesCount completed episodes (Last prompted at $lastPromptEpisodesCount, Rated: $hasUserRated)');
    } catch (e) {
      debugPrint('Error loading AppReviewService state: $e');
    }
  }

  Future<void> fetchRemoteSettings() async {
    try {
      final settings = await ApiService.getAppSettings();
      if (settings != null) {
        if (settings['inAppReviewEnabled'] != null) {
          inAppReviewEnabled.value = settings['inAppReviewEnabled'] == true;
        }
        if (settings['reviewEpisodeInterval'] != null) {
          final interval = (settings['reviewEpisodeInterval'] as num).toInt();
          if (interval > 0) reviewEpisodeInterval.value = interval;
        }
        if (settings['iosAppStoreId'] != null && settings['iosAppStoreId'].toString().isNotEmpty) {
          iosAppStoreId.value = settings['iosAppStoreId'].toString();
        }
        if (settings['androidPackageName'] != null && settings['androidPackageName'].toString().isNotEmpty) {
          androidPackageName.value = settings['androidPackageName'].toString();
        }
        if (settings['isAndroidInReview'] != null) {
          isAndroidInReview.value = settings['isAndroidInReview'] == true;
        }
        if (settings['isIosInReview'] != null) {
          isIosInReview.value = settings['isIosInReview'] == true;
        }
        debugPrint('⚙️ AppReviewService: Synced Admin Settings -> Enabled: ${inAppReviewEnabled.value}, Android In-Review: ${isAndroidInReview.value}, iOS In-Review: ${isIosInReview.value}');
      }
    } catch (e) {
      debugPrint('Note syncing remote app review settings: $e');
    }
  }

  /// Called whenever a user finishes watching an episode
  Future<void> recordEpisodeCompleted() async {
    completedEpisodesCount.value++;
    await _prefs?.setInt(_keyCompletedEpisodesCount, completedEpisodesCount.value);

    debugPrint('🎬 Episode completed! Total completed: ${completedEpisodesCount.value} (Next prompt after: ${lastPromptEpisodesCount.value + reviewEpisodeInterval.value})');

    // 1. Check if Review System is enabled in Admin Panel
    if (!inAppReviewEnabled.value) {
      debugPrint('⭐ AppReviewService: Review system is turned OFF in Admin Panel. Skipping prompt.');
      return;
    }

    // 2. Check if user has already permanently rated
    if (hasUserRated.value) {
      return;
    }

    // 3. Check if threshold reached (e.g. 4 episodes watched since last prompt)
    final diff = completedEpisodesCount.value - lastPromptEpisodesCount.value;
    if (diff >= reviewEpisodeInterval.value) {
      // Trigger prompt after a brief 800ms delay so video transition completes smoothly
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!hasUserRated.value && inAppReviewEnabled.value) {
          showReviewPrompt();
        }
      });
    }
  }

  /// Displays the interactive pre-prompt rating dialog
  void showReviewPrompt() {
    InAppReviewDialog.show();
  }

  /// Triggers the native Apple SKStoreReview or Google Play In-App Review dialog
  Future<void> triggerNativeReview() async {
    try {
      hasUserRated.value = true;
      lastPromptEpisodesCount.value = completedEpisodesCount.value;
      await _prefs?.setBool(_keyHasUserRated, true);
      await _prefs?.setInt(_keyLastPromptEpisodesCount, lastPromptEpisodesCount.value);

      // Track review attempt analytics
      FirebaseAnalyticsService.to.logEvent(
        name: 'app_review_triggered',
        parameters: {
          'platform': Platform.operatingSystem,
          'episodes_completed': completedEpisodesCount.value,
        },
      );

      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable && !kDebugMode) {
        debugPrint('⭐ AppReviewService: Invoking official native In-App Review sheet (Production Store Install)');
        await _inAppReview.requestReview();
      } else {
        debugPrint('⭐ AppReviewService: Invoking store listing (Debug mode / Store fallback)');
        await _inAppReview.openStoreListing(
          appStoreId: iosAppStoreId.value,
        );
      }
    } catch (e) {
      debugPrint('AppReviewService: Error launching store review: $e');
      try {
        await _inAppReview.openStoreListing(appStoreId: iosAppStoreId.value);
      } catch (_) {}
    }
  }

  /// Defers the review prompt when user chooses "Maybe Later"
  /// Automatically resets the interval so they are prompted again after 3-4 more episodes
  Future<void> postponeReview() async {
    lastPromptEpisodesCount.value = completedEpisodesCount.value;
    await _prefs?.setInt(_keyLastPromptEpisodesCount, lastPromptEpisodesCount.value);
    debugPrint('⭐ AppReviewService: Postponed. Next prompt will occur after watching ${reviewEpisodeInterval.value} more episodes (at ep #${lastPromptEpisodesCount.value + reviewEpisodeInterval.value})');
  }

  /// Reset review state (for testing or debugging)
  Future<void> resetReviewState() async {
    completedEpisodesCount.value = 0;
    lastPromptEpisodesCount.value = 0;
    hasUserRated.value = false;
    await _prefs?.remove(_keyCompletedEpisodesCount);
    await _prefs?.remove(_keyLastPromptEpisodesCount);
    await _prefs?.remove(_keyHasUserRated);
  }
}
