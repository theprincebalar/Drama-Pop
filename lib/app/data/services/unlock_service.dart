import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'revenue_cat_service.dart';
import 'meta_events_service.dart';
import 'firebase_analytics_service.dart';

enum SubscriptionPeriod { weekly, monthly, yearly }

class SubscriptionPlan {
  final SubscriptionPeriod period;
  final String title;
  final String durationLabel;
  final double price;
  final String priceFormatted;
  final String? discountBadge;
  final String periodDescription;
  final bool isPopular;
  final bool isBestValue;

  const SubscriptionPlan({
    required this.period,
    required this.title,
    required this.durationLabel,
    required this.price,
    required this.priceFormatted,
    this.discountBadge,
    required this.periodDescription,
    this.isPopular = false,
    this.isBestValue = false,
  });
}

class CoinPackage {
  final String id;
  final int coins;
  final int bonusCoins;
  final double price;
  final String priceFormatted;
  final bool isPopular;
  final bool isBestValue;
  final String rcProductId;

  const CoinPackage({
    required this.id,
    required this.coins,
    this.bonusCoins = 0,
    required this.price,
    required this.priceFormatted,
    this.isPopular = false,
    this.isBestValue = false,
    this.rcProductId = '',
  });

  int get totalCoins => coins + bonusCoins;
}

class UnlockService extends GetxService {
  static UnlockService get to {
    if (!Get.isRegistered<UnlockService>()) {
      Get.put<UnlockService>(UnlockService(), permanent: true);
    }
    return Get.find<UnlockService>();
  }

  static void init() {
    if (!Get.isRegistered<UnlockService>()) {
      Get.put<UnlockService>(UnlockService(), permanent: true);
    }
  }

  // Pre-defined Subscription Plans
  static const List<SubscriptionPlan> subscriptionPlans = [
    SubscriptionPlan(
      period: SubscriptionPeriod.weekly,
      title: 'Weekly Pass',
      durationLabel: '7 Days',
      price: 14.99,
      priceFormatted: '\$14.99',
      periodDescription: 'Billed weekly • Cancel anytime',
      discountBadge: null,
    ),
    SubscriptionPlan(
      period: SubscriptionPeriod.monthly,
      title: 'Monthly Pass',
      durationLabel: '1 Month',
      price: 29.99,
      priceFormatted: '\$29.99',
      periodDescription: 'Billed monthly • Save 50%',
      discountBadge: 'SAVE 50%',
      isPopular: true,
    ),
    SubscriptionPlan(
      period: SubscriptionPeriod.yearly,
      title: 'Annual VIP',
      durationLabel: '1 Year',
      price: 149.99,
      priceFormatted: '\$149.99',
      periodDescription: 'Billed annually • \$12.50 / mo',
      discountBadge: 'BEST VALUE • SAVE 80%',
      isBestValue: true,
    ),
  ];

  // Pre-defined Default Coin Packages
  static const List<CoinPackage> coinPackages = [
    CoinPackage(
      id: 'coins_100',
      coins: 100,
      bonusCoins: 0,
      price: 2.49,
      priceFormatted: '\$2.49',
      rcProductId: 'dramapop_coins_100',
    ),
    CoinPackage(
      id: 'coins_250',
      coins: 200,
      bonusCoins: 50,
      price: 4.99,
      priceFormatted: '\$4.99',
      rcProductId: 'dramapop_coins_250',
    ),
    CoinPackage(
      id: 'coins_550',
      coins: 400,
      bonusCoins: 150,
      price: 9.99,
      priceFormatted: '\$9.99',
      isPopular: true,
      rcProductId: 'dramapop_coins_550',
    ),
    CoinPackage(
      id: 'coins_1200',
      coins: 800,
      bonusCoins: 400,
      price: 19.99,
      priceFormatted: '\$19.99',
      rcProductId: 'dramapop_coins_1200',
    ),
    CoinPackage(
      id: 'coins_3000',
      coins: 2000,
      bonusCoins: 1000,
      price: 49.99,
      priceFormatted: '\$49.99',
      isBestValue: true,
      rcProductId: 'dramapop_coins_3000',
    ),
  ];

  static const String _keyUserCoins = 'dramapop_user_coins_v1';
  static const String _keyUserPurchasedCoins = 'dramapop_user_purchased_coins_v1';
  static const String _keyUserUsedCoins = 'dramapop_user_used_coins_v1';
  static const String _keyUnlockedKeys = 'dramapop_unlocked_keys_v1';
  static const String _keyDeviceId = 'dramapop_device_id_v1';

