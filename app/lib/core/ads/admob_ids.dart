import 'package:flutter/foundation.dart';

class AdMobIds {
  const AdMobIds._();

  static String get bannerAdUnitId {
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
