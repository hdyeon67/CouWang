# 쿠왕 프로젝트 AI 인계서

작성일: 2026-04-27

## 1. 프로젝트 한 줄 설명

쿠왕(Couwang)은 쿠폰·기프티콘·멤버십을 기기 로컬에 저장하고, 만료 전 알림과 이미지 기반 OCR/바코드 인식을 제공하는 Flutter 앱이다.

## 2. 현재 기술 스택

- Flutter
- SQLite 로컬 저장
- `flutter_local_notifications`
- Google ML Kit OCR / Barcode
- Firebase Analytics / Crashlytics
- Google AdMob
- GitHub Pages 기반 법적 문서 공개

## 3. 현재 앱 상태

### 이미 정리된 것

- Android / iOS 출시 문서 정리
- App Store / Google Play 등록정보 문서화
- 개인정보처리방침 및 심사 보조 문서 작성
- iOS Crashlytics 설정 연결
- Android / iOS 업데이트 빌드 기준 정리
- Codex 전역 스킬 `couwang-release` 생성

### 지금 워크트리에 있는 최신 작업

아래 작업은 **아직 커밋되지 않았을 가능성이 높다.**

- 갤러리 자동 감지 기능 구현 중
- 설정 테스트 섹션에 갤러리 감지 테스트 버튼 추가
- 새 서비스/유틸 파일 추가
- iOS 사진 권한 문구 수정
- `pubspec.yaml` / `pubspec.lock` 갱신

현재 작업 대상 주요 파일:

- `app/lib/services/gallery_scan_service.dart`
- `app/lib/utils/scanned_image_store.dart`
- `app/lib/features/coupons/presentation/screens/coupon_list_screen.dart`
- `app/lib/features/coupons/presentation/screens/coupon_create_screen.dart`
- `app/lib/features/settings/presentation/screens/settings_screen.dart`
- `app/lib/app/app.dart`
- `app/lib/main.dart`
- `app/ios/Runner/Info.plist`
- `app/pubspec.yaml`

## 4. 현재 버전 / 빌드 기준

- 앱 버전: `1.1.7+10`
- Android 업데이트 AAB 기준:
  `app/build/app/outputs/bundle/release/app-release.aab`
- iOS 업데이트 IPA 기준:
  `app/build/ios/ipa/couwang_app.ipa`

## 5. 중요한 제품/개발 규칙

### 제품 규칙

- 로그인 없음
- 서버 저장 없음
- 쿠폰/멤버십 데이터는 기기 로컬 저장
- MVP는 실시간 카메라 스캔이 아니라 갤러리 이미지 기반 인식 중심
- 화면 방향은 세로 고정

### 릴리즈 규칙

- 운영용 release 빌드에서는 내부 테스트 섹션 숨김 유지
- QA 전용 테스트 노출은 `ENABLE_INTERNAL_TEST_TOOLS=true`로만 임시 활성화
- Firebase 실제 활성화 빌드는 `ENABLE_FIREBASE=true` 사용

### 문서 규칙

- 스토어 문구: `docs/store/`
- 법적 문서: `docs/legal/`
- 실행/배포 가이드: `docs/operations/`
- 날짜별 작업: `docs/notes/YYYY-MM-DD_*.md`
- 장기 결정사항: `docs/notes/decision_log.md`

## 6. 먼저 읽어야 할 문서

다른 AI는 아래 순서로 읽는 것이 가장 빠르다.

1. `docs/README.md`
2. `docs/notes/decision_log.md`
3. `docs/operations/run_and_release_guide.md`
4. `docs/store/04_release_notes.md`
5. `app/pubspec.yaml`
6. 현재 수정 중인 Flutter 파일들

갤러리 자동 감지 작업을 이어야 한다면 추가로:

1. `app/lib/services/gallery_scan_service.dart`
2. `app/lib/utils/scanned_image_store.dart`
3. `app/lib/features/settings/presentation/screens/settings_screen.dart`
4. `app/lib/features/coupons/presentation/screens/coupon_list_screen.dart`
5. `app/lib/features/coupons/presentation/screens/coupon_create_screen.dart`

## 7. 저장소 구조 요약

- `app/`: Flutter 앱 본체
- `docs/planning/`: 요구사항, 기능 명세
- `docs/store/`: 스토어 등록정보, 출시노트
- `docs/legal/`: 개인정보처리방침, App Store 보조 문서
- `docs/operations/`: 실행/빌드/배포 가이드
- `docs/notes/`: 날짜별 작업 로그, 결정 로그
- `docs/handoff/`: 다른 AI 인계용 문서

## 8. 외부 AI에게 꼭 알려야 할 점

1. 현재 워크트리가 깨끗하지 않을 수 있으니 `git status`를 먼저 확인할 것
2. 최신 미커밋 작업은 갤러리 자동 감지 기능과 테스트 버튼 추가일 가능성이 높음
3. 프로젝트는 기존 코드 구조를 유지하는 보수적 변경을 선호함
4. 상태관리 라이브러리 추가보다 `setState` 기반 연결을 우선함
5. 기존 화면/문서/빌드 규칙을 깨지 않는 방향으로 움직여야 함

## 9. Codex 전역 스킬 참고

현재 작업 환경에는 쿠왕용 전역 스킬이 존재한다.

- `~/.codex/skills/couwang-release/SKILL.md`

이 파일은 Codex 전용이므로 다른 AI가 직접 읽지 못할 수 있다. 필요한 경우 아래 내용을 이관한다.

- Android AAB 빌드 절차
- iOS IPA 빌드 절차
- 파일 크기 / SHA-256 기록 규칙
- `docs/store/04_release_notes.md` 업데이트 규칙
- `docs/notes/`와 `decision_log.md` 업데이트 기준

## 10. 다른 AI가 첫 응답에서 해야 할 일

1. `git status` 요약
2. 현재 버전 확인
3. 미커밋 변경 파일 기능 요약
4. 이어서 무엇을 할지 3~6줄 계획 제시
5. 그 다음 구현 또는 문서 작업 시작
