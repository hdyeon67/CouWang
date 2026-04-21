# 쿠왕 문서 인덱스

이 폴더는 쿠왕(Couwang)의 기획, 구현 기준, 스토어 제출, 법적 문서, 운영 기록을 한곳에서 관리합니다.

## 문서 구조

| 폴더 | 역할 | 주요 문서 |
|---|---|---|
| `planning/` | 제품 기획과 화면/기능 정의 | 요구사항, 화면 흐름, 기능 명세, 정책 |
| `architecture/` | 앱 내부 구조와 로컬 데이터 설계 | 로컬 데이터 ERD, 데이터셋 정의 |
| `analytics/` | 지표와 이벤트 분석 기준 | KPI 정의, 이벤트 로그 명세 |
| `sql/` | 로컬 DB 스키마와 SQL 기준 | SQLite 스키마 |
| `store/` | Google Play / App Store 제출 산출물 | 스토어 등록정보, 이미지 기획 |
| `legal/` | 스토어 제출용 법적/심사 문서 | 개인정보처리방침, App Store 심사 메모 |
| `operations/` | 실행, 빌드, 배포 운영 가이드 | 실행 및 릴리즈 빌드 가이드 |
| `notes/` | 날짜별 작업 정리와 결정사항 | 작업 로그, 결정사항 로그 |
| `meetings/` | 회의록과 원본 참고 자료 | 날짜별 회의록, 참고 원문 |

## 읽는 순서

처음 보는 사람은 아래 순서로 보면 전체 맥락을 빠르게 잡을 수 있습니다.

1. `planning/01_requirements.md`
2. `planning/02_screen_flow.md`
3. `planning/04_functional_spec.md`
4. `architecture/local_data_erd.md`
5. `operations/run_and_release_guide.md`
6. `notes/decision_log.md`

스토어 제출만 확인할 때는 아래 문서를 우선 봅니다.

1. `store/01_google_play_listing.md`
2. `store/02_appstore_listing.md`
3. `store/03_store_image_plan.md`
4. `legal/privacy_policy_ko.md`
5. `legal/ios_privacy_nutrition.md`

## 문서 관리 원칙

- 실제 제출/배포에 쓰는 문서는 `store/`, `legal/`, `operations/`에 둡니다.
- 제품 의사결정의 최종 기준은 `notes/decision_log.md`에 짧게 남깁니다.
- 날짜별 작업 내역은 `notes/YYYY-MM-DD_*.md`에 정리합니다.
- 회의 원문이나 장문의 참고 자료는 `meetings/reference/`에 보관하고, 요약본은 `meetings/` 루트에 둡니다.
- 공개 URL이 필요한 HTML 문서는 GitHub Pages 구조 때문에 기존 경로를 유지합니다.

