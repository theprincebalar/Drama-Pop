import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/series_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../../data/services/app_review_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../feed/controllers/feed_controller.dart';

class PlayerController extends GetxController with WidgetsBindingObserver {
  late Rx<SeriesModel> series;
  final currentEpisodeIndex = 0.obs;
  final selectedQuality = '720p'.obs;
  final playbackSpeed = 1.0.obs;
  final isCurrentEpisodeLocked = false.obs;

  VideoPlayerController? videoPlayerController;
  VideoPlayerController? _pendingController;
  bool _isDisposed = false;

  final isVideoInitialized = false.obs;
  final isPlaying = true.obs;
  final isBuffering = false.obs;
  final hasError = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final areControlsVisible = true.obs;

  // Double tap animation triggers
  final showForward10Overlay = false.obs;
  final showBackward10Overlay = false.obs;

  Timer? _controlsTimer;
  int _initToken = 0;
  bool _hasAutoAdvanced = false;

  UserLibraryService get library => UserLibraryService.to;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    final rawArgs = Get.arguments;
    if (rawArgs is Map) {
      final s = rawArgs['series'];
      if (s is SeriesModel) {
        series = s.obs;
      } else {
        series = SeriesModel(
          id: '1',
          title: 'Drama',
          description: '',
          coverUrl: '',
          genres: [],
          episodesCount: 10,
        ).obs;
      }
      currentEpisodeIndex.value = (rawArgs['episodeIndex'] as int? ?? 0);
    } else if (rawArgs is SeriesModel) {
      series = rawArgs.obs;
      currentEpisodeIndex.value = 0;
    } else {
      series = SeriesModel(
        id: '1',
        title: 'Drama',
        description: '',
        coverUrl: '',
        genres: [],
        episodesCount: 10,
      ).obs;
    }

    _startControlsTimer();

