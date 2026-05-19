// 서비스 레이어에서도 화면 전환을 트리거할 수 있도록 공유하는 navigator key.
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
