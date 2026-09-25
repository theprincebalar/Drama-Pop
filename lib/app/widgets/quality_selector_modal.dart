import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../data/services/unlock_service.dart';
import '../routes/app_routes.dart';

class QualitySelectorModal {
  static void show(
    BuildContext context, {
    required String currentQuality,
    required ValueChanged<String> onQualitySelected,
    String? seriesId,
    int? episodeNumber,
  }) {
    final cleanCurrent = currentQuality.toLowerCase();
    final hasSub = UnlockService.to.hasUnlimitedAccess;
    final isCoinUnlocked = (seriesId != null && episodeNumber != null)
        ? UnlockService.to.isEpisodeUnlocked(seriesId, episodeNumber)
        : false;
    final canAccess1080p = hasSub || isCoinUnlocked;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF130E20),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Color(0xFFFFB800), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Video Streaming Quality',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 16),
                    ),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 540P Option
              _buildOption(
                title: '540P Smooth HD',
                description: 'Fast buffering, low data usage & zero lag',
                badge: '540P',
                badgeColor: AppColors.primary,
                qualityKey: '540p',
                isSelected: cleanCurrent == '540p',
                onTap: () {
                  Get.back();
                  onQualitySelected('540p');
                  Get.snackbar(
                    'Quality Changed',
                    'Streaming in 540P Smooth HD',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF1A122B),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              const SizedBox(height: 10),

              // 720P Option (Default standard)
              _buildOption(
                title: '720P HD (Standard)',
                description: 'Crisp high-definition balanced streaming',
                badge: '720P',
                badgeColor: AppColors.badge720p,
                qualityKey: '720p',
                isSelected: cleanCurrent == '720p',
                onTap: () {
                  Get.back();
                  onQualitySelected('720p');
                  Get.snackbar(
                    'Quality Changed',
                    'Streaming in 720P HD',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF1A122B),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              const SizedBox(height: 10),

              // 1080P Option (VIP or Coin-Unlocked Exclusive)
              _buildOption(
                title: '1080P Ultra Full HD',
                description: canAccess1080p
                    ? 'Crystal clear cinema bitrate (Unlocked)'
                    : 'Exclusive to VIP Pass or Coin-Unlocked Episodes',
                badge: '1080P',
                badgeColor: const Color(0xFFFFB800),
                qualityKey: '1080p',
                isSelected: cleanCurrent == '1080p' && canAccess1080p,
                isVipLocked: !canAccess1080p,
                onTap: () {
                  if (!canAccess1080p) {
                    Get.back();
                    Get.snackbar(
                      '👑 VIP 1080P Ultra HD',
                      '1080P streaming is exclusive to VIP Pass members or coin-unlocked episodes. Upgrade to unlock 1080P!',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: const Color(0xFF261338),
                      colorText: const Color(0xFFFFB800),
                      icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800)),
                      duration: const Duration(seconds: 3),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                    Get.toNamed(Routes.SUBSCRIPTION);
                    return;
                  }

                  Get.back();
                  onQualitySelected('1080p');
                  Get.snackbar(
                    '👑 VIP Quality Activated',
                    'Streaming in 1080P Ultra Full HD',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF1A122B),
                    colorText: const Color(0xFFFFB800),
                    icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800)),
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16),
                    borderRadius: 12,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static Widget _buildOption({
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
    required String qualityKey,
    required bool isSelected,
    bool isVipLocked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (qualityKey == '1080p'
                  ? const Color(0xFF2A1F0A)
                  : const Color(0xFF261338))
              : const Color(0xFF1A1228),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (qualityKey == '1080p' ? const Color(0xFFFFB800) : AppColors.primaryLight)
                : (isVipLocked
                    ? const Color(0xFFFFB800).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (qualityKey == '1080p' ? const Color(0xFFFFB800) : AppColors.primary).withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVipLocked ? const Color(0xFFFFB800) : badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isVipLocked ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? (qualityKey == '1080p' ? const Color(0xFFFFB800) : Colors.white)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (qualityKey == '1080p') ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: isVipLocked ? const Color(0xFFFFB800).withValues(alpha: 0.8) : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFFFB800), size: 20)
            else if (isVipLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.black, size: 11),
                    SizedBox(width: 3),
                    Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
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
}
