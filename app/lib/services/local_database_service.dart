import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

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

  Future<void> init() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    }
    await database;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, 'kuwang_local.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
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
      },
    );
  }
}
