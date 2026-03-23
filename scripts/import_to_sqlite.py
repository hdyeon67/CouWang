from __future__ import annotations

import sqlite3
from pathlib import Path

import pandas as pd

# ----------------------------
# 경로 설정
# ----------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

COUPONS_CSV = DATA_DIR / "coupons.csv"
EVENTS_CSV = DATA_DIR / "events.csv"
SQLITE_DB = DATA_DIR / "couwang.db"


# ----------------------------
# CSV 로드
# ----------------------------
def load_coupons(csv_path: Path) -> pd.DataFrame:
    if not csv_path.exists():
        raise FileNotFoundError(f"쿠폰 CSV 파일을 찾을 수 없습니다: {csv_path}")

    df = pd.read_csv(csv_path)

    required_columns = [
        "coupon_id",
        "user_id",
        "brand",
        "title",
        "coupon_type",
        "created_at",
        "expiry_date",
        "status",
        "redeemed_at",
    ]

    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"coupons.csv에 필요한 컬럼이 없습니다: {missing}")

    # 문자열 컬럼 정리
    for col in ["coupon_id", "user_id", "brand", "title", "coupon_type", "status", "redeemed_at"]:
        df[col] = df[col].fillna("").astype(str)

    # 날짜/시간 컬럼 정리
    df["created_at"] = pd.to_datetime(df["created_at"], errors="coerce")
    df["expiry_date"] = pd.to_datetime(df["expiry_date"], errors="coerce").dt.date.astype(str)

    # redeemed_at은 빈 문자열 허용
    df["redeemed_at"] = df["redeemed_at"].replace("nan", "").fillna("")
    non_empty_mask = df["redeemed_at"].str.strip() != ""
    df.loc[non_empty_mask, "redeemed_at"] = pd.to_datetime(
        df.loc[non_empty_mask, "redeemed_at"], errors="coerce"
    ).dt.strftime("%Y-%m-%dT%H:%M:%S")
    df["redeemed_at"] = df["redeemed_at"].fillna("")

    # created_at도 문자열 저장 형식 통일
    df["created_at"] = df["created_at"].dt.strftime("%Y-%m-%dT%H:%M:%S")

    return df


def load_events(csv_path: Path) -> pd.DataFrame:
    if not csv_path.exists():
        raise FileNotFoundError(f"이벤트 CSV 파일을 찾을 수 없습니다: {csv_path}")

    df = pd.read_csv(csv_path)

    required_columns = [
        "event_id",
        "user_id",
        "coupon_id",
        "event_name",
        "timestamp",
        "days_to_expiry",
        "device_os",
        "app_version",
    ]

    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"events.csv에 필요한 컬럼이 없습니다: {missing}")

    # 문자열 컬럼 정리
    for col in ["event_id", "user_id", "coupon_id", "event_name", "device_os", "app_version"]:
        df[col] = df[col].fillna("").astype(str)

    # timestamp 정리
    df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce").dt.strftime("%Y-%m-%dT%H:%M:%S")

    # days_to_expiry 정리
    df["days_to_expiry"] = pd.to_numeric(df["days_to_expiry"], errors="coerce")

    return df


# ----------------------------
# 테이블 생성
# ----------------------------
def create_tables(conn: sqlite3.Connection) -> None:
    cursor = conn.cursor()

    cursor.execute("DROP TABLE IF EXISTS coupons;")
    cursor.execute("DROP TABLE IF EXISTS events;")

    cursor.execute(
        """
        CREATE TABLE coupons (
            coupon_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            brand TEXT NOT NULL,
            title TEXT NOT NULL,
            coupon_type TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expiry_date TEXT NOT NULL,
            status TEXT NOT NULL,
            redeemed_at TEXT
        );
        """
    )

    cursor.execute(
        """
        CREATE TABLE events (
            event_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            coupon_id TEXT,
            event_name TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            days_to_expiry INTEGER,
            device_os TEXT,
            app_version TEXT
        );
        """
    )

    # 조회 성능용 인덱스
    cursor.execute("CREATE INDEX idx_coupons_user_id ON coupons(user_id);")
    cursor.execute("CREATE INDEX idx_coupons_brand ON coupons(brand);")
    cursor.execute("CREATE INDEX idx_coupons_status ON coupons(status);")

    cursor.execute("CREATE INDEX idx_events_user_id ON events(user_id);")
    cursor.execute("CREATE INDEX idx_events_coupon_id ON events(coupon_id);")
    cursor.execute("CREATE INDEX idx_events_event_name ON events(event_name);")
    cursor.execute("CREATE INDEX idx_events_timestamp ON events(timestamp);")

    conn.commit()


# ----------------------------
# 데이터 적재
# ----------------------------
def insert_data(conn: sqlite3.Connection, coupons_df: pd.DataFrame, events_df: pd.DataFrame) -> None:
    coupons_df.to_sql("coupons", conn, if_exists="append", index=False)
    events_df.to_sql("events", conn, if_exists="append", index=False)


# ----------------------------
# 검증 출력
# ----------------------------
def print_summary(conn: sqlite3.Connection) -> None:
    cursor = conn.cursor()

    coupons_count = cursor.execute("SELECT COUNT(*) FROM coupons;").fetchone()[0]
    events_count = cursor.execute("SELECT COUNT(*) FROM events;").fetchone()[0]

    print(f"\n[SQLite 적재 완료]")
    print(f"- coupons rows: {coupons_count}")
    print(f"- events rows : {events_count}")

    print("\n[coupons status distribution]")
    for row in cursor.execute(
        """
        SELECT status, COUNT(*) AS cnt
        FROM coupons
        GROUP BY status
        ORDER BY cnt DESC;
        """
    ).fetchall():
        print(f"- {row[0]}: {row[1]}")

    print("\n[top 10 event counts]")
    for row in cursor.execute(
        """
        SELECT event_name, COUNT(*) AS cnt
        FROM events
        GROUP BY event_name
        ORDER BY cnt DESC
        LIMIT 10;
        """
    ).fetchall():
        print(f"- {row[0]}: {row[1]}")


# ----------------------------
# 메인 실행
# ----------------------------
def main() -> None:
    print("[1] CSV 파일 로드 중...")
    coupons_df = load_coupons(COUPONS_CSV)
    events_df = load_events(EVENTS_CSV)

    print(f"- coupons.csv rows: {len(coupons_df)}")
    print(f"- events.csv rows : {len(events_df)}")

    print("\n[2] SQLite DB 생성 및 테이블 초기화 중...")
    conn = sqlite3.connect(SQLITE_DB)

    try:
        create_tables(conn)

        print("[3] 데이터 적재 중...")
        insert_data(conn, coupons_df, events_df)

        print_summary(conn)

    finally:
        conn.close()

    print(f"\nSaved SQLite DB -> {SQLITE_DB}")


if __name__ == "__main__":
    main()