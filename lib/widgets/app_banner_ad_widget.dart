import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/iap_service.dart';

class AppBannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const AppBannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<AppBannerAdWidget> createState() => _AppBannerAdWidgetState();
}

class _AppBannerAdWidgetState extends State<AppBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iap = Provider.of<IapService>(context);
    if (!iap.isPremium && _bannerAd == null) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    try {
      _bannerAd = BannerAd(
        adUnitId: "",
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('BannerAd failed to load: $err');
            ad.dispose();
            if (mounted) setState(() => _isLoaded = false);
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iap = Provider.of<IapService>(context);
    if (iap.isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}

