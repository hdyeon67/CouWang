# 2026-04-28 갤러리 감지, 포트폴리오, 입력 폼 보정

## 작업 개요

오늘은 세 가지 흐름을 함께 정리했다.

1. 갤러리 자동 감지 기능과 테스트 보조 흐름 추가
2. 크몽 포트폴리오용 인계/소개 자료 생성
3. 쿠폰/멤버십 입력 화면의 저장 흐름과 OCR, UI 세부 보정

## 문서 정리

### 1. AI 인계 문서 추가
- `docs/handoff/01_project_handoff.md`
- `docs/handoff/02_ai_handoff_prompt.md`
- `docs/handoff/README.md`

다른 AI가 쿠왕 프로젝트를 이어받을 때 필요한 읽기 순서와 복붙용 프롬프트를 별도 폴더로 분리했다.

### 2. 크몽 포트폴리오 산출물 생성
- 저장 위치: 프로젝트 루트 `kmong_portfolio_couwang/`
- 포함 파일:
  - 크몽 입력값 정리
  - 포트폴리오 상세 설명
  - 기술 스택 추천
  - 메인/상세 이미지 문구
  - SVG 템플릿

이 자료는 앱 내부 문서보다 외부 판매/홍보 산출물 성격이 강하므로 `docs/` 바깥 루트 폴더에 두었다.

### 3. 문서 인덱스 보완
- `docs/README.md` 기준 구조를 유지하면서 `handoff/`의 역할을 계속 명확히 관리한다.
- 스토어/법적 문서는 `docs/` 내부, 외부 포트폴리오 패키지는 루트 폴더로 역할을 구분한다.

## 앱 변경 요약

### 갤러리 자동 감지
- 앱 포그라운드 진입 시 신규 이미지를 스캔해 쿠폰 후보를 감지하는 흐름을 추가했다.
- 설정 화면에서만 켤 수 있도록 유지했다.
- 감지 이력과 거절/등록 해시는 로컬 저장으로 관리한다.

관련 파일:
- `app/lib/services/gallery_scan_service.dart`
- `app/lib/utils/scanned_image_store.dart`
- `app/lib/features/coupons/presentation/screens/coupon_list_screen.dart`
- `app/lib/features/settings/presentation/screens/settings_screen.dart`

### 쿠폰 입력 화면 보정
- 날짜 표시 형식을 `yyyy / mm / dd`로 통일했다.
- 쿠퍼티노 날짜 선택기의 한국어 로케일을 반영해 월 표시가 숫자 중심으로 보이게 맞췄다.
- 유효기간/카테고리 입력 박스의 배경색과 아이콘 색을 다른 필드와 통일했다.
- 동일한 교환 코드의 쿠폰은 중복 저장되지 않도록 저장 전에 검사한다.
- 저장 버튼 연타 방지를 위해 저장 중 상태를 추가했고, 저장 직후 `delayed pop` 대신 즉시 이전 화면으로 복귀하도록 정리했다.

관련 파일:
- `app/lib/features/coupons/presentation/screens/coupon_create_screen.dart`
- `app/lib/repositories/coupon_repository.dart`

### 멤버십 리스트/입력 화면 보정
- 아직 동작이 없는 멤버십 카드 메뉴 버튼은 제거하고 우측 `chevron` 아이콘으로 단순화했다.
- 멤버십 저장 화면도 저장 중 중복 탭 방지와 즉시 복귀 흐름으로 정리했다.

관련 파일:
- `app/lib/features/memberships/presentation/screens/membership_list_screen.dart`
- `app/lib/features/memberships/presentation/screens/membership_create_screen.dart`

### OCR 보정
- 브랜드 인식 후보를 확장했다.
- `브랜드`, `교환처`, `사용처`, `매장`, `상호` 라벨 주변 텍스트를 우선 탐색하도록 보강했다.
- `2026년 12월 16일` 형식의 날짜도 인식하도록 날짜 패턴을 추가했다.

## 광고 테스트 점검

- iOS 광고 테스트 시 디버그/테스트 상황에서는 실광고 대신 테스트 광고 단위를 기본 사용하도록 정리했다.
- 광고 단위는 `debug/profile`에서는 테스트 광고, `release`에서는 실광고가 사용되도록 정리했다.
- 배너 광고 실패 시 원인 로그를 확인할 수 있도록 디버그 로그를 추가했다.

관련 파일:
- `app/lib/core/ads/admob_ids.dart`
- `app/lib/core/widgets/couwang_banner_ad.dart`

## 검증

- `flutter pub get`
- `flutter analyze`

두 명령 모두 통과했다.

## 메모

- iPhone 실기기 실행은 계속 연결/설치 단계 이슈가 남아 있어, 앱 코드보다 Xcode-기기 연결 상태 확인이 우선이다.
- Android 실기기에서 저장 후 복귀 문제는 저장 지연 제거와 버튼 상태 갱신 보정으로 먼저 잡았고, 실제 갤럭시 단말 재확인이 남아 있다.
