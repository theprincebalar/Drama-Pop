import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dramapop/app/data/services/unlock_service.dart';
import 'package:dramapop/app/data/services/app_review_service.dart';
import 'package:dramapop/app/data/services/revenue_cat_service.dart';
import 'package:dramapop/app/data/services/user_library_service.dart';
import 'package:dramapop/app/routes/app_pages.dart';

Future<void> setupTestEnvironment({
  bool isVip = false,
  int coins = 100,
  bool isAndroidInReview = false,
  bool isIosInReview = false,
}) async {
  Get.testMode = true;

  SharedPreferences.setMockInitialValues({
    'user_coins_balance': coins,
    'is_global_vip': isVip,
    'dramapop_completed_episodes_count_v1': 0,
    'dramapop_last_prompt_episodes_count_v1': 0,
    'dramapop_has_user_rated_v1': false,
  });

  Get.reset();
  Get.testMode = true;

  final unlockService = UnlockService();
  unlockService.isGlobalVip.value = isVip;
  unlockService.userCoins.value = coins;
  Get.put<UnlockService>(unlockService, permanent: true);

  final appReviewService = AppReviewService();
  appReviewService.isAndroidInReview.value = isAndroidInReview;
  appReviewService.isIosInReview.value = isIosInReview;
  Get.put<AppReviewService>(appReviewService, permanent: true);

  final revenueCatService = RevenueCatService();
  Get.put<RevenueCatService>(revenueCatService, permanent: true);

  final userLibraryService = UserLibraryService();
  Get.put<UserLibraryService>(userLibraryService, permanent: true);
}

Widget createTestApp(Widget child, {TargetPlatform platform = TargetPlatform.android}) {
  return GetMaterialApp(
    theme: ThemeData(
      platform: platform,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0817),
    ),
    home: child,
    getPages: AppPages.routes,
  );
}
