# 2026-04-23 iOS Crashlytics 점검 및 업데이트 빌드 정리

## 작업 개요

iPhone에서 Crashlytics 반응이 없는 문제를 점검하고, Firebase 설정 파일이 실제 iOS 앱 번들에 포함되도록 Xcode 프로젝트를 보정했다. 이어서 Crashlytics 테스트 경로를 정리하고, App Store 업데이트용 `1.1.7+10` IPA와 출시노트를 생성했다.

## 1. iOS Crashlytics 점검 결과

기존에는 `app/ios/Runner/GoogleService-Info.plist` 파일이 저장소에는 있어도 Runner 타깃 리소스에 연결되지 않아, 빌드된 `Runner.app` 안에 포함되지 않는 상태였다.

| 항목 | 내용 |
|---|---|
| 원인 | `GoogleService-Info.plist`가 iOS 앱 번들에 복사되지 않음 |
| 조치 | `app/ios/Runner.xcodeproj/project.pbxproj`에 파일 참조와 Resources 항목 추가 |
| 확인 결과 | `app/build/ios/iphoneos/Runner.app/GoogleService-Info.plist` 포함 확인 |

## 2. Crashlytics 테스트 경로 정리

설정 화면의 테스트 버튼은 단순 Flutter 예외 throw 대신 `FirebaseCrashlytics.instance.crash()`를 직접 호출하도록 바꿨다. 또한 Firebase 초기화 실패 시 앱을 바로 종료하지 않고, 설정 화면에서 실패 이유를 스낵바로 확인할 수 있게 했다.

| 파일 | 변경 내용 |
|---|---|
| `app/lib/services/analytics_service.dart` | Firebase 초기화 실패 상태 저장, Crashlytics 강제 크래시 메서드 추가 |
| `app/lib/features/settings/presentation/screens/settings_screen.dart` | 초기화 실패 메시지 표시, Crashlytics 테스트 버튼 동작 변경 |
| `docs/operations/run_and_release_guide.md` | Firebase / Crashlytics 실행 및 확인 절차 갱신 |

## 3. release 빌드 테스트 도구 노출 정책

출시용 release 빌드에서는 테스트 섹션이 보이지 않도록 유지하되, Crashlytics 검증이 필요한 경우에만 별도 Dart define으로 임시 노출할 수 있게 했다.

| 항목 | 값 |
|---|---|
| 기본 정책 | release 빌드에서 테스트 섹션 숨김 유지 |
| 임시 확인용 플래그 | `--dart-define=ENABLE_INTERNAL_TEST_TOOLS=true` |
| 실제 업데이트 IPA | 테스트 도구 비활성 상태로 생성 |

## 4. App Store 업데이트용 IPA 생성

| 항목 | 내용 |
|---|---|
| 빌드 명령 | `flutter build ipa --release --dart-define=ENABLE_FIREBASE=true` |
| 결과 파일 | `app/build/ios/ipa/couwang_app.ipa` |
| 앱 버전 | `1.1.7` |
| 빌드 번호 | `10` |
| Bundle ID | `com.fineboll.couwangApp` |
| IPA 크기 | 약 52MB |
| IPA SHA-256 | `aa35db7b3ce4e5d01595d9bc3958a8c593146074182c8511299654cb97e0b930` |

## 5. 문서 반영 내용

| 파일 | 반영 내용 |
|---|---|
| `docs/store/04_release_notes.md` | App Store 업데이트용 출시노트 v1.1.7 추가 |
| `docs/operations/run_and_release_guide.md` | iOS Firebase 설정 파일 포함 조건과 Crashlytics 테스트 절차 정리 |
| `docs/notes/decision_log.md` | iOS Crashlytics 및 업데이트 빌드 기준 결정 반영 |

## 6. 검증 메모

- `flutter analyze` 통과
- `flutter build ios --debug --dart-define=ENABLE_FIREBASE=true` 통과
- `flutter build ipa --release --dart-define=ENABLE_FIREBASE=true` 통과
- iPhone release 실행으로 앱 설치 및 실행 확인
