import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../data/services/unlock_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class SubscriptionSuccessDialog extends StatelessWidget {
  final SubscriptionPlan plan;
  final DateTime? expiryDate;

  const SubscriptionSuccessDialog({
    super.key,
    required this.plan,
    this.expiryDate,
  });

  static Future<void> show({
    required SubscriptionPlan plan,
    DateTime? expiryDate,
  }) async {
    await Get.dialog(
      SubscriptionSuccessDialog(plan: plan, expiryDate: expiryDate),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiryFormatted = expiryDate != null
        ? DateFormat('MMMM d, yyyy').format(expiryDate!)
        : 'Auto-renewing';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF130E20),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFB800).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withValues(alpha: 0.25),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 24,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Glowing Crown Hero Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFB800),
                    Color(0xFFFF4D8D),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Congratulations Headline
            const Text(
              '🎉 VIP Access Unlocked!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Congratulations! You have unlocked unlimited access to all short drama episodes on DramaPop.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Subscribed Plan Badge & Expiry
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF221735),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF4D8D).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Plan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: Color(0xFFFFB800),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Access Validity',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        expiryFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // VIP Benefits Checklist
            _buildBenefitRow('Unlimited binge-watching (20,000+ Episodes)'),
            const SizedBox(height: 6),
            _buildBenefitRow('Zero coin deductions across all series'),
            const SizedBox(height: 6),
            _buildBenefitRow('Full Ultra HD 1080p fast streaming'),

            const SizedBox(height: 24),

            // Start Watching Now CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Redirect directly to Home / Root Feed
                  Get.offAllNamed(Routes.ROOT);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Watching Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildBenefitRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
