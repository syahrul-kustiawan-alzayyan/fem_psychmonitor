import 'package:flutter/foundation.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  DateTime? _expiryDate;

  bool get isPremium => _isPremium;
  DateTime? get expiryDate => _expiryDate;
  bool get isExpired => _isPremium && _expiryDate != null && _expiryDate!.isBefore(DateTime.now());

  void init() {
    // Premium status di-reset setiap app start.
    // RevenueCat akan mengecek ulang entitlement via SubscriptionService.init()
    _isPremium = false;
    _expiryDate = null;
  }

  void setPremium({required bool value, DateTime? expiry}) {
    _isPremium = value;
    _expiryDate = expiry;
    notifyListeners();
  }

  void clearPremium() {
    _isPremium = false;
    _expiryDate = null;
    notifyListeners();
  }
}
