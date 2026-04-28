import 'package:flutter/foundation.dart';

class AdMobIds {
  const AdMobIds._();

  static const bool _useRealAds = bool.fromEnvironment(
    'USE_REAL_ADS',
    defaultValue: false,
  );

  static String get bannerAdUnitId {
    if (!_useRealAds) {
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
