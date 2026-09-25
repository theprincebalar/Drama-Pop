import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/home_controller.dart';
import '../widgets/drama_card.dart';
import '../widgets/banner_slider.dart';
import 'view_all_view.dart';
import '../../../data/services/unlock_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'DramaPop',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Coins balance pill - tap opens Coin Store
          GestureDetector(
            onTap: () => Get.toNamed(Routes.COIN_STORE),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF261A38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
              ),
              child: Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${UnlockService.to.userCoins.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle, color: Color(0xFFFFB800), size: 13),
                ],
              )),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            tooltip: 'Search Dramas',
            onPressed: () => Get.toNamed(Routes.SEARCH),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => controller.fetchSeries(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: SpinKitFadingCircle(
                color: AppColors.primaryLight,
                size: 40.0,
              ),
            );
          }

          final allSeries = controller.seriesList;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Genre selection pills
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.genres.length,
                    itemBuilder: (context, index) {
                      final g = controller.genres[index];
                      return Obx(() {
                        final isSelected = controller.selectedGenre.value == g;
                        return GestureDetector(
                          onTap: () => controller.selectGenre(g),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryLight : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Hero Slider (Continuous Auto-scrolling every 3 seconds)
                BannerSlider(items: allSeries),

                const SizedBox(height: 20),

                // Genre Sections (Max 15 per genre + View All button)
                Obx(() {
                  if (controller.selectedGenre.value == 'All') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.homeSections.map((sec) {
                        final genre = sec['genre']!;
                        final dramas = controller.getTop15ForGenre(genre);
                        if (dramas.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              title: '${sec['icon']} ${sec['title']}',
                              subtitle: sec['subtitle']!,
                              onViewAll: () {
                                Get.to(() => ViewAllView(
                                  genreTitle: sec['title']!,
                                  dramas: controller.getDramasForGenre(genre),
                                ));
                              },
                            ),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: dramas.length,
                                itemBuilder: (context, index) {
                                  return DramaCard(series: dramas[index]);
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        );
                      }).toList(),
                    );
                  } else {
                    final sel = controller.selectedGenre.value;
                    final dramas = controller.getTop15ForGenre(sel);
                    final allInGenre = controller.getDramasForGenre(sel);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: '🎬 $sel Dramas',
                          subtitle: 'Top trending episodes in $sel',
                          onViewAll: () {
                            Get.to(() => ViewAllView(
                              genreTitle: '$sel Dramas',
                              dramas: allInGenre,
                            ));
                          },
                        ),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: dramas.length,
                            itemBuilder: (context, index) {
                              return DramaCard(series: dramas[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => ViewAllView(
                                genreTitle: '$sel Dramas',
                                dramas: allInGenre,
                              ));
                            },
                            icon: const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
                            label: Text('View All ${allInGenre.length} $sel Dramas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                }),

                const SizedBox(height: 30),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.accent,
                    size: 11,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
