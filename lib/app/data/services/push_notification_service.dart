import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../../routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Handling background message: ${message.messageId} (${message.notification?.title})');
}

class PushNotificationService extends GetxService {
  static PushNotificationService get to {
    if (!Get.isRegistered<PushNotificationService>()) {
      Get.put<PushNotificationService>(PushNotificationService(), permanent: true);
    }
    return Get.find<PushNotificationService>();
  }

  static void init() {
    if (!Get.isRegistered<PushNotificationService>()) {
      Get.put<PushNotificationService>(PushNotificationService(), permanent: true);
    }
  }

  FirebaseMessaging? _messaging;
  final RxString fcmToken = ''.obs;
  final RxBool hasPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    initNotifications();
  }

  Future<void> initNotifications() async {
    try {
      if (kIsWeb) {
        debugPrint('FCM: Web platform skipped.');
        return;
      }

      _messaging = FirebaseMessaging.instance;

      // 1. Request Push Notification permissions (iOS & Android 13+)
      final settings = await _messaging?.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      hasPermission.value = settings?.authorizationStatus == AuthorizationStatus.authorized ||
          settings?.authorizationStatus == AuthorizationStatus.provisional;
      debugPrint('🔔 Push Notification Permission status: ${settings?.authorizationStatus}');

      // 2. Set foreground notification presentation options for iOS
      await _messaging?.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Retrieve FCM Device Token
      try {
        final token = await _messaging?.getToken();
        if (token != null) {
          fcmToken.value = token;
          debugPrint('🔑 FCM Device Token: $token');
        }
      } catch (tokenErr) {
        debugPrint('ℹ️ FCM token fetch note: $tokenErr');
      }

      // Listen for token refresh
      _messaging?.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        debugPrint('🔑 FCM Token Refreshed: $newToken');
      });

      // 5. Subscribe to global notification topics
      await _subscribeToTopics();

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 7. Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // 8. Check if app was opened from terminated state via a notification
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationClick(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('ℹ️ PushNotificationService init note: $e');
    }
  }

  Future<void> _subscribeToTopics() async {
    try {
      await _messaging?.subscribeToTopic('all_users');
      await _messaging?.subscribeToTopic('new_dramas');
      await _messaging?.subscribeToTopic('promotions');
      debugPrint('📡 Subscribed to notification topics (all_users, new_dramas, promotions)');
    } catch (e) {
      debugPrint('Note subscribing to topics: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 
                  message.data['title']?.toString() ?? 
                  'DramaPop';
    final body = message.notification?.body ?? 
                 message.data['body']?.toString() ?? 
                 message.data['message']?.toString() ?? 
                 '';

    if (title.isNotEmpty || body.isNotEmpty) {
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E1035).withValues(alpha: 0.95),
        colorText: Colors.white,
        icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF4D8D)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        onTap: (_) => _handleNotificationClick(message),
      );
    }
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    try {
      final data = message.data;
      debugPrint('👆 User tapped notification with data: $data');

      final seriesId = data['series_id'] ?? data['drama_id'] ?? data['id'];
      final route = data['route'];

      if (seriesId != null && seriesId.toString().isNotEmpty) {
        final catalog = await ApiService.loadBundledCatalog();
        final series = catalog.firstWhereOrNull((s) => s.id == seriesId.toString());
        if (series != null) {
          Get.toNamed(Routes.DETAIL, arguments: series);
          return;
        }
      }

      if (route != null && route.toString().isNotEmpty) {
        Get.toNamed(route.toString());
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
  }
}
