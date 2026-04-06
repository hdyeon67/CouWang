import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../services/local_database_service.dart';
import '../services/local_image_storage_service.dart';

class MembershipDraft {
  const MembershipDraft({
    this.id,
    required this.name,
    required this.brand,
    required this.cardNumber,
    this.memo,
    this.imageBytes,
    this.sourceImagePath,
    this.createdAt,
  });

  final String? id;
  final String name;
  final String brand;
  final String cardNumber;
  final String? memo;
  final Uint8List? imageBytes;
  final String? sourceImagePath;
  final String? createdAt;
}

class MembershipRepository {
  MembershipRepository._();

  static final List<MembershipDetailModel> _cache = <MembershipDetailModel>[];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final db = await LocalDatabaseService.instance.database;
    final rows = await db.query(
      'memberships',
      orderBy: 'created_at DESC',
    );

    _cache
      ..clear()
      ..addAll(await _mapMemberships(rows));
    _initialized = true;
  }

  static List<MembershipDetailModel> getAll() => List.unmodifiable(_cache);

  static MembershipDetailModel? findById(String id) {
    for (final membership in _cache) {
      if (membership.id == id) {
        return membership;
      }
    }
    return null;
  }

  static Future<MembershipDetailModel> saveDraft(MembershipDraft draft) async {
    final db = await LocalDatabaseService.instance.database;
    final now = DateTime.now().toIso8601String();
    final membershipId =
        draft.id ?? 'membership_${DateTime.now().microsecondsSinceEpoch}';
    String? imageAssetId;
    String? imagePath;
    Uint8List? imageBytes;

    final existing = findById(membershipId);
    if (existing != null) {
      imageAssetId = await _findImageAssetId(db, membershipId);
      imagePath = existing.imagePath;
      imageBytes = existing.imageBytes;
    }

    if (draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
      final storedImage = await LocalImageStorageService.instance.saveImage(
        ownerType: 'memberships',
        entityId: membershipId,
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
          'owner_type': 'membership',
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

    await db.insert(
      'memberships',
      {
        'id': membershipId,
        'name': draft.name,
        'brand': draft.brand,
        'card_number': draft.cardNumber,
        'memo': draft.memo,
        'image_asset_id': imageAssetId,
        'created_at': draft.createdAt ?? existing?.createdAt ?? now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final saved = MembershipDetailModel(
      id: membershipId,
      name: draft.name,
      brand: draft.brand,
      cardNumber: draft.cardNumber,
      memo: draft.memo,
      imagePath: imagePath,
      imageBytes: imageBytes,
      createdAt: draft.createdAt ?? existing?.createdAt ?? now,
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

    await db.delete('memberships', where: 'id = ?', whereArgs: [id]);
    _cache.removeWhere((membership) => membership.id == id);
  }

  static Future<List<MembershipDetailModel>> _mapMemberships(
    List<Map<String, Object?>> rows,
  ) async {
    final db = await LocalDatabaseService.instance.database;
    final mapped = <MembershipDetailModel>[];

    for (final row in rows) {
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

      mapped.add(
        MembershipDetailModel(
          id: row['id'] as String,
          name: row['name'] as String,
          brand: row['brand'] as String,
          cardNumber: row['card_number'] as String,
          memo: row['memo'] as String?,
          imagePath: imagePath,
          imageBytes: imageBytes,
          createdAt: row['created_at'] as String?,
        ),
      );
    }

    return mapped;
  }

  static Future<String?> _findImageAssetId(Database db, String membershipId) async {
    final rows = await db.query(
      'memberships',
      columns: ['image_asset_id'],
      where: 'id = ?',
      whereArgs: [membershipId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['image_asset_id'] as String?;
  }

  static void _upsertCache(MembershipDetailModel membership) {
    final index = _cache.indexWhere((item) => item.id == membership.id);
    if (index >= 0) {
      _cache[index] = membership;
    } else {
      _cache.insert(0, membership);
    }
  }
}
