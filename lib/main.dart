import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/modules/feed/controllers/feed_controller.dart';
import 'app/data/services/security_service.dart';
import 'app/data/services/unlock_service.dart';
import 'app/data/services/revenue_cat_service.dart';
import 'app/data/services/meta_events_service.dart';
import 'app/data/services/firebase_analytics_service.dart';
import 'app/data/services/push_notification_service.dart';
import 'app/data/services/user_library_service.dart';
import 'app/data/services/app_review_service.dart';
import 'app/theme/app_theme.dart';

class DramaPopHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = DramaPopHttpOverrides();

  // Initialize Firebase (Push Notifications & Google Analytics)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAnalyticsService.init();
    PushNotificationService.init();
  } catch (e) {
    debugPrint('ℹ️ Firebase initialization note: $e');
  }

  // Enforce screenshot and screen recording prevention (Android & iOS)
  await SecurityService.enableScreenshotProtection();
  
  // Initialize unlock & subscription manager
  UnlockService.init();

  // Initialize cross-platform RevenueCat In-App Purchase service
  RevenueCatService.init();
  
  // Initialize Meta (Facebook) Ad Network & App Events Tracking
  MetaEventsService.init();

  // Initialize user library (Saved episodes, Watchlist, Watch progress)
  await UserLibraryService.init();
  
  // Initialize Apple & Google Play In-App Review System
  await AppReviewService.init();
  
  // Set immersive full-screen status and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0A14),
      systemNavigationBarDividerColor: Color(0xFF0D0A14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DramaPopApp());
}

class DramaPopApp extends StatelessWidget {
  const DramaPopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DramaPop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      routingCallback: (routing) {
        if (routing != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<FeedController>()) {
              final feed = Get.find<FeedController>();
              if (routing.current == Routes.ROOT) {
                feed.isDetailOpen.value = false;
                if (feed.isFeedActive) {
                  feed.resumeVideo();
                }
              } else if (routing.current != Routes.SPLASH) {
                feed.isDetailOpen.value = true;
                feed.pauseVideo();
              }
            }
          });
        }
      },
    );
  }
}
