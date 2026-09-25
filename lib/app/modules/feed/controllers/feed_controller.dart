import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/series_model.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/meta_events_service.dart';
import '../../../data/services/firebase_analytics_service.dart';
import '../../../routes/app_routes.dart';
import '../../root/controllers/root_controller.dart';

class FeedController extends GetxController with WidgetsBindingObserver {
  final seriesList = <SeriesModel>[].obs;
  final currentSeriesIndex = 0.obs;
  final currentEpisodeIndex = 0.obs;
  final selectedQuality = '540p'.obs; // 540p Fast & Smooth stream for zero-lag mobile playback
  
  final PageController pageController = PageController();
  VideoPlayerController? videoPlayerController;
  VideoPlayerController? _pendingController;
  bool _isDisposed = false;

  final isVideoInitialized = false.obs;
  final isPlaying = true.obs;
  final isBuffering = false.obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  bool isFeedActive = false;
  final isDetailOpen = false.obs;
  bool isNavigatingToEpisode = false;
  int _initToken = 0;

  UserLibraryService get library => UserLibraryService.to;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    // Sync default quality from user preferences
    selectedQuality.value = library.defaultQuality.value;
    ever(library.defaultQuality, (String q) {
      if (selectedQuality.value != q) {
        setQuality(q, syncLibrary: false);
      }
    });

    // Check initial active tab state and bind reactively
    if (Get.isRegistered<RootController>()) {
      final root = Get.find<RootController>();
      isFeedActive = (root.currentIndex.value == 1);
      ever(root.currentIndex, (int idx) {
        if (idx == 1) {
          onFeedTabActive();
        } else {
          isFeedActive = false;
          pauseVideo();
        }
      });
    }

