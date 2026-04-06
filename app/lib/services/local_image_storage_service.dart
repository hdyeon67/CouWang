import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

class LocalImageStorageService {
  LocalImageStorageService._();

  static final LocalImageStorageService instance =
      LocalImageStorageService._();

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

  Future<void> deleteImage(String? absolutePath) async {
    if (absolutePath == null || absolutePath.isEmpty) {
      return;
    }
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

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
