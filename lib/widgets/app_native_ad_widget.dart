import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/iap_service.dart';

class AppNativeAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  final bool compact;
  final double? height;

  const AppNativeAdWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.compact = true,
    this.height,
  });

  @override
  State<AppNativeAdWidget> createState() => _AppNativeAdWidgetState();
}

class _AppNativeAdWidgetState extends State<AppNativeAdWidget> with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iap = Provider.of<IapService>(context);
    if (iap.isPremium) {
      if (_nativeAd != null) {
        _nativeAd?.dispose();
        _nativeAd = null;
        if (mounted) setState(() => _isLoaded = false);
      }
      return;
    }
    if (_nativeAd == null) {
      _loadNativeAd();
    }
  }

  void _loadNativeAd() {
    try {
      final adService = Provider.of<AdService>(context, listen: false);
      _nativeAd = NativeAd(
        adUnitId: adService.activeNativeId,
        factoryId: widget.compact ? 'compact' : 'listTile',
        request: const AdRequest(),
        nativeAdOptions: NativeAdOptions(
          videoOptions: VideoOptions(
            startMuted: true,
            customControlsRequested: false,
            clickToExpandRequested: false,
          ),
          mediaAspectRatio: MediaAspectRatio.landscape,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() => _isLoaded = true);
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logAdImpression(
                  adType: 'native',
                  placement: widget.compact ? 'compact_banner' : 'list_tile',
                );
              } catch (_) {}
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint("Native Ad failed to load: $error");
            ad.dispose();
            if (mounted) setState(() => _isLoaded = false);
          },
        ),
      );
      _nativeAd!.load();
    } catch (e) {
      debugPrint("Error loading native ad: $e");
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final iap = Provider.of<IapService>(context);
    if (iap.isPremium) return const SizedBox.shrink();

    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Just a little more height (86.0 vs previous 68.0) for comfortable layout
    final adHeight = widget.height ?? (widget.compact ? 86.0 : 220.0);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: adHeight,
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}
