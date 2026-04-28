import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/admob_ids.dart';

class CouWangBannerAd extends StatefulWidget {
  const CouWangBannerAd({super.key});

  static const double height = 50;

  @override
  State<CouWangBannerAd> createState() => _CouWangBannerAdState();
}

class _CouWangBannerAdState extends State<CouWangBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (kIsWeb || AdMobIds.bannerAdUnitId.isEmpty) {
      return;
    }

    debugPrint(
      '[AdMob] Loading banner ad. platform=$defaultTargetPlatform unitId=${AdMobIds.bannerAdUnitId}',
    );

    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdMobIds.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
          debugPrint('[AdMob] Banner ad loaded successfully.');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
            '[AdMob] Banner ad failed to load. code=${error.code}, domain=${error.domain}, message=${error.message}',
          );
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );

    bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: CouWangBannerAd.height);
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
