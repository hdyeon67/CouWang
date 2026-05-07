---
문서명: 출시노트
프로젝트: 쿠왕 (Couwang)
버전: v1.1.10
작성일: 2026-05-07
담당: 기획/마케팅
---

# 출시노트

이 문서는 스토어 제출에 바로 사용하는 **최신 버전 기준 출시노트**와 현재 배포 산출물 정보를 관리합니다.  
이전 버전의 상세 작업 기록은 `docs/notes/`에서 확인합니다.

## Google Play 업데이트 노트

### v1.1.10 한국어

```text
앱 사용성과 안정성을 개선했어요.

- 쿠폰명 OCR 인식을 다듬어 1줄을 기본으로, 필요한 경우 최대 2줄까지 더 자연스럽게 반영되도록 개선했어요.
- 멤버십 이름 OCR에도 같은 기준을 적용해 상단 상태바나 불필요한 텍스트가 덜 섞이도록 보완했어요.
- iPhone에서 첫 실행 시 알림 권한을 허용하면 쿠폰 만료 알림 기본 설정이 바로 켜지도록 정리했어요.
- 전반적인 등록 흐름과 권한 처리 안정성을 함께 다듬었어요.
```

### v1.1.10 English

```text
Improved usability and stability.

- Refined coupon name OCR to prefer a single line and allow up to two lines only when needed.
- Applied the same OCR cleanup rules to membership names so status bar text and unrelated headers are less likely to be captured.
- Updated the first-launch notification flow on iPhone so coupon expiry alerts turn on by default after permission is granted.
- Improved overall registration flow and permission handling stability.
```

## App Store 업데이트 노트

### v1.1.10 한국어

```text
앱 사용성과 안정성을 개선했어요.

- 쿠폰명 OCR 인식을 다듬어 1줄을 기본으로, 필요한 경우 최대 2줄까지 더 자연스럽게 반영되도록 개선했어요.
- 멤버십 이름 OCR에도 같은 기준을 적용해 상단 상태바나 불필요한 텍스트가 덜 섞이도록 보완했어요.
- iPhone에서 첫 실행 시 알림 권한을 허용하면 쿠폰 만료 알림 기본 설정이 바로 켜지도록 정리했어요.
- 전반적인 등록 흐름과 권한 처리 안정성을 함께 다듬었어요.
```

### v1.1.10 English

```text
Improved usability and stability.

- Refined coupon name OCR to prefer a single line and allow up to two lines only when needed.
- Applied the same OCR cleanup rules to membership names so status bar text and unrelated headers are less likely to be captured.
- Updated the first-launch notification flow on iPhone so coupon expiry alerts turn on by default after permission is granted.
- Improved overall registration flow and permission handling stability.
```

## 내부 빌드 기록

| 항목 | 내용 |
|---|---|
| 앱 버전 | `1.1.10+14` |
| 빌드 목적 | Android / iOS 업데이트용 릴리즈 |
| Android AAB 파일 | `app/build/app/outputs/bundle/release/1.1.10.aab` |
| Android AAB 크기 | 약 80MB |
| Android AAB SHA-256 | `bd5819dd82a7e7d1a3a817d8af4c8c358de5ddcf4f912fe33ec7f779d65cd4c2` |
| IPA 파일 | `app/build/ios/ipa/couwang_app.ipa` |
| IPA 크기 | 약 52MB |
| IPA SHA-256 | `46075bad8c2fea0a786959b898e120a125a9d5446272db1b7d0e7dd3b9f4eb9c` |
| Firebase | `--dart-define=ENABLE_FIREBASE=true`로 활성화 |
| AdMob | release 빌드 기준 실제 광고 단위 사용 |
| 주요 확인 사항 | 쿠폰명/멤버십명 OCR 상단 12% 제외 및 2줄 제한, iPhone 첫 실행 알림 토글 기본값 동기화 |
