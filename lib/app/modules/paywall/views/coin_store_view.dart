import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../data/services/unlock_service.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/revenue_cat_service.dart';
import '../../../data/services/meta_events_service.dart';
import '../../../data/services/firebase_analytics_service.dart';
import '../../profile/views/privacy_policy_view.dart';
import '../../profile/views/terms_of_service_view.dart';

class CoinStoreView extends StatefulWidget {
  const CoinStoreView({super.key});

  @override
  State<CoinStoreView> createState() => _CoinStoreViewState();
}

class _CoinStoreViewState extends State<CoinStoreView> with SingleTickerProviderStateMixin {
  int _selectedPackageIndex = 1; // Default to popular package
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    MetaEventsService.to.logInitiatedCheckout(
      amount: 4.99,
      currency: 'USD',
      contentId: 'coin_store_paywall',
      contentType: 'coin_package',
    );
    FirebaseAnalyticsService.to.logBeginCheckout(
      amount: 4.99,
      currency: 'USD',
      itemId: 'coin_store_paywall',
      itemName: 'DramaPop Coin Store',
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090611),
      body: Stack(
        children: [
          // Ambient luxury background spotlights
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB800).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Custom Navigation Bar
                _buildHeader(context),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Hero Coin Vault Card
                        _buildHeroBanner(),

                        const SizedBox(height: 16),

                        // VIP Unlimited Pass Upsell Card
                        _buildVipUpsellBanner(),

                        const SizedBox(height: 22),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.flash_on_rounded, color: Color(0xFFFFB800), size: 18),
                                  SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Choose Coin Package',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'INSTANT REFILL',
                                style: TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Packages List (Dynamic from Admin Panel with Local Store Currency)
                        Obx(() {
                          RevenueCatService.to.localizedCoinPrices.length;
                          final packages = UnlockService.to.effectiveCoinPackages;
                          final safeSelectedIndex = _selectedPackageIndex.clamp(
                            0,
                            packages.isNotEmpty ? packages.length - 1 : 0,
                          );

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: packages.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final pkg = packages[index];
                              final isSelected = index == safeSelectedIndex;
                              final localPrice = RevenueCatService.to.getLocalizedCoinPrice(pkg);
                              return _buildModernPackageCard(pkg, index, isSelected, localPrice);
                            },
                          );
                        }),

                        const SizedBox(height: 22),

                        // Trust & Security Guarantee Badges
                        _buildTrustRow(),

                        const SizedBox(height: 110), // Padding for sticky bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Checkout Bar
          _buildStickyPurchaseBar(),
        ],
      ),
    );
  }

  // Header Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Coin Store',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Live Coin Balance Badge
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2E2009),
                  Color(0xFF1E1430),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800), size: 15),
                const SizedBox(width: 5),
                Text(
                  '${UnlockService.to.userCoins.value}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Hero Vault Banner
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF281347),
            Color(0xFF160E28),
            Color(0xFF0F0B1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFDF00),
                    Color(0xFFFF9500),
                    Color(0xFFCC6600),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF351C00), size: 36),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Any Episode Instantly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Permanent episode unlock • No expiry • Watch anytime in crystal clear 1080P HD.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // VIP Pass Upsell Banner
  Widget _buildVipUpsellBanner() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.SUBSCRIPTION);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE11D48), Color(0xFF9333EA), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE11D48).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Prefer Unlimited Watching?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.bolt_rounded, color: Color(0xFFFFDF00), size: 15),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Get VIP Pass • Stream 20,000+ Episodes with Zero Coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // Modern Package Card
  Widget _buildModernPackageCard(CoinPackage pkg, int index, bool isSelected, String localPrice) {
    final isBest = pkg.isBestValue;
    final isPop = pkg.isPopular;

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
                colors: [Color(0xFF2C200B), Color(0xFF1E1508)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF2C1020), Color(0xFF1E0E1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : const LinearGradient(
            colors: [Color(0xFF161024), Color(0xFF110C1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackageIndex = index;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  width: 20,
                  height: 20,
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
                          size: 13,
                          color: isBest ? Colors.black : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),

                // Coin Stack Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFE066),
                        Color(0xFFFFB800),
                        Color(0xFFE67E00),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.monetization_on_rounded, color: Color(0xFF331B00), size: 24),
                ),
                const SizedBox(width: 10),

                // Package Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${pkg.totalCoins} Coins',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (pkg.bonusCoins > 0) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, color: Colors.black, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  '+${pkg.bonusCoins} BONUS FREE',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        isBest
                            ? '⭐ Best Value'
                            : isPop
                                ? '🔥 Most Popular'
                                : '⚡ Instant Refill',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Price Tag Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? (isBest
                            ? const LinearGradient(colors: [Color(0xFFFFDF00), Color(0xFFFF9500)])
                            : const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]))
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.06),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isBest ? const Color(0xFFFFB800) : const Color(0xFFE11D48)).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    localPrice,
                    style: TextStyle(
                      color: isSelected
                          ? (isBest ? Colors.black : Colors.white)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Badge for Best Value or Popular
          if (isBest || isPop)
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
                      isBest ? Icons.star_rounded : Icons.local_fire_department_rounded,
                      color: isBest ? Colors.black : Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBest ? 'BEST VALUE DEAL' : 'MOST POPULAR',
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

  // Trust Row
  Widget _buildTrustRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF130E20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Row(
        children: [
          Expanded(child: _TrustItem(icon: Icons.flash_on_rounded, label: 'Instant Refill')),
          SizedBox(width: 4),
          Expanded(child: _TrustItem(icon: Icons.all_inclusive_rounded, label: 'Lifetime Coins')),
          SizedBox(width: 4),
          Expanded(child: _TrustItem(icon: Icons.verified_user_rounded, label: 'Secure Pay')),
        ],
      ),
    );
  }

  // Sticky Purchase Action Bar
  Widget _buildStickyPurchaseBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Obx(() {
        RevenueCatService.to.localizedCoinPrices.length;
        final packages = UnlockService.to.effectiveCoinPackages;
        if (packages.isEmpty) return const SizedBox.shrink();
        final safeIndex = _selectedPackageIndex.clamp(0, packages.length - 1);
        final selectedPkg = packages[safeIndex];
        final selectedLocalPrice = RevenueCatService.to.getLocalizedCoinPrice(selectedPkg);

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0A1C),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: selectedPkg.isBestValue
                    ? const Color(0xFFFFB800).withValues(alpha: 0.4)
                    : const Color(0xFFE11D48).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      await RevenueCatService.to.purchaseCoinPackage(selectedPkg);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedPkg.isBestValue
                          ? const Color(0xFFFFB800)
                          : const Color(0xFFE11D48),
                      foregroundColor: selectedPkg.isBestValue ? Colors.black : Colors.white,
                      elevation: 8,
                      shadowColor: (selectedPkg.isBestValue
                              ? const Color(0xFFFFB800)
                              : const Color(0xFFE11D48))
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: selectedPkg.isBestValue ? Colors.black : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Get ${selectedPkg.totalCoins} Coins • $selectedLocalPrice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selectedPkg.isBestValue ? Colors.black : Colors.white,
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
                Text(
                  'Encrypted store payment • Coins added to wallet immediately',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
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
          ),
        );
      }),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFFB800), size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
