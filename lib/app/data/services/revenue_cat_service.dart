import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:get/get.dart';
import 'unlock_service.dart';
import 'meta_events_service.dart';
import 'firebase_analytics_service.dart';

class RevenueCatService extends GetxService {
  static RevenueCatService get to {
    if (!Get.isRegistered<RevenueCatService>()) {
      Get.put<RevenueCatService>(RevenueCatService(), permanent: true);
    }
    return Get.find<RevenueCatService>();
  }

  static void init() {
    if (!Get.isRegistered<RevenueCatService>()) {
      Get.put<RevenueCatService>(RevenueCatService(), permanent: true);
    }
  }

  // Production RevenueCat Public API Keys
  static const String _googleApiKey = 'goog_JANIrTZpiEtkEgcFHNGVQKAIlJj';
  static const String _appleApiKey = 'appl_shqynyCMxUdmvFzfTUhFZgVxNYf';
  
  // Entitlement Identifiers (including user's live RevenueCat entitlement)
  static const String entitlementHubPro = 'dramapop_dramas_series_hub_pro';
  static const String entitlementUnlimited = 'unlimited_access';
  static const String entitlementVip = 'vip_access';

  final RxBool isConfigured = false.obs;
  final Rx<CustomerInfo?> customerInfo = Rx<CustomerInfo?>(null);
  final Rx<Offerings?> offerings = Rx<Offerings?>(null);

  // Reactive Localized Prices in User's Local Store Currency
  final RxMap<SubscriptionPeriod, String> localizedSubscriptionPrices = <SubscriptionPeriod, String>{}.obs;
  final RxMap<String, String> localizedCoinPrices = <String, String>{}.obs;
  final RxMap<String, StoreProduct> storeProductsMap = <String, StoreProduct>{}.obs;
  final RxMap<SubscriptionPeriod, Package> subscriptionPackagesMap = <SubscriptionPeriod, Package>{}.obs;

  @override
  void onInit() {
    super.onInit();
    initRevenueCat();
  }

  Future<void> initRevenueCat() async {
    try {
      if (kIsWeb) {
        debugPrint('RevenueCat is not supported on web platforms.');
        return;
      }

      final apiKey = Platform.isIOS ? _appleApiKey : _googleApiKey;
      
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final devId = UnlockService.to.deviceId;
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = devId.isNotEmpty ? devId : null;
      await Purchases.configure(configuration);
      isConfigured.value = true;
      debugPrint('💳 RevenueCat initialized successfully for ${Platform.operatingSystem} (User: ${devId.isNotEmpty ? devId : "anonymous"})');

      // Listen for real-time customer info & entitlement updates
      Purchases.addCustomerInfoUpdateListener((info) {
        customerInfo.value = info;
        _syncEntitlements(info);
      });

      // Fetch initial customer info
      final info = await Purchases.getCustomerInfo();
      customerInfo.value = info;
      _syncEntitlements(info);

      // Fetch offerings & local prices automatically in user's currency
      await refreshOfferingsAndLocalPrices();
    } catch (e) {
      debugPrint('ℹ️ RevenueCat initialization note: $e');
    }
  }

  void _syncEntitlements(CustomerInfo info) {
    final activeEntitlements = info.entitlements.active;
    final hasActiveUnlimited = activeEntitlements.containsKey(entitlementHubPro) ||
        activeEntitlements.containsKey(entitlementUnlimited) ||
        activeEntitlements.containsKey(entitlementVip) ||
        activeEntitlements.isNotEmpty;

    UnlockService.to.isGlobalVip.value = hasActiveUnlimited;

    if (hasActiveUnlimited && activeEntitlements.isNotEmpty) {
      final activeEntitlement = activeEntitlements.values.first;
      final expStr = activeEntitlement.expirationDate;
      if (expStr != null) {
        final expDate = DateTime.tryParse(expStr);
        if (expDate != null) {
          UnlockService.to.subscriptionExpiry.value = expDate;
        }
      }

      // Sync active plan object
      final prodId = activeEntitlement.productIdentifier.toLowerCase();
      if (prodId.contains('weekly') || prodId.contains('week')) {
        UnlockService.to.activeSubscription.value = UnlockService.subscriptionPlans.firstWhere(
          (p) => p.period == SubscriptionPeriod.weekly,
          orElse: () => UnlockService.subscriptionPlans[0],
        );
      } else if (prodId.contains('yearly') || prodId.contains('annual') || prodId.contains('year')) {
        UnlockService.to.activeSubscription.value = UnlockService.subscriptionPlans.firstWhere(
          (p) => p.period == SubscriptionPeriod.yearly,
          orElse: () => UnlockService.subscriptionPlans[2],
        );
      } else {
        UnlockService.to.activeSubscription.value = UnlockService.subscriptionPlans.firstWhere(
          (p) => p.period == SubscriptionPeriod.monthly,
          orElse: () => UnlockService.subscriptionPlans[1],
        );
      }
    } else if (isConfigured.value) {
      UnlockService.to.activeSubscription.value = null;
      UnlockService.to.subscriptionExpiry.value = null;
    }
  }

