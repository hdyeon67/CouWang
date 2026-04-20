---
문서명: 기능 정의서
프로젝트: 쿠왕 (Couwang)
버전: v1.0
작성일: 2026-04-14
작성자: 기획팀
---

# 기능 정의서

| 기능명 | 분류 | 한줄 설명 | 관련 화면 | 구현 상태 | 비고 |
|---|---|---|---|---|---|
| 쿠폰 등록 | 쿠폰 관리 | 쿠폰명, 브랜드, 유효기간, 코드값, 이미지 등을 저장한다. | CouponCreateScreen | 구현완료 | 로컬 SQLite 저장 |
| 쿠폰 수정 | 쿠폰 관리 | 기존 쿠폰 데이터를 프리필해 수정 저장한다. | CouponCreateScreen, CouponDetailScreen | 구현완료 | CTA 문구 수정하기 |
| 쿠폰 삭제 | 쿠폰 관리 | 쿠폰과 연결 이미지, 예약 알림을 삭제/취소한다. | CouponDetailScreen | 구현완료 | 삭제 확인 다이얼로그 |
| 쿠폰 상세 조회 | 쿠폰 관리 | 쿠폰 정보, 이미지, 바코드/QR, 상태를 표시한다. | CouponDetailScreen | 구현완료 | 알림 클릭 라우팅 포함 |
| 쿠폰 사용 완료 | 쿠폰 관리 | 쿠폰을 사용 완료 상태로 변경한다. | CouponDetailScreen | 구현완료 | 알림 취소 |
| 쿠폰 사용 미완료 되돌리기 | 쿠폰 관리 | 사용 완료 쿠폰을 다시 사용 가능 또는 만료 상태로 되돌린다. | CouponDetailScreen | 구현완료 | 확인 다이얼로그 |
| 쿠폰 상태 필터 | UI/UX | 사용가능, 사용완료, 만료 목록을 전환한다. | HomeDashboardScreen | 구현완료 | D-DAY/상태 기반 |
| 쿠폰 정렬 | UI/UX | 만료순/이름순 정렬을 토글한다. | HomeDashboardScreen | 구현완료 | 드롭다운이 아닌 클릭 토글 |
| 쿠폰 검색 | UI/UX | 쿠폰명, 브랜드, 카테고리로 검색한다. | HomeDashboardScreen | 구현완료 | 검색 필드 UI 보정 완료 |
| D-DAY 뱃지 | UI/UX | D-DAY, D-n, 사용완료, 만료 상태를 색상과 라벨로 표현한다. | 홈, 쿠폰 상세, 알림 리스트 | 구현완료 | 색상 단계 적용 |
| SavingSpeechBubbleCard | UI/UX | 이번 달 사용 완료 쿠폰 예상 금액과 마스코트 문구를 표시한다. | HomeDashboardScreen | 구현완료 | TopMascotHeader 탭으로 문구 순환 |
| EmptyStateMascot | UI/UX | 리스트 empty 상태에 `assets/icon/4.png` 마스코트를 표시한다. | 쿠폰/멤버십/알림 화면 | 구현완료 | 공통 위젯 |
| 갤러리 이미지 선택 | 이미지 처리 | 쿠폰/멤버십 이미지를 갤러리에서 선택한다. | CouponCreateScreen, MembershipCreateScreen | 구현완료 | 사진 권한 확인 |
| 이미지 확대 | 이미지 처리 | 등록/상세 이미지 전체화면 확대 팝업을 제공한다. | 쿠폰/멤버십 등록/상세 | 구현완료 | 닫기 버튼 상단 표시 |
| OCR 텍스트 추출 | 이미지 처리 | 이미지에서 쿠폰/멤버십 텍스트 후보를 추출한다. | CouponCreateScreen, MembershipCreateScreen | 구현완료 | ML Kit TextRecognizer |
| 바코드/QR 인식 | 이미지 처리 | 갤러리 이미지에서 바코드/QR 값을 인식한다. | CouponCreateScreen, MembershipCreateScreen | 구현완료 | 실시간 카메라 스캔 없음 |
| 바코드/QR 미리보기 | 이미지 처리 | 코드값을 바코드 또는 QR로 렌더링한다. | 등록/상세 화면 | 구현완료 | `barcode_widget` 사용 |
| 멤버십 등록 | 멤버십 관리 | 멤버십명, 브랜드, 카드번호, 이미지, 메모를 저장한다. | MembershipCreateScreen | 구현완료 | 로컬 SQLite 저장 |
| 멤버십 수정 | 멤버십 관리 | 기존 멤버십 데이터를 프리필해 수정한다. | MembershipCreateScreen, MembershipDetailScreen | 구현완료 | 이미지 유지 |
| 멤버십 삭제 | 멤버십 관리 | 멤버십과 연결 이미지를 삭제한다. | MembershipDetailScreen | 구현완료 | 확인 다이얼로그 |
| 멤버십 상세 조회 | 멤버십 관리 | 멤버십 이미지와 카드번호 바코드를 표시한다. | MembershipDetailScreen | 구현완료 | 바코드 확대 포함 |
| 쿠폰함 바텀시트 | 멤버십 관리 | 멤버십 상세에서 쿠폰 목록을 팝업으로 확인한다. | MembershipDetailScreen | 구현완료 | 쿠폰 상세 이동 |
| 멤버십 바텀시트 | 쿠폰 관리 | 쿠폰 상세에서 멤버십 목록을 팝업으로 확인한다. | CouponDetailScreen | 구현완료 | 멤버십 상세 이동 |
| 로컬 알림 스케줄링 | 알림 시스템 | 쿠폰 만료 전/당일/만료 후 알림을 예약한다. | NotificationService | 구현완료 | 현재 정오 12시 예약 |
| 알림 로그 저장 | 알림 시스템 | 예약 알림 정보를 최근 알림 리스트에 쌓는다. | NotificationListScreen | 구현완료 | `notification_logs` |
| 알림 읽음/삭제 | 알림 시스템 | 알림을 읽음 처리하고 개별/전체 삭제한다. | NotificationListScreen | 구현완료 | 삭제 확인 다이얼로그 |
| 알림 클릭 라우팅 | 알림 시스템 | 알림 클릭 시 해당 쿠폰 상세로 이동한다. | NotificationService, CouponDetailScreen | 구현완료 | payload `couponId|type`, iOS pending 처리 |
| Android 버전별 알림 권한 | 설정 | Android 13 이상/12 이하 권한 흐름을 분리한다. | SettingsScreen, AppPermissionService | 구현완료 | MethodChannel 사용 |
| 알림 설정 토글 | 설정 | 마스터/세부 주기 토글을 저장하고 재스케줄한다. | SettingsScreen | 구현완료 | 로컬 DB 저장 |
| 테스트 알림 | 설정 | 내부 테스트용 쿠폰과 알림을 생성한다. | SettingsScreen | 구현완료 | 개발/QA 용도 |
| 가상 멤버십 생성 | 설정 | 스토어 캡처와 QA를 위해 주요 멤버십 4종을 생성한다. | SettingsScreen, MembershipRepository | 구현완료 | OK캐시백, 해피포인트, L.POINT, CJ ONE |
| 버전 표시 | 설정 | 앱 버전명과 빌드 번호를 표시한다. | SettingsScreen | 구현완료 | 낮은 강조도 |
| 로그인 | 계정 | 사용자 계정으로 데이터를 동기화한다. | 없음 | 미구현 | 향후 확장 |
| 클라우드/이메일 백업 | 데이터 | 로컬 데이터를 외부 백업한다. | 없음 | 미구현 | 향후 확장 |
| AdMob 광고 | 수익화 | 광고 SDK를 연동한다. | 없음 | 미구현 | 첫 심사 이후 검토 |
