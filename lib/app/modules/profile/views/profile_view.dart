import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/user_library_service.dart';
import '../../../widgets/quality_selector_modal.dart';
import '../../root/controllers/root_controller.dart';
import 'saved_episodes_view.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.card, AppColors.surface],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drama Fan #8821',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          final isUnlimited = UnlockService.to.hasUnlimitedAccess;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isUnlimited
                                    ? [const Color(0xFFFF2E93), const Color(0xFF9333EA)]
                                    : [const Color(0xFF334155), const Color(0xFF1E293B)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isUnlimited ? '👑 UNLIMITED VIP MEMBER' : 'STANDARD MEMBER',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subscription & Coins Wallet Cards
            Row(
              children: [
                // Coins Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.COIN_STORE),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800), size: 16),
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Top Up',
                                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Obx(() => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${UnlockService.to.userCoins.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )),
                          const SizedBox(height: 2),
                          const Text(
                            'Coins Balance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Unlimited Pass Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.toNamed(Routes.SUBSCRIPTION),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E174D), Color(0xFF1E1035)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryLight, size: 16),
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Pass',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Obx(() {
                            final isUnlimited = UnlockService.to.hasUnlimitedAccess;
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isUnlimited ? 'Active VIP' : 'Unlimited',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 2),
                          const Text(
                            '20,000+ Episodes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistics Bar (Watchlist count, Saved Episodes count, HD Quality)
            Row(
              children: [
                Obx(() => _buildStatItem(
                  '${UserLibraryService.to.watchlist.length}',
                  'In Watchlist',
                  onTap: () {
                    if (Get.isRegistered<RootController>()) {
                      Get.find<RootController>().changePage(2);
                    }
                  },
                )),
                const SizedBox(width: 12),
                Obx(() => _buildStatItem(
                  '${UserLibraryService.to.savedEpisodes.length}',
                  'Saved Episodes',
                  onTap: () => Get.to(() => const SavedEpisodesView()),
                )),
                const SizedBox(width: 12),
                Obx(() => _buildStatItem(
                  UserLibraryService.to.defaultQuality.value.toUpperCase(),
                  'Default Quality',
                  onTap: () {
                    QualitySelectorModal.show(
                      context,
                      currentQuality: UserLibraryService.to.defaultQuality.value,
                      onQualitySelected: (q) => UserLibraryService.to.setDefaultQuality(q),
                    );
                  },
                )),
              ],
            ),

            const SizedBox(height: 28),

            // Library & Collection Section
            const Text(
              'My Library',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Instagram-Style Saved Episodes Navigation Tile
            Obx(() {
              final count = UserLibraryService.to.savedEpisodes.length;
              return _buildSettingTile(
                icon: Icons.bookmark_rounded,
                title: 'Saved Episodes',
                subtitle: count > 0 ? '$count bookmarked episodes • Tap to view' : 'No saved episodes yet • Tap to view',
                color: AppColors.accent,
                trailingBadge: count > 0 ? '$count' : null,
                onTap: () => Get.to(() => const SavedEpisodesView()),
              );
            }),

            const SizedBox(height: 20),

            // Settings & App Info List
            const Text(
              'App Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Obx(() => _buildSettingTile(
              icon: Icons.high_quality_rounded,
              title: 'Default Video Quality',
              subtitle: '${UserLibraryService.to.defaultQuality.value.toUpperCase()} Streaming Quality • Tap to change',
              color: AppColors.primaryLight,
              onTap: () {
                QualitySelectorModal.show(
                  context,
                  currentQuality: UserLibraryService.to.defaultQuality.value,
                  onQualitySelected: (q) => UserLibraryService.to.setDefaultQuality(q),
                );
              },
            )),
            _buildSettingTile(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy Policy',
              subtitle: 'Data usage & security compliance • Tap to read',
              color: AppColors.primary,
              onTap: () => Get.to(() => const PrivacyPolicyView()),
            ),
            _buildSettingTile(
              icon: Icons.gavel_rounded,
              title: 'Terms of Service',
              subtitle: 'Subscriptions & content guidelines • Tap to read',
              color: AppColors.accent,
              onTap: () => Get.to(() => const TermsOfServiceView()),
            ),
            _buildSettingTile(
              icon: Icons.delete_outline_rounded,
              title: 'Account & Data Management',
              subtitle: 'Clear watch history or request data deletion',
              color: const Color(0xFFEF4444),
              onTap: () => _showDataManagementDialog(context),
            ),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'DramaPop App Version',
              subtitle: 'v1.0.0 (Production Release)',
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Data & Privacy',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy is our top priority. You can clear your local watch history and bookmarks, or email us at support@genxappstudio.cloud for permanent account & data erasure under GDPR / CCPA.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await UserLibraryService.to.clearAllUserData();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              Get.snackbar(
                'Data Cleared',
                'Your watch history and saved list have been reset.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF22163B),
                colorText: Colors.white,
                borderRadius: 14,
                margin: const EdgeInsets.all(16),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear Local Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? trailingBadge,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            if (trailingBadge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    ),
  );
}
}
