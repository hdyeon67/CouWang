-- =========================================
-- CouWang SQL Queries
-- 기준 테이블:
-- 1) coupons
-- 2) events
-- =========================================


-- =========================================
-- 1. 퍼널 단계별 유저 수
-- 등록 시작 → 등록 완료 → 상세 조회 → 사용 완료
-- =========================================

SELECT 'coupon__start__create' AS step, COUNT(DISTINCT user_id) AS users
FROM events
WHERE event_name = 'coupon__start__create'

UNION ALL

SELECT 'coupon__complete__create' AS step, COUNT(DISTINCT user_id) AS users
FROM events
WHERE event_name = 'coupon__complete__create'

UNION ALL

SELECT 'coupon__view__detail' AS step, COUNT(DISTINCT user_id) AS users
FROM events
WHERE event_name = 'coupon__view__detail'

UNION ALL

SELECT 'coupon__complete__redeem' AS step, COUNT(DISTINCT user_id) AS users
FROM events
WHERE event_name = 'coupon__complete__redeem'
;


-- =========================================
-- 2. 퍼널 단계별 쿠폰 수(쿠폰 기준)
-- 등록 시작 → 등록 완료 → 상세 조회 → 사용 완료
-- =========================================

SELECT 'coupon__start__create' AS step, COUNT(DISTINCT coupon_id) AS coupons
FROM events
WHERE event_name = 'coupon__start__create'

UNION ALL

SELECT 'coupon__complete__create' AS step, COUNT(DISTINCT coupon_id) AS coupons
FROM events
WHERE event_name = 'coupon__complete__create'

UNION ALL

SELECT 'coupon__view__detail' AS step, COUNT(DISTINCT coupon_id) AS coupons
FROM events
WHERE event_name = 'coupon__view__detail'

UNION ALL

SELECT 'coupon__complete__redeem' AS step, COUNT(DISTINCT coupon_id) AS coupons
FROM events
WHERE event_name = 'coupon__complete__redeem'
;


-- =========================================
-- 3. 전체 사용 완료율
-- 정의: redeemed 상태 쿠폰 / 전체 쿠폰
-- =========================================

SELECT
    COUNT(*) AS total_coupons,
    SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) AS redeemed_coupons,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS redemption_rate_pct
FROM coupons
;


-- =========================================
-- 4. 전체 만료율
-- 정의: expired 상태 쿠폰 / 전체 쿠폰
-- =========================================

SELECT
    COUNT(*) AS total_coupons,
    SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) AS expired_coupons,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS expiration_rate_pct
FROM coupons
;


-- =========================================
-- 5. 알림 발송 수 / 알림 오픈율
-- =========================================

WITH sent AS (
    SELECT COUNT(*) AS sent_count
    FROM events
    WHERE event_name = 'notification__send__expiry_reminder'
),
opened AS (
    SELECT COUNT(*) AS open_count
    FROM events
    WHERE event_name = 'notification__open__expiry_reminder'
)
SELECT
    sent.sent_count,
    opened.open_count,
    ROUND(100.0 * opened.open_count / NULLIF(sent.sent_count, 0), 2) AS notification_open_rate_pct
FROM sent, opened
;


-- =========================================
-- 6. 알림 오픈 유저 vs 미오픈 유저 사용 완료율 비교
-- 정의:
-- - open_group: 알림 오픈 이벤트가 1회 이상 있는 유저
-- - no_open_group: 알림 발송은 받았지만 오픈 이벤트가 없는 유저
-- - 사용 완료율: 해당 그룹 내 redeemed 쿠폰 보유 비율(유저 기준)
-- =========================================

WITH users_sent AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'notification__send__expiry_reminder'
),
users_opened AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'notification__open__expiry_reminder'
),
user_group AS (
    SELECT
        s.user_id,
        CASE
            WHEN o.user_id IS NOT NULL THEN 'opened'
            ELSE 'not_opened'
        END AS notification_group
    FROM users_sent s
    LEFT JOIN users_opened o
        ON s.user_id = o.user_id
),
user_redeem AS (
    SELECT
        user_id,
        CASE
            WHEN SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) > 0 THEN 1
            ELSE 0
        END AS has_redeemed_coupon
    FROM coupons
    GROUP BY user_id
)
SELECT
    g.notification_group,
    COUNT(*) AS users,
    SUM(COALESCE(r.has_redeemed_coupon, 0)) AS users_with_redeem,
    ROUND(
        100.0 * SUM(COALESCE(r.has_redeemed_coupon, 0)) / COUNT(*),
        2
    ) AS redeem_user_rate_pct
FROM user_group g
LEFT JOIN user_redeem r
    ON g.user_id = r.user_id
GROUP BY g.notification_group
ORDER BY g.notification_group
;


-- =========================================
-- 7. 알림 오픈 유저 vs 미오픈 유저 쿠폰 사용 완료율 비교
-- 정의: 해당 그룹의 redeemed 쿠폰 수 / 전체 쿠폰 수
-- =========================================

