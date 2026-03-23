from __future__ import annotations

import random
import uuid
from datetime import datetime, timedelta, time
from pathlib import Path

import pandas as pd

random.seed(42)

# ----------------------------
# 설정값
# ----------------------------
N_USERS = 80
N_COUPONS = 450

START_DATE = datetime(2026, 2, 1, 9, 0, 0)
END_DATE = datetime(2026, 3, 1, 18, 0, 0)

BRANDS = [
    "스타벅스", "투썸플레이스", "이디야", "메가커피",
    "CU", "GS25", "세븐일레븐",
    "버거킹", "맥도날드", "롯데리아", "BBQ", "교촌치킨",
    "올리브영", "배스킨라빈스"
]

COUPON_TITLES = {
    "스타벅스": ["아메리카노 Tall", "카페라떼 Tall", "디저트 5,000원권"],
    "투썸플레이스": ["아메리카노", "조각 케이크", "커피 2잔 세트"],
    "이디야": ["아메리카노", "카페라떼", "5,000원 금액권"],
    "메가커피": ["아메리카노", "아이스티", "5,000원 금액권"],
    "CU": ["3,000원권", "5,000원권", "1+1 음료 쿠폰"],
    "GS25": ["3,000원권", "5,000원권", "도시락 할인권"],
    "세븐일레븐": ["3,000원권", "간식 할인권", "5,000원권"],
    "버거킹": ["와퍼 세트", "불고기버거 세트", "5,000원 할인권"],
    "맥도날드": ["빅맥 세트", "치즈버거 세트", "음료 쿠폰"],
    "롯데리아": ["새우버거 세트", "데리버거 세트", "5,000원 할인권"],
    "BBQ": ["황금올리브 반반", "치킨 5,000원 할인권", "사이드 쿠폰"],
    "교촌치킨": ["허니콤보 할인권", "치킨 5,000원 할인권", "사이드 쿠폰"],
    "올리브영": ["10,000원권", "5,000원권", "뷰티 할인권"],
    "배스킨라빈스": ["싱글킹", "파인트 할인권", "케이크 할인권"],
}

COUPON_TYPE_OPTIONS = ["barcode", "qr", "none"]

# 프로젝트 루트 기준 경로
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

COUPONS_PATH = DATA_DIR / "coupons.csv"
EVENTS_PATH = DATA_DIR / "events.csv"


# ----------------------------
# 유틸 함수
# ----------------------------
def rand_dt(start: datetime, end: datetime) -> datetime:
    """start~end 사이 임의 시각"""
    delta = end - start
    seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=seconds)


def make_event(
    user_id: str,
    event_name: str,
    ts: datetime,
    coupon_id: str = "",
    days_to_expiry: int | None = None,
    device_os: str | None = None,
    app_version: str | None = None,
) -> dict:
    return {
        "event_id": f"e_{uuid.uuid4().hex[:10]}",
        "user_id": user_id,
        "coupon_id": coupon_id,
        "event_name": event_name,
        "timestamp": ts.isoformat(timespec="seconds"),
        "days_to_expiry": days_to_expiry if days_to_expiry is not None else "",
        "device_os": device_os if device_os else random.choice(["android", "ios"]),
        "app_version": app_version if app_version else random.choice(["1.0.0", "1.0.1", "1.1.0"]),
    }


def dte_from(expiry_date: datetime, current_dt: datetime) -> int:
    return (expiry_date.date() - current_dt.date()).days


# ----------------------------
# 유저 생성
# ----------------------------
users = [f"u_{i:03d}" for i in range(1, N_USERS + 1)]

# ----------------------------
# 쿠폰 / 이벤트 생성
# ----------------------------
coupons: list[dict] = []
events: list[dict] = []

