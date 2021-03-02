import 'dart:async';
import 'package:demo/strings.dart';
import 'package:demo/utils.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseService {
  InAppPurchaseConnection _connection;

  static const _productIds = {"product_2"};

  List<ProductDetails> _products = [];
  List<String> _notFoundIDs = [];

  StreamSubscription<List<PurchaseDetails>> _subscription;

  InAppPurchaseService() {
    _connection = InAppPurchaseConnection.instance;
  }

  initPurchaseUpdated() {
    Stream purchaseUpdated = _connection.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      showToast(message: "Purchase Updated Stream Error: " + error.toString());
    });
  }

  _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // show progress bar or something
        showToast(message: "Purchase Status: " + Strings.PURCHASED_PENDING);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // show error message or failure icon
          showToast(
              message:
                  "Purchase Status Error: " + purchaseDetails.error.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          // show success message and deliver the product.
          showToast(message: Strings.PRODUCT_PURCHASED);
        }
        // if (Platform.isAndroid) {
        //   if (purchaseDetails.productID == _kConsumableId) {
        //     await _connection.consumePurchase(purchaseDetails);
        //   }
        // }
        if (purchaseDetails.pendingCompletePurchase) {
          await _connection.completePurchase(purchaseDetails);
        }
      }
    });
  }

  initStoreInfo() async {
    final bool isAvailable = await _connection.isAvailable();
    if (isAvailable) {
      ProductDetailsResponse productDetailResponse =
          await _connection.queryProductDetails(_productIds);
      if (productDetailResponse.error == null) {
        if (productDetailResponse.productDetails.isEmpty) {
          showToast(message: Strings.PRODUCT_NOT_FOUND);
        } else {
          _products = productDetailResponse.productDetails;
          _notFoundIDs = productDetailResponse.notFoundIDs;
          print("Products $_products");
          print("Not Found IDs $_notFoundIDs");
          _buyProduct();
        }
      } else {
        showToast(
            message: "Query Product Details Error: " +
                productDetailResponse.error.message);
      }
    } else {
      showToast(message: Strings.CONNECTION_FAILED);
    }
  }

  _buyProduct() {
    if (_products.length > 0) {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: _products[0], sandboxTesting: true);
      _connection.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
