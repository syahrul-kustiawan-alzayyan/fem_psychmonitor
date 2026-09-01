import 'package:flutter/foundation.dart';

class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  DateTime? _expiryDate;
  bool _isLoaded = false;

  /// True if subscription is active. Returns false once past expiryDate,
  /// so expired users immediately lose premium benefits (unlimited, no ads).
  bool get isPremium =>
      _isPremium &&
      (_expiryDate == null || !_expiryDate!.isBefore(DateTime.now()));

  /// Raw stored premium flag (ignores expiry) — used by expiry-aware logic.
  bool get rawPremium => _isPremium;

  DateTime? get expiryDate => _expiryDate;
  bool get isExpired =>
      _isPremium && _expiryDate != null && _expiryDate!.isBefore(DateTime.now());

  /// Whether premium status has been loaded from server/billing.
  bool get isLoaded => _isLoaded;

  void init() {
    _isPremium = false;
    _expiryDate = null;
    _isLoaded = false;
  }

  void setPremium({required bool value, DateTime? expiry}) {
    _isPremium = value;
    _expiryDate = expiry;
    _isLoaded = true;
    notifyListeners();
  }

  void clearPremium() {
    _isPremium = false;
    _expiryDate = null;
    _isLoaded = true;
    notifyListeners();
  }

  /// Check and auto-revoke if expired. Call periodically (e.g., every minute)
  /// and on app start so the stored flag doesn't stay `true` after expiry.
  void checkExpiry() {
    if (_isPremium && _expiryDate != null && _expiryDate!.isBefore(DateTime.now())) {
      _isPremium = false;
      notifyListeners();
    }
  }
}
