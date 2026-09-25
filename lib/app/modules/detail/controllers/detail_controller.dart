import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/user_library_service.dart';
import '../../feed/controllers/feed_controller.dart';

class DetailController extends GetxController {
  late Rx<SeriesModel> series;
  final selectedQuality = '1080p'.obs;

  UserLibraryService get library => UserLibraryService.to;

  bool get isInWatchlist => library.isSeriesInWatchlist(series.value.id);

  int get reachedEpisodeIndex => library.getReachedEpisodeIndex(series.value.id);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SeriesModel) {
      series = args.obs;
    } else {
      series = SeriesModel(
        id: '1',
        title: 'Drama Detail',
        description: '',
        coverUrl: '',
        genres: [],
        episodesCount: 10,
      ).obs;
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Guarantee video in feed is paused immediately upon entering detail/episode screen
    if (Get.isRegistered<FeedController>()) {
      final feed = Get.find<FeedController>();
      feed.isDetailOpen.value = true;
      feed.pauseVideo();
    }
  }

  @override
  void onClose() {
    if (Get.isRegistered<FeedController>()) {
      final feed = Get.find<FeedController>();
      feed.isDetailOpen.value = false;
      if (feed.isFeedActive && !feed.isNavigatingToEpisode) {
        feed.resumeVideo();
      }
    }
    super.onClose();
  }

  void toggleWatchlist() {
    library.toggleWatchlist(series.value);
  }

  void shareDrama() {
    library.shareDrama(series.value);
  }
}
