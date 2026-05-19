// 앱 전체 로컬 DB를 여는 단일 진입점.
//
// schema 생성과 migration을 한 파일에 모아둬서, 저장소 레이어는
// "어떤 테이블이 있는지"보다 "어떻게 읽고 쓰는지"에 집중하게 만든다.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// sqflite 데이터베이스 초기화와 migration을 담당하는 서비스.
class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  // init 관련 처리를 수행한다.
  Future<void> init() async {
    if (kIsWeb) {
      // 웹에서는 sqlite wasm 팩토리를 명시적으로 교체해야 같은 코드로 동작한다.
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    }
    await database;
  }

  // openDatabase 관련 처리를 수행한다.
  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'kuwang_local.db');

    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        // image_assets는 coupon/membership 본문과 분리해 파일 메타데이터만 보관한다.
        await db.execute('''
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
          )
        ''');

        await db.execute('''
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
          )
        ''');

        await db.execute('''
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
          )
        ''');

        await db.execute('''
          CREATE TABLE notification_settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            master_enabled INTEGER NOT NULL,
            expire_day_enabled INTEGER NOT NULL,
            day1_enabled INTEGER NOT NULL,
            day3_enabled INTEGER NOT NULL,
            day7_enabled INTEGER NOT NULL,
            day30_enabled INTEGER NOT NULL,
            notification_consent_asked INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
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
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 운영 앱이므로 destructive migration 대신 점진적 추가만 허용한다.
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notification_logs (
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
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE notification_settings
            ADD COLUMN notification_consent_asked INTEGER NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            UPDATE notification_settings
            SET notification_consent_asked = CASE
              WHEN master_enabled = 1 THEN 1
              ELSE 0
            END
          ''');
        }
      },
    );
  }
}
