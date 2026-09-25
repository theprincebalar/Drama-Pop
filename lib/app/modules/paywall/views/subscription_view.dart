import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_colors.dart';
import '../../../data/models/series_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/unlock_service.dart';
import '../../../data/services/app_review_service.dart';
import '../../../data/services/revenue_cat_service.dart';
import '../../../data/services/meta_events_service.dart';
import '../../../data/services/firebase_analytics_service.dart';
import '../../../widgets/subscription_success_dialog.dart';
import '../../profile/views/privacy_policy_view.dart';
import '../../profile/views/terms_of_service_view.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> with TickerProviderStateMixin {
  int _selectedPlanIndex = 2; // Default to Yearly (Best Value) for maximum conversion & savings
  late AnimationController _rotationController;
  List<SeriesModel> _rotatingDramas = [];

  @override
  void initState() {
    super.initState();
    // Continuous smooth 3D rounded rotating wheel animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    // 🚀 Instant Frame-0 synchronous random selection from drama catalog
    _rotatingDramas = ApiService.getRandomRotatingDramas(count: 8);

    // Warm-up and pre-cache images into GPU texture memory immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheSelectedDramas();
    });

    // If catalog was empty during cold start, refresh once bundled catalog loads
    if (ApiService.cachedCatalog.isEmpty) {
      _loadAndShuffleDramas();
    }

    MetaEventsService.to.logInitiatedCheckout(
      amount: 149.99,
      currency: 'USD',
      contentId: 'vip_subscription_paywall',
      contentType: 'subscription',
    );
    FirebaseAnalyticsService.to.logBeginCheckout(
      amount: 149.99,
      currency: 'USD',
      itemId: 'vip_subscription_paywall',
      itemName: 'VIP Unlimited Subscription',
    );
  }

  void _precacheSelectedDramas() {
    for (final drama in _rotatingDramas) {
      if (drama.coverUrl.isNotEmpty && mounted) {
        precacheImage(
          CachedNetworkImageProvider(drama.coverUrl),
          context,
        );
      }
    }
  }

  Future<void> _loadAndShuffleDramas() async {
    try {
      final catalog = await ApiService.loadBundledCatalog();
      if (catalog.isNotEmpty && mounted) {
        final randomSelection = ApiService.getRandomRotatingDramas(count: 8);
        setState(() {
          _rotatingDramas = randomSelection;
        });
        _precacheSelectedDramas();
      }
    } catch (e) {
      debugPrint('Error loading rotating dramas: $e');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = UnlockService.subscriptionPlans;

    return Scaffold(
      backgroundColor: const Color(0xFF090611),
      body: Stack(
        children: [
          // Background ambient gradient glows
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            height: 440,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.9,
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.38),
                    const Color(0xFFE11D48).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB800).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar with Close & Restore
                _buildTopBar(),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 4),

                        // Active Plan Status Banner (If already subscribed)
                        _buildActivePlanBanner(),

                        // 3D Rounded Rotating Drama Poster Wheel (Crisp, fully opaque, no blacking out)
                        _buildRotatingDramaCarousel(),

                        const SizedBox(height: 16),

                        // Prominent Unlimited Access 20,000+ Episodes Headline & Subtitle
                        _buildDramaStoryPitch(),

                        const SizedBox(height: 18),

                        // 4-Item Drama VIP Perks Grid (High contrast, clearly visible)
                        _buildDramaPerksGrid(),

                        const SizedBox(height: 14),

                        // Drama Fan Social Proof Banner (Hidden automatically when in App Store review)
                        _buildSocialProofStrip(),

                        const SizedBox(height: 20),

                        // Section Heading
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            final isVip = UnlockService.to.hasUnlimitedAccess;
                            return Row(
                              children: [
                                const Icon(Icons.movie_filter_rounded, color: Color(0xFFFFB800), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isVip ? 'Switch or Upgrade Plan' : 'Choose Your Drama Pass',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 12),

                        // Subscription Plans Cards (Weekly, Monthly, Yearly in Local Currency)
                        Obx(() {
                          RevenueCatService.to.localizedSubscriptionPrices.length;

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: plans.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              final isSelected = _selectedPlanIndex == index;
                              final localPrice = RevenueCatService.to.getLocalizedSubscriptionPrice(plan);

                              return _buildDramaPlanCard(plan, localPrice, isSelected, () {
                                setState(() => _selectedPlanIndex = index);
                              });
                            },
                          );
                        }),

                        const SizedBox(height: 16),

                        // Terms & Cancellation Notice
                        _buildTermsCard(),

                        const SizedBox(height: 115), // Padding for sticky bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom CTA Action
          _buildStickyCtaBar(plans),
        ],
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E164D), Color(0xFF1E0E33)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 14),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'UNLIMITED VIP PASS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFFB800),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => RevenueCatService.to.restorePurchases(),
            child: const Text(
              'Restore',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Active VIP Plan Card
  Widget _buildActivePlanBanner() {
    return Obx(() {
      final isVip = UnlockService.to.hasUnlimitedAccess;
      final activePlan = UnlockService.to.activeSubscription.value;
      final expiry = UnlockService.to.subscriptionExpiry.value;
      if (!isVip && activePlan == null) return const SizedBox.shrink();

      final expiryText = expiry != null
          ? 'Active until ${DateFormat("MMMM d, yyyy").format(expiry)}'
          : 'Auto-renewing active';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1C08), Color(0xFF1F1230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'CURRENT ACTIVE PLAN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              activePlan?.title ?? 'VIP Unlimited Pass',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              expiryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ],
        ),
      );
    });
  }

  // 3D Rounded Rotating Drama Poster Wheel Showcase (Crisp, fully opaque, permanently visible)
  Widget _buildRotatingDramaCarousel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final carouselRadiusX = math.min(availableWidth * 0.40, 145.0);
        const carouselRadiusY = 22.0; // Elliptical curve tilt for 3D rounded depth
        const cardWidth = 72.0;
        const cardHeight = 104.0;

        return SizedBox(
          width: availableWidth,
          height: 146,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final count = _rotatingDramas.isNotEmpty ? _rotatingDramas.length : 6;
              final currentRotation = _rotationController.value * 2 * math.pi;

              // Generate orbital items and sort by depth (z-order)
              final List<_OrbitalDramaItem> items = [];
              for (int i = 0; i < count; i++) {
                final baseAngle = (i / count) * 2 * math.pi;
                final angle = baseAngle + currentRotation;
                
                final sinVal = math.sin(angle); // Depth factor (-1.0 back, +1.0 front)
                final cosVal = math.cos(angle); // Horizontal factor (-1.0 left, +1.0 right)

                final xPos = cosVal * carouselRadiusX;
                final yPos = sinVal * carouselRadiusY;
                
                // Scale factor: front items are 1.05x, back items are 0.72x
                final scale = 0.72 + ((sinVal + 1.0) / 2.0) * 0.33;
                // High opacity at all times (90% to 100%) so items NEVER turn black
                final opacity = 0.90 + ((sinVal + 1.0) / 2.0) * 0.10;

                final drama = _rotatingDramas.isNotEmpty
                    ? _rotatingDramas[i]
                    : SeriesModel(
                        id: '$i',
                        title: 'Drama $i',
                        description: '',
                        coverUrl: '',
                        genres: [],
                        episodesCount: 50,
                      );

                items.add(_OrbitalDramaItem(
                  drama: drama,
                  xPos: xPos,
                  yPos: yPos,
                  scale: scale,
                  opacity: opacity,
                  depth: sinVal,
                  index: i,
                ));
              }

              // Sort items by depth so frontmost cards render on top of back cards
              items.sort((a, b) => a.depth.compareTo(b.depth));

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ambient background spotlight in wheel center
                  Container(
                    width: 140,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF9333EA).withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Render rotating 3D cards
                  ...items.map((item) {
                    final isFront = item.depth > 0.65;
                    return Transform.translate(
                      offset: Offset(item.xPos, item.yPos),
                      child: Transform.scale(
                        scale: item.scale,
                        child: Opacity(
                          opacity: item.opacity.clamp(0.0, 1.0),
                          child: Container(
                            width: cardWidth,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22163B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFront ? const Color(0xFFFFB800) : Colors.white.withValues(alpha: 0.35),
                                width: isFront ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isFront
                                      ? const Color(0xFFFFB800).withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.7),
                                  blurRadius: isFront ? 12 : 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: item.drama.coverUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.drama.coverUrl,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 200,
                                      memCacheHeight: 300,
                                      maxWidthDiskCache: 400,
                                      maxHeightDiskCache: 600,
                                      fadeInDuration: const Duration(milliseconds: 150),
                                      placeholder: (context, url) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF2E164D), Color(0xFF1B0C30)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.drama.title.isNotEmpty ? item.drama.title[0] : '🎬',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF381540), Color(0xFF1F0E2A)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Text(
                                              item.drama.title,
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFF261338),
                                      child: const Icon(Icons.movie_rounded, color: Colors.white54, size: 24),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Prominent Unlimited Access 20,000+ Episodes Headline & Subtitle
  Widget _buildDramaStoryPitch() {
    return const Column(
      children: [
        Text(
          'Unlimited Access to 20,000+ Episodes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Watch every viral drama from Episode 1 to the finale with zero coins, zero ads, and zero limits.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 4-Item Drama VIP Perks Grid (Spacious, high-contrast, zero text trimming)
  Widget _buildDramaPerksGrid() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF181028),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMiniPerkItem(
                    icon: Icons.movie_filter_rounded,
                    iconColor: const Color(0xFFFFB800),
                    title: '20,000+ Episodes',
                    subtitle: 'All dramas fully unlocked',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniPerkItem(
                    icon: Icons.block_rounded,
                    iconColor: const Color(0xFFFF4D8D),
                    title: '100% Ad-Free',
                    subtitle: 'Zero video interruptions',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMiniPerkItem(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Daily Early Access',
                    subtitle: 'New episodes 24h early',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniPerkItem(
                    icon: Icons.hd_rounded,
                    iconColor: const Color(0xFFA855F7),
                    title: '1080P Ultra HD',
                    subtitle: 'Crystal-clear cinema stream',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPerkItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22163B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            softWrap: true,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Social Proof Strip (Automatically reactive to Admin Panel In-Review Mode)
  Widget _buildSocialProofStrip() {
    return Obx(() {
      // If current platform is marked as in-review by admin, hide this banner
      if (AppReviewService.to.isCurrentPlatformInReview) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFB800).withValues(alpha: 0.12),
              const Color(0xFFE11D48).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '4.9/5 • Joined by 100,000+ Drama Lovers',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Modern Drama Subscription Plan Card
  Widget _buildDramaPlanCard(
    SubscriptionPlan plan,
    String localPrice,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isBest = plan.isBestValue;
    final isPop = plan.isPopular;

    final borderColor = isSelected
        ? (isBest ? const Color(0xFFFFB800) : const Color(0xFFE11D48))
        : (isBest
            ? const Color(0xFFFFB800).withValues(alpha: 0.35)
            : isPop
                ? const Color(0xFFE11D48).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08));

    final cardBgGradient = isSelected
        ? (isBest
            ? const LinearGradient(
                colors: [Color(0xFF2E2009), Color(0xFF1E1407)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF2C1022), Color(0xFF1C0D1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : const LinearGradient(
            colors: [Color(0xFF161024), Color(0xFF110C1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              gradient: cardBgGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isBest ? const Color(0xFFFFB800) : const Color(0xFFE11D48)).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isBest ? const Color(0xFFFFB800) : const Color(0xFFE11D48))
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? (isBest ? const Color(0xFFFFB800) : const Color(0xFFE11D48))
                          : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: isBest ? Colors.black : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Plan Titles & Breakdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.periodDescription,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Localized Price Tag
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      localPrice,
                      style: TextStyle(
                        color: isSelected
                            ? (isBest ? const Color(0xFFFFB800) : const Color(0xFFFF4D8D))
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      plan.durationLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ribbon Badge (BEST FOR DRAMA LOVERS / MOST POPULAR)
          if (plan.discountBadge != null || isPop)
            Positioned(
              top: -8,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: isBest
                      ? const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFFF8C00)])
                      : const LinearGradient(colors: [Color(0xFFFF2E93), Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isBest ? const Color(0xFFFFB800) : const Color(0xFFFF2E93)).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBest ? Icons.stars_rounded : Icons.local_fire_department_rounded,
                      color: isBest ? Colors.black : Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBest ? (plan.discountBadge ?? 'BEST VALUE') : 'MOST POPULAR',
                      style: TextStyle(
                        color: isBest ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Terms Card
  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF130E20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  '100% Satisfaction Guarantee • Cancel Anytime',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Renews automatically unless canceled at least 24h before period ends in App Store / Google Play account settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Sticky Bottom CTA Bar
  Widget _buildStickyCtaBar(List<SubscriptionPlan> plans) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0A1C),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE11D48),
              width: 1.5,
            ),
          ),
        ),
        child: Obx(() {
          final isVip = UnlockService.to.hasUnlimitedAccess;
          final activePlan = UnlockService.to.activeSubscription.value;
          final safeIndex = _selectedPlanIndex.clamp(0, plans.length - 1);
          final selectedPlan = plans[safeIndex];
          final selectedPrice = RevenueCatService.to.getLocalizedSubscriptionPrice(selectedPlan);
          final isCurrentPlan = isVip && activePlan?.period == selectedPlan.period;

          final buttonLabel = isCurrentPlan
              ? 'Current Active Plan ($selectedPrice)'
              : (isVip
                  ? 'Upgrade to ${selectedPlan.title} • $selectedPrice'
                  : 'Start Unlimited Drama Pass • $selectedPrice');

          return SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isCurrentPlan) {
                        Get.snackbar(
                          'Already Active',
                          'You are currently subscribed to ${selectedPlan.title}.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF1E1035),
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                        return;
                      }

                      final ok = await RevenueCatService.to.purchaseSubscriptionPackage(selectedPlan);
                      if (ok) {
                        await SubscriptionSuccessDialog.show(
                          plan: selectedPlan,
                          expiryDate: UnlockService.to.subscriptionExpiry.value,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan ? const Color(0xFF2E2248) : const Color(0xFFE11D48),
                      foregroundColor: Colors.white,
                      elevation: isCurrentPlan ? 0 : 10,
                      shadowColor: const Color(0xFFE11D48).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCurrentPlan ? Icons.check_circle_rounded : Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            buttonLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cancel anytime in App Store / Google Play • Instant VIP Cinema Activation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Get.to(() => const TermsOfServiceView()),
                        child: const Text(
                          'Terms',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      GestureDetector(
                        onTap: () => Get.to(() => const PrivacyPolicyView()),
                        child: const Text(
                          'Privacy',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      GestureDetector(
                        onTap: () async {
                          await RevenueCatService.to.restorePurchases();
                        },
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _OrbitalDramaItem {
  final SeriesModel drama;
  final double xPos;
  final double yPos;
  final double scale;
  final double opacity;
  final double depth;
  final int index;

  const _OrbitalDramaItem({
    required this.drama,
    required this.xPos,
    required this.yPos,
    required this.scale,
    required this.opacity,
    required this.depth,
    required this.index,
  });
}
