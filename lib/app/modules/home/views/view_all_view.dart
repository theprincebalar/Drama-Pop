import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/series_model.dart';
import '../../../theme/app_colors.dart';
import '../widgets/drama_card.dart';

class ViewAllView extends StatelessWidget {
  final String genreTitle;
  final List<SeriesModel> dramas;

  const ViewAllView({
    super.key,
    required this.genreTitle,
    required this.dramas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              genreTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '20,000+ Episodes Available',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: dramas.isEmpty
          ? const Center(
              child: Text(
                'No dramas available in this category',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              itemCount: dramas.length,
              itemBuilder: (context, index) {
                final drama = dramas[index];
                return DramaCard(
                  series: drama,
                  isGrid: true,
                );
              },
            ),
    );
  }
}
