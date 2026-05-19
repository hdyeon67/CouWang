// 화면 하단 공통 배너 광고 위젯.
//
// 광고 로드 성공/실패를 로그로 남겨 디바이스별 이슈를 추적하기 쉽게 해둔다.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/admob_ids.dart';

// CouWangBannerAd 관련 역할을 담당하는 클래스.
class CouWangBannerAd extends StatefulWidget {
  const CouWangBannerAd({super.key});

  static const double height = 50;

  @override
  State<CouWangBannerAd> createState() => _CouWangBannerAdState();
}

// CouWangBannerAdState 관련 역할을 담당하는 클래스.
class _CouWangBannerAdState extends State<CouWangBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  // 화면 또는 객체가 처음 생성될 때 필요한 초기 설정을 수행한다.
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  // 사용이 끝난 리소스를 정리한다.
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // 필요한 데이터나 상태를 불러온다.
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
  // 현재 상태를 기준으로 화면 UI를 구성한다.
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
