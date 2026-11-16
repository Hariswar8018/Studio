package com.starwish.funbits

import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Native Ad Factories
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(layoutInflater)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "compact",
            CompactNativeAdFactory(layoutInflater)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "compact")
    }
}

class CompactNativeAdFactory(private val inflater: LayoutInflater) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = inflater.inflate(
            R.layout.native_ad_compact,
            null
        ) as NativeAdView

        // HEADLINE
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // BODY
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = android.view.View.VISIBLE
            adView.bodyView = bodyView
        } else {
            bodyView.visibility = android.view.View.GONE
        }

        // ICON
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon!!.drawable)
            iconView.visibility = android.view.View.VISIBLE
            adView.iconView = iconView
        } else {
            iconView.visibility = android.view.View.GONE
        }

        // CALL TO ACTION
        val ctaView = adView.findViewById<android.widget.Button>(R.id.ad_call_to_action)
        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = android.view.View.VISIBLE
            adView.callToActionView = ctaView
        } else {
            ctaView.visibility = android.view.View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}

class ListTileNativeAdFactory(private val inflater: LayoutInflater) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = inflater.inflate(
            R.layout.native_ad_listtile,
            null
        ) as NativeAdView

        // -------------------------
        // MEDIA (VIDEO / IMAGE)
        // -------------------------
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.mediaView = mediaView

        nativeAd.mediaContent?.let {
            mediaView.setMediaContent(it)
        }

        // -------------------------
        // HEADLINE (REQUIRED)
        // -------------------------
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // -------------------------
        // BODY
        // -------------------------
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = android.view.View.VISIBLE
            adView.bodyView = bodyView
        } else {
            bodyView.visibility = android.view.View.GONE
        }

        // -------------------------
        // ICON
        // -------------------------
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon!!.drawable)
            iconView.visibility = android.view.View.VISIBLE
            adView.iconView = iconView
        } else {
            iconView.visibility = android.view.View.GONE
        }

        // -------------------------
        // ADVERTISER
        // -------------------------
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = android.view.View.VISIBLE
            adView.advertiserView = advertiserView
        } else {
            advertiserView.visibility = android.view.View.GONE
        }

        // -------------------------
        // CALL TO ACTION
        // -------------------------
        val ctaView = adView.findViewById<android.widget.Button>(R.id.ad_call_to_action)
        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = android.view.View.VISIBLE
            adView.callToActionView = ctaView
        } else {
            ctaView.visibility = android.view.View.GONE
        }

        // -------------------------
        // FINAL BIND
        // -------------------------
        adView.setNativeAd(nativeAd)

        return adView
    }
}
