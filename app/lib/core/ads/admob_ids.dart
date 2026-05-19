// AdMob 단위를 build mode에 따라 분기하는 헬퍼.
//
// 현재 규칙:
// - debug/profile: 테스트 광고
// - release: 실광고
import 'package:flutter/foundation.dart';

// AdMobIds 관련 역할을 담당하는 클래스.
class AdMobIds {
  const AdMobIds._();

  static String get bannerAdUnitId {
    if (!kReleaseMode) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return 'ca-app-pub-3940256099942544/6300978111';
        case TargetPlatform.iOS:
          return 'ca-app-pub-3940256099942544/2934735716';
        default:
          return '';
      }
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-9758365972980092/7911163697';
      case TargetPlatform.iOS:
        return 'ca-app-pub-9758365972980092/4576447551';
      default:
        return '';
    }
  }
}