  // Automatically fetches prices in the user's localized currency from Google Play / Apple App Store
  Future<void> refreshOfferingsAndLocalPrices() async {
    try {
      if (!isConfigured.value) return;

      // 1. Fetch Subscription Offerings in User's Local Currency
      final off = await Purchases.getOfferings();
      offerings.value = off;

      if (off.current != null) {
        final currentOffering = off.current!;
        if (currentOffering.weekly != null) {
          final p = currentOffering.weekly!;
          localizedSubscriptionPrices[SubscriptionPeriod.weekly] = p.storeProduct.priceString;
          subscriptionPackagesMap[SubscriptionPeriod.weekly] = p;
          debugPrint('🪙 Localized Weekly Subscription: ${p.storeProduct.priceString} (${p.storeProduct.currencyCode})');
        }
        if (currentOffering.monthly != null) {
          final p = currentOffering.monthly!;
          localizedSubscriptionPrices[SubscriptionPeriod.monthly] = p.storeProduct.priceString;
          subscriptionPackagesMap[SubscriptionPeriod.monthly] = p;
          debugPrint('🪙 Localized Monthly Subscription: ${p.storeProduct.priceString} (${p.storeProduct.currencyCode})');
        }
        if (currentOffering.annual != null) {
          final p = currentOffering.annual!;
          localizedSubscriptionPrices[SubscriptionPeriod.yearly] = p.storeProduct.priceString;
          subscriptionPackagesMap[SubscriptionPeriod.yearly] = p;
          debugPrint('🪙 Localized Annual Subscription: ${p.storeProduct.priceString} (${p.storeProduct.currencyCode})');
        }

        for (final pkg in currentOffering.availablePackages) {
          if (pkg.packageType == PackageType.weekly && !localizedSubscriptionPrices.containsKey(SubscriptionPeriod.weekly)) {
            localizedSubscriptionPrices[SubscriptionPeriod.weekly] = pkg.storeProduct.priceString;
            subscriptionPackagesMap[SubscriptionPeriod.weekly] = pkg;
          } else if (pkg.packageType == PackageType.monthly && !localizedSubscriptionPrices.containsKey(SubscriptionPeriod.monthly)) {
            localizedSubscriptionPrices[SubscriptionPeriod.monthly] = pkg.storeProduct.priceString;
            subscriptionPackagesMap[SubscriptionPeriod.monthly] = pkg;
          } else if (pkg.packageType == PackageType.annual && !localizedSubscriptionPrices.containsKey(SubscriptionPeriod.yearly)) {
            localizedSubscriptionPrices[SubscriptionPeriod.yearly] = pkg.storeProduct.priceString;
            subscriptionPackagesMap[SubscriptionPeriod.yearly] = pkg;
          }
        }
      }

      // Also index all packages across all offerings
      for (final offEntry in (off.all.values)) {
        for (final pkg in offEntry.availablePackages) {
          if (pkg.packageType == PackageType.weekly && !subscriptionPackagesMap.containsKey(SubscriptionPeriod.weekly)) {
            subscriptionPackagesMap[SubscriptionPeriod.weekly] = pkg;
            localizedSubscriptionPrices[SubscriptionPeriod.weekly] = pkg.storeProduct.priceString;
          } else if (pkg.packageType == PackageType.monthly && !subscriptionPackagesMap.containsKey(SubscriptionPeriod.monthly)) {
            subscriptionPackagesMap[SubscriptionPeriod.monthly] = pkg;
            localizedSubscriptionPrices[SubscriptionPeriod.monthly] = pkg.storeProduct.priceString;
          } else if (pkg.packageType == PackageType.annual && !subscriptionPackagesMap.containsKey(SubscriptionPeriod.yearly)) {
            subscriptionPackagesMap[SubscriptionPeriod.yearly] = pkg;
            localizedSubscriptionPrices[SubscriptionPeriod.yearly] = pkg.storeProduct.priceString;
          }
        }
      }

      // 2. Fetch Non-Subscription Coin Products in User's Local Currency
      final allCoinPackages = UnlockService.to.effectiveCoinPackages;
      final Set<String> productIdsToFetch = {};
      for (final coinPkg in allCoinPackages) {
        if (coinPkg.rcProductId.isNotEmpty) productIdsToFetch.add(coinPkg.rcProductId);
        if (coinPkg.id.isNotEmpty) productIdsToFetch.add(coinPkg.id);
        productIdsToFetch.add('dramapop_${coinPkg.id}');
        productIdsToFetch.add('coins_${coinPkg.totalCoins}');
        productIdsToFetch.add('dramapop_coins_${coinPkg.totalCoins}');
      }

      if (productIdsToFetch.isNotEmpty) {
        List<StoreProduct> products = [];
        try {
          products = await Purchases.getProducts(
            productIdsToFetch.toList(),
            productCategory: ProductCategory.nonSubscription,
          );
        } catch (_) {
          products = await Purchases.getProducts(productIdsToFetch.toList());
        }

        for (final sp in products) {
          storeProductsMap[sp.identifier] = sp;
          localizedCoinPrices[sp.identifier] = sp.priceString;
          debugPrint('🪙 Localized Coin Product [${sp.identifier}]: ${sp.priceString} (${sp.currencyCode})');
        }
      }
    } catch (e) {
      debugPrint('ℹ️ RevenueCat local prices note: $e');
    }
  }

