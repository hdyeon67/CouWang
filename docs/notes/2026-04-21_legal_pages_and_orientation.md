# 2026-04-21 법적 문서, 광고/Firebase 준비, 내부테스트 빌드 정리

## 작업 개요

스토어 제출에 필요한 법적 문서와 공개 URL용 HTML 페이지를 추가하고, 앱 화면 방향을 세로로 고정했다. 이후 Google AdMob 실제 광고 ID, Firebase Crashlytics 준비, 내부테스트용 Android AAB 생성까지 출시 준비 항목을 이어서 정리했다.

## 1. URL이 필요한 문서

스토어 제출 시 실제 공개 URL이 필요한 항목은 아래와 같다.

| 항목 | 필요도 | 사용 위치 | 권장 URL |
|---|---|---|---|
| 개인정보처리방침 URL | 필수 | Google Play, App Store Connect | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_ko.html` |
| Privacy Policy URL | 권장 | 영문 스토어/해외 심사 대응 | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_en.html` |
| 웹사이트 URL | 선택/권장 | 스토어 개발자 웹사이트 또는 지원 URL | `https://hdyeon67.github.io/CouWang/` |

GitHub Pages를 저장소의 `docs/` 폴더 기준으로 배포하면 위 URL 구조를 사용할 수 있다.

## 2. 법적 Markdown 문서

`docs/legal/` 폴더에 스토어 제출과 심사 대응용 문서를 추가했다.

| 파일 | 목적 |
|---|---|
| `docs/legal/privacy_policy_ko.md` | 한국어 개인정보처리방침 원문 |
| `docs/legal/privacy_policy_en.md` | 영어 Privacy Policy 원문 |
| `docs/legal/ios_review_notes.md` | App Store Connect Review Notes 입력용 문구 |
| `docs/legal/ios_privacy_nutrition.md` | 앱 개인정보 라벨 입력 가이드 |

초기 문서 기준:

- 로그인/회원가입 없음
- 서버 없음
- 모든 데이터는 기기 내 로컬 저장
- 개인정보 수집 없음
- 외부 전송 데이터 없음
- 사진/갤러리 권한은 쿠폰·멤버십 이미지 등록 목적
- 알림 권한은 서버 미연동 로컬 만료 알림 목적

2026-04-21 추가 업데이트:

- Google AdMob 배너 광고 적용에 맞춰 개인정보처리방침과 App Store 개인정보 라벨 가이드를 갱신했다.
- 쿠폰/멤버십/이미지 데이터는 계속 기기 내 로컬 저장이며 쿠왕 서버로 전송되지 않는다.
- 광고 SDK가 처리할 수 있는 광고 식별자, 앱 상호작용, 진단 정보는 스토어 개인정보 입력에 반영해야 한다.

## 3. GitHub Pages HTML 문서

GitHub Pages에서 바로 열 수 있는 HTML 파일을 추가했다.

| 파일 | 예상 URL | 용도 |
|---|---|---|
| `docs/index.html` | `https://hdyeon67.github.io/CouWang/` | 앱 소개 및 법적 문서 링크 |
| `docs/legal/index.html` | `https://hdyeon67.github.io/CouWang/legal/` | 법적 문서 목록 |
| `docs/legal/privacy_policy_ko.html` | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_ko.html` | 한국어 개인정보처리방침 공개 URL |
| `docs/legal/privacy_policy_en.html` | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_en.html` | 영어 Privacy Policy 공개 URL |

## 4. App Store 개인정보 라벨 기준

현재 쿠왕 v1.0은 쿠폰/멤버십/이미지 데이터가 개발자 서버로 전송되지 않는다. 다만 Google AdMob 배너 광고가 포함되어 있으므로 App Store Connect 앱 개인정보 라벨은 아래 기준을 우선한다.

| 항목 | 입력 기준 |
|---|---|
| 데이터 수집 여부 | 데이터 수집함 |
| 추적 여부 | AdMob 개인 맞춤 광고/ATT 설정에 따라 최종 확인 |
| 사진/동영상 | 현재는 외부 전송이 없으므로 수집 안 함으로 판단 |
| 식별자/사용 데이터/진단 | AdMob SDK 처리 가능 항목으로 검토 |

단, 향후 이미지가 서버, 클라우드, 외부 OCR, 분석 도구 등으로 전송되는 구조가 생기면 `사용자 콘텐츠 > 사진 또는 동영상` 항목을 다시 검토해야 한다.

## 5. 화면 방향 고정

앱 전체 화면 방향을 세로 고정으로 변경했다.

