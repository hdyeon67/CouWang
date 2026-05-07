---
문서명: 작업 노트
프로젝트: 쿠왕 (Couwang)
버전: v1.1.10
작성일: 2026-05-07
담당: 개발
---

# 2026-05-07 작업 정리

## 오늘 한 일

- 쿠폰명 OCR을 상단 12% 영역 제외, 기본 1줄/최대 2줄 기준으로 안정화했다.
- 멤버십 이름 OCR에도 같은 규칙을 적용해 상단 상태바 텍스트와 불필요한 헤더 문구가 덜 섞이도록 보완했다.
- iPhone 첫 실행 시 시스템 알림 권한을 허용하면 앱 내부 `쿠폰 만료 알림` 기본값도 함께 켜지도록 동기화했다.
- Android 배포용 AAB와 iOS 배포용 IPA를 최신 버전 기준으로 다시 생성했다.
- `docs/store/04_release_notes.md`를 최신 버전 중심 문서로 정리하고, 중복된 과거 릴리즈 메모는 작업 노트로 역할을 분리했다.

## 변경 이유

- 쿠폰/멤버십 OCR에서 상태바, 시간, 앱 타이틀이 이름 필드로 섞이는 문제가 반복됐다.
- iOS에서는 시스템 권한을 이미 허용했는데 설정 화면 기본 토글이 꺼져 보여 사용자 경험이 어색했다.
- 배포 전 문서가 최신 릴리즈 기준보다 과거 기록이 더 많이 섞여 있어 스토어 제출용 참고 문서로 쓰기 불편했다.

## 검증

- `flutter analyze` 통과
- `flutter build appbundle --release --dart-define=ENABLE_FIREBASE=true`
- `flutter build ipa --release --dart-define=ENABLE_FIREBASE=true`
- iOS App Settings Validation 기준 버전 `1.1.10`, 빌드 `14` 확인

## 산출물

| 항목 | 내용 |
|---|---|
| Android AAB | `app/build/app/outputs/bundle/release/1.1.10.aab` |
| Android AAB SHA-256 | `bd5819dd82a7e7d1a3a817d8af4c8c358de5ddcf4f912fe33ec7f779d65cd4c2` |
| iOS IPA | `app/build/ios/ipa/couwang_app.ipa` |
| iOS IPA SHA-256 | `46075bad8c2fea0a786959b898e120a125a9d5446272db1b7d0e7dd3b9f4eb9c` |

## 문서 정리 메모

- `docs/store/04_release_notes.md`는 최신 스토어 제출 문안과 현재 배포 산출물 정보만 남긴다.
- 이전 버전의 작업 맥락과 세부 변경사항은 `docs/notes/`에서 관리한다.
- `docs/.DS_Store`처럼 문서 관리와 무관한 파일은 저장소에서 제거한다.
