# 쿠폰 사용 완료 처리 실패 (릴리스 전용) 원인 분석 및 수정

## 2026-10-19

### 증상
- 쿠폰 상세 화면에서 "사용 완료 처리하기"를 눌러 확인해도 쿠폰이 사용 완료로 바뀌지 않음.
- 디버그 빌드에서는 재현되지 않고, 스토어/릴리스 빌드(1.1.13+17)에서만 발생.

### 원인
갤럭시노트10(Android 12) 릴리스 빌드에서 재현 후 logcat 확인 결과:

```
E MethodChannel#dexterous.com/flutter/local_notifications: Failed to handle method call
E MethodChannel#...: java.lang.RuntimeException: Missing type parameter.
E flutter : Unhandled Exception: PlatformException(error, Missing type parameter., null, ...)
#2 FlutterLocalNotificationsPlugin.cancel (flutter_local_notifications_plugin.dart:277)
#3 NotificationService.cancelCouponNotifications (notification_service.dart:330)
#4 _CouponDetailScreenState._markAsUsed.<anonymous closure> (coupon_detail_screen.dart:468)
```

두 가지가 겹친 문제였다.

1. **근본 원인 — R8 코드 축소.** `minifyEnabled true` + `shrinkResources true` 릴리스 빌드에서 R8이 `flutter_local_notifications`가 내부적으로 쓰는 Gson 제네릭 타입(TypeToken) 정보를 제거한다. 그 결과 알림 예약/취소 호출이 `Missing type parameter.`로 터진다. 디버그 빌드는 minify를 하지 않아 재현되지 않는다.
2. **2차 원인 — 예외 비격리.** `_markAsUsed`가 `cancelCouponNotifications()`를 `markUsed()`보다 **먼저** 호출하고 try/catch가 없어서, 알림 취소에서 예외가 나면 그 뒤의 `CouponRepository.markUsed()`가 아예 실행되지 않았다. → 완료 처리 자체가 되지 않음.

### 수정
- `android/app/proguard-rules.pro`에 keep 룰 추가 (근본 수정, 알림 기능 전체를 릴리스에서 복구):
  - `-keep class com.dexterous.** { *; }`
  - `-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod`
  - `-keep class com.google.gson.** { *; }` 및 `com.google.gson.reflect.TypeToken` 보존
- `coupon_detail_screen.dart`의 완료/미완료/삭제 흐름을 방어적으로 재구성:
  - 핵심 상태 변경(`markUsed` / `markUnused` / `delete`)을 **먼저** 확정.
  - `cancelCouponNotifications` / `scheduleCouponNotifications` / `logCouponUsed` 등 부가 작업은 각각 try/catch로 감싸 실패해도 핵심 동작·화면 갱신이 이어지도록 함.

### 검증
- 릴리스 APK 재빌드 후 노트10에서 쿠폰 생성 → 사용 완료 처리 → "사용 완료" 필터로 이동 확인.
- logcat에 `Missing type parameter` 예외가 더 이상 발생하지 않음.

### 교훈 / 재발 방지
- 알림·analytics 같은 부가 작업은 사용자 핵심 동작(저장/상태 변경) 이후에, 실패해도 무방한 형태로 분리한다.
- `flutter_local_notifications` 등 Gson/리플렉션을 쓰는 플러그인은 R8 릴리스 빌드에서만 깨질 수 있으므로, 알림 관련 변경 후에는 반드시 **릴리스 빌드로** 실기기 검증한다.