for _ in range(N_COUPONS):
    user_id = random.choice(users)
    coupon_id = f"c_{uuid.uuid4().hex[:8]}"
    brand = random.choice(BRANDS)
    title = random.choice(COUPON_TITLES[brand])
    coupon_type = random.choice(COUPON_TYPE_OPTIONS)

    # 등록 시작/완료는 2월 한 달 안에서 발생
    create_start_at = rand_dt(START_DATE, END_DATE - timedelta(days=1))
    create_complete_at = create_start_at + timedelta(seconds=random.randint(10, 90))

    # 만료일은 등록일 이후 3~60일
    expiry_days = int(random.triangular(3, 60, 18))
    expiry_dt = datetime.combine(
        (create_complete_at + timedelta(days=expiry_days)).date(),
        time(23, 59, 0),
    )

    # 퍼널 이탈 포함: 등록 시작 후 일부는 등록 완료 안 함
    create_completed = random.random() < 0.92

    # 등록 시작 이벤트
    events.append(
        make_event(
            user_id=user_id,
            coupon_id=coupon_id,
            event_name="coupon__start__create",
            ts=create_start_at,
            days_to_expiry=dte_from(expiry_dt, create_start_at),
        )
    )

    if not create_completed:
        # 등록 완료 실패한 케이스는 coupon master에 넣지 않음
        continue

    # 등록 완료 이벤트
    events.append(
        make_event(
            user_id=user_id,
            coupon_id=coupon_id,
            event_name="coupon__complete__create",
            ts=create_complete_at,
            days_to_expiry=dte_from(expiry_dt, create_complete_at),
        )
    )

    # 상태 결정
    # redeemed / expired / active
    r = random.random()
    if r < 0.52:
        final_status = "redeemed"
    elif r < 0.76:
        final_status = "expired"
    else:
        final_status = "active"

    redeemed_at = None

    # 상세 조회 이벤트(0~4회)
    view_count = random.choices([0, 1, 2, 3, 4], weights=[18, 38, 24, 14, 6], k=1)[0]
    view_times: list[datetime] = []

    for _v in range(view_count):
        latest_view_limit = min(expiry_dt, END_DATE + timedelta(days=10))
        if create_complete_at >= latest_view_limit:
            break
        viewed_at = rand_dt(create_complete_at + timedelta(minutes=1), latest_view_limit)
        view_times.append(viewed_at)
        events.append(
            make_event(
                user_id=user_id,
                coupon_id=coupon_id,
                event_name="coupon__view__detail",
                ts=viewed_at,
                days_to_expiry=dte_from(expiry_dt, viewed_at),
            )
        )

    # 알림 발송/오픈
    # D-7, D-1에 대해 발송 이벤트 생성
    notification_opened = False

    for days_before in [7, 1]:
        notify_dt = datetime.combine(
            (expiry_dt - timedelta(days=days_before)).date(),
            time(9, 0, 0),
        )

        # 등록 후에만 알림 의미가 있으므로 조건 체크
        if notify_dt <= create_complete_at:
            continue

        # 너무 먼 미래는 제외
        if notify_dt > END_DATE + timedelta(days=35):
            continue

        events.append(
            make_event(
                user_id=user_id,
                coupon_id=coupon_id,
                event_name="notification__send__expiry_reminder",
                ts=notify_dt,
                days_to_expiry=days_before,
            )
        )

        open_prob = 0.16 if days_before == 7 else 0.34
        if random.random() < open_prob:
            opened_at = notify_dt + timedelta(minutes=random.randint(1, 180))
            notification_opened = True

            events.append(
                make_event(
                    user_id=user_id,
                    coupon_id=coupon_id,
                    event_name="notification__open__expiry_reminder",
                    ts=opened_at,
                    days_to_expiry=dte_from(expiry_dt, opened_at),
                )
            )

            # 알림을 열면 상세 재조회 확률 상승
            if random.random() < 0.72:
                revisit_at = opened_at + timedelta(minutes=random.randint(1, 20))
                events.append(
                    make_event(
                        user_id=user_id,
                        coupon_id=coupon_id,
                        event_name="coupon__view__detail",
                        ts=revisit_at,
                        days_to_expiry=dte_from(expiry_dt, revisit_at),
                    )
                )

    # 사용 완료 시점 생성
    if final_status == "redeemed":
        # 알림을 열었으면 사용 가능성이 조금 더 높고, 사용 시점도 만료 직전일 확률 증가
        redeem_start = create_complete_at + timedelta(hours=1)
        redeem_end = min(expiry_dt - timedelta(hours=1), END_DATE + timedelta(days=20))

        if redeem_start < redeem_end:
            if notification_opened and random.random() < 0.75:
                # 만료일 가까운 시점에 사용
                base_day = max(create_complete_at.date(), (expiry_dt - timedelta(days=random.randint(0, 5))).date())
                redeemed_at = datetime.combine(base_day, time(hour=random.randint(10, 20), minute=random.randint(0, 59)))
                if redeemed_at < redeem_start:
                    redeemed_at = redeem_start
                if redeemed_at > redeem_end:
                    redeemed_at = redeem_end
            else:
                redeemed_at = rand_dt(redeem_start, redeem_end)

            events.append(
                make_event(
                    user_id=user_id,
                    coupon_id=coupon_id,
                    event_name="coupon__complete__redeem",
                    ts=redeemed_at,
                    days_to_expiry=dte_from(expiry_dt, redeemed_at),
                )
            )

    # 만료 이벤트
    if final_status == "expired":
        expired_at = expiry_dt
        events.append(
            make_event(
                user_id=user_id,
                coupon_id=coupon_id,
                event_name="coupon__complete__expire",
                ts=expired_at,
                days_to_expiry=0,
            )
        )

    # active 상태면 아직 사용하지 않았고 만료되지 않은 쿠폰
    coupons.append(
        {
            "coupon_id": coupon_id,
            "user_id": user_id,
            "brand": brand,
            "title": title,
            "coupon_type": coupon_type,
            "created_at": create_complete_at.isoformat(timespec="seconds"),
            "expiry_date": expiry_dt.date().isoformat(),
            "status": final_status,
            "redeemed_at": redeemed_at.isoformat(timespec="seconds") if redeemed_at else "",
        }
    )

# ----------------------------
# DataFrame 생성 및 저장
# ----------------------------
coupons_df = pd.DataFrame(coupons).sort_values(["created_at", "coupon_id"]).reset_index(drop=True)
events_df = pd.DataFrame(events).sort_values(["timestamp", "event_name"]).reset_index(drop=True)

coupons_df.to_csv(COUPONS_PATH, index=False)
events_df.to_csv(EVENTS_PATH, index=False)

print(f"Generated coupons: {len(coupons_df)}")
print(f"Generated events : {len(events_df)}")
print(f"Saved coupons.csv -> {COUPONS_PATH}")
print(f"Saved events.csv  -> {EVENTS_PATH}")

print("\n[Coupon status distribution]")
print(coupons_df["status"].value_counts())

print("\n[Top 10 event counts]")
print(events_df["event_name"].value_counts().head(10))