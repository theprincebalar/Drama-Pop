import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class MetaEventsService extends GetxService {
  static MetaEventsService get to {
    if (!Get.isRegistered<MetaEventsService>()) {
      Get.put<MetaEventsService>(MetaEventsService(), permanent: true);
    }
    return Get.find<MetaEventsService>();
  }

  static void init() {
    if (!Get.isRegistered<MetaEventsService>()) {
      Get.put<MetaEventsService>(MetaEventsService(), permanent: true);
    }
  }

  static const String metaAppId = '1090576830489562';
  static const String metaClientToken = '82fb354e388eebf70c71a49b6950613c';

  final FacebookAppEvents _fb = FacebookAppEvents();
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    initMetaSdk();
  }

  Future<void> initMetaSdk() async {
    try {
      if (kIsWeb) {
        debugPrint('Meta App Events: Web platform skipped.');
        return;
      }

      // Handle iOS App Tracking Transparency (iOS 14.5+)
      if (Platform.isIOS) {
        try {
          final trackingStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
          if (trackingStatus == TrackingStatus.notDetermined) {
            // Wait a brief moment before prompting ATT dialog for best UX
            await Future.delayed(const Duration(milliseconds: 600));
            final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
            final isAuthorized = newStatus == TrackingStatus.authorized;
            await _fb.setAdvertiserTracking(enabled: isAuthorized);
            debugPrint('🎯 Meta ATT Authorization status: $newStatus (Advertiser Tracking: $isAuthorized)');
          } else {
            final isAuthorized = trackingStatus == TrackingStatus.authorized;
            await _fb.setAdvertiserTracking(enabled: isAuthorized);
            debugPrint('🎯 Meta ATT existing status: $trackingStatus (Advertiser Tracking: $isAuthorized)');
          }
        } catch (attError) {
          debugPrint('ℹ️ ATT Request note: $attError');
        }
      }

      // Auto log activate app
      await _fb.logEvent(name: 'fb_mobile_activate_app');
      isInitialized.value = true;
      debugPrint('🚀 Meta App Events SDK initialized for DramaPop (App ID: $metaAppId)');
    } catch (e) {
      debugPrint('ℹ️ Meta App Events init note: $e');
    }
  }

  /// Sets user ID for cross-device event attribution
  Future<void> setUserId(String userId) async {
    try {
      if (userId.isNotEmpty) {
        await _fb.setUserID(userId);
      }
    } catch (e) {
      debugPrint('Meta setUserID error: $e');
    }
  }

  /// Logs purchase of Coin Packages (In-App Purchase)
  Future<void> logCoinPurchase({
    required double amount,
    required String currency,
    required String packageId,
    required int coinsCount,
  }) async {
    try {
      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          'package_id': packageId,
          'coins_count': coinsCount,
          'item_type': 'coins_pack',
        },
      );
      debugPrint('📊 [Meta Event] Purchase (Coins): $amount $currency ($coinsCount coins)');
    } catch (e) {
      debugPrint('Meta logCoinPurchase error: $e');
    }
  }

  /// Logs VIP Subscription Purchase
  Future<void> logSubscriptionPurchase({
    required double amount,
    required String currency,
    required String planId,
    required String planName,
  }) async {
    try {
      await _fb.logPurchase(
        amount: amount,
        currency: currency,
        parameters: {
          'plan_id': planId,
          'plan_name': planName,
          'item_type': 'vip_subscription',
        },
      );
      
      // Also log standard Meta Subscribe event
      await _fb.logEvent(
        name: 'Subscribe',
        valueToSum: amount,
        parameters: {
          'fb_currency': currency,
          'fb_order_id': '${planId}_${DateTime.now().millisecondsSinceEpoch}',
          'subscription_period': planId,
        },
      );
      debugPrint('📊 [Meta Event] Subscribe: $amount $currency ($planName)');
    } catch (e) {
      debugPrint('Meta logSubscriptionPurchase error: $e');
    }
  }

  /// Logs Initiated Checkout when opening Coin Store / Subscription screen
  Future<void> logInitiatedCheckout({
    required double amount,
    required String currency,
    required String contentId,
    required String contentType,
  }) async {
    try {
      await _fb.logInitiatedCheckout(
        totalPrice: amount,
        currency: currency,
        contentId: contentId,
        contentType: contentType,
      );
      debugPrint('📊 [Meta Event] InitiatedCheckout: $contentId ($amount $currency)');
    } catch (e) {
      debugPrint('Meta logInitiatedCheckout error: $e');
    }
  }

  /// Logs when a user views a drama or episode
  Future<void> logViewDrama({
    required String dramaId,
    required String dramaTitle,
    int? episodeNumber,
  }) async {
    try {
      await _fb.logViewContent(
        id: dramaId,
        type: 'drama_series',
        currency: 'USD',
        price: 0.0,
      );
      await _fb.logEvent(
        name: 'fb_mobile_content_view',
        parameters: {
          'fb_content_id': dramaId,
          'fb_content_type': 'drama_series',
          'drama_title': dramaTitle,
          'episode_number': episodeNumber ?? 1,
        },
      );
      debugPrint('📊 [Meta Event] ViewContent: $dramaTitle (Ep: ${episodeNumber ?? 1})');
    } catch (e) {
      debugPrint('Meta logViewDrama error: $e');
    }
  }

  /// Logs when coins are spent to unlock an episode
  Future<void> logCoinsSpent({
    required int coinsSpent,
    required String dramaId,
    required String dramaTitle,
    required int episodeNumber,
  }) async {
    try {
      await _fb.logEvent(
        name: 'fb_mobile_spent_credits',
        valueToSum: coinsSpent.toDouble(),
        parameters: {
          'drama_id': dramaId,
          'drama_title': dramaTitle,
          'episode_number': episodeNumber,
          'coins_spent': coinsSpent,
        },
      );
      debugPrint('📊 [Meta Event] SpentCredits: $coinsSpent coins for $dramaTitle Ep $episodeNumber');
    } catch (e) {
      debugPrint('Meta logCoinsSpent error: $e');
    }
  }

  /// Logs when a user adds drama to Watchlist
  Future<void> logAddToWatchlist({
    required String dramaId,
    required String dramaTitle,
  }) async {
    try {
      await _fb.logAddToWishlist(
        id: dramaId,
        type: 'drama_series',
        currency: 'USD',
        price: 0.0,
      );
      debugPrint('📊 [Meta Event] AddToWishlist: $dramaTitle ($dramaId)');
    } catch (e) {
      debugPrint('Meta logAddToWatchlist error: $e');
    }
  }
}
