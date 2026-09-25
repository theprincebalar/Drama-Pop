import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../player/controllers/player_controller.dart';
import '../../root/controllers/root_controller.dart';
import '../../../routes/app_routes.dart';

class SavedEpisodesView extends StatelessWidget {
  const SavedEpisodesView({super.key});

  void _playSavedEpisode(SavedEpisodeItem item) async {
    if (Get.isRegistered<PlayerController>()) {
      Get.delete<PlayerController>(force: true);
    }

    final catalog = await ApiService.loadBundledCatalog();
    final series = catalog.firstWhere(
      (s) => s.id == item.seriesId,
      orElse: () => SeriesModel(
        id: item.seriesId,
        title: item.seriesTitle,
        description: '',
        coverUrl: item.coverUrl,
        genres: item.genres,
        episodesCount: item.episodeNumber > 45 ? item.episodeNumber : 45,
      ),
    );

    Get.toNamed(Routes.PLAYER, arguments: {
      'series': series,
      'episodeIndex': item.episodeNumber - 1,
    });
  }

  void _showRemoveConfirmation(BuildContext context, SavedEpisodeItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const Icon(Icons.bookmark_remove_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Remove from Saved?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remove "${item.seriesTitle} - EP ${item.episodeNumber}" from your saved episodes?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      UserLibraryService.to.removeSavedEpisode(item.seriesId, item.episodeNumber);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Saved',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final count = UserLibraryService.to.savedEpisodes.length;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      body: Obx(() {
        final list = UserLibraryService.to.savedEpisodes;

        if (list.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder, width: 2),
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.accent,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Save Videos to Watch Later',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When you tap the bookmark button on any drama episode, it will be saved here so you can easily find and rewatch it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      if (Get.isRegistered<RootController>()) {
                        Get.find<RootController>().changePage(0); // Discover tab
                      }
                    },
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: const Text('Explore Dramas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return _buildInstagramSavedCard(context, item);
          },
        );
      }),
    );
  }

  Widget _buildInstagramSavedCard(BuildContext context, SavedEpisodeItem item) {
    return GestureDetector(
      onTap: () => _playSavedEpisode(item),
      onLongPress: () => _showRemoveConfirmation(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Poster Image
            CachedNetworkImage(
              imageUrl: item.coverUrl,
              memCacheWidth: 400,
              httpHeaders: const {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
              },
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.card,
                child: const Center(
                  child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 28),
                ),
              ),
              errorWidget: (context, url, error) => Image.network(
                'https://dramapop-admin.genxappstudio.cloud/covers/${item.seriesId}.webp?v=2',
                fit: BoxFit.cover,
                errorBuilder: (c, err, s) => Container(
                  color: AppColors.card,
                  child: const Center(
                    child: Icon(Icons.movie_rounded, color: AppColors.textMuted, size: 32),
                  ),
                ),
              ),
            ),

            // Top & Bottom Subtle Gradients for contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.25, 0.6, 1.0],
                ),
              ),
            ),

            // Top-Left Episode Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      'EP ${item.episodeNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Right Bookmark Action (Quick Remove)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRemoveConfirmation(context, item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Center Play Icon Indicator
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Bottom Content Overlay (Title, Genre & Duration)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.seriesTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.genres.isNotEmpty)
                        Flexible(
                          child: Text(
                            item.genres.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 9),
                            const SizedBox(width: 2),
                            Text(
                              item.duration,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