| 플랫폼 | 변경 파일 | 내용 |
|---|---|---|
| Flutter | `app/lib/main.dart` | `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` 적용 |
| Android | `app/android/app/src/main/AndroidManifest.xml` | `android:screenOrientation="portrait"` 추가 |
| iOS | `app/ios/Runner/Info.plist` | 지원 방향을 Portrait만 남김 |

## 6. AdMob 실제 ID 반영

스토어 제출 전 테스트 광고 ID 대신 실제 AdMob 값을 반영했다.

| 구분 | 플랫폼 | 값 |
|---|---|---|
| AdMob App ID | Android | `ca-app-pub-9758365972980092~2994938423` |
| AdMob App ID | iOS | `ca-app-pub-9758365972980092~8594749463` |
| 배너 광고 단위 ID | Android | `ca-app-pub-9758365972980092/7911163697` |
| 배너 광고 단위 ID | iOS | `ca-app-pub-9758365972980092/4576447551` |

광고 적용에 따라 Google Play Console에서는 **광고 포함: 예**로 제출하고, Google Play 데이터 보안 및 App Store 개인정보 라벨에는 Google Mobile Ads SDK가 처리할 수 있는 데이터 항목을 반영한다.

## 7. Firebase Crashlytics / Analytics 준비

Firebase Crashlytics 공식 Flutter 시작하기 1~3단계 기준으로 아래 상태까지 반영했다.

| 항목 | 상태 |
|---|---|
| `firebase_core`, `firebase_analytics`, `firebase_crashlytics` 의존성 | 추가됨 |
| Android Google Services / Crashlytics Gradle 플러그인 선언 | 추가됨 |
| `FlutterError.onError` / `PlatformDispatcher.instance.onError` 연결 | 추가됨 |
| 설정 화면 debug 전용 Crashlytics 테스트 예외 버튼 | 추가됨 |
| 실제 Firebase 설정 파일 | 아직 없음 |
| 기본 빌드에서 Firebase 수집 | 비활성 |

실제 활성화 조건:

```bash
flutter run -d <device-id> --dart-define=ENABLE_FIREBASE=true
flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true
```

단, 위 명령은 `app/android/app/google-services.json` 또는 `app/ios/Runner/GoogleService-Info.plist`가 준비된 뒤 사용한다.

## 8. 내부테스트 AAB 생성

내부테스트 업로드용 Android App Bundle을 생성했다.

| 항목 | 내용 |
|---|---|
| 빌드 명령 | `flutter build appbundle --release` |
| 결과 파일 | `app/build/app/outputs/bundle/release/app-release.aab` |
| 파일 크기 | 약 73MB |
| SHA-256 | `a9352f688e33c88429b49137c02b78fbc965cd26a66d7d2ee3abb9f5134f8bea` |
| 버전 | `1.1.5+8` |
| Firebase | 설정 파일 없음, 기본 비활성 |
| AdMob | 실제 ID 반영 |

## 9. 제출 전 확인 사항

| 항목 | 상태 |
|---|---|
| GitHub Pages Source를 `main` 브랜치의 `/docs`로 설정 | 완료 |
| 개인정보처리방침 URL 접속 가능 여부 | 완료 |
| 개인정보 보호책임자 정보 입력 | 완료: fineboll / fineboll67@gmail.com |
| 스토어 등록정보의 웹사이트/개인정보처리방침 URL 갱신 | 완료 |
| Android 실기기 실행 확인 | 완료: SM F946N |
| iOS 실기기에서 화면 회전 고정 확인 | 필요 |
| Play Console 내부테스트 AAB 업로드 | 생성 완료, 업로드 필요 |

## 10. 문서 구조 정리

문서가 늘어나면서 루트에 섞여 있던 운영/분석 문서를 폴더별 역할에 맞게 재배치했다.

| 폴더 | 역할 |
|---|---|
| `docs/planning/` | 제품 기획, 화면 흐름, 기능 명세, 정책 |
| `docs/architecture/` | 로컬 데이터 구조와 저장 기준 |
| `docs/analytics/` | 이벤트 명세와 KPI 정의 |
| `docs/sql/` | SQLite 스키마 |
| `docs/store/` | Google Play / App Store 제출 문서 |
| `docs/legal/` | 개인정보처리방침, 심사 메모, 개인정보 라벨 |
| `docs/operations/` | 실행, 빌드, 릴리즈 운영 가이드 |
| `docs/notes/` | 날짜별 작업 노트와 결정사항 |
| `docs/meetings/` | 회의 요약과 원문 참고 자료 |

각 폴더에는 README를 추가해 문서 역할과 관리 기준을 바로 확인할 수 있게 했다.
