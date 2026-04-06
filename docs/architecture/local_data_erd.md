# 쿠왕 로컬 데이터 ERD

## 현재 상태 요약

기존 앱은 화면 안 하드코딩 리스트와 메모리 저장소를 섞어 사용했습니다.

- 쿠폰: 화면 상수 리스트 + 메모리 `CouponRepository`
- 멤버십: 화면 상수 리스트
- 알림 설정: 메모리 `SettingsRepository`
- 결과: 앱 재실행 시 사용자 입력 데이터가 유지되지 않음

이번 변경으로 Android/iOS 로컬 SQLite 기반 구조로 전환했습니다.

## ERD

```text
+-------------------------+
| image_assets            |
+-------------------------+
| id (PK)                 |
| owner_type              |
| original_name           |
| stored_name             |
| relative_path           |
| mime_type               |
| byte_size               |
| created_at              |
| updated_at              |
+-------------------------+
           ^
           |
           | image_asset_id
           |
+-------------------------+        +-----------------------------+
| coupons                 |        | memberships                 |
+-------------------------+        +-----------------------------+
| id (PK)                 |        | id (PK)                     |
| name                    |        | name                        |
| brand                   |        | brand                       |
| category                |        | card_number                 |
| code_value              |        | memo                        |
| code_type               |        | image_asset_id (FK)         |
| expiry_at               |        | created_at                  |
| memo                    |        | updated_at                  |
| status                  |        +-----------------------------+
| is_used                 |
| image_asset_id (FK)     |
| created_at              |
| updated_at              |
| used_at                 |
+-------------------------+

+-----------------------------+
| notification_settings       |
+-----------------------------+
| id = 1 (PK)                 |
| master_enabled              |
| expire_day_enabled          |
| day1_enabled                |
| day3_enabled                |
| day7_enabled                |
| day30_enabled               |
| updated_at                  |
+-----------------------------+

+-----------------------------+
| notification_logs           |
+-----------------------------+
| id (PK)                     |
| coupon_id                   |
| notification_type           |
| title                       |
| body                        |
| scheduled_at                |
| is_read                     |
| is_deleted                  |
| created_at                  |
| updated_at                  |
+-----------------------------+
```

## 테이블 역할

### `coupons`
- 사용자가 등록한 실제 쿠폰 데이터
- 바코드/QR 값, 만료일, 상태, 메모를 저장
- 이미지 자체는 직접 넣지 않고 `image_asset_id`로 참조

### `memberships`
- 사용자가 등록한 실제 멤버십 데이터
- 멤버십 이름, 카드번호, 메모 저장
- 이미지가 있다면 `image_asset_id` 참조

### `image_assets`
- 이미지 메타데이터 전용 테이블
- 실제 파일은 앱 내부 저장소에 저장
- DB에는 파일 상대경로와 용량/이름/타입만 저장

### `notification_settings`
- 설정 화면 알림 토글 상태를 저장
- 앱 재실행 후에도 유지

### `notification_logs`
- 알림 인박스용 로그 테이블
- 쿠폰 상태를 보고 화면에서 임의 생성하지 않고, 실제 스케줄 단위의 엔트리를 저장
- 읽음 여부, 삭제 여부를 유지

## 이미지 관리 전략

이미지는 DB BLOB로 직접 장기 저장하지 않고, 앱 내부 파일 저장소 + DB 메타데이터 방식으로 관리합니다.

### 이유

- SQLite 파일 크기 비대화 방지
- 쿠폰/멤버십 조회 시 메인 데이터와 이미지 메타를 분리 가능
- 나중에 클라우드 백업 시 업로드 대상과 메타데이터를 분리하기 쉬움
- 이미지 교체/삭제 시 파일 정리와 DB 정리를 분리해 처리 가능

### 저장 흐름

1. 사용자가 갤러리에서 이미지를 선택
2. 앱이 원본 바이트를 읽음
3. 앱 내부 문서 디렉터리 아래로 복사
   - 예: `documents/images/coupons/...`
   - 예: `documents/images/memberships/...`
4. `image_assets`에 메타데이터 저장
5. `coupons` 또는 `memberships`는 `image_asset_id`만 참조

### 조회 흐름

1. 쿠폰/멤버십 조회
2. 연결된 `image_asset_id` 확인
3. `image_assets.relative_path`로 실제 파일 위치 복원
4. 파일 바이트를 읽어 화면에 표시

### 삭제 흐름

1. 쿠폰/멤버십 삭제
2. 연결된 `image_asset_id` 조회
3. 앱 내부 이미지 파일 삭제
4. `image_assets` 메타데이터 삭제
5. 본 데이터 삭제

## 향후 확장 포인트

나중에 로그인/클라우드 백업이 붙을 경우에도 현재 구조를 그대로 확장하기 쉽도록 잡았습니다.

- `coupons`, `memberships`에 `user_id`, `backup_state`, `remote_id` 추가 가능
- `image_assets`에 `remote_url`, `upload_status`, `checksum` 추가 가능
- 이메일 백업 시:
  - DB dump + 이미지 zip 묶음
  - 또는 JSON + image manifest 형태 가능
- 클라우드 서버 연동 시:
  - 메타데이터는 API
  - 이미지 파일은 object storage 업로드
