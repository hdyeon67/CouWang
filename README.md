# 쿠왕 (CouWang)

쿠왕은 쿠폰/기프티콘과 멤버십을 한곳에 모아 관리하고, 만료 전에 알림을 주어 실제 사용까지 이어지도록 돕는 모바일 앱 MVP입니다.

## 프로젝트 개요
- Flutter 기반 모바일 앱
- SQLite/CSV 기반 데이터 흐름
- Python 샘플 데이터 생성 및 SQLite 적재
- SQL/노트북/대시보드로 이어지는 분석 구조

현재 MVP는 `쿠폰 관리 + 멤버십 관리 + 알림 + 자동 입력(OCR/바코드/QR 일부)` 흐름을 중심으로 정리되어 있습니다.

## 주요 기능
- 쿠폰 리스트 및 상세 조회
- 쿠폰 등록
  - 수동 입력
  - 갤러리 이미지 기반 자동 입력
  - 바코드/QR 실시간 스캔
- 쿠폰 사용 완료 처리
- 멤버십 리스트 / 등록 / 상세
- 알림 리스트 / 알림 설정
- 샘플 데이터 생성 및 SQLite 적재

## 폴더 구조
```text
CouWang/
├─ app/        # Flutter 앱
├─ data/       # csv, sqlite db
├─ scripts/    # 샘플 데이터 생성 / sqlite 적재
├─ analysis/   # 분석 노트북
├─ docs/       # 이벤트, KPI, 회의록
└─ queries/    # SQL 쿼리
```

## 앱 화면 구조
```text
시스템 스플래시
└─ MainTabScreen
   ├─ 쿠폰
   │  ├─ 홈/쿠폰 리스트
   │  ├─ 쿠폰 등록
   │  │  ├─ 이미지 자동 입력
   │  │  └─ 실시간 코드 스캔
   │  ├─ 쿠폰 상세
   │  ├─ 멤버십 리스트
   │  ├─ 멤버십 등록
   │  └─ 멤버십 상세
   └─ 알림
      ├─ 알림 리스트
      └─ 알림 설정
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
- [이벤트 정의](./docs/event_spec.md)
- [KPI 정의](./docs/kpi_definition.md)
- [2026-03-19 회의록](./docs/meetings/2026-03-19_meeting.md)
- [2026-03-20 회의록](./docs/meetings/2026-03-20_meeting.md)

## 저장소
- GitHub: https://github.com/hdyeon67/CouWang.git
