import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

/// A store we control, so the tip jar can be walked without one.
class FakeSupportStore implements InAppPurchase {
  FakeSupportStore({this.prices = const {}, this.available = true});

  /// Price label per product id. A missing id is a product the store does
  /// not sell, which is the state every product is in before it is created.
  final Map<String, String> prices;
  final bool available;

  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  int buyCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    final details = [
      for (final id in ids)
        if (prices.containsKey(id))
          ProductDetails(
            id: id,
            title: id,
            description: id,
            price: prices[id]!,
            rawPrice: 4.99,
            currencyCode: 'USD',
          ),
    ];
    return ProductDetailsResponse(
      productDetails: details,
      notFoundIDs: ids.where((id) => !prices.containsKey(id)).toList(),
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    buyCalls++;
    return true;
  }

  @override
  Future<bool> buyNonConsumable({
    required PurchaseParam purchaseParam,
  }) async => false;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<String> countryCode() async => 'US';

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() {
    throw UnimplementedError('no platform addition in tests');
  }

  void emit(PurchaseStatus status, String productId) {
    _controller.add([
      PurchaseDetails(
        productID: productId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: '0',
        status: status,
      ),
    ]);
  }

  void close() => _controller.close();
}
