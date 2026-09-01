import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../providers/premium_provider.dart';
import 'api_service.dart';
import 'config_service.dart';
import 'database_service.dart';

/// Status alur pembelian (untuk UI premium screen).
enum PurchaseState { idle, pending, success, canceled, error }

/// Layanan Google Play Billing langsung (tanpa RevenueCat).
///
/// Sumber kebenaran premium = verifikasi server (POST /premium.php),
/// yang memvalidasi purchase token ke Google Play Developer API.
/// Status premium per akun disimpan server-side (MySQL), bukan dari klien.
class BillingService extends ChangeNotifier {
  static final BillingService _instance = BillingService._();
  factory BillingService() => _instance;
  BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final List<ProductDetails> _products = [];
  bool _initialized = false;

  PurchaseState _state = PurchaseState.idle;
  PurchaseState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Product ID subscription (weekly, monthly, yearly) dari .env.
  List<String> get productIds => [
        ConfigService.billingProductWeekly,
        ConfigService.billingProductMonthly,
        ConfigService.billingProductYearly,
      ].where((id) => id.isNotEmpty).toList();

  /// Harga & detail produk asli dari Play Console.
  Map<String, ProductDetails> get productsById =>
      {for (final p in _products) p.id: p};

  Future<void> init(PremiumProvider premiumProvider) async {
    if (_initialized) return;
    _initialized = true;

    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase, premiumProvider);
      }
    });

    await _loadProducts();
  }

  /// Re-initialize after dispose — resets state and re-subscribes.
  void reinit(PremiumProvider premiumProvider) {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
    init(premiumProvider);
  }

  Future<void> _loadProducts() async {
    if (!Platform.isAndroid || productIds.isEmpty) return;
    try {
      final response = await _iap.queryProductDetails(productIds.toSet());
      _products
        ..clear()
        ..addAll(response.productDetails);
      notifyListeners();
    } catch (e) {
      debugPrint('Query product details error: $e');
    }
  }

  /// Mulai alur pembelian subscription. Hasil datang asinkron via
  /// purchaseStream dan di-apply langsung ke [premiumProvider].
  Future<bool> purchase(String productId) async {
    if (!Platform.isAndroid) return false;
    final product = productsById[productId];
    if (product == null) return false;
    _setState(PurchaseState.pending, null);
    try {
      await _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(productDetails: product),
      );
      return true;
    } catch (e) {
      debugPrint('Launch billing flow error: $e');
      _setState(PurchaseState.error, e.toString());
      return false;
    }
  }

  /// Pulihkan pembelian (restore). Hasil datang via purchaseStream.
  Future<bool> restore() async {
    if (!Platform.isAndroid) return false;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      return false;
    }
  }

  /// Panggil saat app start / login:
  /// 1. Re-verifikasi purchase aktif di device (via restorePurchases → stream)
  /// 2. Fallback: status premium terverifikasi terakhir dari server (GET).
  Future<void> refreshFromServer(PremiumProvider premiumProvider) async {
    if (!Platform.isAndroid) return;
    // Reset stale premium flag immediately if the stored expiry has passed.
    premiumProvider.checkExpiry();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
    }
    try {
      final status = await DatabaseService.loadPremiumStatus();
      if (status.isPremium) {
        final current = premiumProvider.expiryDate;
        var e = status.expiry;
        if (current != null && e != null && current.isAfter(e)) e = current;
        premiumProvider.setPremium(value: true, expiry: e);
      } else {
        // Server says not premium — revoke if previously granted.
        if (premiumProvider.rawPremium) {
          premiumProvider.clearPremium();
        }
      }
    } catch (e) {
      debugPrint('Load premium status error: $e');
    }
  }

  Future<void> _handlePurchase(
    PurchaseDetails purchase,
    PremiumProvider premiumProvider,
  ) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _setState(PurchaseState.pending, null);
        return;
      case PurchaseStatus.canceled:
        _setState(PurchaseState.canceled, null);
        return;
      case PurchaseStatus.error:
        _setState(PurchaseState.error, purchase.error?.message);
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        break;
    }

    final verified = await _verifyAndGrant(purchase, premiumProvider);
    _setState(
      verified ? PurchaseState.success : PurchaseState.error,
      verified ? null : 'Verifikasi pembelian gagal.',
    );
  }

  /// Verifikasi ke server (sumber kebenaran), fallback offline best-effort.
  /// Kembali true jika premium berhasil diaktifkan.
  Future<bool> _verifyAndGrant(
    PurchaseDetails purchase,
    PremiumProvider premiumProvider,
  ) async {
    final token = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;
    var verified = false;
    DateTime? verifiedExpiry;
    var serverReached = false;

    try {
      final result = await DatabaseService.verifyPremium(productId, token);
      serverReached = true;
      if (result.isPremium) {
        verified = true;
        verifiedExpiry = result.expiry;
      }
    } on ApiException catch (e) {
      // Server merespons & menolak token → jangan fallback ke data device.
      // (ApiException tsb bisa juga berasal dari timeout/network, tapi statusCode
      //  null. Hanya anggap "server tercapai" saat benar-benar ada respons HTTP.)
      if (e.statusCode != null) serverReached = true;
    } catch (e) {
      // Gangguan jaringan → fallback best-effort ke data device.
      debugPrint('Server verify error: $e');
      serverReached = false;
    }

    if (!verified && !serverReached) {
      final product = productsById[productId];
      final purchaseTime = purchase is GooglePlayPurchaseDetails
          ? purchase.billingClientPurchase.purchaseTime
          : null;
      final period = product is GooglePlayProductDetails
          ? _billingPeriod(product)
          : null;
      if (period != null && purchaseTime != null && purchaseTime > 0) {
        final start = DateTime.fromMillisecondsSinceEpoch(purchaseTime);
        final expiry = _estimateExpiry(start, period);
        if (expiry.isAfter(DateTime.now())) {
          verified = true;
          verifiedExpiry = expiry;
          debugPrint('Offline premium fallback until $expiry');
        }
      }
    }

    if (verified) {
      final current = premiumProvider.expiryDate;
      var expiry = verifiedExpiry;
      if (current != null && expiry != null && current.isAfter(expiry)) {
        expiry = current;
      }
      premiumProvider.setPremium(value: true, expiry: expiry);
    }

    // Always acknowledge purchase to prevent auto-refund (Google requires within 3 days).
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
      } catch (e) {
        debugPrint('Acknowledge purchase error: $e');
      }
    }
    return verified;
  }

  /// Periode billing ("P1W" | "P1M" | "P1Y") dari offer pertama produk.
  String? _billingPeriod(GooglePlayProductDetails product) {
    final details = product.productDetails.subscriptionOfferDetails;
    if (details == null || details.isEmpty) return null;
    final phases = details.first.pricingPhases;
    return phases.isEmpty ? null : phases.first.billingPeriod;
  }

  /// Estimasi tanggal berakhir dari periode produk (offline fallback).
  DateTime _estimateExpiry(DateTime start, String period) {
    final weeks = RegExp(r'(\d+)W').firstMatch(period)?.group(1);
    final months = RegExp(r'(\d+)M').firstMatch(period)?.group(1);
    final years = RegExp(r'(\d+)Y').firstMatch(period)?.group(1);
    var result = start;
    if (weeks != null) {
      result = result.add(Duration(days: int.parse(weeks) * 7));
    }
    if (months != null) {
      // Use actual calendar month addition for accuracy.
      final m = int.parse(months);
      result = DateTime(result.year, result.month + m, result.day,
          result.hour, result.minute, result.second);
    }
    if (years != null) {
      final y = int.parse(years);
      result = DateTime(result.year + y, result.month, result.day,
          result.hour, result.minute, result.second);
    }
    return result;
  }

  void _setState(PurchaseState state, String? message) {
    _state = state;
    _errorMessage = message;
    notifyListeners();
  }

  /// Ambil state terakhir & reset ke idle (dipakai UI untuk dialog sekali pakai).
  ///
  /// Tidak memanggil [notifyListeners]: dipanggil dari dalam listener, sehingga
  /// tidak boleh memicu notifikasi re-entrant (rekursi tak terbatas).
  PurchaseState consumeState() {
    final s = _state;
    _state = PurchaseState.idle;
    _errorMessage = null;
    return s;
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