    loadFeed();
  }

  @override
  void onClose() {
    _isDisposed = true;
    _initToken++;
    WidgetsBinding.instance.removeObserver(this);

    final pending = _pendingController;
    _pendingController = null;
    if (pending != null) {
      try {
        pending.pause();
        pending.dispose();
      } catch (e) {
        debugPrint('Error disposing pending feed controller: $e');
      }
    }

    final active = videoPlayerController;
    videoPlayerController = null;
    if (active != null) {
      try {
        active.pause();
        active.dispose();
      } catch (e) {
        debugPrint('Error disposing active feed controller: $e');
      }
    }

    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pauseVideo();
    } else if (state == AppLifecycleState.resumed) {
      if (isFeedActive && !isDetailOpen.value) {
        resumeVideo();
      }
    }
  }

  bool _isFeedInvalid(int token) =>
      _isDisposed || isClosed || token != _initToken || !isFeedActive;

  Future<void> _disposeFeedController(VideoPlayerController? ctrl) async {
    if (ctrl == null) return;
    try {
      await ctrl.pause();
      await ctrl.dispose();
    } catch (e) {
      debugPrint('Error in _disposeFeedController: $e');
    }
  }

  void onFeedTabActive() {
    isFeedActive = true;
    isDetailOpen.value = false;
    if (seriesList.isNotEmpty) {
      if (videoPlayerController == null ||
          !videoPlayerController!.value.isInitialized ||
          hasError.value) {
        initializeVideoForCurrentSeries();
      } else if (!videoPlayerController!.value.isPlaying) {
        videoPlayerController!.play();
        isPlaying.value = true;
        WidgetsBinding.instance.scheduleFrame();
      }
    }
  }

  void pauseVideo() {
    _initToken++;
    final pending = _pendingController;
    _pendingController = null;
    if (pending != null) {
      try {
        pending.pause();
        pending.dispose();
      } catch (e) {
        debugPrint('Note disposing pending feed controller: $e');
      }
    }

    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _executePauseVideo());
    } else {
      _executePauseVideo();
    }
  }

  void _executePauseVideo() {
    isPlaying.value = false;
    final vpc = videoPlayerController;
    if (vpc != null) {
      try {
        if (vpc.value.isInitialized) {
          vpc.pause();
        }
      } catch (e) {
        debugPrint('Note while pausing video: $e');
      }
    }
  }

  void resumeVideo() {
    if (!isFeedActive || isDetailOpen.value) return;
    final vpc = videoPlayerController;
    if (vpc != null) {
      try {
        if (vpc.value.isInitialized && !vpc.value.isPlaying) {
          vpc.play();
          isPlaying.value = true;
          WidgetsBinding.instance.scheduleFrame();
        }
      } catch (e) {
        debugPrint('Note while resuming video: $e');
      }
    }
  }

  Future<void> openDetailScreen(SeriesModel series) async {
    isDetailOpen.value = true;
    pauseVideo();
    await Get.toNamed('/detail', arguments: series);
    isDetailOpen.value = false;
    if (isFeedActive && !isNavigatingToEpisode) {
      resumeVideo();
    }
  }

  // Always load a completely randomized feed from the entire 379-drama catalog
  Future<void> loadFeed() async {
    isLoading.value = true;
    final catalog = await ApiService.loadBundledCatalog();
    final randomized = List<SeriesModel>.from(catalog)..shuffle();
    seriesList.assignAll(randomized);
    currentSeriesIndex.value = 0;
    currentEpisodeIndex.value = 0;
    isLoading.value = false;
    
    final root = Get.isRegistered<RootController>() ? Get.find<RootController>() : null;
    final isTab1 = (root != null && root.currentIndex.value == 1);
    if (seriesList.isNotEmpty && (isFeedActive || isTab1)) {
      isFeedActive = true;
      initializeVideoForCurrentSeries();
    }
  }

  Future<void> refreshFeed() async {
    final catalog = await ApiService.loadBundledCatalog();
    final randomized = List<SeriesModel>.from(catalog)..shuffle();
    seriesList.assignAll(randomized);
    currentSeriesIndex.value = 0;
    currentEpisodeIndex.value = 0;
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    if (isFeedActive) {
      await initializeVideoForCurrentSeries();
    }
  }

  void shuffleFeed() {
    refreshFeed();
  }

  SeriesModel? get currentSeries {
    if (seriesList.isEmpty || currentSeriesIndex.value >= seriesList.length) return null;
    return seriesList[currentSeriesIndex.value];
  }

  EpisodeModel? get currentEpisode {
    final s = currentSeries;
    if (s == null) return null;
    final eps = s.effectiveEpisodes;
    if (eps.isEmpty) return null;
    if (currentEpisodeIndex.value >= eps.length) return eps.first;
    return eps[currentEpisodeIndex.value];
  }

  bool get isCurrentEpisodeSaved {
    final s = currentSeries;
    final ep = currentEpisode;
    if (s == null || ep == null) return false;
    return library.isEpisodeSaved(s.id, ep.episodeNumber);
  }

  void toggleSaveEpisode() {
    final s = currentSeries;
    final ep = currentEpisode;
    if (s == null || ep == null) return;
    library.toggleSaveEpisode(
      series: s,
      episodeNumber: ep.episodeNumber,
      episodeTitle: ep.title,
      duration: ep.duration,
    );
  }

  void shareDrama() {
    final s = currentSeries;
    final ep = currentEpisode;
    if (s == null) return;
    library.shareDrama(s, episodeNumber: ep?.episodeNumber);
  }

  void onPageChanged(int index) {
    if (index != currentSeriesIndex.value) {
      currentSeriesIndex.value = index;
      currentEpisodeIndex.value = 0;
      isFeedActive = true;
      initializeVideoForCurrentSeries();
    }
  }

  void setQuality(String quality, {bool syncLibrary = true}) {
    if (quality.toLowerCase() == '1080p') {
      final s = currentSeries;
      final ep = currentEpisode;
      final hasSub = UnlockService.to.hasUnlimitedAccess;
      final isCoinUnlocked = (s != null && ep != null)
          ? UnlockService.to.isEpisodeUnlocked(s.id, ep.episodeNumber)
          : false;

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
    final currentPos = videoPlayerController?.value.position ?? Duration.zero;
    if (isFeedActive) {
      initializeVideoForCurrentSeries(seekTo: currentPos);
    }
  }

  void selectEpisode(int episodeIdx) {
    currentEpisodeIndex.value = episodeIdx;
    isFeedActive = true;
    initializeVideoForCurrentSeries();
  }

  void seekTo(Duration pos) {
    videoPlayerController?.seekTo(pos);
  }

  Future<void> initializeVideoForCurrentSeries({Duration? seekTo}) async {
    final thisToken = ++_initToken;
    isFeedActive = true;
    isDetailOpen.value = false;

    if (_isDisposed || isClosed) {
      debugPrint('⏸️ Skipping video init: controller disposed');
      return;
    }

    isVideoInitialized.value = false;
    isBuffering.value = false;
    hasError.value = false;
    currentPosition.value = Duration.zero;
    totalDuration.value = Duration.zero;

    final oldActive = videoPlayerController;
    videoPlayerController = null;
    final oldPending = _pendingController;
    _pendingController = null;

    await _disposeFeedController(oldActive);
    await _disposeFeedController(oldPending);

    if (_isFeedInvalid(thisToken)) {
      debugPrint('⏭️ Discarding superseded video init ($thisToken != $_initToken)');
      return;
    }

    final s = currentSeries;
    final ep = currentEpisode;
    if (s == null || ep == null) return;

    // Record user progress
    library.recordWatchProgress(s.id, currentEpisodeIndex.value);

    var effectiveQuality = selectedQuality.value;
    if (effectiveQuality.toLowerCase() == '1080p') {
      final hasSub = UnlockService.to.hasUnlimitedAccess;
      final isCoinUnlocked = UnlockService.to.isEpisodeUnlocked(s.id, ep.episodeNumber);
      if (!hasSub && !isCoinUnlocked) {
        effectiveQuality = '720p';
      }
    }

    final streamUrl = ep.getStreamForQuality(effectiveQuality, defaultSeriesId: s.id);
    if (streamUrl.isEmpty) {
      hasError.value = true;
      return;
    }

    try {
      debugPrint('🎬 Initializing Mobile HLS Video: $streamUrl');
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      _pendingController = controller;

      controller.addListener(() {
        if (!_isFeedInvalid(thisToken) && videoPlayerController == controller) {
          isBuffering.value = controller.value.isBuffering;
          currentPosition.value = controller.value.position;
          totalDuration.value = controller.value.duration;
        }
      });

      await controller.initialize();
      if (_isFeedInvalid(thisToken)) {
        await _disposeFeedController(controller);
        if (_pendingController == controller) _pendingController = null;
        return;
      }

      videoPlayerController = controller;
      if (_pendingController == controller) _pendingController = null;

      controller.setLooping(true);
      if (seekTo != null && seekTo > Duration.zero) {
        await controller.seekTo(seekTo);
      }
      if (_isFeedInvalid(thisToken)) {
        await _disposeFeedController(controller);
        return;
      }

      // Mount Texture widget in Flutter tree FIRST so it is ready to receive frames
      isVideoInitialized.value = true;
      isPlaying.value = true;

      await Future.delayed(const Duration(milliseconds: 100));
      if (_isFeedInvalid(thisToken)) {
        await _disposeFeedController(controller);
        return;
      }

      // Start playback so frames flow to the mounted texture simultaneously with audio
      await controller.play();
      if (_isFeedInvalid(thisToken)) {
        await _disposeFeedController(controller);
        return;
      }
      WidgetsBinding.instance.scheduleFrame();

      // Track ViewContent in Meta Ad Network
      MetaEventsService.to.logViewDrama(
        dramaId: s.id,
        dramaTitle: s.title,
        episodeNumber: ep.episodeNumber,
      );

      // Track ViewItem in Google Analytics
      FirebaseAnalyticsService.to.logViewDrama(
        dramaId: s.id,
        dramaTitle: s.title,
        episodeNumber: ep.episodeNumber,
      );
    } catch (e) {
      debugPrint('Video Player stream error ($streamUrl): $e, trying 540p/720p fallback');
      if (_pendingController != null) {
        await _disposeFeedController(_pendingController);
        _pendingController = null;
      }
      if (_isFeedInvalid(thisToken)) return;

      try {
        final fallbackUrl = 'https://dirjqbe1kaah2.cloudfront.net/${s.id}/${ep.episodeNumber}/videon540x960.m3u8';
        final fallbackController = VideoPlayerController.networkUrl(
          Uri.parse(fallbackUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
        _pendingController = fallbackController;

        fallbackController.addListener(() {
          if (!_isFeedInvalid(thisToken) && videoPlayerController == fallbackController) {
            isBuffering.value = fallbackController.value.isBuffering;
            currentPosition.value = fallbackController.value.position;
            totalDuration.value = fallbackController.value.duration;
          }
        });
        await fallbackController.initialize();
        if (_isFeedInvalid(thisToken)) {
          await _disposeFeedController(fallbackController);
          if (_pendingController == fallbackController) _pendingController = null;
          return;
        }

        videoPlayerController = fallbackController;
        if (_pendingController == fallbackController) _pendingController = null;

        fallbackController.setLooping(true);

        isVideoInitialized.value = true;
        isPlaying.value = true;
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isFeedInvalid(thisToken)) {
          await _disposeFeedController(fallbackController);
          return;
        }

        await fallbackController.play();
        if (_isFeedInvalid(thisToken)) {
          await _disposeFeedController(fallbackController);
          return;
        }
        WidgetsBinding.instance.scheduleFrame();
      } catch (fallbackErr) {
        debugPrint('Fallback stream failed: $fallbackErr');
        if (_pendingController != null) {
          await _disposeFeedController(_pendingController);
          _pendingController = null;
        }
        if (!_isFeedInvalid(thisToken)) {
          isVideoInitialized.value = false;
          hasError.value = true;
        }
      }
    }
  }

  void togglePlayPause() {
    isFeedActive = true;
    isDetailOpen.value = false;
    if (videoPlayerController == null || !videoPlayerController!.value.isInitialized || hasError.value) {
      hasError.value = false;
      initializeVideoForCurrentSeries();
      return;
    }
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
      isPlaying.value = false;
    } else {
      videoPlayerController!.play();
      isPlaying.value = true;
    }
  }
}
