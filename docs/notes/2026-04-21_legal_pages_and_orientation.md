# 2026-04-21 법적 문서, GitHub Pages, 화면 방향 고정 정리

## 작업 개요

스토어 제출에 필요한 법적 문서와 공개 URL용 HTML 페이지를 추가하고, 앱 화면 방향을 세로로 고정했다.

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

문서 기준:

- 로그인/회원가입 없음
- 서버 없음
- 모든 데이터는 기기 내 로컬 저장
- 개인정보 수집 없음
- 광고 없음
- 사용자 추적 없음
- 외부 전송 데이터 없음
- 사진/갤러리 권한은 쿠폰·멤버십 이미지 등록 목적
- 알림 권한은 서버 미연동 로컬 만료 알림 목적

## 3. GitHub Pages HTML 문서

GitHub Pages에서 바로 열 수 있는 HTML 파일을 추가했다.

| 파일 | 예상 URL | 용도 |
|---|---|---|
| `docs/index.html` | `https://hdyeon67.github.io/CouWang/` | 앱 소개 및 법적 문서 링크 |
| `docs/legal/index.html` | `https://hdyeon67.github.io/CouWang/legal/` | 법적 문서 목록 |
| `docs/legal/privacy_policy_ko.html` | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_ko.html` | 한국어 개인정보처리방침 공개 URL |
| `docs/legal/privacy_policy_en.html` | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_en.html` | 영어 Privacy Policy 공개 URL |

## 4. App Store 개인정보 라벨 기준

현재 쿠왕 v1.0은 사용자 데이터가 개발자 서버 또는 제3자 서버로 전송되지 않는다. 따라서 App Store Connect 앱 개인정보 라벨은 아래 기준을 우선한다.

| 항목 | 입력 기준 |
|---|---|
| 데이터 수집 여부 | 데이터를 수집하지 않음 |
| 추적 여부 | 이 앱은 사용자 또는 기기를 추적하지 않습니다 |
| 사진/동영상 | 현재는 외부 전송이 없으므로 수집 안 함으로 판단 |

단, 향후 이미지가 서버, 클라우드, 외부 OCR, 분석 도구 등으로 전송되는 구조가 생기면 `사용자 콘텐츠 > 사진 또는 동영상` 항목을 다시 검토해야 한다.

## 5. 화면 방향 고정

앱 전체 화면 방향을 세로 고정으로 변경했다.

| 플랫폼 | 변경 파일 | 내용 |
|---|---|---|
| Flutter | `app/lib/main.dart` | `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` 적용 |
| Android | `app/android/app/src/main/AndroidManifest.xml` | `android:screenOrientation="portrait"` 추가 |
| iOS | `app/ios/Runner/Info.plist` | 지원 방향을 Portrait만 남김 |

## 6. 제출 전 확인 사항

| 항목 | 상태 |
|---|---|
| GitHub Pages Source를 `main` 브랜치의 `/docs`로 설정 | GitHub 저장소 설정에서 확인 필요 |
| 개인정보처리방침 URL 접속 가능 여부 | Pages 배포 후 확인 필요 |
| 개인정보 보호책임자 `[담당자명]`, `[이메일]`, `[주소]` 실제 값 입력 | 제출 전 필요 |
| 스토어 등록정보의 웹사이트/개인정보처리방침 URL 갱신 | 제출 전 필요 |
| iOS/Android 실기기에서 화면 회전 고정 확인 | 빌드 실행 후 확인 필요 |
