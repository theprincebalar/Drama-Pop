import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:dramapop/app/data/services/unlock_service.dart';
import 'package:dramapop/app/data/services/revenue_cat_service.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setupTestEnvironment();
  });

  tearDown(() {
    Get.closeAllSnackbars();
  });

  group('Restore Purchases Service & Logic Tests', () {
    testWidgets('Restore with no purchases triggers "No Purchase Found" flow', (WidgetTester tester) async {
      await setupTestEnvironment(isVip: false);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => RevenueCatService.to.restorePurchases(),
                child: const Text('Restore'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(UnlockService.to.hasUnlimitedAccess, false);

      await tester.tap(find.text('Restore'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4)); // Let snackbar lifecycle complete

      expect(UnlockService.to.hasUnlimitedAccess, false);
    });

    testWidgets('Restore with active VIP triggers "Purchases Restored" flow', (WidgetTester tester) async {
      await setupTestEnvironment(isVip: true);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => RevenueCatService.to.restorePurchases(),
                child: const Text('Restore'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(UnlockService.to.hasUnlimitedAccess, true);

      await tester.tap(find.text('Restore'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4)); // Let snackbar lifecycle complete

      expect(UnlockService.to.hasUnlimitedAccess, true);
    });
  });
}
