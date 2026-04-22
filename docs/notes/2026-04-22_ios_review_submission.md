# 2026-04-22 iOS 첫 출시 심사 준비 정리

## 작업 개요

App Store 첫 출시 심사를 위해 iOS IPA를 생성하고, Transporter 검증 중 발생한 iPad 멀티태스킹 방향 오류를 수정했다. App Store Connect 수출 규정 입력 기준과 출시노트도 함께 정리했다.

## 1. iOS 심사용 IPA 생성

| 항목 | 내용 |
|---|---|
| 빌드 명령 | `flutter build ipa --release` |
| 결과 파일 | `app/build/ios/ipa/couwang_app.ipa` |
| 앱 버전 | `1.1.6` |
| 빌드 번호 | `9` |
| Bundle ID | `com.fineboll.couwangApp` |
| Display Name | `쿠왕` |
| Deployment Target | `15.5` |
| IPA 크기 | 약 52MB |
| IPA SHA-256 | `feca666ddef31735c72cd998bbca6bb27bd6af4e37cb74b9797937cec0bb47ab` |

## 2. iPad 멀티태스킹 검증 오류 대응

Transporter 검증에서 아래 오류가 발생했다.

```text
Invalid bundle. The “UIInterfaceOrientationPortrait” orientations were provided for the UISupportedInterfaceOrientations Info.plist key, but you need to include all orientations to support iPad multitasking.
```

쿠왕은 세로 화면 고정 앱이므로 iPad 방향을 모두 허용하지 않고, 전체화면 앱으로 명시했다.

| 파일 | 변경 내용 |
|---|---|
| `app/ios/Runner/Info.plist` | `UIRequiresFullScreen` 값을 `true`로 추가 |

수정 후 `UISupportedInterfaceOrientations~ipad`는 세로 방향만 유지하고, iPad 멀티태스킹 요구에서 제외되도록 했다.

## 3. App Store Connect 입력값

| 항목 | 값 |
|---|---|
| 지원 URL | `https://hdyeon67.github.io/CouWang/` |
| 마케팅 URL | `https://hdyeon67.github.io/CouWang/` |
| 개인정보처리방침 URL | `https://hdyeon67.github.io/CouWang/legal/privacy_policy_ko.html` |
| 저작권 | `© 2026 fineboll. All rights reserved.` |
| 심사 연락처 이메일 | `fineboll67@gmail.com` |
| 심사 연락처 전화번호 | `+821062978758` |

## 4. 수출 규정 입력 기준

쿠왕은 자체 암호화 알고리즘, VPN, 보안 메신저, 파일 암호화, 금융/보안용 암호화 기능을 제공하지 않는다. AdMob 등 SDK 통신은 일반적인 HTTPS/TLS 기반 통신으로 본다.

App Store Connect의 앱 암호화 문서 화면에서는 아래 선택을 기준으로 한다.

| 질문 | 선택 |
|---|---|
| 앱에서 구현하는 암호화 알고리즘 유형 | 위에 언급된 알고리즘에 모두 해당하지 않음 |
| 별도 수출 규정 문서 제출 | 필요 없음으로 판단 |

## 5. 제출 전 남은 확인

| 항목 | 상태 |
|---|---|
| Transporter 새 IPA 업로드 | 필요 |
| App Store Connect 빌드 `9` 선택 | 업로드 처리 후 필요 |
| 개인정보 라벨 AdMob 포함 기준 확인 | 필요 |
| `Add for Review` / `Submit for Review` | 빌드 선택 후 진행 |

