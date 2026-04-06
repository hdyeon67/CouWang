# 쿠왕 로컬 데이터셋 상세 정의

## 1. 쿠폰 데이터셋

### 엔티티명
- `Coupon`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `id` | `TEXT` | Y | 앱 내부 고유 ID |
| `name` | `TEXT` | Y | 쿠폰명 |
| `brand` | `TEXT` | Y | 브랜드명 |
| `category` | `TEXT` | Y | 카테고리 |
| `code_value` | `TEXT` | Y | 바코드 번호 또는 QR 링크 |
| `code_type` | `TEXT` | Y | `barcode`, `qr` |
| `expiry_at` | `TEXT` | Y | `yyyy.MM.dd` 형식 만료일 |
| `memo` | `TEXT` | N | 사용자 메모 |
| `status` | `TEXT` | Y | `available`, `urgent`, `expired`, `redeemed` |
| `is_used` | `INTEGER` | Y | 0/1 |
| `image_asset_id` | `TEXT` | N | 연결된 이미지 메타 ID |
| `created_at` | `TEXT` | Y | ISO8601 생성시각 |
| `updated_at` | `TEXT` | Y | ISO8601 수정시각 |
| `used_at` | `TEXT` | N | 사용완료 처리 시각 |

### 파생값

앱에서 계산하는 값:

- `dday`
  - `expiry_at - today`
- `isExpired`
  - `expiry_at < today`

## 2. 멤버십 데이터셋

### 엔티티명
- `Membership`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `id` | `TEXT` | Y | 앱 내부 고유 ID |
| `name` | `TEXT` | Y | 멤버십명 |
| `brand` | `TEXT` | Y | 브랜드/분류명 |
| `card_number` | `TEXT` | Y | 포인트/카드 번호 |
| `memo` | `TEXT` | N | 사용자 메모 |
| `image_asset_id` | `TEXT` | N | 연결된 이미지 메타 ID |
| `created_at` | `TEXT` | Y | 생성 시각 |
| `updated_at` | `TEXT` | Y | 수정 시각 |

## 3. 이미지 데이터셋

### 엔티티명
- `ImageAsset`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `id` | `TEXT` | Y | 이미지 메타 고유 ID |
| `owner_type` | `TEXT` | Y | `coupon` 또는 `membership` |
| `original_name` | `TEXT` | N | 원본 파일명 |
| `stored_name` | `TEXT` | Y | 앱 내부 저장 파일명 |
| `relative_path` | `TEXT` | Y | 앱 문서 디렉터리 기준 상대 경로 |
| `mime_type` | `TEXT` | N | `image/jpeg`, `image/png` 등 |
| `byte_size` | `INTEGER` | N | 바이트 크기 |
| `created_at` | `TEXT` | Y | 저장 시각 |
| `updated_at` | `TEXT` | Y | 수정 시각 |

### 파일 저장 위치 예시

- 쿠폰: `documents/images/coupons/<file>`
- 멤버십: `documents/images/memberships/<file>`

## 4. 알림 설정 데이터셋

### 엔티티명
- `NotificationSettings`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `id` | `INTEGER` | Y | 항상 1 |
| `master_enabled` | `INTEGER` | Y | 전체 알림 on/off |
| `expire_day_enabled` | `INTEGER` | Y | 만료일 및 만료 후 알림 |
| `day1_enabled` | `INTEGER` | Y | 1일 전 |
| `day3_enabled` | `INTEGER` | Y | 3일 전 |
| `day7_enabled` | `INTEGER` | Y | 7일 전 |
| `day30_enabled` | `INTEGER` | Y | 30일 전 |
| `updated_at` | `TEXT` | Y | 수정 시각 |

## 5. 알림 로그 데이터셋

### 엔티티명
- `NotificationLog`

### 필드 정의

| 필드명 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `id` | `TEXT` | Y | 알림 로그 고유 ID (`couponId_type`) |
| `coupon_id` | `TEXT` | Y | 연결된 쿠폰 ID |
| `notification_type` | `TEXT` | Y | `d30`, `d7`, `d3`, `d1`, `dday`, `expire` |
| `title` | `TEXT` | Y | 알림 제목 |
| `body` | `TEXT` | Y | 알림 본문 |
| `scheduled_at` | `TEXT` | Y | 발송 예정 시각 |
| `is_read` | `INTEGER` | Y | 읽음 여부 |
| `is_deleted` | `INTEGER` | Y | 삭제 여부 |
| `created_at` | `TEXT` | Y | 생성 시각 |
| `updated_at` | `TEXT` | Y | 수정 시각 |

## 운영 규칙

### 쿠폰
- 등록 시 `created_at`, `updated_at`는 동일
- 수정 시 `updated_at`만 갱신
- 사용 완료 시 `is_used = 1`, `status = redeemed`, `used_at` 기록
- 삭제 시 연결 이미지도 정리

### 멤버십
- 삭제 시 연결 이미지도 정리
- 카드번호는 원문 그대로 저장하고 화면에서 포맷

### 이미지
- 원본 갤러리 경로를 영구 참조하지 않음
- 앱 내부 저장소로 복사 후 그 경로를 관리
- 이후 백업 시 이미지 폴더를 별도로 묶기 쉬운 구조