WITH users_sent AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'notification__send__expiry_reminder'
),
users_opened AS (
    SELECT DISTINCT user_id
    FROM events
    WHERE event_name = 'notification__open__expiry_reminder'
),
user_group AS (
    SELECT
        s.user_id,
        CASE
            WHEN o.user_id IS NOT NULL THEN 'opened'
            ELSE 'not_opened'
        END AS notification_group
    FROM users_sent s
    LEFT JOIN users_opened o
        ON s.user_id = o.user_id
)
SELECT
    g.notification_group,
    COUNT(c.coupon_id) AS total_coupons,
    SUM(CASE WHEN c.status = 'redeemed' THEN 1 ELSE 0 END) AS redeemed_coupons,
    ROUND(
        100.0 * SUM(CASE WHEN c.status = 'redeemed' THEN 1 ELSE 0 END) / COUNT(c.coupon_id),
        2
    ) AS coupon_redemption_rate_pct
FROM user_group g
JOIN coupons c
    ON g.user_id = c.user_id
GROUP BY g.notification_group
ORDER BY g.notification_group
;


-- =========================================
-- 8. 브랜드별 만료율 Top 5
-- =========================================

SELECT
    brand,
    COUNT(*) AS total_coupons,
    SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) AS expired_coupons,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS expiration_rate_pct,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS redemption_rate_pct
FROM coupons
GROUP BY brand
HAVING COUNT(*) >= 5
ORDER BY expiration_rate_pct DESC, total_coupons DESC
LIMIT 5
;


-- =========================================
-- 9. 브랜드별 등록 수 / 사용 완료율 / 만료율
-- 대시보드 표용
-- =========================================

SELECT
    brand,
    COUNT(*) AS registrations,
    SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) AS redeemed_count,
    SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) AS expired_count,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'redeemed' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS redemption_rate_pct,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS expiration_rate_pct
FROM coupons
GROUP BY brand
ORDER BY registrations DESC
;


-- =========================================
-- 10. 일별 등록 수(최근 30일 느낌)
-- 등록 완료 이벤트 기준
-- =========================================

SELECT
    DATE(timestamp) AS create_date,
    COUNT(*) AS created_coupons
FROM events
WHERE event_name = 'coupon__complete__create'
GROUP BY DATE(timestamp)
ORDER BY create_date
;


-- =========================================
-- 11. 간단한 D1 리텐션 느낌
-- 정의:
-- 등록 완료일(D0) 이후 1일 이내에 상세 조회를 다시 한 유저 비율
-- =========================================

WITH create_users AS (
    SELECT
        user_id,
        MIN(timestamp) AS first_create_at
    FROM events
    WHERE event_name = 'coupon__complete__create'
    GROUP BY user_id
),
d1_return AS (
    SELECT DISTINCT c.user_id
    FROM create_users c
    JOIN events e
      ON c.user_id = e.user_id
    WHERE e.event_name = 'coupon__view__detail'
      AND e.timestamp > c.first_create_at
      AND e.timestamp <= datetime(c.first_create_at, '+1 day')
)
SELECT
    COUNT(DISTINCT c.user_id) AS created_users,
    COUNT(DISTINCT d.user_id) AS d1_return_users,
    ROUND(
        100.0 * COUNT(DISTINCT d.user_id) / COUNT(DISTINCT c.user_id),
        2
    ) AS d1_retention_pct
FROM create_users c
LEFT JOIN d1_return d
  ON c.user_id = d.user_id
;


-- =========================================
-- 12. 간단한 D7 리텐션 느낌
-- 정의:
-- 등록 완료일(D0) 이후 7일 이내에 상세 조회를 다시 한 유저 비율
-- =========================================

WITH create_users AS (
    SELECT
        user_id,
        MIN(timestamp) AS first_create_at
    FROM events
    WHERE event_name = 'coupon__complete__create'
    GROUP BY user_id
),
d7_return AS (
    SELECT DISTINCT c.user_id
    FROM create_users c
    JOIN events e
      ON c.user_id = e.user_id
    WHERE e.event_name = 'coupon__view__detail'
      AND e.timestamp > c.first_create_at
      AND e.timestamp <= datetime(c.first_create_at, '+7 day')
)
SELECT
    COUNT(DISTINCT c.user_id) AS created_users,
    COUNT(DISTINCT d.user_id) AS d7_return_users,
    ROUND(
        100.0 * COUNT(DISTINCT d.user_id) / COUNT(DISTINCT c.user_id),
        2
    ) AS d7_retention_pct
FROM create_users c
LEFT JOIN d7_return d
  ON c.user_id = d.user_id
;


-- =========================================
-- 13. 등록 완료율(등록 시작 대비)
-- =========================================

WITH started AS (
    SELECT COUNT(DISTINCT coupon_id) AS started_coupons
    FROM events
    WHERE event_name = 'coupon__start__create'
),
completed AS (
    SELECT COUNT(DISTINCT coupon_id) AS completed_coupons
    FROM events
    WHERE event_name = 'coupon__complete__create'
)
SELECT
    started.started_coupons,
    completed.completed_coupons,
    ROUND(
        100.0 * completed.completed_coupons / NULLIF(started.started_coupons, 0),
        2
    ) AS create_completion_rate_pct
FROM started, completed
;