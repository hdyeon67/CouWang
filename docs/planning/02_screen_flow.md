---
문서명: 화면 흐름도
프로젝트: 쿠왕 (Couwang)
버전: v1.0
작성일: 2026-04-14
작성자: 기획팀
---

# 화면 흐름도

## 1. 전체 화면 이동 흐름

```mermaid
flowchart TD
  A[앱 실행] --> B[SplashScreen]
  B --> C[HomeDashboardScreen<br/>홈/쿠폰 리스트]

  C -->|FAB 추가| D[CouponCreateScreen<br/>쿠폰 등록]
  D -->|저장 완료| C
  D -->|뒤로가기| C

  C -->|쿠폰 카드 탭| E[CouponDetailScreen]
  E -->|수정하기| F[CouponCreateScreen<br/>쿠폰 수정]
  F -->|수정 저장| E
  E -->|삭제하기| C
  E -->|사용 완료 처리| E
  E -->|사용 미완료 처리| E
  E -->|이미지 탭| E1[이미지 전체화면 팝업]
  E -->|바코드/QR 탭| E2[코드 전체화면 팝업]
  E -->|멤버십 화면으로 가기| E3[멤버십 리스트 바텀시트]
  E3 -->|멤버십 항목 탭| H[MembershipDetailScreen]

  C -->|알림 아이콘 탭| G[NotificationListScreen]
  G -->|알림 항목 탭| E
  G -->|삭제/전체 삭제| G

  C -->|하단탭: 멤버십| I[MembershipListScreen]
  C -->|하단탭: 설정| J[SettingsScreen]
  I -->|하단탭: 홈| C
  I -->|하단탭: 설정| J
  J -->|하단탭: 홈| C
  J -->|하단탭: 멤버십| I

  I -->|FAB 추가| K[MembershipCreateScreen<br/>멤버십 등록]
  K -->|저장 완료| I
  I -->|멤버십 카드 탭| H
  H -->|수정하기| L[MembershipCreateScreen<br/>멤버십 수정]
  L -->|수정 저장| H
  H -->|삭제하기| I
  H -->|이미지 탭| H1[이미지 전체화면 팝업]
  H -->|바코드 탭| H2[바코드 전체화면 팝업]
  H -->|쿠폰함으로 가기| H3[쿠폰 리스트 바텀시트]
  H3 -->|쿠폰 항목 탭| E

  J -->|알림 토글 변경| N[알림 스케줄 재등록]
  N --> J
```

## 2. 알림 클릭 라우팅 흐름

```mermaid
flowchart TD
  A[OS 로컬 알림 수신] --> B{사용자가 알림 클릭}
  B --> C[NotificationService payload 파싱<br/>couponId|type]
  C --> D{쿠폰 존재 여부}
  D -->|없음| E[라우팅 중단]
  D -->|있음| F[알림 로그 읽음 처리]
  F --> G[홈 화면으로 스택 재구성]
  G --> H[CouponDetailScreen으로 이동]
  H --> I{앱 종료 후 아이콘으로 재실행}
  I --> J[SplashScreen]
  J --> K[HomeDashboardScreen]
```

## 3. 쿠폰 등록/수정 상세 흐름

```mermaid
flowchart TD
  A[CouponCreateScreen 진입] --> B{수정 모드인가?}
  B -->|예| C[기존 쿠폰 데이터 프리필]
  B -->|아니오| D[빈 등록 폼 표시]
  C --> E[이미지/필드 수정]
  D --> E
  E --> F{이미지 선택}
  F -->|예| G[갤러리 이미지 로드]
  G --> H[이미지에서 정보 추출하기 활성화]
  H --> I[OCR/바코드/QR 인식]
  I --> J[코드/쿠폰명/브랜드/카테고리/유효기간 후보 반영]
  E --> K{필수값 충족}
  J --> K
  K -->|아니오| L[저장 버튼 비활성]
  K -->|예| M[추가하기/수정하기 버튼 활성]
  M --> N[CouponRepository.saveDraft]
  N --> O[NotificationService.scheduleCouponNotifications]
  O --> P[상세 또는 홈으로 복귀]
```

## 4. 설정 토글과 알림 재스케줄 흐름

```mermaid
flowchart TD
  A[SettingsScreen] --> B[마스터/세부 알림 토글 변경]
  B --> C{알림 권한 필요}
  C -->|Android 13 이상| D[시스템 알림 권한 요청]
  C -->|Android 12 이하| E[앱 내부 알림 동의 다이얼로그]
  C -->|권한 이미 허용| F[설정 저장]
  D --> F
  E --> F
  F --> G{마스터 ON}
  G -->|아니오| H[예약 알림 전체 취소]
  G -->|예| I[미사용/미만료 쿠폰 순회]
  I --> J[D-30/D-7/D-3/D-1/D-DAY/만료 타입 조건 확인]
  J --> K[정오 12시에 로컬 알림 예약]
  K --> L[notification_logs upsert]
```
