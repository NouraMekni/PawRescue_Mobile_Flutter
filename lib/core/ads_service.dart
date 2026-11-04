import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  static const _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  Future<void>? _initialization;
  int _animalDetailReturns = 0;
  bool _interstitialDue = false;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!isSupportedPlatform) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  Future<void> onAnimalDetailClosed() async {
    if (!isSupportedPlatform) {
      return;
    }

    _animalDetailReturns++;
    if (_animalDetailReturns >= 3) {
      _interstitialDue = true;
    }
    if (!_interstitialDue) {
      return;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    _interstitialAd = null;
    _interstitialDue = false;
    _animalDetailReturns = 0;
    try {
      await ad.show();
    } catch (error) {
      debugPrint('Interstitial ad failed to show: $error');
      ad.dispose();
      _loadInterstitial();
    }
  }

  void _loadInterstitial() {
    if (_initialization == null || _interstitialAd != null) {
      return;
    }

    final adUnitId = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidInterstitialId,
      TargetPlatform.iOS => _iosInterstitialId,
      _ => null,
    };
    if (adUnitId == null) {
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }
}
