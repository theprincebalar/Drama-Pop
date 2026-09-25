import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/player_controller.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../../widgets/quality_selector_modal.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/report_modal.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  PlayerController get controller {
    if (Get.isRegistered<PlayerController>()) {
      return Get.find<PlayerController>();
    }
    return Get.put(PlayerController());
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Surface & Gestures
              _buildVideoPlayerArea(),

              // 2. Double Tap 10s Overlays
              _buildDoubleTapOverlays(),

              // 3. Top Gradient & AppBar Controls (Back, Title, Quality, Save, Share, Report)
              _buildTopControls(context),

              // 4. Center Play/Pause Indicator (when paused)
              _buildCenterPlayIndicator(),

              // 5. Complete Bottom Controller Overlay (Seekbar + Prev/Play/Next + Speed + Quality + Episode Drawer)
              _buildBottomControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerArea() {
    return Obx(() {
      final initialized = controller.isVideoInitialized.value;
      final vpc = controller.videoPlayerController;
      final isReady = initialized && vpc != null && vpc.value.isInitialized;

      final double width = (isReady && vpc.value.size.width > 0) ? vpc.value.size.width : 540.0;
      final double height = (isReady && vpc.value.size.height > 0) ? vpc.value.size.height : 960.0;
      final double ar = (height > 0) ? width / height : 9 / 16;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.toggleControlsVisibility,
        onDoubleTapDown: (details) {
          final screenWidth = Get.width;
          if (details.globalPosition.dx < screenWidth * 0.4) {
            controller.skipBackward10();
          } else if (details.globalPosition.dx > screenWidth * 0.6) {
            controller.skipForward10();
          } else {
            controller.togglePlayPause();
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                Center(
                  child: AspectRatio(
                    aspectRatio: ar,
                    child: VideoPlayer(vpc),
                  ),
                ),

              // Buffering or loading state
              if (!isReady || controller.isBuffering.value)
                const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.primaryLight,
                    size: 46.0,
                  ),
                ),

              // Error State
              if (controller.hasError.value)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 44),
                        const SizedBox(height: 12),
                        const Text(
                          'Playback Error',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Could not load stream. Please check your connection or switch quality.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => controller.playEpisode(controller.currentEpisodeIndex.value),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Locked Episode Premium Overlay
              if (controller.isCurrentEpisodeLocked.value)
                _buildLockedEpisodeOverlay(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLockedEpisodeOverlay() {
    final ep = controller.currentEpisode;
    final epNum = controller.currentEpisodeIndex.value + 1;
    final price = ep?.coinPrice ?? 10;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Episode $epNum is Locked',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock this episode with $price coins or choose an unlimited subscription for all dramas.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: controller.unlockAndPlayCurrentEpisode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Unlock Episode ($price Coins)',
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
            OutlinedButton(
              onPressed: () => Get.toNamed(Routes.SUBSCRIPTION),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.primaryLight, size: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleTapOverlays() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                if (!controller.showBackward10Overlay.value) return const SizedBox.shrink();
                return Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                        SizedBox(height: 4),
                        Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Expanded(
              child: Obx(() {
                if (!controller.showForward10Overlay.value) return const SizedBox.shrink();
                return Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                        SizedBox(height: 4),
                        Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Obx(() {
        final visible = controller.areControlsVisible.value;
        final series = controller.series.value;
        final epIndex = controller.currentEpisodeIndex.value;
        final totalEps = controller.episodes.length;
        final quality = controller.selectedQuality.value;
        final isSaved = UserLibraryService.to.isEpisodeSaved(series.id, epIndex + 1);

        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !visible,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                right: 12,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          series.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Episode ${epIndex + 1} of $totalEps',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Quality Badge Button
                  GestureDetector(
                    onTap: () => QualitySelectorModal.show(
                      context,
                      currentQuality: quality,
                      onQualitySelected: controller.setQuality,
                      seriesId: series.id,
                      episodeNumber: epIndex + 1,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hd_outlined, color: AppColors.primaryLight, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            quality.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Save Episode Bookmark Button
                  GestureDetector(
                    onTap: controller.toggleSaveCurrentEpisode,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSaved ? AppColors.accent : AppColors.cardBorder,
                        ),
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.accent : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Share Button
                  GestureDetector(
                    onTap: controller.shareDrama,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Report Button
                  GestureDetector(
                    onTap: () => ReportModal.show(
                      context,
                      series: series,
                      episodeNumber: epIndex + 1,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.outlined_flag_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCenterPlayIndicator() {
    return Positioned.fill(
      child: Obx(() {
        final visible = controller.areControlsVisible.value;
        final isPlaying = controller.isPlaying.value;
        final isLocked = controller.isCurrentEpisodeLocked.value;

        if (isLocked || (!visible && isPlaying)) {
          return const SizedBox.shrink();
        }

        return Center(
          child: AnimatedOpacity(
            opacity: (visible || !isPlaying) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind 10s button
                GestureDetector(
                  onTap: controller.skipBackward10,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 24),

                // Center Play/Pause
                GestureDetector(
                  onTap: controller.togglePlayPause,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Forward 10s button
                GestureDetector(
                  onTap: controller.skipForward10,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Obx(() {
        final visible = controller.areControlsVisible.value;
        final totalMs = controller.totalDuration.value.inMilliseconds.toDouble();
        final maxSlider = totalMs > 0 ? totalMs : 1.0;
        final posMs = controller.currentPosition.value.inMilliseconds.toDouble().clamp(0.0, maxSlider);
        final epIndex = controller.currentEpisodeIndex.value;
        final totalEps = controller.episodes.length;
        final quality = controller.selectedQuality.value;
        final speed = controller.playbackSpeed.value;
        final isPlaying = controller.isPlaying.value;

        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !visible,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scrubber Bar
                  Row(
                    children: [
                      Text(
                        _formatDuration(controller.currentPosition.value),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: AppColors.accent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.accent,
                            overlayColor: AppColors.accent.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: posMs,
                            max: maxSlider,
                            onChanged: (val) {
                              controller.seekTo(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(controller.totalDuration.value),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Comprehensive Controller Actions Row (FittedBox ensures 0% overflow on any screen width)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Episode Drawer Button
                        TextButton.icon(
                          onPressed: () => _showEpisodeDrawer(context),
                          icon: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 20),
                          label: Text(
                            'Ep. ${epIndex + 1} / $totalEps',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quality Selector Button
                        GestureDetector(
                          onTap: () => QualitySelectorModal.show(
                            context,
                            currentQuality: quality,
                            onQualitySelected: controller.setQuality,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, color: AppColors.accent, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  quality.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Speed Selector Button
                        GestureDetector(
                          onTap: () => _showSpeedSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${speed}x',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Playback Navigation Control buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 26),
                              tooltip: 'Previous Episode',
                              onPressed: controller.playPreviousEpisode,
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: AppColors.primaryLight,
                                size: 36,
                              ),
                              tooltip: isPlaying ? 'Pause' : 'Play',
                              onPressed: controller.togglePlayPause,
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                              tooltip: 'Next Episode',
                              onPressed: controller.playNextEpisode,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...speeds.map((spd) => Obx(() {
              final isSelected = controller.playbackSpeed.value == spd;
              return ListTile(
                title: Text(
                  spd == 1.0 ? '1.0x (Normal)' : '${spd}x',
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.accent) : null,
                onTap: () {
                  controller.setSpeed(spd);
                  Navigator.pop(ctx);
                },
              );
            })),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEpisodeDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.series.value.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total ${controller.episodes.length} Episodes • Select to Watch',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: controller.episodes.length,
                itemBuilder: (context, index) {
                  final ep = controller.episodes[index];
                  return Obx(() {
                    final isCurrent = controller.currentEpisodeIndex.value == index;
                    final isUnlocked = UnlockService.to.isEpisodeUnlocked(controller.series.value.id, ep.episodeNumber);
                    final isLocked = ep.isLocked && !isUnlocked;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        controller.playEpisode(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : isLocked
                                  ? AppColors.surface.withValues(alpha: 0.6)
                                  : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primaryLight
                                : isLocked
                                    ? AppColors.accent.withValues(alpha: 0.5)
                                    : AppColors.cardBorder,
                            width: (isCurrent || isLocked) ? 1.2 : 1.0,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : isLocked
                                        ? AppColors.accentLight
                                        : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (isLocked)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 12),
                                ),
                              ),
                            if (isCurrent && !isLocked)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 13),
                              ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
