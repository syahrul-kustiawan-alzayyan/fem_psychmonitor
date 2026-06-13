import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/premium_provider.dart';
import 'database_service.dart';
import 'config_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  bool _isInitialized = false;

  List<Offering> _offerings = [];
  List<Offering> get offerings => _offerings;

  bool get isInitialized => _isInitialized;

  Future<void> init(PremiumProvider premiumProvider) async {
    if (_isInitialized) return;
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration(ConfigService.revenueCatApiKey),
      );
      final customerInfo = await Purchases.getCustomerInfo();
      _checkEntitlements(customerInfo, premiumProvider);
      _isInitialized = true;
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  void _checkEntitlements(CustomerInfo info, PremiumProvider premiumProvider) {
    final premium = info.entitlements.active['Fem-psychalMonitor Pro'];
    if (premium != null) {
      DateTime? expiry;
      if (premium.expirationDate != null) {
        expiry = DateTime.tryParse(premium.expirationDate!);
      }
      premiumProvider.setPremium(value: true, expiry: expiry);
      DatabaseService.updatePremiumStatus(true, expiry);
    } else {
      premiumProvider.clearPremium();
      DatabaseService.updatePremiumStatus(false, null);
    }
  }

  Future<void> fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _offerings = [offerings.current!];
      } else {
        _offerings = [];
      }
    } catch (e) {
      debugPrint('Fetch offerings error: $e');
    }
  }

  Future<bool> purchasePackage(
    Package package,
    PremiumProvider premiumProvider,
  ) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _checkEntitlements(customerInfo, premiumProvider);
      return true;
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases(PremiumProvider premiumProvider) async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _checkEntitlements(customerInfo, premiumProvider);
      return premiumProvider.isPremium;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  /// Refresh entitlement status — panggil setelah login/logout/ganti akun
  Future<void> refresh(PremiumProvider premiumProvider) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _checkEntitlements(customerInfo, premiumProvider);
    } catch (e) {
      debugPrint('Refresh entitlements error: $e');
      premiumProvider.clearPremium();
      DatabaseService.updatePremiumStatus(false, null);
    }
  }

  /// Identifikasi user ke RevenueCat setelah Firebase login.
  /// Ini memastikan RevenueCat menggunakan user ID yang benar,
  /// bukan anonymous ID dari sesi sebelumnya.
  Future<void> identifyUser(String uid, PremiumProvider premiumProvider) async {
    try {
      final result = await Purchases.logIn(uid);
      _checkEntitlements(result.customerInfo, premiumProvider);
    } catch (e) {
      debugPrint('RevenueCat identifyUser error: $e');
      premiumProvider.clearPremium();
      DatabaseService.updatePremiumStatus(false, null);
    }
  }

  /// Logout dari RevenueCat — panggil saat Firebase logout.
  /// Mencegah bocornya entitlement user lama ke user baru.
  Future<void> logOut(PremiumProvider premiumProvider) async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logOut error: $e');
    }
    premiumProvider.clearPremium();
    DatabaseService.updatePremiumStatus(false, null);
  }
}
