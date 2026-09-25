import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class DramaCard extends StatelessWidget {
  final SeriesModel series;
  final double? width;
  final double? height;
  final bool isGrid;

  const DramaCard({
    super.key,
    required this.series,
    this.width,
    this.height,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIsGrid = isGrid || (width == double.infinity);
    final cardWidth = effectiveIsGrid ? null : (width ?? 130.0);
    final cardHeight = effectiveIsGrid ? null : (height ?? 190.0);

    Widget posterContent = CachedNetworkImage(
      imageUrl: series.coverUrl,
      memCacheWidth: 260,
      httpHeaders: const {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
      },
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.card,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 16),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Image.network(
        'https://dramapop-admin.genxappstudio.cloud/covers/${series.id}.webp?v=2',
        fit: BoxFit.cover,
        errorBuilder: (context, err, stack) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2D1B4E), Color(0xFF161026)],
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              series.title,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.DETAIL, arguments: series);
      },
      child: Container(
        width: cardWidth,
        margin: effectiveIsGrid ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poster with overlays
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  effectiveIsGrid
                      ? AspectRatio(
                          aspectRatio: 2 / 3,
                          child: posterContent,
                        )
                      : Container(
                          width: cardWidth,
                          height: cardHeight,
                          color: AppColors.card,
                          child: posterContent,
                        ),

                  // Top gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // HD badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.badge1080p.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '1080P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient & episode count
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.accent, size: 13),
                              const SizedBox(width: 2),
                              Text(
                                '${series.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${series.episodesCount} Eps',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Title
            Text(
              series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}