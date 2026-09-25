import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dramapop/app/modules/home/views/home_view.dart';
import 'package:dramapop/app/modules/home/controllers/home_controller.dart';
import 'package:dramapop/app/modules/paywall/views/subscription_view.dart';
import 'package:dramapop/app/modules/paywall/views/coin_store_view.dart';
import 'package:dramapop/app/modules/watchlist/views/watchlist_view.dart';
import 'package:dramapop/app/modules/watchlist/controllers/watchlist_controller.dart';
import 'package:dramapop/app/modules/detail/views/detail_view.dart';
import 'package:dramapop/app/modules/detail/controllers/detail_controller.dart';
import 'package:dramapop/app/data/models/series_model.dart';
import 'package:dramapop/app/data/models/episode_model.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  final outDir = Directory(r'E:\DramaPop\play_store_assets\raw_screenshots');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  Future<void> saveWidgetImage(
    WidgetTester tester,
    GlobalKey key,
    String filename,
  ) async {
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          File('${outDir.path}/$filename').writeAsBytesSync(pngBytes);
          // ignore: avoid_print
          print('[OK] Saved screenshot: $filename (${image.width}x${image.height})');
        }
      }
    });
  }

  testWidgets('Capture Home Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await setupTestEnvironment(isVip: false, coins: 500);
    Get.put<HomeController>(HomeController());

    final key = GlobalKey();
    await tester.pumpWidget(
      createTestApp(
        RepaintBoundary(
          key: key,
          child: const HomeView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await saveWidgetImage(tester, key, 'screen_01_home.png');
  });

  testWidgets('Capture Subscription 3D Paywall Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await setupTestEnvironment(isVip: false, coins: 500);

    final key = GlobalKey();
    await tester.pumpWidget(
      createTestApp(
        RepaintBoundary(
          key: key,
          child: const SubscriptionView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await saveWidgetImage(tester, key, 'screen_03_paywall.png');
  });

  testWidgets('Capture Coin Store Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await setupTestEnvironment(isVip: false, coins: 250);

    final key = GlobalKey();
    await tester.pumpWidget(
      createTestApp(
        RepaintBoundary(
          key: key,
          child: const CoinStoreView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await saveWidgetImage(tester, key, 'screen_04_coinstore.png');
  });

  testWidgets('Capture Watchlist & Library Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await setupTestEnvironment(isVip: false, coins: 500);
    Get.put<WatchlistController>(WatchlistController());

    final key = GlobalKey();
    await tester.pumpWidget(
      createTestApp(
        RepaintBoundary(
          key: key,
          child: const WatchlistView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await saveWidgetImage(tester, key, 'screen_05_library.png');
  });

  testWidgets('Capture Detail & Player Screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await setupTestEnvironment(isVip: false, coins: 500);

    final drama = SeriesModel(
      id: 'drama_1',
      title: "The Billionaire's Secret Bride",
      description: 'An accidental encounter leads to an unexpected contract marriage with the wealthiest CEO in the city. Can their fake love survive deep secrets and hidden enemies?',
      coverUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      genres: ['Billionaire', 'Romance', 'Contract Marriage', 'Drama'],
      episodesCount: 45,
      rating: 4.9,
      views: 284000,
      episodes: List.generate(
        45,
        (i) => EpisodeModel(
          episodeNumber: i + 1,
          title: 'Episode ${i + 1}: ${i == 0 ? "The Accidental Encounter" : "Unspoken Truths"}',
          duration: '1:30',
          isLocked: i >= 5,
          coinPrice: 10,
        ),
      ),
    );

    final controller = Get.put<DetailController>(DetailController());
    controller.series.value = drama;

    final key = GlobalKey();
    await tester.pumpWidget(
      createTestApp(
        RepaintBoundary(
          key: key,
          child: const DetailView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await saveWidgetImage(tester, key, 'screen_02_detail_player.png');
  });
}
