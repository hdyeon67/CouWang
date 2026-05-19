// 멤버십 로컬 저장소.
//
// 쿠폰 저장소와 같은 패턴으로 sqflite + 메모리 캐시를 함께 사용한다.
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../core/resources/app_strings.dart';
import '../features/memberships/presentation/screens/membership_detail_screen.dart';
import '../services/local_database_service.dart';
import '../services/local_image_storage_service.dart';

// MembershipDraft 초안 데이터 모델 역할을 담당하는 클래스.
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

// 멤버십 로컬 데이터와 메모리 캐시를 관리하는 저장소.
class MembershipRepository {
  MembershipRepository._();

  static final List<MembershipDetailModel> _cache = <MembershipDetailModel>[];
  static bool _initialized = false;

  // initialize 관련 처리를 수행한다.
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

  // getAll 관련 처리를 수행한다.
  static List<MembershipDetailModel> getAll() => List.unmodifiable(_cache);

  // 조건에 맞는 항목을 찾는다.
  static MembershipDetailModel? findById(String id) {
    for (final membership in _cache) {
      if (membership.id == id) {
        return membership;
      }
    }
    return null;
  }

  // 변경된 데이터나 상태를 저장한다.
  static Future<MembershipDetailModel> saveDraft(MembershipDraft draft) async {
    // 멤버십도 수정/생성을 같은 upsert 흐름으로 처리한다.
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

    final resolvedImageBytes = await _resolveImageBytes(draft);

    if (resolvedImageBytes != null && resolvedImageBytes.isNotEmpty) {
      final storedImage = await LocalImageStorageService.instance.saveImage(
        ownerType: 'memberships',
        entityId: membershipId,
        bytes: resolvedImageBytes,
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
      imageBytes = resolvedImageBytes;
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

  // 대상 데이터를 삭제한다.
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

  // addVirtualMemberships 관련 처리를 수행한다.
  static Future<void> addVirtualMemberships() async {
    // 스토어 캡처/QA용 더미 데이터.
    // 동일 id를 써서 여러 번 눌러도 중복 생성되지 않는다.
    final now = DateTime.now().toIso8601String();
    final memberships = <MembershipDraft>[
      const MembershipDraft(
        id: 'virtual_membership_ok_cashbag',
        name: AppStrings.membershipOkCashbag,
        brand: AppStrings.membershipOkCashbag,
        cardNumber: '9100123456789',
        memo: '가상 멤버십 카드',
      ),
      const MembershipDraft(
        id: 'virtual_membership_happy_point',
        name: AppStrings.membershipHappyPoint,
        brand: AppStrings.membershipHappyPoint,
        cardNumber: '9200123456789',
        memo: '가상 멤버십 카드',
      ),
      const MembershipDraft(
        id: 'virtual_membership_l_point',
        name: AppStrings.membershipLPoint,
        brand: AppStrings.membershipLPoint,
        cardNumber: '9300123456789',
        memo: '가상 멤버십 카드',
      ),
      const MembershipDraft(
        id: 'virtual_membership_cj_one',
        name: AppStrings.membershipCjOne,
        brand: AppStrings.membershipCjOne,
        cardNumber: '9400123456789',
        memo: '가상 멤버십 카드',
      ),
    ];

    for (final draft in memberships) {
      await saveDraft(
        MembershipDraft(
          id: draft.id,
          name: draft.name,
          brand: draft.brand,
          cardNumber: draft.cardNumber,
          memo: draft.memo,
          createdAt: findById(draft.id!)?.createdAt ?? now,
        ),
      );
    }
  }

  // 현재 맥락에서 사용할 값을 계산하거나 선택한다.
  static Future<Uint8List?> _resolveImageBytes(MembershipDraft draft) async {
    if (draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
      return draft.imageBytes;
    }

    final sourcePath = draft.sourceImagePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      return null;
    }

    final file = File(sourcePath);
    if (!await file.exists()) {
      return null;
    }

    return file.readAsBytes();
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

  // 조건에 맞는 항목을 찾는다.
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

  // 기존 데이터를 갱신하거나 없으면 새로 추가한다.
  static void _upsertCache(MembershipDetailModel membership) {
    final index = _cache.indexWhere((item) => item.id == membership.id);
    if (index >= 0) {
      _cache[index] = membership;
    } else {
      _cache.insert(0, membership);
    }
  }
}