  // Returns plan price in user's local currency (e.g. ₹499.00, €4.99, $4.99)
  String getLocalizedSubscriptionPrice(SubscriptionPlan plan) {
    if (localizedSubscriptionPrices.containsKey(plan.period)) {
      return localizedSubscriptionPrices[plan.period]!;
    }
    return plan.priceFormatted;
  }

  // Returns coin package price in user's local currency (e.g. ₹89.00, €0.99, $0.99)
  String getLocalizedCoinPrice(CoinPackage pkg) {
    final candidateKeys = [
      pkg.rcProductId,
      pkg.id,
      'dramapop_${pkg.id}',
      'dramapop_coins_${pkg.totalCoins}',
      'coins_${pkg.totalCoins}',
    ];

    for (final key in candidateKeys) {
      if (key.isNotEmpty && localizedCoinPrices.containsKey(key)) {
        return localizedCoinPrices[key]!;
      }
      if (key.isNotEmpty && storeProductsMap.containsKey(key)) {
        return storeProductsMap[key]!.priceString;
      }
    }

    return pkg.priceFormatted;
  }

  // Handles real in-app subscription purchase through Google Play / Apple App Store
  Future<bool> purchaseSubscriptionPackage(SubscriptionPlan plan) async {
    try {
      if (isConfigured.value) {
        Package? targetPackage = subscriptionPackagesMap[plan.period];
        if (targetPackage == null && offerings.value?.current != null) {
          final currentOffering = offerings.value!.current!;
          if (plan.period == SubscriptionPeriod.weekly) {
            targetPackage = currentOffering.weekly;
          } else if (plan.period == SubscriptionPeriod.monthly) {
            targetPackage = currentOffering.monthly;
          } else if (plan.period == SubscriptionPeriod.yearly) {
            targetPackage = currentOffering.annual;
          }
        }

        if (targetPackage != null) {
          final res = await Purchases.purchase(PurchaseParams.package(targetPackage));
          customerInfo.value = res.customerInfo;
          _syncEntitlements(res.customerInfo);
          UnlockService.to.subscribe(plan);
          
          // Track purchase in Meta Ad Network
          MetaEventsService.to.logSubscriptionPurchase(
            amount: targetPackage.storeProduct.price,
            currency: targetPackage.storeProduct.currencyCode,
            planId: plan.period.name,
            planName: plan.title,
          );

          // Track purchase in Google Analytics
          FirebaseAnalyticsService.to.logSubscriptionPurchase(
            amount: targetPackage.storeProduct.price,
            currency: targetPackage.storeProduct.currencyCode,
            planId: plan.period.name,
            planName: plan.title,
          );
          return true;
        }
      }

      Get.snackbar(
        'Purchase Unavailable',
        'Store in-app purchases are not ready yet. Please try again shortly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1035),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D8D)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } catch (e) {
      debugPrint('Subscription purchase error: $e');
      final isCancelled = e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('user_cancelled');
      if (isCancelled) {
        Get.snackbar(
          'Purchase Cancelled',
          'The subscription purchase was cancelled.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1035),
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Purchase Failed',
          'Payment could not be processed. Please check your store payment method and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1035),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D8D)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
      return false;
    }
  }

  // Handles real in-app consumable coin purchase through Google Play / Apple App Store
  Future<bool> purchaseCoinPackage(CoinPackage coinPkg) async {
    try {
      if (isConfigured.value) {
        StoreProduct? targetProduct;
        final candidateKeys = [
          coinPkg.rcProductId,
          coinPkg.id,
          'dramapop_${coinPkg.id}',
          'dramapop_coins_${coinPkg.totalCoins}',
          'coins_${coinPkg.totalCoins}',
        ];

        for (final k in candidateKeys) {
          if (k.isNotEmpty && storeProductsMap.containsKey(k)) {
            targetProduct = storeProductsMap[k];
            break;
          }
        }

        if (targetProduct == null) {
          final candidateIds = [
            coinPkg.rcProductId,
            coinPkg.id,
            'dramapop_${coinPkg.id}',
            'coins_${coinPkg.totalCoins}',
          ].where((s) => s.isNotEmpty).toList();

          try {
            final products = await Purchases.getProducts(
              candidateIds,
              productCategory: ProductCategory.nonSubscription,
            );
            if (products.isNotEmpty) {
              targetProduct = products.first;
              storeProductsMap[targetProduct.identifier] = targetProduct;
            }
          } catch (_) {
            try {
              final products = await Purchases.getProducts(candidateIds);
              if (products.isNotEmpty) {
                targetProduct = products.first;
                storeProductsMap[targetProduct.identifier] = targetProduct;
              }
            } catch (_) {}
          }
        }

        if (targetProduct != null) {
          final res = await Purchases.purchase(PurchaseParams.storeProduct(targetProduct));
          customerInfo.value = res.customerInfo;
          UnlockService.to.buyCoins(coinPkg);

          // Track purchase in Meta Ad Network
          MetaEventsService.to.logCoinPurchase(
            amount: targetProduct.price,
            currency: targetProduct.currencyCode,
            packageId: coinPkg.id,
            coinsCount: coinPkg.totalCoins,
          );

          // Track purchase in Google Analytics
          FirebaseAnalyticsService.to.logCoinPurchase(
            amount: targetProduct.price,
            currency: targetProduct.currencyCode,
            packageId: coinPkg.id,
            coinsCount: coinPkg.totalCoins,
          );
          return true;
        }
      }

      Get.snackbar(
        'Purchase Unavailable',
        'Store in-app products are not ready yet. Please try again shortly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1035),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D8D)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return false;
    } catch (e) {
      debugPrint('Coin purchase note: $e');
      final isCancelled = e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('user_cancelled');
      if (isCancelled) {
        Get.snackbar(
          'Purchase Cancelled',
          'The coin purchase was cancelled.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1035),
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          'Purchase Failed',
          'Payment could not be processed. Please check your store payment method and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1035),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4D8D)),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
      return false;
    }
  }

  // Restore purchases across devices
  Future<void> restorePurchases() async {
    try {
      if (isConfigured.value) {
        final res = await Purchases.restorePurchases();
        customerInfo.value = res;
        _syncEntitlements(res);

        final activeEntitlements = res.entitlements.active;
        final hasActiveUnlimited = activeEntitlements.containsKey(entitlementHubPro) ||
            activeEntitlements.containsKey(entitlementUnlimited) ||
            activeEntitlements.containsKey(entitlementVip) ||
            activeEntitlements.isNotEmpty ||
            UnlockService.to.isGlobalVip.value;

        if (Get.context != null) {
          if (hasActiveUnlimited) {
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
        UnlockService.to.syncCoinsWithServer();
        return;
      }

      UnlockService.to.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases note: $e');
      UnlockService.to.restorePurchases();
    }
  }
}
