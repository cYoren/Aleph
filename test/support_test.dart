import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:original_bible/core/support_service.dart';
import 'package:original_bible/features/settings/support_sheet.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';

import 'support/fake_support_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final prices = {
    'support_small': r'$2.99',
    'support_medium': r'$9.99',
    'support_large': r'$24.99',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSheet(WidgetTester tester, {SupportService? service}) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SupportSheet(service: service)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the tip jar', () {
    testWidgets('offers the three tips with the price the store gave', (
      tester,
    ) async {
      final store = FakeSupportStore(prices: prices);
      final service = SupportService(purchasePlatform: store);
      addTearDown(service.dispose);
      addTearDown(store.close);
      await service.load();

      await pumpSheet(tester, service: service);

      expect(find.text('Support Aleph'), findsOneWidget);
      expect(find.text('A small tip'), findsOneWidget);
      expect(find.text('A generous tip'), findsOneWidget);
      expect(find.text('A big tip'), findsOneWidget);
      // Every amount is the store's label, never a number typed here.
      expect(find.text(r'$2.99'), findsOneWidget);
      expect(find.text(r'$9.99'), findsOneWidget);
      expect(find.text(r'$24.99'), findsOneWidget);
      expect(find.textContaining('unlock nothing'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    test('tiers map to one product each, and only those products', () {
      expect(
        SupportTier.values.map((t) => t.productId).toSet(),
        {'support_small', 'support_medium', 'support_large'},
      );
      expect(SupportTierX.fromProductId('support_medium'), SupportTier.medium);
      expect(SupportTierX.fromProductId('unlock'), isNull);
    });

    test('the store price is what the sheet shows, per tier', () async {
      final store = FakeSupportStore(prices: prices);
      final service = SupportService(purchasePlatform: store);
      addTearDown(service.dispose);

      await service.load();

      expect(service.state.products[SupportTier.small]!.price, r'$2.99');
      expect(service.state.products[SupportTier.medium]!.price, r'$9.99');
      expect(service.state.products[SupportTier.large]!.price, r'$24.99');
      store.close();
    });

    test('a tier the store does not sell is simply not offered', () async {
      final store = FakeSupportStore(prices: {'support_small': r'$2.99'});
      final service = SupportService(purchasePlatform: store);
      addTearDown(service.dispose);

      await service.load();

      expect(service.state.products.containsKey(SupportTier.small), isTrue);
      expect(service.state.products.containsKey(SupportTier.medium), isFalse);
      expect(service.state.products.containsKey(SupportTier.large), isFalse);
      store.close();
    });

    test('a completed tip is a consumable, and thanks the reader', () async {
      final store = FakeSupportStore(prices: prices);
      final service = SupportService(purchasePlatform: store);
      addTearDown(service.dispose);
      await service.load();

      await service.buy(SupportTier.medium);
      expect(store.buyCalls, 1);

      store.emit(PurchaseStatus.purchased, 'support_medium');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.state.thanked, isTrue);
      expect(service.state.buying, isFalse);
      store.close();
    });

    test('a cancelled tip is not an error', () async {
      final store = FakeSupportStore(prices: prices);
      final service = SupportService(purchasePlatform: store);
      addTearDown(service.dispose);
      await service.load();

      await service.buy(SupportTier.small);
      store.emit(PurchaseStatus.canceled, 'support_small');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.state.error, isNull);
      expect(service.state.thanked, isFalse);
      store.close();
    });
  });
}
