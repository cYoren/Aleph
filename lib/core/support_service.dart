/// A tip jar, and nothing else.
///
/// Aleph is free and stays free: these are three consumable products that
/// unlock nothing. They exist because some readers ask how to give something
/// back, and a store purchase is the only way to do that from inside an app.
///
/// The two rules this file keeps: the price always comes from the store, and
/// a completed tip is recorded as an anonymised event only when the reader
/// has already opted into usage counts.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'usage_events.dart';

/// One tip, by how big it is.
enum SupportTier { small, medium, large }

extension SupportTierX on SupportTier {
  /// The store product. The same string has to exist in App Store Connect
  /// and in the Play Console, as a **consumable**, or the tier is simply not
  /// offered.
  String get productId => switch (this) {
    SupportTier.small => 'support_small',
    SupportTier.medium => 'support_medium',
    SupportTier.large => 'support_large',
  };

  static SupportTier? fromProductId(String id) {
    for (final tier in SupportTier.values) {
      if (tier.productId == id) return tier;
    }
    return null;
  }
}

class SupportState {
  final bool storeSupported;
  final bool loading;
  final bool buying;
  final bool thanked;

  /// The store's localised price per tier, keyed by tier. A tier the store
  /// did not return is simply not shown.
  final Map<SupportTier, ProductDetails> products;
  final String? error;

  const SupportState({
    this.storeSupported = false,
    this.loading = false,
    this.buying = false,
    this.thanked = false,
    this.products = const {},
    this.error,
  });

  bool get hasProducts => products.isNotEmpty;

  SupportState copyWith({
    bool? storeSupported,
    bool? loading,
    bool? buying,
    bool? thanked,
    Map<SupportTier, ProductDetails>? products,
    String? error,
  }) {
    return SupportState(
      storeSupported: storeSupported ?? this.storeSupported,
      loading: loading ?? this.loading,
      buying: buying ?? this.buying,
      thanked: thanked ?? this.thanked,
      products: products ?? this.products,
      error: error,
    );
  }
}

class SupportService extends ChangeNotifier {
  SupportService({InAppPurchase? purchasePlatform})
    : _purchasePlatform = purchasePlatform;

  /// Injected in tests so the flow can be exercised without a store.
  InAppPurchase? _purchasePlatform;

  @visibleForTesting
  set purchasePlatform(InAppPurchase? platform) => _purchasePlatform = platform;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  SupportState _state = const SupportState();
  SupportState get state => _state;

  bool _attemptedInit = false;

  /// Whether this platform can sell. `in_app_purchase` has no implementation
  /// on desktop or web, and touching `InAppPurchase.instance` there throws
  /// before the plugin registers.
  bool get storeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  InAppPurchase get _store => _purchasePlatform ?? InAppPurchase.instance;

  /// Asks the store what the three tips cost, and starts listening for
  /// results.
  ///
  /// Called when the sheet opens, never at startup: a reading app should not
  /// talk to a store before the reader asks for anything.
  Future<void> load() async {
    if (!storeSupported) {
      _state = _state.copyWith(storeSupported: false, loading: false);
      notifyListeners();
      return;
    }

    _subscription ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) {
        _state = _state.copyWith(
          loading: false,
          buying: false,
          error: "The store connection failed.",
        );
        notifyListeners();
      },
    );

    _attemptedInit = true;
    _state = _state.copyWith(
      storeSupported: true,
      loading: true,
      error: null,
    );
    notifyListeners();

    try {
      if (!await _store.isAvailable()) {
        _state = _state.copyWith(
          loading: false,
          products: const {},
          error: 'The store is not available right now.',
        );
        notifyListeners();
        return;
      }

      final response = await _store.queryProductDetails({
        for (final tier in SupportTier.values) tier.productId,
      });
      final products = <SupportTier, ProductDetails>{};
      for (final detail in response.productDetails) {
        final tier = SupportTierX.fromProductId(detail.id);
        if (tier != null) products[tier] = detail;
      }
      _state = _state.copyWith(
        loading: false,
        products: products,
        error: products.isEmpty ? 'Tips are not available right now.' : null,
      );
    } catch (error) {
      _state = _state.copyWith(
        loading: false,
        products: const {},
        error: 'The store is not available right now.',
      );
      debugPrint('SupportService: could not load products: $error');
    }
    notifyListeners();
  }

  bool get _alreadyLoaded => _attemptedInit;

  /// Opens the store's payment sheet for [tier].
  Future<void> buy(SupportTier tier) async {
    if (!_alreadyLoaded) await load();
    final product = _state.products[tier];
    if (product == null || _state.buying) return;

    await UsageEvents.record(UsageEvent.supportStarted);
    _state = _state.copyWith(buying: true, error: null);
    notifyListeners();

    try {
      // Consumable: the same tip can be given again next month, and the
      // store must let it be bought again.
      await _store.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
        autoConsume: true,
      );
    } catch (error) {
      _state = _state.copyWith(
        buying: false,
        error: 'The purchase could not be started.',
      );
      notifyListeners();
      debugPrint('SupportService: could not start purchase: $error');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final tier = SupportTierX.fromProductId(purchase.productID);
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _state = _state.copyWith(buying: true);
          notifyListeners();
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (tier != null) {
            await UsageEvents.record(UsageEvent.supportCompleted);
            _state = _state.copyWith(buying: false, thanked: true, error: null);
          } else {
            _state = _state.copyWith(buying: false);
          }
          notifyListeners();
        case PurchaseStatus.error:
          _state = _state.copyWith(
            buying: false,
            error: 'The purchase did not go through.',
          );
          notifyListeners();
        case PurchaseStatus.canceled:
          _state = _state.copyWith(buying: false);
          notifyListeners();
      }

      // Always, and for every outcome: an uncompleted purchase is redelivered
      // on every launch forever.
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (error) {
          debugPrint('SupportService: could not complete purchase: $error');
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
