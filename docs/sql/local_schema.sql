CREATE TABLE image_assets (
  id TEXT PRIMARY KEY,
  owner_type TEXT NOT NULL,
  original_name TEXT,
  stored_name TEXT NOT NULL,
  relative_path TEXT NOT NULL,
  mime_type TEXT,
  byte_size INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE coupons (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand TEXT NOT NULL,
  category TEXT NOT NULL,
  code_value TEXT NOT NULL,
  code_type TEXT NOT NULL,
  expiry_at TEXT NOT NULL,
  memo TEXT,
  status TEXT NOT NULL,
  is_used INTEGER NOT NULL DEFAULT 0,
  image_asset_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  used_at TEXT,
  FOREIGN KEY (image_asset_id) REFERENCES image_assets(id)
);

CREATE TABLE memberships (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  brand TEXT NOT NULL,
  card_number TEXT NOT NULL,
  memo TEXT,
  image_asset_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (image_asset_id) REFERENCES image_assets(id)
);

CREATE TABLE notification_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  master_enabled INTEGER NOT NULL,
  expire_day_enabled INTEGER NOT NULL,
  day1_enabled INTEGER NOT NULL,
  day3_enabled INTEGER NOT NULL,
  day7_enabled INTEGER NOT NULL,
  day30_enabled INTEGER NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE notification_logs (
  id TEXT PRIMARY KEY,
  coupon_id TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  scheduled_at TEXT NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
