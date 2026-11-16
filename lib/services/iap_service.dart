import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class IapService extends ChangeNotifier {
  static const String monthlySubscriptionId = 'monthly_premium';
  static const String yearlySubscriptionId = 'yearly_premium';

  final bool useFirebase;
  final AuthService authService;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = false;

  IapService({required this.useFirebase, required this.authService}) {
    _initIAP();
  }

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;

  bool get isPremium => authService.currentUser?.hasActivePremium ?? false;

  ProductDetails? get monthlyProduct {
    final match = _products.where((p) => p.id == monthlySubscriptionId).toList();
    return match.isNotEmpty ? match.first : null;
  }

  ProductDetails? get yearlyProduct {
    final match = _products.where((p) => p.id == yearlySubscriptionId).toList();
    return match.isNotEmpty ? match.first : null;
  }

  String get monthlyPriceString {
    if (monthlyProduct != null && monthlyProduct!.price.isNotEmpty) {
      return monthlyProduct!.price;
    }
    return '\$3.99 / mo';
  }

  String get yearlyPriceString {
    if (yearlyProduct != null && yearlyProduct!.price.isNotEmpty) {
      return yearlyProduct!.price;
    }
    return '\$29.99 / yr';
  }

  void _initIAP() async {
    try {
      _isAvailable = await _iap.isAvailable();
      if (_isAvailable) {
        final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
        _subscription = purchaseUpdated.listen(
          (purchaseDetailsList) {
            _listenToPurchaseUpdated(purchaseDetailsList);
          },
          onDone: () {
            _subscription?.cancel();
          },
          onError: (error) {
            debugPrint("IAP stream error: $error");
          },
        );

        // Query product details from Google Play
        const Set<String> kIds = <String>{monthlySubscriptionId, yearlySubscriptionId};
        final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint("IAP products not found on store: ${response.notFoundIDs}");
        }
        _products = response.productDetails;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("IAP initialization error: $e");
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _isLoading = false;
          debugPrint("IAP Purchase error: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _deliverProduct(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == monthlySubscriptionId) {
      final expiry = DateTime.now().add(const Duration(days: 30));
      await authService.setPremiumStatus(true, monthlySubscriptionId, expiry);
    } else if (purchaseDetails.productID == yearlySubscriptionId) {
      final expiry = DateTime.now().add(const Duration(days: 365));
      await authService.setPremiumStatus(true, yearlySubscriptionId, expiry);
    }
  }

  /// Purchase live product through Google Play Billing (Monthly)
  Future<void> buyMonthlySubscription() async {
    final product = monthlyProduct;
    if (product != null) {
      _isLoading = true;
      notifyListeners();
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      debugPrint("Monthly subscription product ($monthlySubscriptionId) not found in Google Play store query.");
      throw Exception("Subscription product ($monthlySubscriptionId) is not available from Google Play. Please check your internet connection or Google Play configuration.");
    }
  }

  /// Purchase live product through Google Play Billing (Yearly)
  Future<void> buyYearlySubscription() async {
    final product = yearlyProduct;
    if (product != null) {
      _isLoading = true;
      notifyListeners();
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      debugPrint("Yearly subscription product ($yearlySubscriptionId) not found in Google Play store query.");
      throw Exception("Subscription product ($yearlySubscriptionId) is not available from Google Play. Please check your internet connection or Google Play configuration.");
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("Restore purchases error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulator for development & test environments
  Future<void> simulateMonthlyPurchase() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final expiry = DateTime.now().add(const Duration(days: 30));
    await authService.setPremiumStatus(true, monthlySubscriptionId, expiry);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> simulateYearlyPurchase() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final expiry = DateTime.now().add(const Duration(days: 365));
    await authService.setPremiumStatus(true, yearlySubscriptionId, expiry);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelMonthlySubscription() async {
    await authService.setPremiumStatus(false, 'none', DateTime.now());
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

