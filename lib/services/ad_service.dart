import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/premium_provider.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _isInitialized = false;
  PremiumProvider? _premiumProvider;
  bool _isShowingAd = false;

  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';

  String _bannerTopAdUnitId = _testBannerAdUnitId;
  String _bannerBottomAdUnitId = _testBannerAdUnitId;
  String _interstitialAdUnitId = _testInterstitialAdUnitId;
  String _rewardedAdUnitId = _testRewardedAdUnitId;
  String _appOpenAdUnitId = _testAppOpenAdUnitId;

  AppOpenAd? _appOpenAd;
  bool _isLoadingAppOpenAd = false;

  void setProductionIds({
    required String bannerTop,
    required String bannerBottom,
    required String interstitial,
    required String rewarded,
    required String appOpen,
  }) {
    _bannerTopAdUnitId = bannerTop;
    _bannerBottomAdUnitId = bannerBottom;
    _interstitialAdUnitId = interstitial;
    _rewardedAdUnitId = rewarded;
    _appOpenAdUnitId = appOpen;
  }

  Future<void> init(PremiumProvider premiumProvider) async {
    if (_isInitialized) return;
    _premiumProvider = premiumProvider;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('AdMob init error: $e');
    }
  }

  bool get _canShowAds => _premiumProvider != null && !_premiumProvider!.isPremium && !_premiumProvider!.isExpired;

  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad ad) onAdLoaded,
    required void Function(Object error) onAdFailedToLoad,
    bool isTop = true,
  }) {
    return BannerAd(
      adUnitId: isTop ? _bannerTopAdUnitId : _bannerBottomAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    );
  }

  Widget buildBannerWidget({double height = 50, bool isTop = true}) {
    if (!_canShowAds) return const SizedBox.shrink();
    return _BannerAdWidget(
      adService: this,
      height: height,
      isTop: isTop,
    );
  }

  Future<void> showInterstitialAd() async {
    if (!_canShowAds || _isShowingAd) return;
    _isShowingAd = true;
    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          _isShowingAd = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    return completer.future;
  }

  /// Show a rewarded ad. Returns true if user watched fully (reward earned).
  Future<bool> showRewardedAd() async {
    if (!_canShowAds || _isShowingAd) return false;
    _isShowingAd = true;
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (error) {
          _isShowingAd = false;
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  void loadAppOpenAd() {
    if (!_canShowAds || _isLoadingAppOpenAd) return;
    _isLoadingAppOpenAd = true;
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAppOpenAd = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;
        },
      ),
    );
  }

  static const String _keyLastAppOpen = 'last_app_open_ad_time';
  static const int _appOpenCooldown = 3 * 60 * 60; // 3 jam dalam detik

  Future<void> showAppOpenAd() async {
    if (!_canShowAds || _isShowingAd || _appOpenAd == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShow = prefs.getInt(_keyLastAppOpen) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now - lastShow < _appOpenCooldown) return;

    await prefs.setInt(_keyLastAppOpen, now);

    _isShowingAd = true;
    final completer = Completer<void>();
    final ad = _appOpenAd!;
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        loadAppOpenAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    return completer.future;
  }
}

class _BannerAdWidget extends StatefulWidget {
  final AdService adService;
  final double height;
  final bool isTop;

  const _BannerAdWidget({required this.adService, required this.height, this.isTop = true});

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = widget.adService.createBannerAd(
      adSize: AdSize(width: 320, height: 50),
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (error) {
        debugPrint('Banner ad failed: $error');
      },
      isTop: widget.isTop,
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: widget.height,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
