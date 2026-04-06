import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../features/coupons/presentation/screens/coupon_detail_screen.dart';
import '../services/local_database_service.dart';
import '../services/local_image_storage_service.dart';

class CouponDraft {
  const CouponDraft({
    this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.barcodeNumber,
    required this.expiry,
    this.memo,
    this.isUsed = false,
    this.couponType,
    this.status,
    this.imageBytes,
    this.sourceImagePath,
    this.createdAt,
    this.usedAt,
  });

  final String? id;
  final String name;
  final String brand;
  final String category;
  final String barcodeNumber;
  final String expiry;
  final String? memo;
  final bool isUsed;
  final String? couponType;
  final CouponDetailStatus? status;
  final Uint8List? imageBytes;
  final String? sourceImagePath;
  final String? createdAt;
  final String? usedAt;
}

class CouponRepository {
  CouponRepository._();

  static final List<CouponDetailModel> _cache = <CouponDetailModel>[];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final db = await LocalDatabaseService.instance.database;
    final coupons = await db.query(
      'coupons',
      orderBy: 'created_at DESC',
    );

    _cache
      ..clear()
      ..addAll(await _mapCoupons(dbRows: coupons));
    _initialized = true;
  }

  static List<CouponDetailModel> getAll() => List.unmodifiable(_cache);

  static CouponDetailModel? findById(String id) {
    for (final coupon in _cache) {
      if (coupon.id == id) {
        return coupon;
      }
    }
    return null;
  }

  static Future<CouponDetailModel> saveDraft(CouponDraft draft) async {
    final db = await LocalDatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();
    final couponId = draft.id ?? 'coupon_${DateTime.now().microsecondsSinceEpoch}';
    String? imageAssetId;
    String? imagePath;
    Uint8List? imageBytes;

    final existing = findById(couponId);
    if (existing != null) {
      imageAssetId = await _findImageAssetId(db, couponId);
      imagePath = existing.imagePath;
      imageBytes = existing.imageBytes;
    }

    if (draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
      final storedImage = await LocalImageStorageService.instance.saveImage(
        ownerType: 'coupons',
        entityId: couponId,
        bytes: draft.imageBytes!,
        sourcePath: draft.sourceImagePath,
      );

      if (imageAssetId != null) {
        await db.update(
          'image_assets',
          {
            'original_name': storedImage.originalName,
            'stored_name': storedImage.storedName,
            'relative_path': storedImage.relativePath,
            'mime_type': storedImage.mimeType,
            'byte_size': storedImage.byteSize,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [imageAssetId],
        );
      } else {
        imageAssetId = 'img_${DateTime.now().microsecondsSinceEpoch}';
        await db.insert('image_assets', {
          'id': imageAssetId,
          'owner_type': 'coupon',
          'original_name': storedImage.originalName,
          'stored_name': storedImage.storedName,
          'relative_path': storedImage.relativePath,
          'mime_type': storedImage.mimeType,
          'byte_size': storedImage.byteSize,
          'created_at': now,
          'updated_at': now,
        });
      }

      imagePath = storedImage.absolutePath;
      imageBytes = draft.imageBytes;
    }

    final expiryDate = _parseDate(draft.expiry);
    final resolvedStatus = draft.status ??
        (draft.isUsed
            ? CouponDetailStatus.redeemed
            : _resolveStatus(expiryDate));

    await db.insert(
      'coupons',
      {
        'id': couponId,
        'name': draft.name,
        'brand': draft.brand,
        'category': draft.category,
        'code_value': draft.barcodeNumber,
        'code_type': draft.couponType ?? 'barcode',
        'expiry_at': draft.expiry,
        'memo': draft.memo,
        'status': resolvedStatus.name,
        'is_used': draft.isUsed ? 1 : 0,
        'image_asset_id': imageAssetId,
        'created_at': draft.createdAt ?? existing?.createdAt ?? now,
        'updated_at': now,
        'used_at': draft.isUsed ? (draft.usedAt ?? existing?.usedAt ?? now) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final saved = CouponDetailModel(
      id: couponId,
      brand: draft.brand,
      name: draft.name,
      category: draft.category,
      dday: _calculateDday(expiryDate),
      expiry: draft.expiry,
      barcodeNumber: draft.barcodeNumber,
      imagePath: imagePath,
      imageBytes: imageBytes,
      memo: draft.memo,
      isUsed: draft.isUsed,
      status: resolvedStatus,
      couponType: draft.couponType,
      createdAt: draft.createdAt ?? existing?.createdAt ?? now,
      usedAt: draft.isUsed ? (draft.usedAt ?? existing?.usedAt ?? now) : null,
    );

    _upsertCache(saved);
    return saved;
  }

  static Future<void> delete(String id) async {
    final db = await LocalDatabaseService.instance.database;
    final imageAssetId = await _findImageAssetId(db, id);

    if (imageAssetId != null) {
      final rows = await db.query(
        'image_assets',
        where: 'id = ?',
        whereArgs: [imageAssetId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final absolutePath = await LocalImageStorageService.instance
            .resolveAbsolutePath(rows.first['relative_path'] as String?);
        await LocalImageStorageService.instance.deleteImage(absolutePath);
      }
      await db.delete('image_assets', where: 'id = ?', whereArgs: [imageAssetId]);
    }

    await db.delete('coupons', where: 'id = ?', whereArgs: [id]);
    _cache.removeWhere((coupon) => coupon.id == id);
  }

  static Future<CouponDetailModel?> markUsed(String id) async {
    final coupon = findById(id);
    if (coupon == null) {
      return null;
    }

    return saveDraft(
      CouponDraft(
        id: coupon.id,
        name: coupon.name,
        brand: coupon.brand,
        category: coupon.category,
        barcodeNumber: coupon.barcodeNumber,
        expiry: coupon.expiry,
        memo: coupon.memo,
        isUsed: true,
        couponType: coupon.couponType,
        status: CouponDetailStatus.redeemed,
        imageBytes: coupon.imageBytes,
        sourceImagePath: coupon.imagePath,
        createdAt: coupon.createdAt,
        usedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  static Future<CouponDetailModel?> markUnused(String id) async {
    final coupon = findById(id);
    if (coupon == null) {
      return null;
    }

    return saveDraft(
      CouponDraft(
        id: coupon.id,
        name: coupon.name,
        brand: coupon.brand,
        category: coupon.category,
        barcodeNumber: coupon.barcodeNumber,
        expiry: coupon.expiry,
        memo: coupon.memo,
        isUsed: false,
        couponType: coupon.couponType,
        status: _resolveStatus(_parseDate(coupon.expiry)),
        imageBytes: coupon.imageBytes,
        sourceImagePath: coupon.imagePath,
        createdAt: coupon.createdAt,
        usedAt: null,
      ),
    );
  }

  static Future<List<CouponDetailModel>> _mapCoupons({
    required List<Map<String, Object?>> dbRows,
  }) async {
    final mapped = <CouponDetailModel>[];
    final db = await LocalDatabaseService.instance.database;

    for (final row in dbRows) {
      Uint8List? imageBytes;
      String? imagePath;
      final imageAssetId = row['image_asset_id'] as String?;

      if (imageAssetId != null && imageAssetId.isNotEmpty) {
        final imageRows = await db.query(
          'image_assets',
          where: 'id = ?',
          whereArgs: [imageAssetId],
          limit: 1,
        );
        if (imageRows.isNotEmpty) {
          imagePath = await LocalImageStorageService.instance.resolveAbsolutePath(
            imageRows.first['relative_path'] as String?,
          );
          imageBytes = await LocalImageStorageService.instance.readBytes(imagePath);
        }
      }

      final expiry = row['expiry_at'] as String;
      mapped.add(
        CouponDetailModel(
          id: row['id'] as String,
          brand: row['brand'] as String,
          name: row['name'] as String,
          category: row['category'] as String,
          dday: _calculateDday(_parseDate(expiry)),
          expiry: expiry,
          barcodeNumber: row['code_value'] as String,
          imagePath: imagePath,
          imageBytes: imageBytes,
          memo: row['memo'] as String?,
          isUsed: (row['is_used'] as int? ?? 0) == 1,
          status: _parseStatus(row['status'] as String?),
          couponType: row['code_type'] as String?,
          createdAt: row['created_at'] as String?,
          usedAt: row['used_at'] as String?,
        ),
      );
    }

    return mapped;
  }

  static Future<String?> _findImageAssetId(Database db, String couponId) async {
    final rows = await db.query(
      'coupons',
      columns: ['image_asset_id'],
      where: 'id = ?',
      whereArgs: [couponId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['image_asset_id'] as String?;
  }

  static void _upsertCache(CouponDetailModel coupon) {
    final index = _cache.indexWhere((item) => item.id == coupon.id);
    if (index >= 0) {
      _cache[index] = coupon;
    } else {
      _cache.insert(0, coupon);
    }
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('.');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static int _calculateDday(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(target.year, target.month, target.day)
        .difference(today)
        .inDays;
  }

  static CouponDetailStatus _resolveStatus(DateTime expiryDate) {
    final dday = _calculateDday(expiryDate);
    if (dday < 0) {
      return CouponDetailStatus.expired;
    }
    if (dday <= 3) {
      return CouponDetailStatus.urgent;
    }
    return CouponDetailStatus.available;
  }

  static CouponDetailStatus _parseStatus(String? value) {
    switch (value) {
      case 'urgent':
        return CouponDetailStatus.urgent;
      case 'expired':
        return CouponDetailStatus.expired;
      case 'redeemed':
        return CouponDetailStatus.redeemed;
      default:
        return CouponDetailStatus.available;
    }
  }
}
