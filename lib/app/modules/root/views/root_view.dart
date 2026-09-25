import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/root_controller.dart';
import '../../home/views/home_view.dart';
import '../../feed/views/feed_view.dart';
import '../../watchlist/views/watchlist_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../theme/app_colors.dart';

class RootView extends GetView<RootController> {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeView(),
      const FeedView(),
      const WatchlistView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              activeIcon: Icon(Icons.home_filled, color: AppColors.primaryLight),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle_fill, color: AppColors.primaryLight),
              label: 'For You',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmarks_outlined),
              activeIcon: Icon(Icons.bookmarks_rounded, color: AppColors.primaryLight),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppColors.primaryLight),
              label: 'Profile',
            ),
          ],
        ),
      )),
    );
  }
}
