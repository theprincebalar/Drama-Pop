import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsService extends GetxService {
  static FirebaseAnalyticsService get to {
    if (!Get.isRegistered<FirebaseAnalyticsService>()) {
      Get.put<FirebaseAnalyticsService>(FirebaseAnalyticsService(), permanent: true);
    }
    return Get.find<FirebaseAnalyticsService>();
  }

  static void init() {
    if (!Get.isRegistered<FirebaseAnalyticsService>()) {
      Get.put<FirebaseAnalyticsService>(FirebaseAnalyticsService(), permanent: true);
    }
  }

  FirebaseAnalytics? _analytics;
  final RxBool isInitialized = false.obs;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics ?? FirebaseAnalytics.instance);

  @override
  void onInit() {
    super.onInit();
    initAnalytics();
  }

  Future<void> initAnalytics() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
      await _analytics?.logAppOpen();
      isInitialized.value = true;
      debugPrint('📈 Google Analytics initialized successfully for DramaPop');
    } catch (e) {
      debugPrint('ℹ️ Google Analytics init note: $e');
    }
  }

  /// Set User ID for cross-platform Analytics tracking
  Future<void> setUserId(String userId) async {
    try {
      if (userId.isNotEmpty) {
        await _analytics?.setUserId(id: userId);
      }
    } catch (e) {
      debugPrint('Google Analytics setUserId error: $e');
    }
  }

  /// Set User Properties (e.g. is_vip, coin_tier)
  Future<void> setUserProperty({required String name, required String value}) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Google Analytics setUserProperty error: $e');
    }
  }

  /// Track E-commerce Coin Package Purchase
  Future<void> logCoinPurchase({
    required double amount,
    required String currency,
    required String packageId,
    required int coinsCount,
  }) async {
    try {
      await _analytics?.logPurchase(
        value: amount,
        currency: currency,
        transactionId: 'rc_coin_${packageId}_${DateTime.now().millisecondsSinceEpoch}',
        items: [
          AnalyticsEventItem(
            itemId: packageId,
            itemName: '$coinsCount Coins Package',
            itemCategory: 'in_app_currency',
            price: amount,
            quantity: 1,
          ),
        ],
      );
      debugPrint('📈 [Google Analytics] Purchase (Coins): $amount $currency ($packageId)');
    } catch (e) {
      debugPrint('Google Analytics logCoinPurchase error: $e');
    }
  }

  /// Track VIP Subscription Purchase
  Future<void> logSubscriptionPurchase({
    required double amount,
    required String currency,
    required String planId,
    required String planName,
  }) async {
    try {
      await _analytics?.logPurchase(
        value: amount,
        currency: currency,
        transactionId: 'rc_sub_${planId}_${DateTime.now().millisecondsSinceEpoch}',
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: planName,
            itemCategory: 'vip_subscription',
            price: amount,
            quantity: 1,
          ),
        ],
      );

      // Also log custom subscribe event
      await _analytics?.logEvent(
        name: 'subscribe',
        parameters: {
          'plan_id': planId,
          'plan_name': planName,
          'value': amount,
          'currency': currency,
        },
      );
      debugPrint('📈 [Google Analytics] Subscribe: $amount $currency ($planName)');
    } catch (e) {
      debugPrint('Google Analytics logSubscriptionPurchase error: $e');
    }
  }

  /// Track Begin Checkout
  Future<void> logBeginCheckout({
    required double amount,
    required String currency,
    required String itemId,
    required String itemName,
  }) async {
    try {
      await _analytics?.logBeginCheckout(
        value: amount,
        currency: currency,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            price: amount,
            quantity: 1,
          ),
        ],
      );
      debugPrint('📈 [Google Analytics] Begin Checkout: $itemId ($amount $currency)');
    } catch (e) {
      debugPrint('Google Analytics logBeginCheckout error: $e');
    }
  }

  /// Track Drama View (View Item)
  Future<void> logViewDrama({
    required String dramaId,
    required String dramaTitle,
    int? episodeNumber,
  }) async {
    try {
      await _analytics?.logViewItem(
        currency: 'USD',
        value: 0.0,
        items: [
          AnalyticsEventItem(
            itemId: dramaId,
            itemName: dramaTitle,
            itemCategory: 'drama_series',
            itemVariant: 'Episode ${episodeNumber ?? 1}',
          ),
        ],
      );
      debugPrint('📈 [Google Analytics] ViewItem: $dramaTitle (Ep: ${episodeNumber ?? 1})');
    } catch (e) {
      debugPrint('Google Analytics logViewDrama error: $e');
    }
  }

  /// Track Virtual Currency (Coins) Spent
  Future<void> logCoinsSpent({
    required int coinsSpent,
    required String dramaId,
    required String dramaTitle,
    required int episodeNumber,
  }) async {
    try {
      await _analytics?.logSpendVirtualCurrency(
        itemName: '$dramaTitle (Episode $episodeNumber)',
        virtualCurrencyName: 'Coins',
        value: coinsSpent.toDouble(),
      );
      debugPrint('📈 [Google Analytics] SpendVirtualCurrency: $coinsSpent coins on $dramaTitle Ep $episodeNumber');
    } catch (e) {
      debugPrint('Google Analytics logCoinsSpent error: $e');
    }
  }

  /// Track Add to Wishlist / Watchlist
  Future<void> logAddToWatchlist({
    required String dramaId,
    required String dramaTitle,
  }) async {
    try {
      await _analytics?.logAddToWishlist(
        items: [
          AnalyticsEventItem(
            itemId: dramaId,
            itemName: dramaTitle,
            itemCategory: 'drama_series',
          ),
        ],
      );
      debugPrint('📈 [Google Analytics] AddToWishlist: $dramaTitle');
    } catch (e) {
      debugPrint('Google Analytics logAddToWatchlist error: $e');
    }
  }

  /// Track Search Query
  Future<void> logSearch(String query) async {
    try {
      if (query.isNotEmpty) {
        await _analytics?.logSearch(searchTerm: query);
        debugPrint('📈 [Google Analytics] Search: $query');
      }
    } catch (e) {
      debugPrint('Google Analytics logSearch error: $e');
    }
  }

  /// Track Drama Share
  Future<void> logShare({required String dramaId, required String dramaTitle}) async {
    try {
      await _analytics?.logShare(
        contentType: 'drama_series',
        itemId: dramaId,
        method: 'system_share',
      );
      debugPrint('📈 [Google Analytics] Share: $dramaTitle');
    } catch (e) {
      debugPrint('Google Analytics logShare error: $e');
    }
  }

  /// Track In-App Review Prompt & Trigger
  Future<void> logAppReviewTriggered({required String platform, required int episodesCompleted}) async {
    try {
      await _analytics?.logEvent(
        name: 'app_review_triggered',
        parameters: {
          'platform': platform,
          'episodes_completed': episodesCompleted,
        },
      );
      debugPrint('📈 [Google Analytics] App Review Triggered: $platform ($episodesCompleted eps)');
    } catch (e) {
      debugPrint('Google Analytics logAppReviewTriggered error: $e');
    }
  }

  /// Generic Custom Event Logging
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Google Analytics logEvent ($name) error: $e');
    }
  }
}
