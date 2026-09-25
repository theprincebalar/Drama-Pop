import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feed_controller.dart';
import '../../../widgets/quality_selector_modal.dart';

class QualitySelectorSheet extends GetView<FeedController> {
  const QualitySelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = controller.currentSeries;
    final ep = controller.currentEpisode;

    return QualitySelectorModalWidget(
      currentQuality: controller.selectedQuality.value,
      onQualitySelected: controller.setQuality,
      seriesId: s?.id,
      episodeNumber: ep?.episodeNumber,
    );
  }
}

class QualitySelectorModalWidget extends StatelessWidget {
  final String currentQuality;
  final ValueChanged<String> onQualitySelected;
  final String? seriesId;
  final int? episodeNumber;

  const QualitySelectorModalWidget({
    super.key,
    required this.currentQuality,
    required this.onQualitySelected,
    this.seriesId,
    this.episodeNumber,
  });

  @override
  Widget build(BuildContext context) {
    QualitySelectorModal.show(
      context,
      currentQuality: currentQuality,
      onQualitySelected: onQualitySelected,
      seriesId: seriesId,
      episodeNumber: episodeNumber,
    );
    return const SizedBox.shrink();
  }
}