import '../modules/profile/views/saved_episodes_view.dart';
import '../modules/splash/views/splash_view.dart';
import 'package:get/get.dart';
import 'app_routes.dart';
import '../modules/root/views/root_view.dart';
import '../modules/root/controllers/root_controller.dart';
import '../modules/home/views/home_view.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/feed/views/feed_view.dart';
import '../modules/feed/controllers/feed_controller.dart';
import '../modules/watchlist/views/watchlist_view.dart';
import '../modules/watchlist/controllers/watchlist_controller.dart';
import '../modules/detail/views/detail_view.dart';
import '../modules/detail/controllers/detail_controller.dart';
import '../modules/search/views/search_view.dart';
import '../modules/search/controllers/search_controller.dart';
import '../modules/player/views/player_view.dart';
import '../modules/player/controllers/player_controller.dart';
import '../modules/paywall/views/subscription_view.dart';
import '../modules/paywall/views/coin_store_view.dart';

// ignore_for_file: constant_identifier_names
class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: Routes.ROOT,
      page: () => const RootView(),
      binding: BindingsBuilder(() {
        Get.put(RootController());
        Get.put(HomeController());
        Get.put(FeedController());
        Get.put(WatchlistController());
      }),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: Routes.FEED,
      page: () => const FeedView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<FeedController>(() => FeedController());
      }),
    ),
    GetPage(
      name: Routes.WATCHLIST,
      page: () => const WatchlistView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WatchlistController>(() => WatchlistController());
      }),
    ),
    GetPage(
      name: Routes.DETAIL,
      page: () => const DetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DetailController>(() => DetailController());
      }),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DramaSearchController>(() => DramaSearchController());
      }),
    ),
    GetPage(
      name: Routes.PLAYER,
      page: () => const PlayerView(),
      binding: BindingsBuilder(() {
        if (Get.isRegistered<PlayerController>()) {
          Get.delete<PlayerController>(force: true);
        }
        Get.put<PlayerController>(PlayerController());
      }),
    ),
    GetPage(
      name: Routes.SUBSCRIPTION,
      page: () => const SubscriptionView(),
    ),
    GetPage(
      name: Routes.COIN_STORE,
      page: () => const CoinStoreView(),
    ),
    GetPage(
      name: Routes.SAVED,
      page: () => const SavedEpisodesView(),
    ),
  ];
}
