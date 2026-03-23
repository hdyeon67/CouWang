# 쿠왕(CouWang) 이벤트 로그 명세

## 문서 목적
이 문서는 쿠왕 서비스에서 사용할 이벤트 로그 정의를 통일하기 위한 기준 문서다.  
Flutter 앱, SQLite 저장 구조, SQL 분석, 웹 대시보드가 동일한 이벤트 이름과 속성을 사용하도록 맞추는 것을 목적으로 한다.  
이번 MVP에서는 실제 서버 전송 이벤트가 아니라, 앱 내부 및 로컬 SQLite에 저장되는 로컬 로그 기준으로 정의한다.

## 1. 이벤트 네이밍 규칙
쿠왕 이벤트는 아래 규칙을 따른다.

`domain__action__target`

- `domain`: 이벤트가 발생한 기능 영역
- `action`: 사용자의 행위 또는 시스템 동작
- `target`: 이벤트 대상

예시:
- `coupon__start__create`
- `coupon__complete__create`
- `notification__send__expiry_reminder`

규칙:
- 모두 소문자 사용
- 단어 구분은 언더스코어 `_` 사용
- 구간 구분은 더블 언더스코어 `__` 사용
- 분석 시 의미가 바로 드러나도록 동사보다 상태가 명확한 이름을 우선 사용

## 2. 핵심 퍼널 이벤트
쿠왕 MVP의 핵심 퍼널은 아래 4개 이벤트를 기준으로 본다.

| 이벤트명 | 의미 |
|---|---|
| `coupon__start__create` | 사용자가 쿠폰 등록 화면에 진입하거나 등록을 시작한 시점 |
| `coupon__complete__create` | 쿠폰 등록이 정상적으로 완료된 시점 |
| `coupon__view__detail` | 사용자가 쿠폰 상세 화면을 조회한 시점 |
| `coupon__complete__redeem` | 사용자가 쿠폰을 사용 완료 처리한 시점 |

## 3. 알림 이벤트
만료 임박 알림 관련 이벤트는 아래 2개를 사용한다.

| 이벤트명 | 의미 |
|---|---|
| `notification__send__expiry_reminder` | 시스템이 만료 임박 알림을 로컬에서 발송한 시점 |
| `notification__open__expiry_reminder` | 사용자가 만료 임박 알림을 눌러 앱을 연 시점 |

추가로 쿠폰 상태 변화를 분석하기 위해 아래 이벤트도 함께 사용한다.

| 이벤트명 | 의미 |
|---|---|
| `coupon__complete__expire` | 쿠폰이 사용되지 않은 채 만료 처리된 시점 |

## 4. 이벤트별 설명
각 이벤트의 의미와 발생 시점은 아래 기준으로 정의한다.

| 이벤트명 | 발생 시점 | 설명 |
|---|---|---|
| `coupon__start__create` | 등록 시작 | 사용자가 새 쿠폰 등록 플로우에 진입한 경우 기록 |
| `coupon__complete__create` | 등록 완료 | 필수 입력값 저장이 끝나고 쿠폰이 생성된 경우 기록 |
| `coupon__view__detail` | 상세 조회 | 쿠폰 상세 화면 진입 시 기록 |
| `coupon__complete__redeem` | 사용 완료 | 사용 완료 버튼 등으로 쿠폰 상태가 redeemed로 바뀐 경우 기록 |
| `coupon__complete__expire` | 만료 완료 | 현재 시점 기준 만료일이 지나고 사용되지 않은 쿠폰이 expired 상태가 된 경우 기록 |
| `notification__send__expiry_reminder` | 알림 발송 | D-7 또는 D-1 조건에 따라 로컬 알림이 생성된 경우 기록 |
| `notification__open__expiry_reminder` | 알림 오픈 | 사용자가 해당 알림을 눌러 앱으로 진입한 경우 기록 |

## 5. 공통 속성
모든 이벤트는 아래 공통 속성을 가능한 범위에서 동일하게 가진다.

| 속성명 | 타입 | 설명 | 예시 |
|---|---|---|---|
| `event_name` | TEXT | 이벤트 이름 | `coupon__complete__create` |
| `user_id` | TEXT | 사용자 식별자 | `U001` |
| `coupon_id` | TEXT | 쿠폰 식별자 | `C0001` |
| `timestamp` | TEXT | 이벤트 발생 시각(ISO 또는 YYYY-MM-DD HH:MM:SS) | `2026-03-19 10:30:00` |
| `device_os` | TEXT | 기기 운영체제 | `android`, `ios` |
| `app_version` | TEXT | 앱 버전 | `0.1.0` |
| `days_to_expiry` | INTEGER | 이벤트 시점 기준 만료까지 남은 일수 | `7`, `1`, `0` |

설명:
- `coupon_id`는 쿠폰과 직접 연결되지 않는 이벤트에서는 비어 있을 수 있지만, 이번 MVP에서는 대부분 쿠폰 기준 이벤트이므로 가능하면 항상 저장한다.
- `days_to_expiry`는 알림 분석과 만료 임박 행동 분석에 사용한다.

## 6. 이벤트별 추가 속성
이벤트별로 필요한 추가 속성은 아래와 같이 정의한다.

| 이벤트명 | 추가 속성 | 설명 |
|---|---|---|
| `coupon__start__create` | `entry_point` | 등록 시작 진입 경로. 예: `home`, `list_empty_state` |
| `coupon__complete__create` | `brand_name`, `coupon_type`, `expiry_date` | 등록된 쿠폰의 기본 정보 |
| `coupon__view__detail` | `current_status` | 상세 조회 시점의 쿠폰 상태 |
| `coupon__complete__redeem` | `redeem_method`, `current_status` | 사용 완료 처리 방식과 변경된 상태 |
| `coupon__complete__expire` | `current_status` | 만료 처리 후 상태. 기본값 `expired` |
| `notification__send__expiry_reminder` | `reminder_type`, `scheduled_days_before_expiry` | 알림 유형과 발송 기준. 예: `d7`, `7` |
| `notification__open__expiry_reminder` | `reminder_type`, `open_source` | 어떤 알림을 통해 열렸는지 식별 |

추가 속성 예시:
- `brand_name`: `스타벅스`
- `coupon_type`: `gifticon`, `discount_coupon`
- `current_status`: `active`, `redeemed`, `expired`
- `reminder_type`: `d7`, `d1`

## 7. 수집 목적
각 이벤트는 아래 목적에 따라 수집한다.

| 이벤트명 | 수집 목적 |
|---|---|
| `coupon__start__create` | 등록 시작 대비 완료율 파악 |
| `coupon__complete__create` | 생성된 쿠폰 수와 등록 전환율 집계 |
| `coupon__view__detail` | 등록된 쿠폰의 재방문 및 확인 행동 파악 |
| `coupon__complete__redeem` | 실제 사용 완료율 및 리텐션성 행동 측정 |
| `coupon__complete__expire` | 미사용 만료 비율과 관리 실패 구간 파악 |
| `notification__send__expiry_reminder` | 알림 발송량 및 시점별 효과 분석 |
| `notification__open__expiry_reminder` | 알림 오픈율 및 오픈 후 사용 전환 분석 |

## 구현 메모
- 이벤트 이름은 앱, SQLite 테이블, SQL 쿼리, CSV 헤더에서 동일하게 유지한다.
- `timestamp`는 문자열로 저장하되, 분석 시 정렬 가능하도록 일관된 포맷을 사용한다.
- 이번 MVP에서는 로컬 로그 기준으로 충분하며, 서버 이벤트 파이프라인은 향후 확장 범위로 둔다.
