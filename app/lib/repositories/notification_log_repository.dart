import 'package:sqflite/sqflite.dart';

import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../services/local_database_service.dart';
import 'coupon_repository.dart';

class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.couponId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.isRead,
    required this.coupon,
  });

  final String id;
  final String couponId;
  final String notificationType;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool isRead;
  final CouponDetailModel coupon;
}

class NotificationLogRepository {
  NotificationLogRepository._();

  static Future<void> upsertLog({
    required String id,
    required String couponId,
    required String notificationType,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final db = await LocalDatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'notification_logs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    await db.insert(
      'notification_logs',
      {
        'id': id,
        'coupon_id': couponId,
        'notification_type': notificationType,
        'title': title,
        'body': body,
        'scheduled_at': scheduledAt.toIso8601String(),
        'is_read': existing.isEmpty ? 0 : (existing.first['is_read'] as int? ?? 0),
        'is_deleted': 0,
        'created_at': existing.isEmpty
            ? now
            : (existing.first['created_at'] as String? ?? now),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<NotificationLogEntry>> loadVisibleLogs() async {
    final db = await LocalDatabaseService.instance.database;
    final rows = await db.query(
      'notification_logs',
      where: 'is_deleted = 0',
      orderBy: 'scheduled_at DESC',
    );

    final now = DateTime.now();
    final items = <NotificationLogEntry>[];

    for (final row in rows) {
      final scheduledAt = DateTime.tryParse(row['scheduled_at'] as String? ?? '');
      if (scheduledAt == null || scheduledAt.isAfter(now)) {
        continue;
      }

      final couponId = row['coupon_id'] as String;
      final coupon = CouponRepository.findById(couponId);
      if (coupon == null) {
        continue;
      }

      items.add(
        NotificationLogEntry(
          id: row['id'] as String,
          couponId: couponId,
          notificationType: row['notification_type'] as String,
          title: row['title'] as String,
          body: row['body'] as String,
          scheduledAt: scheduledAt,
          isRead: (row['is_read'] as int? ?? 0) == 1,
          coupon: coupon,
        ),
      );
    }

    return items;
  }

  static Future<void> markAsRead(String id) async {
    final db = await LocalDatabaseService.instance.database;
    await db.update(
      'notification_logs',
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markLatestUnreadAsReadByCouponId(String couponId) async {
    final db = await LocalDatabaseService.instance.database;
    final rows = await db.query(
      'notification_logs',
      where: 'coupon_id = ? AND is_read = 0 AND is_deleted = 0',
      whereArgs: [couponId],
      orderBy: 'scheduled_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return;
    }
    await markAsRead(rows.first['id'] as String);
  }

  static Future<void> deleteLog(String id) async {
    final db = await LocalDatabaseService.instance.database;
    await db.update(
      'notification_logs',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAllLogs() async {
    final db = await LocalDatabaseService.instance.database;
    await db.update(
      'notification_logs',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'is_deleted = 0',
    );
  }

  static Future<void> deleteLogsByCouponId(String couponId) async {
    final db = await LocalDatabaseService.instance.database;
    await db.update(
      'notification_logs',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'coupon_id = ?',
      whereArgs: [couponId],
    );
  }
}