  final RxList<CoinPackage> dynamicCoinPackages = <CoinPackage>[].obs;
  String deviceId = '';
  SharedPreferences? _prefs;

  List<CoinPackage> get effectiveCoinPackages =>
      dynamicCoinPackages.isNotEmpty ? dynamicCoinPackages : coinPackages;

  @override
  void onInit() {
    super.onInit();
    _loadFromDisk();
    fetchDynamicCoinPackages();
  }

  Future<void> _loadFromDisk() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 1. Persistent Device ID (Survives across sessions)
      var savedId = _prefs?.getString(_keyDeviceId);
      if (savedId == null || savedId.isEmpty) {
        final rand = Random();
        savedId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(999999).toString().padLeft(6, '0')}';
        await _prefs?.setString(_keyDeviceId, savedId);
      }
      deviceId = savedId;
      MetaEventsService.to.setUserId(deviceId);
      FirebaseAnalyticsService.to.setUserId(deviceId);
      debugPrint('📱 Device ID initialized: $deviceId');

      // 2. Saved Coins Balance & Lifetime Metrics
      final savedCoins = _prefs?.getInt(_keyUserCoins);
      if (savedCoins != null && savedCoins >= 0) {
        userCoins.value = savedCoins;
      }
      final savedPurchased = _prefs?.getInt(_keyUserPurchasedCoins);
      if (savedPurchased != null && savedPurchased >= 0) {
        purchasedCoins.value = savedPurchased;
      }
      final savedUsed = _prefs?.getInt(_keyUserUsedCoins);
      if (savedUsed != null && savedUsed >= 0) {
        usedCoins.value = savedUsed;
      }

      // 3. Saved Unlocked Episode Keys
      final savedKeysList = _prefs?.getStringList(_keyUnlockedKeys);
      if (savedKeysList != null && savedKeysList.isNotEmpty) {
        _unlockedEpisodeKeys.assignAll(savedKeysList);
      }

      // 4. Check for any pending refund coin deductions from server
      await syncCoinsWithServer();
    } catch (e) {
      debugPrint('UnlockService: Error loading saved state: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      await _prefs?.setInt(_keyUserCoins, userCoins.value);
      await _prefs?.setInt(_keyUserPurchasedCoins, purchasedCoins.value);
      await _prefs?.setInt(_keyUserUsedCoins, usedCoins.value);
      await _prefs?.setStringList(_keyUnlockedKeys, _unlockedEpisodeKeys.toList());
    } catch (e) {
      debugPrint('UnlockService: Error saving state to disk: $e');
    }
  }

  // Server-Side Coin Protection & Refund Sync
  Future<void> syncCoinsWithServer() async {
    if (deviceId.isEmpty) return;
    try {
      final res = await ApiService.syncCoinBalance(
        deviceId: deviceId,
        currentCoins: userCoins.value,
        purchasedCoins: purchasedCoins.value,
        usedCoins: usedCoins.value,
      );

      if (res != null && res['hasDeductions'] == true) {
        final totalDeducted = (res['totalDeducted'] as num?)?.toInt() ?? 0;
        if (totalDeducted > 0) {
          final before = userCoins.value;
          userCoins.value = max(0, userCoins.value - totalDeducted);
          await _saveToDisk();

          debugPrint('🛡️ Server Protection: Deducted $totalDeducted coins from refund ($before -> ${userCoins.value})');

          Get.snackbar(
            'Coins Deducted',
            '$totalDeducted coins were deducted from your balance due to a refunded purchase.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF261338),
            colorText: const Color(0xFFFF4D8D),
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFFF4D8D)),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }
      }
    } catch (e) {
      debugPrint('UnlockService: Error syncing coins with server: $e');
    }
  }

  Future<void> fetchDynamicCoinPackages() async {
    try {
      final pkgs = await ApiService.getCoinPackages();
      if (pkgs.isNotEmpty) {
        dynamicCoinPackages.assignAll(pkgs);
        debugPrint('🪙 Loaded ${pkgs.length} coin packages dynamically from Admin Panel!');
        if (Get.isRegistered<RevenueCatService>()) {
          RevenueCatService.to.refreshOfferingsAndLocalPrices();
        }
      }
    } catch (e) {
      debugPrint('Note loading coin packages: $e');
    }
  }

  // Reactive State
  final RxInt userCoins = 0.obs; // Current available coins
  final RxInt purchasedCoins = 0.obs; // Total lifetime purchased coins
  final RxInt usedCoins = 0.obs; // Total lifetime used coins
  final Rx<SubscriptionPlan?> activeSubscription = Rx<SubscriptionPlan?>(null);
  final Rx<DateTime?> subscriptionExpiry = Rx<DateTime?>(null);
  final RxSet<String> _unlockedEpisodeKeys = <String>{}.obs;
  final RxSet<String> _unlockedSeriesIds = <String>{}.obs;
  final RxBool isGlobalVip = false.obs;

  bool get hasUnlimitedAccess {
    if (isGlobalVip.value) return true;
    if (activeSubscription.value != null && subscriptionExpiry.value != null) {
      if (DateTime.now().isBefore(subscriptionExpiry.value!)) {
        return true;
      }
    }
    return false;
  }

  bool isEpisodeUnlocked(String seriesId, int episodeNumber) {
    if (hasUnlimitedAccess) return true;
    if (_unlockedSeriesIds.contains(seriesId)) return true;
    return _unlockedEpisodeKeys.contains('${seriesId}_$episodeNumber');
  }

  bool unlockEpisodeWithCoins(String seriesId, int episodeNumber, {int coinPrice = 10, String seriesTitle = ''}) {
    if (isEpisodeUnlocked(seriesId, episodeNumber)) return true;

    if (userCoins.value < coinPrice) {
      return false;
    }

    userCoins.value -= coinPrice;
    usedCoins.value += coinPrice;
    _unlockedEpisodeKeys.add('${seriesId}_$episodeNumber');
    _saveToDisk();
    syncCoinsWithServer();

    // Track coins spent in Meta Ad Network
    MetaEventsService.to.logCoinsSpent(
      coinsSpent: coinPrice,
      dramaId: seriesId,
      dramaTitle: seriesTitle.isNotEmpty ? seriesTitle : seriesId,
      episodeNumber: episodeNumber,
    );

    // Track coins spent in Google Analytics
    FirebaseAnalyticsService.to.logCoinsSpent(
      coinsSpent: coinPrice,
      dramaId: seriesId,
      dramaTitle: seriesTitle.isNotEmpty ? seriesTitle : seriesId,
      episodeNumber: episodeNumber,
    );
    return true;
  }

  void unlockEpisodeDirect(String seriesId, int episodeNumber) {
    _unlockedEpisodeKeys.add('${seriesId}_$episodeNumber');
    _saveToDisk();
  }

  void unlockSeries(String seriesId, int totalEpisodes) {
    _unlockedSeriesIds.add(seriesId);
    for (int i = 1; i <= totalEpisodes; i++) {
      _unlockedEpisodeKeys.add('${seriesId}_$i');
    }
    _saveToDisk();
  }

  void buyCoins(CoinPackage package) {
    userCoins.value += package.totalCoins;
    purchasedCoins.value += package.totalCoins;
    _saveToDisk();
    syncCoinsWithServer();
    Get.snackbar(
      'Coins Added!',
      '+${package.totalCoins} coins have been added to your balance.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E1632),
      colorText: const Color(0xFFFFB800),
      icon: const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFB800)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void subscribe(SubscriptionPlan plan) {
    activeSubscription.value = plan;
    final now = DateTime.now();
    switch (plan.period) {
      case SubscriptionPeriod.weekly:
        subscriptionExpiry.value = now.add(const Duration(days: 7));
        break;
      case SubscriptionPeriod.monthly:
        subscriptionExpiry.value = now.add(const Duration(days: 30));
        break;
      case SubscriptionPeriod.yearly:
        subscriptionExpiry.value = now.add(const Duration(days: 365));
        break;
    }

    Get.snackbar(
      '👑 Unlimited Access Active',
      'You now have unlimited streaming across all drama episodes!',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E1632),
      colorText: const Color(0xFFFF4D8D),
      icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFF4D8D)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void restorePurchases() {
    syncCoinsWithServer();
    if (Get.context == null) return;
    if (hasUnlimitedAccess) {
      Get.snackbar(
        'Purchases Restored',
        'Your VIP subscription has been successfully restored!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1632),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } else {
      Get.snackbar(
        'No Purchase Found',
        'No active subscription or previous purchases were found for this account.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1632),
        colorText: Colors.white,
        icon: const Icon(Icons.info_outline_rounded, color: Color(0xFFFFB800)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }
}
