import '../../player/controllers/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/detail_controller.dart';
import '../../../data/models/episode_model.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../../widgets/quality_selector_modal.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/report_modal.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  void _playEpisode(int episodeIndex) {
    if (Get.isRegistered<PlayerController>()) {
      Get.delete<PlayerController>(force: true);
    }
    Get.toNamed(Routes.PLAYER, arguments: {
      'series': controller.series.value,
      'episodeIndex': episodeIndex,
    });
  }

  void _showUnlockSheet(BuildContext context, EpisodeModel ep, int index) {
    final s = controller.series.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock Episode ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use ${ep.coinPrice} coins to unlock this episode or choose an unlimited subscription.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Live Coin Balance Indicator
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF261A38),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Balance: ${UnlockService.to.userCoins.value} Coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 20),

              // 1. Unlock with Coins CTA
              ElevatedButton(
                onPressed: () {
                  final unlocked = UnlockService.to.unlockEpisodeWithCoins(s.id, ep.episodeNumber, coinPrice: ep.coinPrice);
                  if (unlocked) {
                    Navigator.pop(ctx);
                    Get.snackbar(
                      'Episode Unlocked',
                      'Episode ${ep.episodeNumber} unlocked with ${ep.coinPrice} coins.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.card,
                      colorText: AppColors.primaryLight,
                      duration: const Duration(seconds: 2),
                    );
                    _playEpisode(index);
                  } else {
                    Navigator.pop(ctx);
                    Get.toNamed(Routes.COIN_STORE);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Unlock for ${ep.coinPrice} Coins',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Unlimited Subscription CTA
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Get.toNamed(Routes.SUBSCRIPTION);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: AppColors.primaryLight, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Get Unlimited Subscription',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.series.value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible Poster Header
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: s.coverUrl,
                    memCacheWidth: 720,
                    httpHeaders: const {
                      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                    },
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.card,
                      child: const Center(
                        child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 36),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.network(
                      'https://dramapop-admin.genxappstudio.cloud/covers/${s.id}.webp?v=2',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2D1B4E), Color(0xFF161026)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.movie_creation_outlined, color: AppColors.primaryLight, size: 48),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  s.title,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  // Bottom title inside header
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Quality Pill (Clickable to select streaming quality)
                            Obx(() {
                              final q = UserLibraryService.to.defaultQuality.value.toUpperCase();
                              return GestureDetector(
                                onTap: () => QualitySelectorModal.show(
                                  context,
                                  currentQuality: UserLibraryService.to.defaultQuality.value,
                                  onQualitySelected: (newQ) => UserLibraryService.to.setDefaultQuality(newQ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hd_outlined, color: Colors.white, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$q HD',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.genres.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.outlined_flag_rounded, color: Colors.white),
                tooltip: 'Report Drama',
                onPressed: () => ReportModal.show(context, series: s),
              ),
              // Watchlist Bookmark Button
              Obx(() {
                final inWatchlist = UserLibraryService.to.isSeriesInWatchlist(s.id);
                return IconButton(
                  icon: Icon(
                    inWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: inWatchlist ? AppColors.accent : Colors.white,
                  ),
                  tooltip: inWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                  onPressed: controller.toggleWatchlist,
                );
              }),
              // Share Button
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share Drama',
                onPressed: controller.shareDrama,
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Dynamic "Watch Episode X" / "Continue Episode X" Button
                  Obx(() {
                    final reachedIdx = UserLibraryService.to.getReachedEpisodeIndex(s.id);
                    final epNum = reachedIdx + 1;
                    final buttonText = reachedIdx > 0 ? 'Continue Episode $epNum' : 'Watch Episode 1';
                    final buttonIcon = reachedIdx > 0 ? Icons.play_circle_fill_rounded : Icons.play_arrow_rounded;

                    return ElevatedButton(
                      onPressed: () => _playEpisode(reachedIdx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(buttonIcon, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Synopsis
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Episode List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Episodes (${s.episodesCount})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.SUBSCRIPTION),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B25C6), Color(0xFFFF2E93)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 13),
                              SizedBox(width: 4),
                              Text(
                                'Unlimited Pass',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Episode Grid
                  Obx(() {
                    final episodes = s.effectiveEpisodes;
                    final reachedIdx = UserLibraryService.to.getReachedEpisodeIndex(s.id);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final ep = episodes[index];
                        final isLocked = ep.isLocked;
                        final isReached = (index == reachedIdx);

                        return GestureDetector(
                          onTap: () {
                            if (isLocked) {
                              _showUnlockSheet(context, ep, index);
                            } else {
                              _playEpisode(index);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isReached
                                  ? AppColors.primary
                                  : (isLocked ? AppColors.surface : AppColors.card),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isReached
                                    ? AppColors.primaryLight
                                    : (isLocked
                                        ? AppColors.accent.withValues(alpha: 0.5)
                                        : AppColors.cardBorder),
                                width: (isReached || isLocked) ? 1.2 : 1.0,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isReached
                                        ? Colors.white
                                        : (isLocked ? AppColors.accentLight : AppColors.textPrimary),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (isLocked)
                                  Positioned(
                                    top: 3,
                                    right: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lock_rounded, size: 11, color: AppColors.accent),
                                    ),
                                  ),
                                if (isReached && !isLocked)
                                  const Positioned(
                                    top: 3,
                                    right: 3,
                                    child: Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
