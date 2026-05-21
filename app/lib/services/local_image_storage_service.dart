// 쿠폰/멤버십 이미지를 앱 전용 디렉터리에 저장하는 서비스.
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 이미지 저장 결과를 한 번에 전달하기 위한 값 객체.
class StoredImageFile {
  const StoredImageFile({
    required this.originalName,
    required this.storedName,
    required this.relativePath,
    required this.absolutePath,
    required this.byteSize,
    this.mimeType,
  });

  final String originalName;
  final String storedName;
  final String relativePath;
  final String absolutePath;
  final int byteSize;
  final String? mimeType;
}

// 쿠폰/멤버십 이미지를 앱 전용 디렉터리에 저장하는 서비스.
//
// 이미지 바이너리를 SQLite에 직접 넣지 않고 파일 시스템에 저장한 뒤
// 경로와 메타데이터만 DB에 저장하는 구조다.
class LocalImageStorageService {
  LocalImageStorageService._();

  static final LocalImageStorageService instance =
      LocalImageStorageService._();

  // 선택한 이미지 bytes를 앱 전용 디렉터리에 저장하고 메타데이터를 반환한다.
  Future<StoredImageFile> saveImage({
    required String ownerType,
    required String entityId,
    required Uint8List bytes,
    String? sourcePath,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = _buildFileName(
      entityId: entityId,
      sourcePath: sourcePath,
    );
    final relativePath = p.join('images', ownerType, fileName);
    final absolutePath = p.join(docsDir.path, relativePath);

    await Directory(p.dirname(absolutePath)).create(recursive: true);
    final file = File(absolutePath);
    await file.writeAsBytes(bytes, flush: true);

    return StoredImageFile(
      originalName: sourcePath == null ? fileName : p.basename(sourcePath),
      storedName: fileName,
      relativePath: relativePath,
      absolutePath: absolutePath,
      byteSize: bytes.lengthInBytes,
      mimeType: _guessMimeType(sourcePath),
    );
  }

  // 저장된 이미지 파일을 실제 파일 시스템에서 삭제한다.
  Future<void> deleteImage(String? absolutePath) async {
    if (absolutePath == null || absolutePath.isEmpty) {
      return;
    }
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 저장된 이미지 파일을 다시 읽어 bytes로 반환한다.
  Future<Uint8List?> readBytes(String? absolutePath) async {
    if (absolutePath == null || absolutePath.isEmpty) {
      return null;
    }
    final file = File(absolutePath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  // DB에 저장된 relative path를 실제 absolute path로 변환한다.
  Future<String?> resolveAbsolutePath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, relativePath);
  }

  String _buildFileName({
    required String entityId,
    String? sourcePath,
  }) {
    final extension = sourcePath == null ? '.jpg' : p.extension(sourcePath);
    return '${entityId}_${DateTime.now().microsecondsSinceEpoch}$extension';
  }

  String? _guessMimeType(String? sourcePath) {
    if (sourcePath == null) {
      return null;
    }
    final ext = p.extension(sourcePath).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
