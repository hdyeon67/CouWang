---
문서명: 출시노트
프로젝트: 쿠왕 (Couwang)
버전: v1.1.7
작성일: 2026-04-23
담당: 기획/마케팅
---

# 출시노트

## App Store 업데이트 노트

### v1.1.7 한국어

```text
앱 안정성을 개선했어요.

- iPhone 환경에서 앱 오류를 더 안정적으로 확인할 수 있도록 내부 진단 구성을 보강했어요.
- Firebase 설정을 정리해 업데이트 이후 품질 개선에 필요한 기반을 다듬었어요.
- 출시 빌드에서는 테스트 도구가 보이지 않도록 유지했어요.
```

### v1.1.7 English

```text
Improved app stability.

- Improved internal diagnostics for iPhone app issues.
- Refined Firebase configuration to support future quality improvements.
- Kept internal test tools hidden in release builds.
```

## 내부 빌드 기록

| 항목 | 내용 |
|---|---|
| 앱 버전 | `1.1.7+10` |
| 빌드 목적 | App Store 업데이트용 IPA |
| IPA 파일 | `app/build/ios/ipa/couwang_app.ipa` |
| IPA 크기 | 약 52MB |
| IPA SHA-256 | `aa35db7b3ce4e5d01595d9bc3958a8c593146074182c8511299654cb97e0b930` |
| Firebase | `--dart-define=ENABLE_FIREBASE=true`로 활성화 |
| 내부 테스트 도구 | 출시용 IPA에서는 비활성 |
| 주요 확인 사항 | iOS Firebase 설정 파일 번들 포함, Crashlytics 진단 경로 보강, release 모드 테스트 섹션 숨김 |

## Google Play 출시노트

### 한국어

```text
쿠왕의 첫 출시 버전입니다.

- 쿠폰과 기프티콘을 한곳에서 관리할 수 있어요.
- 만료일을 기준으로 D-DAY 상태를 쉽게 확인할 수 있어요.
- 만료 전 로컬 알림으로 놓치기 쉬운 쿠폰을 챙길 수 있어요.
- 쿠폰 상세 화면에서 바코드와 QR 코드를 바로 확인할 수 있어요.
- 갤러리 이미지를 불러와 쿠폰 정보를 등록할 수 있어요.
- 자주 쓰는 멤버십 바코드도 함께 관리할 수 있어요.
- 화면 방향을 세로 모드로 고정해 더 안정적으로 사용할 수 있어요.
```

### English

```text
Couwang's first release is here.

- Manage coupons and gifticons in one place.
- Check D-DAY status based on expiry dates.
- Get local reminders before coupons expire.
- Open barcodes and QR codes from the coupon detail screen.
- Add coupon information from gallery images.
- Manage frequently used membership barcodes together.
- Use the app more reliably with portrait mode support.
```

## App Store 새로운 기능

### 한국어

```text
쿠왕의 첫 출시 버전입니다.

쿠폰·기프티콘·멤버십을 한곳에 모아 관리하고, 만료 전에 알림을 받아보세요.
바코드와 QR 코드를 바로 확인하고, 갤러리 이미지로 쿠폰 등록도 더 간편하게 시작할 수 있어요.
```

### English

```text
Couwang's first release is here.

Manage coupons, gifticons, and memberships in one place, and receive reminders before they expire.
You can quickly open barcodes and QR codes, and add coupon information from gallery images.
```

## 내부 기록

| 항목 | 내용 |
|---|---|
| 앱 버전 | `1.1.6+9` |
| 빌드 목적 | 첫 출시 심사용 AAB / IPA |
| AAB 파일 | `app/build/app/outputs/bundle/release/app-release.aab` |
| AAB 크기 | 약 73MB |
| AAB SHA-256 | `ac93d03ddac3ae8a34f2697468268a92fb47d3e14703da500557ed5b5dfc09c4` |
| IPA 파일 | `app/build/ios/ipa/couwang_app.ipa` |
| IPA 크기 | 약 52MB |
| IPA SHA-256 | `feca666ddef31735c72cd998bbca6bb27bd6af4e37cb74b9797937cec0bb47ab` |
| Firebase | 기본 빌드에서는 비활성 |
| AdMob | 실제 광고 ID 반영 |
| 주요 확인 사항 | 세로 화면 고정, iPad 전체화면 요구 설정, release 모드 테스트 섹션 숨김, 개인정보/스토어 문서 갱신 |

## App Store 수출 규정 입력 메모

쿠왕은 자체 암호화 기능, VPN, 보안 메신저, 파일 암호화 기능을 제공하지 않습니다. App Store Connect의 앱 암호화 문서 화면에서는 아래 기준으로 입력합니다.

| 항목 | 선택 |
|---|---|
| 앱에서 구현하는 암호화 알고리즘 유형 | 위에 언급된 알고리즘에 모두 해당하지 않음 |
| 별도 수출 규정 문서 | 일반적인 HTTPS/TLS 및 SDK 통신만 사용하는 구조이므로 별도 문서 제출 대상이 아님 |

최종 제출 전 App Store Connect 화면 문구가 바뀐 경우, 앱 기능이 자체 암호화 기능을 제공하지 않는다는 기준으로 다시 확인합니다.
