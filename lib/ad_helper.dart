import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob unit IDs + interstitial manager.
///
/// DEBUG builds use Google's official TEST ad units (safe to click, earn nothing).
/// RELEASE builds use the real Spendly units.
///
/// TODO: after creating the Spendly app in AdMob, replace the REAL ids below and
/// the APPLICATION_ID in AndroidManifest.xml. Until then the release ids are set
/// to the test ids as a safe placeholder.
class AdHelper {
  // Set these to your real Spendly ad unit ids from the AdMob console.
  static const String _realBanner = 'ca-app-pub-3940256099942544/6300978111';       // TODO replace
  static const String _realInterstitial = 'ca-app-pub-3940256099942544/1033173712'; // TODO replace

  static String get bannerAdUnitId =>
      kDebugMode ? 'ca-app-pub-3940256099942544/6300978111' : _realBanner;

  static String get interstitialAdUnitId =>
      kDebugMode ? 'ca-app-pub-3940256099942544/1033173712' : _realInterstitial;
}

class InterstitialManager {
  InterstitialAd? _ad;
  bool _loading = false;
  int _count = 0;
  final int showEvery;
  InterstitialManager({this.showEvery = 4});

  void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) { ad.dispose(); _ad = null; load(); },
            onAdFailedToShowFullScreenContent: (ad, e) { ad.dispose(); _ad = null; load(); },
          );
        },
        onAdFailedToLoad: (e) { _ad = null; _loading = false; },
      ),
    );
  }

  void maybeShow() {
    _count++;
    if (_count % showEvery != 0) return;
    if (_ad != null) { _ad!.show(); } else { load(); }
  }

  void dispose() { _ad?.dispose(); _ad = null; }
}
