import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/search_controller.dart';
import '../../home/widgets/drama_card.dart';
import '../../../theme/app_colors.dart';

class SearchView extends GetView<DramaSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: TextField(
            controller: controller.textController,
            focusNode: controller.focusNode,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search 20,000+ drama episodes, titles...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight, size: 20),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: controller.clearSearch,
                  );
                }
                return const SizedBox.shrink();
              }),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
            onChanged: controller.onQueryChanged,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SpinKitFadingCircle(
              color: AppColors.primaryLight,
              size: 40.0,
            ),
          );
        }

        final query = controller.searchQuery.value.trim();

        // 1. Empty query state: Popular Tags + Trending Suggestions
        if (query.isEmpty) {
          return _buildEmptyQueryContent(context);
        }

        // 2. Active search query state
        final results = controller.searchResults;
        if (results.isEmpty) {
          return _buildNoResultsState(query);
        }

        return _buildSearchResultsGrid(results, query);
      }),
    );
  }

  Widget _buildEmptyQueryContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Popular Categories & Keywords',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: controller.popularKeywords.map((tag) {
              return ActionChip(
                label: Text(tag),
                labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.cardBorder, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => controller.selectTag(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.trending_up_rounded, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Trending Dramas',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '20,000+ Episodes',
                style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.55,
            ),
            itemCount: controller.trendingDramas.length,
            itemBuilder: (context, index) {
              final drama = controller.trendingDramas[index];
              return DramaCard(series: drama, isGrid: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid(List results, String query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface.withValues(alpha: 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  children: [
                    const TextSpan(text: 'Found '),
                    TextSpan(
                      text: '${results.length}',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' dramas for '),
                    TextSpan(
                      text: '"$query"',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                'Instant Live',
                style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.55,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final drama = results[index];
              return DramaCard(series: drama, isGrid: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'No dramas found for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching with a broader keyword, character theme, or select from popular tags.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
