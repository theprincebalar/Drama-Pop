import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/feed_controller.dart';
import '../../root/controllers/root_controller.dart';
import '../../../data/services/user_library_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/quality_selector_modal.dart';
import '../../../widgets/report_modal.dart';

class FeedView extends GetView<FeedController> {
  const FeedView({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SpinKitFadingCircle(
              color: AppColors.primaryLight,
              size: 44.0,
            ),
          );
        }

        if (controller.seriesList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tv_off, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                const Text('No streams available', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller.loadFeed(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshFeed,
          color: AppColors.primaryLight,
          backgroundColor: AppColors.surface,
          edgeOffset: MediaQuery.of(context).padding.top,
          child: PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.seriesList.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              final series = controller.seriesList[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Video player or cover placeholder
                  GestureDetector(
                    onTap: controller.togglePlayPause,
                    child: Obx(() {
                      final root = Get.isRegistered<RootController>() ? Get.find<RootController>() : null;
                      final isTabActive = (root == null || root.currentIndex.value == 1);
                      final canPlayVideo = isTabActive;

                      if (canPlayVideo &&
                          controller.currentSeriesIndex.value == index &&
                          controller.isVideoInitialized.value &&
                          controller.videoPlayerController != null) {
                        final size = controller.videoPlayerController!.value.size;
                        final vWidth = size.width > 0 ? size.width : 540.0;
                        final vHeight = size.height > 0 ? size.height : 960.0;

                        return SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: vWidth,
                              height: vHeight,
                              child: VideoPlayer(
                                controller.videoPlayerController!,
                                key: ValueKey(
                                  'vp_${series.id}_${controller.currentEpisodeIndex.value}_${controller.videoPlayerController.hashCode}',
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: series.coverUrl,
                            memCacheWidth: 720,
                            httpHeaders: const {
                              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                            },
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Image.network(
                              'https://dramapop-admin.genxappstudio.cloud/covers/${series.id}.webp?v=2',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.black),
                            ),
                          ),
                          Container(color: Colors.black.withValues(alpha: 0.4)),
                          if (canPlayVideo)
                            const Center(
                              child: SpinKitRing(
                                color: AppColors.primaryLight,
                                lineWidth: 3,
                                size: 40,
                              ),
                            ),
                        ],
                      );
                    }),
                  ),

                  // Play/Pause icon overlay
                  Obx(() {
                    if (!controller.isPlaying.value) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 54),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Live Buffering indicator overlay
                  Obx(() {
                    if (controller.isBuffering.value && controller.isVideoInitialized.value) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const SpinKitRing(
                            color: AppColors.primaryLight,
                            lineWidth: 2.5,
                            size: 38,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Right vertical action icons (Save Episode, Episodes, Share, Quality, Report)
                Positioned(
                  right: 12,
                  bottom: 100,
                  top: 100,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Save Episode Button (Saves specific episode to profile)
                          Obx(() {
                            final ep = controller.currentEpisode;
                            final epNum = ep != null ? ep.episodeNumber : 1;
                            final isSaved = UserLibraryService.to.isEpisodeSaved(series.id, epNum);

                            return _buildActionButton(
                              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? AppColors.accent : Colors.white,
                              label: isSaved ? 'Saved' : 'Save',
                              onTap: controller.toggleSaveEpisode,
                            );
                          }),
                          const SizedBox(height: 16),

                          // Share Drama Button
                          _buildActionButton(
                            icon: Icons.share_rounded,
                            color: Colors.white,
                            label: 'Share',
                            onTap: controller.shareDrama,
                          ),
                          const SizedBox(height: 16),

                          // Episode list button: Redirect directly to Detail screen
                          _buildActionButton(
                            icon: Icons.layers_rounded,
                            color: AppColors.accent,
                            label: 'Episodes',
                            onTap: () => controller.openDetailScreen(series),
                          ),
                          const SizedBox(height: 16),

                          // Quality Switcher Icon
                          _buildActionButton(
                            icon: Icons.tune_rounded,
                            color: Colors.white,
                            label: 'Quality',
                            onTap: () => QualitySelectorModal.show(
                              context,
                              currentQuality: controller.selectedQuality.value,
                              onQualitySelected: controller.setQuality,
                              seriesId: series.id,
                              episodeNumber: controller.currentEpisode?.episodeNumber,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Report Drama Button
                          _buildActionButton(
                            icon: Icons.outlined_flag_rounded,
                            color: Colors.white70,
                            label: 'Report',
                            onTap: () {
                              final ep = controller.currentEpisode;
                              ReportModal.show(
                                context,
                                series: series,
                                episodeNumber: ep?.episodeNumber ?? 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Overlay with Synopsis & Episode Selector Trigger
                Positioned(
                  left: 16,
                  right: 80,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drama Title & Episode Number (clickable to open detail screen)
                      Obx(() {
                        final ep = controller.currentEpisode;
                        final epNum = ep != null ? ep.episodeNumber : 1;
                        return GestureDetector(
                          onTap: () => controller.openDetailScreen(series),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '@ ${series.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'EP $epNum',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        series.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: series.genres.map((g) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              '#$g',
                              style: const TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 11,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Interactive Video Progress Controller Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Obx(() {
                    final dur = controller.totalDuration.value.inMilliseconds.toDouble();
                    final pos = controller.currentPosition.value.inMilliseconds.toDouble();
                    final validDur = dur > 0 ? dur : 1.0;
                    final validPos = pos.clamp(0.0, validDur);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(controller.currentPosition.value),
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppColors.primaryLight,
                              ),
                              child: Slider(
                                value: validPos,
                                max: validDur,
                                onChanged: (val) {
                                  controller.seekTo(Duration(milliseconds: val.toInt()));
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(controller.totalDuration.value),
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      );
    }),
  );
}

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
