import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class BannerSlider extends StatefulWidget {
  final List<SeriesModel> items;

  const BannerSlider({super.key, required this.items});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _current = 0;
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_pageController.hasClients || widget.items.isEmpty) return;
      final maxItems = widget.items.length > 5 ? 5 : widget.items.length;
      if (maxItems <= 1) return;

      int nextPage = _current + 1;
      if (nextPage >= maxItems) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final maxItems = widget.items.length > 5 ? 5 : widget.items.length;

    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _current = index);
              _startAutoScroll();
            },
            itemCount: maxItems,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.DETAIL, arguments: item);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Ambient blurred background
                        CachedNetworkImage(
                          imageUrl: item.coverUrl,
                          memCacheWidth: 300,
                          httpHeaders: const {
                            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                          },
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: AppColors.card),
                          errorWidget: (c, u, e) => Container(color: AppColors.card),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.68),
                          ),
                        ),

                        // 2. Foreground content: Sharp Portrait Poster (Left) + Drama Details (Right)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Un-stretched 2:3 vertical poster
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AspectRatio(
                                  aspectRatio: 2 / 3,
                                  child: CachedNetworkImage(
                                    imageUrl: item.coverUrl,
                                    memCacheWidth: 260,
                                    httpHeaders: const {
                                      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36',
                                    },
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Container(
                                      color: AppColors.card,
                                      child: const Center(
                                        child: Icon(Icons.movie, color: AppColors.textMuted, size: 24),
                                      ),
                                    ),
                                    errorWidget: (c, u, e) => Image.network(
                                      'https://dramapop-admin.genxappstudio.cloud/covers/${item.id}.webp?v=2',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, err, s) => Container(
                                        color: AppColors.card,
                                        child: const Center(
                                          child: Icon(Icons.movie_creation_outlined, color: AppColors.textMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Right column: Tag, Title, Description, Watch Now CTA
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'HOT DRAMA',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item.genres.take(2).join(' • '),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 15),
                                              SizedBox(width: 4),
                                              Text(
                                                'Watch Now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            maxItems,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _current == index ? 18 : 6,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _current == index ? AppColors.primary : AppColors.cardBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}