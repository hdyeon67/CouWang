# 쿠왕 (CouWang)

쿠왕은 쿠폰/기프티콘과 멤버십을 한곳에 모아 관리하고, 만료 전에 알림을 주어 실제 사용까지 이어지도록 돕는 모바일 앱 MVP입니다.

## 프로젝트 개요
- Flutter 기반 모바일 앱
- SQLite/CSV 기반 데이터 흐름
- Python 샘플 데이터 생성 및 SQLite 적재
- SQL/노트북/대시보드로 이어지는 분석 구조

현재 MVP는 `쿠폰 관리 + 멤버십 관리 + 알림 + 자동 입력(OCR/바코드/QR 일부)` 흐름을 중심으로 정리되어 있으며, 주요 데이터는 로컬 SQLite에 저장됩니다.

최근 업데이트:
- Android 버전별 알림 권한 흐름 정리: Android 13 이상은 시스템 권한, Android 12 이하는 앱 내부 동의 다이얼로그 사용
- Chrome 실행을 위한 웹 알림 플러그인 우회와 SQLite wasm 자산 정리
- 리스트 empty 상태의 공통 마스코트 UI와 검색 필드 라운드 border 보정
- iOS/TestFlight 업로드를 위한 archive, signing, AppIcon 정리 진행
- iOS 빌드 오류를 정리하고 TestFlight 내부 테스트 설치까지 완료
- 쿠폰/멤버십/알림 설정이 실제 로컬 SQLite 데이터로 저장되도록 전환
- 쿠폰 만료 로컬 알림 및 알림 로그 저장 구조 추가
- 쿠폰/멤버십 상세 화면 리디자인
- 이미지 선택 권한, 알림 권한 요청 흐름 정리
- 링크 입력 시 QR 코드 미리보기 지원
- 앱 아이콘, 스플래시, 웹 SQLite 자산 정리

## 주요 기능
- 쿠폰 리스트 및 상세 조회
- 쿠폰 등록
  - 수동 입력
  - 갤러리 이미지 기반 자동 입력
  - 갤러리 이미지 기반 바코드/QR 인식
- 쿠폰 사용 완료 처리
- 멤버십 리스트 / 등록 / 상세
- 알림 리스트 / 설정 내 알림 토글
- 쿠폰 만료 로컬 알림 스케줄링 및 알림 로그 관리
- 앱 시작 권한 확인
  - 알림 권한
  - 사진 접근 권한
- 샘플 데이터 생성 및 SQLite 적재

## 폴더 구조
```text
CouWang/
├─ app/        # Flutter 앱
├─ data/       # csv, sqlite db
├─ scripts/    # 샘플 데이터 생성 / sqlite 적재
├─ analysis/   # 분석 노트북
├─ docs/       # 기획, 아키텍처, 분석, 스토어, 법무, 운영 문서
└─ queries/    # SQL 쿼리
```

## 앱 화면 구조
```text
스플래시
└─ 홈/쿠폰 대시보드
   ├─ 절약 리포트 카드
   ├─ 내 쿠폰함
   ├─ 쿠폰 등록
   │  ├─ 이미지 자동 입력
   │  └─ 바코드 미리보기
   ├─ 쿠폰 상세
   ├─ 멤버십 리스트
   ├─ 멤버십 등록
   ├─ 멤버십 상세
   └─ 하단 탭
      ├─ 멤버십
      ├─ 홈
      └─ 설정

알림은 별도 서브 화면으로 구성됩니다.
- 알림 리스트
- 설정 화면 내 알림 토글
```

## 실행 방법

### 1. Flutter 앱
```bash
cd app
flutter pub get
flutter run
```

### 2. 샘플 데이터 생성
```bash
.venv/bin/python scripts/generate_sample_data.py
```

### 3. SQLite 적재
```bash
.venv/bin/python scripts/import_to_sqlite.py
```

## 문서
- [업데이트 로그](./CHANGELOG.md)
- [문서 인덱스](./docs/README.md)
- [실행 및 릴리즈 가이드](./docs/operations/run_and_release_guide.md)
- [로컬 데이터 ERD](./docs/architecture/local_data_erd.md)
- [로컬 데이터셋 정의](./docs/architecture/local_dataset_spec.md)
- [로컬 SQL 스키마](./docs/sql/local_schema.sql)
- [이벤트 정의](./docs/analytics/event_spec.md)
- [KPI 정의](./docs/analytics/kpi_definition.md)
- [스토어 제출 문서](./docs/store/README.md)
- [법적 문서](./docs/legal/README.md)
- [결정사항 로그](./docs/notes/decision_log.md)
- [2026-03-19 회의록](./docs/meetings/2026-03-19_meeting.md)
- [2026-03-20 회의록](./docs/meetings/2026-03-20_meeting.md)
- [2026-03-23 회의록](./docs/meetings/2026-03-23_meeting.md)
- [2026-03-24 회의록](./docs/meetings/2026-03-24_meeting.md)
- [2026-03-25 회의록](./docs/meetings/2026-03-25_meeting.md)
- [2026-03-26 회의록](./docs/meetings/2026-03-26_meeting.md)

## 저장소
- GitHub: https://github.com/hdyeon67/CouWang.git
