# 2026-04-24 Android 업데이트 빌드 정리

## 작업 개요

Android 업데이트 제출을 위해 release App Bundle을 생성하고, `1.1.7+10` 기준의 Google Play 출시노트를 정리했다. 이번 빌드는 Firebase 활성화 옵션을 포함하되, 운영용 release 정책에 따라 내부 테스트 도구는 노출하지 않는 기준으로 유지했다.

## 1. Android 업데이트용 AAB 생성

| 항목 | 내용 |
|---|---|
| 빌드 명령 | `flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true` |
| 결과 파일 | `app/build/app/outputs/bundle/release/app-release.aab` |
| 앱 버전 | `1.1.7` |
| 빌드 번호 | `10` |
| 파일 크기 | 약 74MB |
| SHA-256 | `98d3247d0e0bdd2355302f7890833a084639b3ea03022c5804187a61eeffcd30` |

## 2. 출시노트 정리 기준

이번 업데이트 문구는 신규 기능 나열보다 안정성 개선과 운영 빌드 정리에 초점을 맞췄다.

| 항목 | 방향 |
|---|---|
| 사용자 노출 문구 | 안정성 개선 중심의 짧은 릴리즈 노트 |
| 내부 기록 | Android AAB / iOS IPA 빌드 결과와 해시값 유지 |
| Firebase | `ENABLE_FIREBASE=true` 포함 기준 명시 |

## 3. 관련 문서 반영

| 파일 | 반영 내용 |
|---|---|
| `docs/store/04_release_notes.md` | Google Play 업데이트용 v1.1.7 릴리즈 노트와 AAB 빌드 기록 추가 |
| `docs/notes/decision_log.md` | Android 업데이트 AAB 생성 기준 추가 |

## 4. 검증 메모

- `flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true` 통과
- 결과물 `app-release.aab` 생성 확인
