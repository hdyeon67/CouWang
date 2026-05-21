# 2026-05-21 Flutter 면접 정리 연계 주석 보강

## 작업 개요
- `docs/interview/flutter_interview_couwang_core_points.md`를 기준으로 앱 코드 주석을 다시 점검했다.
- Flutter 실무 면접에서 자주 묻는 주제와 직접 연결되는 코드 지점을 더 쉽게 찾을 수 있도록 파일/클래스/함수 설명을 보강했다.
- 코드 내부 주석에는 면접용 메타 표현 대신, 인수인계와 유지보수에 바로 도움이 되는 설명만 남기도록 정리했다.

## 반영한 코드 범위
- 앱 전역 lifecycle / 라우팅
  - `app/lib/app/app.dart`
  - `app/lib/app/router.dart`
- 공통 UI 구조
  - `app/lib/core/widgets/app_tab_scaffold.dart`
- Stateful 화면과 Navigator 복귀 흐름
  - `app/lib/features/coupons/presentation/screens/coupon_list_screen.dart`
  - `app/lib/features/memberships/presentation/screens/membership_list_screen.dart`
- 권한 / SQLite / 로컬 저장 / 알림 / 갤러리 자동 감지
  - `app/lib/core/services/app_permission_service.dart`
  - `app/lib/services/local_database_service.dart`
  - `app/lib/services/local_image_storage_service.dart`
  - `app/lib/services/notification_service.dart`
  - `app/lib/services/gallery_scan_service.dart`
  - `app/lib/repositories/settings_repository.dart`

## 정리 방식
- `StatelessWidget` / `StatefulWidget` 선택 이유가 드러나도록 클래스 설명을 조정했다.
- `initState`, `dispose`, `didChangeAppLifecycleState`, `build`의 역할을 실제 쿠왕 흐름과 연결해 설명했다.
- `Navigator.push(...).then(...)`, 라우트 중앙화, 탭 교체 구조가 왜 필요한지 주석으로 보강했다.
- `setState`, `Future`, SQLite, MethodChannel, 알림 payload 처리처럼 인수인계 난도가 높은 지점은 흐름 중심으로 주석을 정리했다.
- `면접에서는`, `설명하기 좋다` 같은 메타 표현은 제거하고 중립적인 설명형 주석만 유지했다.

## 검증
- `flutter analyze` 통과
