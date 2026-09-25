import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/user_library_service.dart';
import '../../../routes/app_routes.dart';
import '../../root/controllers/root_controller.dart';

class WatchlistController extends GetxController {
  UserLibraryService get library => UserLibraryService.to;

  List<SeriesModel> get watchlist => library.watchlist;

  void playSeries(SeriesModel series) {
    final reachedIdx = library.getReachedEpisodeIndex(series.id);
    Get.toNamed(Routes.PLAYER, arguments: {
      'series': series,
      'episodeIndex': reachedIdx,
    });
  }

  void openDetail(SeriesModel series) {
    Get.toNamed(Routes.DETAIL, arguments: series);
  }

  void removeSeries(SeriesModel series) {
    library.removeFromWatchlist(series.id);
  }

  void exploreDramas() {
    if (Get.isRegistered<RootController>()) {
      Get.find<RootController>().changePage(0);
    }
  }
}
