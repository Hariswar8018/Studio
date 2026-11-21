import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  // Google AdMob App & Unit IDs
  static const String appId = 'ca-app-pub-4345035649216928~3991536616';

  // Production AdMob Unit IDs
  static const String nativeAdUnitId = 'ca-app-pub-4345035649216928/5590899608';
  static const String interstitialAdUnitId = 'ca-app-pub-4345035649216928/3670548936';
  static const String rewardedAdUnitId = 'ca-app-pub-4345035649216928/6086979230';

  // Google Test Ad Unit IDs (for safe debug mode testing)
  static const String testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  final bool useFirebase;
  bool useDemoAds = false;
  bool _isInitialized = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownTime;
  int _actionCount = 0;
  static const int interstitialInterval = 2; // Show every 2nd action (1/2 frequency)

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  AdService({required this.useFirebase}) {
    // Delay initialization so Flutter can finish splash frame render and prevent startup ANR
    Future.delayed(const Duration(milliseconds: 1800), () {
      _initGoogleMobileAds();
    });
  }

  bool get isDebugOrDemo => kDebugMode || useDemoAds;
  bool get isInitialized => _isInitialized;

  void setDemoAdsMode(bool enableDemo) {
    useDemoAds = enableDemo;
    notifyListeners();
  }

  String get activeNativeId => isDebugOrDemo ? testNativeId : nativeAdUnitId;
  String get activeInterstitialId => isDebugOrDemo ? testInterstitialId : interstitialAdUnitId;
  String get activeRewardedId => isDebugOrDemo ? testRewardedId : (rewardedAdUnitId.isNotEmpty ? rewardedAdUnitId : testRewardedId);

  Future<void> _initGoogleMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      preloadInterstitial();
      preloadRewarded();
      notifyListeners();
    } catch (e) {
      debugPrint("AdMob failed to initialize: $e");
    }
  }

  void preloadInterstitial({bool isPremium = false}) {
    if (isPremium) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return;
    }
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: activeInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("Interstitial failed to show: $error");
              ad.dispose();
              _interstitialAd = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial failed to load: $error");
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Show interstitial ad between screens (e.g. after quiz finish or navigating between lessons)
  Future<void> showInterstitialAdIfNeeded({bool isPremium = false}) async {
    if (isPremium) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return;
    }

    _actionCount++;
    // Show each 2nd time (1/2 frequency)
    if (_actionCount % interstitialInterval != 0) {
      preloadInterstitial();
      return;
    }

    // Safety cooldown (at least 2 minutes between full-screen interstitial ads to prevent ad spam)
    if (_lastInterstitialShownTime != null) {
      final diff = DateTime.now().difference(_lastInterstitialShownTime!);
      if (diff.inSeconds < 120) {
        return;
      }
    }

    if (_interstitialAd != null) {
      _lastInterstitialShownTime = DateTime.now();
      await _interstitialAd!.show();
    } else {
      preloadInterstitial();
    }
  }

  void preloadRewarded({bool isPremium = false}) {
    if (isPremium) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return;
    }
    if (_rewardedAd != null || _isRewardedLoading) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: activeRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("Rewarded ad failed to show: $error");
              ad.dispose();
              _rewardedAd = null;
              preloadRewarded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("Rewarded ad failed to load: $error");
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Show Rewarded Ad after a test completes (SRS review, Quick test, or Weak Point full test)
  Future<void> showRewardedAdAfterTest({bool isPremium = false, VoidCallback? onReward}) async {
    if (isPremium) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return;
    }

    if (_rewardedAd != null) {
      final ad = _rewardedAd!;
      _rewardedAd = null;
      await ad.show(onUserEarnedReward: (adWithoutView, reward) {
        debugPrint('User completed test and earned reward: ${reward.amount} ${reward.type}');
        onReward?.call();
      });
      preloadRewarded();
    } else {
      // Fallback: If rewarded ad is still loading, present interstitial so completion ad is always shown safely
      if (_interstitialAd != null) {
        _lastInterstitialShownTime = DateTime.now();
        await _interstitialAd!.show();
      } else {
        preloadInterstitial();
      }
      preloadRewarded();
    }
  }
}