    // Sync default quality preference from user library
    selectedQuality.value = library.defaultQuality.value;
    ever(library.defaultQuality, (String q) {
      if (selectedQuality.value != q) {
        setQuality(q, syncLibrary: false);
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (_isDisposed || isClosed) return;
    // Pause FeedController video if running so there is no audio overlap
    if (Get.isRegistered<FeedController>()) {
      final feed = Get.find<FeedController>();
      feed.pauseVideo();
    }
    playEpisode(currentEpisodeIndex.value);
  }

  @override
  void onClose() {
    _isDisposed = true;
    _initToken++;
    _controlsTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Immediately stop and dispose any pending controller being initialized
    final pending = _pendingController;
    _pendingController = null;
    if (pending != null) {
      try {
        pending.pause();
        pending.dispose();
      } catch (e) {
        debugPrint('Error disposing pending player controller: $e');
      }
    }

    // Immediately stop and dispose the active controller
    final active = videoPlayerController;
    videoPlayerController = null;
    if (active != null) {
      try {
        active.pause();
        active.dispose();
      } catch (e) {
        debugPrint('Error disposing active player controller: $e');
      }
    }

    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pauseVideo();
    }
  }

  bool _isInvalid(int token) => _isDisposed || isClosed || token != _initToken;

  Future<void> _disposeController(VideoPlayerController? ctrl) async {
    if (ctrl == null) return;
    try {
      await ctrl.pause();
      await ctrl.dispose();
    } catch (e) {
      debugPrint('Error in _disposeController: $e');
    }
  }

  List<EpisodeModel> get episodes => series.value.effectiveEpisodes;

  EpisodeModel? get currentEpisode {
    if (episodes.isEmpty) return null;
    if (currentEpisodeIndex.value >= episodes.length) return episodes.first;
    return episodes[currentEpisodeIndex.value];
  }

  bool get isCurrentEpisodeSaved {
    final epNum = currentEpisodeIndex.value + 1;
    return library.isEpisodeSaved(series.value.id, epNum);
  }

  void toggleSaveCurrentEpisode() {
    final epNum = currentEpisodeIndex.value + 1;
    final ep = currentEpisode;
    library.toggleSaveEpisode(
      series: series.value,
      episodeNumber: epNum,
      episodeTitle: ep?.title ?? 'Episode $epNum',
      duration: ep?.duration ?? '1:30',
    );
  }

  void shareDrama() {
    final epNum = currentEpisodeIndex.value + 1;
    library.shareDrama(series.value, episodeNumber: epNum);
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (isPlaying.value) {
        areControlsVisible.value = false;
      }
    });
  }

  void toggleControlsVisibility() {
    areControlsVisible.value = !areControlsVisible.value;
    if (areControlsVisible.value) {
      _startControlsTimer();
    }
  }

  void userInteracted() {
    areControlsVisible.value = true;
    _startControlsTimer();
  }

  void playEpisode(int index) {
    if (index < 0 || index >= episodes.length) return;

    currentEpisodeIndex.value = index;
    // Record user progress
    library.recordWatchProgress(series.value.id, index);

    final ep = episodes[index];
    final isUnlocked = UnlockService.to.isEpisodeUnlocked(series.value.id, ep.episodeNumber);

    if (ep.isLocked && !isUnlocked) {
      isCurrentEpisodeLocked.value = true;
      pauseVideo();
      return;
    }

    isCurrentEpisodeLocked.value = false;
    _hasAutoAdvanced = false;
    _initVideoForCurrentEpisode();
  }

  void unlockAndPlayCurrentEpisode() {
    final ep = currentEpisode;
    if (ep == null) return;
    final unlocked = UnlockService.to.unlockEpisodeWithCoins(series.value.id, ep.episodeNumber, coinPrice: ep.coinPrice);
    if (unlocked) {
      isCurrentEpisodeLocked.value = false;
      Get.snackbar(
        'Episode Unlocked',
        'Episode ${ep.episodeNumber} unlocked with ${ep.coinPrice} coins.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.surface,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      _hasAutoAdvanced = false;
      _initVideoForCurrentEpisode();
    } else {
      Get.toNamed(Routes.COIN_STORE);
    }
  }

  void openSubscriptionPaywall() {
    Get.toNamed(Routes.SUBSCRIPTION);
  }

  void playNextEpisode() {
    if (currentEpisodeIndex.value + 1 < episodes.length) {
      playEpisode(currentEpisodeIndex.value + 1);
    } else {
      AppReviewService.to.recordEpisodeCompleted();
      Get.snackbar(
        'Series Completed',
        'You have reached the final episode of ${series.value.title}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card,
        colorText: AppColors.textPrimary,
      );
    }
  }

  void playPreviousEpisode() {
    if (currentEpisodeIndex.value > 0) {
      playEpisode(currentEpisodeIndex.value - 1);
    }
  }

  Future<void> _initVideoForCurrentEpisode({Duration? seekTo}) async {
    final thisToken = ++_initToken;
    isVideoInitialized.value = false;
    isBuffering.value = false;
    hasError.value = false;
    currentPosition.value = Duration.zero;
    totalDuration.value = Duration.zero;

    final oldActive = videoPlayerController;
    videoPlayerController = null;
    final oldPending = _pendingController;
    _pendingController = null;

    await _disposeController(oldActive);
    await _disposeController(oldPending);

    if (_isInvalid(thisToken)) return;

    final ep = currentEpisode;
    if (ep == null) return;

    var effectiveQuality = selectedQuality.value;
    if (effectiveQuality.toLowerCase() == '1080p') {
      final hasSub = UnlockService.to.hasUnlimitedAccess;
      final isCoinUnlocked = UnlockService.to.isEpisodeUnlocked(series.value.id, ep.episodeNumber);
      if (!hasSub && !isCoinUnlocked) {
        effectiveQuality = '720p';
      }
    }

    final streamUrl = ep.getStreamForQuality(effectiveQuality, defaultSeriesId: series.value.id);
    if (streamUrl.isEmpty) {
      hasError.value = true;
      return;
    }

    try {
      debugPrint('🎬 Dedicated Player: Loading stream $streamUrl');
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      _pendingController = controller;

      controller.addListener(() {
        if (!_isInvalid(thisToken) && videoPlayerController == controller && controller.value.isInitialized) {
          isBuffering.value = controller.value.isBuffering;
          currentPosition.value = controller.value.position;
          totalDuration.value = controller.value.duration;

          // Auto-advance detection: when episode reaches end (< 600ms remaining and duration > 5s)
          if (!_hasAutoAdvanced &&
              controller.value.duration > const Duration(seconds: 5) &&
              controller.value.position >= controller.value.duration - const Duration(milliseconds: 600)) {
            _hasAutoAdvanced = true;
            AppReviewService.to.recordEpisodeCompleted();
            playNextEpisode();
          }
        }
      });

      await controller.initialize();
      if (_isInvalid(thisToken)) {
        await _disposeController(controller);
        if (_pendingController == controller) _pendingController = null;
        return;
      }

      videoPlayerController = controller;
      if (_pendingController == controller) _pendingController = null;

      if (seekTo != null && seekTo > Duration.zero) {
        await controller.seekTo(seekTo);
      }
      if (_isInvalid(thisToken)) {
        await _disposeController(controller);
        return;
      }

      // Apply current playback speed
      await controller.setPlaybackSpeed(playbackSpeed.value);
      if (_isInvalid(thisToken)) {
        await _disposeController(controller);
        return;
      }

      isVideoInitialized.value = true;
      isPlaying.value = true;
      await controller.play();
      if (_isInvalid(thisToken)) {
        await _disposeController(controller);
        return;
      }
      _startControlsTimer();
    } catch (e) {
      debugPrint('Dedicated player error loading $streamUrl: $e');
      if (_pendingController != null) {
        await _disposeController(_pendingController);
        _pendingController = null;
      }
      if (!_isInvalid(thisToken)) {
        _tryFallbackStream(ep, thisToken);
      }
    }
  }

  Future<void> _tryFallbackStream(EpisodeModel ep, int token) async {
    if (_isInvalid(token)) return;
    try {
      final fallbackUrl = 'https://dirjqbe1kaah2.cloudfront.net/${series.value.id}/${ep.episodeNumber}/videon540x960.m3u8';
      final fallbackController = VideoPlayerController.networkUrl(
        Uri.parse(fallbackUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      _pendingController = fallbackController;

      fallbackController.addListener(() {
        if (!_isInvalid(token) && videoPlayerController == fallbackController && fallbackController.value.isInitialized) {
          isBuffering.value = fallbackController.value.isBuffering;
          currentPosition.value = fallbackController.value.position;
          totalDuration.value = fallbackController.value.duration;
        }
      });

      await fallbackController.initialize();
      if (_isInvalid(token)) {
        await _disposeController(fallbackController);
        if (_pendingController == fallbackController) _pendingController = null;
        return;
      }

      videoPlayerController = fallbackController;
      if (_pendingController == fallbackController) _pendingController = null;

      await fallbackController.setPlaybackSpeed(playbackSpeed.value);
      if (_isInvalid(token)) {
        await _disposeController(fallbackController);
        return;
      }

      isVideoInitialized.value = true;
      isPlaying.value = true;
      await fallbackController.play();
      if (_isInvalid(token)) {
        await _disposeController(fallbackController);
        return;
      }
      _startControlsTimer();
    } catch (fallbackErr) {
      debugPrint('Fallback stream also failed: $fallbackErr');
      if (_pendingController != null) {
        await _disposeController(_pendingController);
        _pendingController = null;
      }
      if (!_isInvalid(token)) {
        isVideoInitialized.value = false;
        hasError.value = true;
      }
    }
  }

  void togglePlayPause() {
    userInteracted();
    final vpc = videoPlayerController;
    if (vpc == null || !vpc.value.isInitialized) return;
    try {
      if (vpc.value.isPlaying) {
        vpc.pause();
        isPlaying.value = false;
      } else {
        vpc.play();
        isPlaying.value = true;
        _startControlsTimer();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  void pauseVideo() {
    isPlaying.value = false;
    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      try {
        vpc.pause();
      } catch (e) {
        debugPrint('Error pausing player: $e');
      }
    }
  }

  void resumeVideo() {
    isPlaying.value = true;
    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      try {
        vpc.play();
      } catch (e) {
        debugPrint('Error resuming player: $e');
      }
    }
  }

  void seekTo(Duration pos) {
    userInteracted();
    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      vpc.seekTo(pos);
    }
  }

  void skipForward10() {
    userInteracted();
    showForward10Overlay.value = true;
    Timer(const Duration(milliseconds: 600), () => showForward10Overlay.value = false);

    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      final newPos = currentPosition.value + const Duration(seconds: 10);
      if (newPos < totalDuration.value) {
        vpc.seekTo(newPos);
      }
    }
  }

  void skipBackward10() {
    userInteracted();
    showBackward10Overlay.value = true;
    Timer(const Duration(milliseconds: 600), () => showBackward10Overlay.value = false);

    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      final newPos = currentPosition.value - const Duration(seconds: 10);
      vpc.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
    }
  }

  void setQuality(String quality, {bool syncLibrary = true}) {
    if (quality.toLowerCase() == '1080p') {
      final epNum = currentEpisodeIndex.value + 1;
      final hasSub = UnlockService.to.hasUnlimitedAccess;
      final isCoinUnlocked = UnlockService.to.isEpisodeUnlocked(series.value.id, epNum);
      if (!hasSub && !isCoinUnlocked) {
        Get.snackbar(
          '👑 VIP 1080P Ultra HD',
          '1080P streaming is exclusive to VIP Pass members or coin-unlocked episodes. Upgrade to unlock 1080P!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF261338),
          colorText: const Color(0xFFFFB800),
          icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        Get.toNamed(Routes.SUBSCRIPTION);
        return;
      }
    }

    if (selectedQuality.value == quality) return;
    selectedQuality.value = quality;
    if (syncLibrary) {
      library.setDefaultQuality(quality);
    }
    final currentPos = (videoPlayerController != null && videoPlayerController!.value.isInitialized)
        ? videoPlayerController!.value.position
        : Duration.zero;
    _initVideoForCurrentEpisode(seekTo: currentPos);
  }

  void setSpeed(double speed) {
    playbackSpeed.value = speed;
    final vpc = videoPlayerController;
    if (vpc != null && vpc.value.isInitialized) {
      vpc.setPlaybackSpeed(speed);
    }
  }
}
