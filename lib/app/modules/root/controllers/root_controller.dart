import 'package:get/get.dart';
import '../../feed/controllers/feed_controller.dart';

class RootController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (currentIndex.value == index && index == 1) {
      // User is already on For You page and clicked For You tab -> refresh/randomize feed
      if (Get.isRegistered<FeedController>()) {
        final feed = Get.find<FeedController>();
        feed.refreshFeed();
      }
      return;
    }

    currentIndex.value = index;
    if (Get.isRegistered<FeedController>()) {
      final feed = Get.find<FeedController>();
      if (index == 1) {
        feed.onFeedTabActive();
      } else {
        feed.isFeedActive = false;
        feed.pauseVideo();
      }
    }
  }
}