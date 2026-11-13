import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../library/application/library_providers.dart';
import '../library/domain/document.dart';
import 'thumbnail_service.dart';

class UnsupportedDocumentException implements Exception {
  const UnsupportedDocumentException(this.fileName);

  final String fileName;

  @override
  String toString() => '"$fileName" is not a supported file. Upload a PDF or a .txt file.';
}

/// Copies documents into app storage and registers them in the library.
class ImportService {
  ImportService({
    required this.storageDir,
    required this.thumbnails,
    required this.clock,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final Directory storageDir;
  final ThumbnailService thumbnails;
  final DateTime Function() clock;
  final Uuid _uuid;

  static const supportedExtensions = ['pdf', 'txt'];

  Directory get _documentsDir => Directory(p.join(storageDir.path, 'documents'));
  Directory get _thumbnailsDir => Directory(p.join(storageDir.path, 'thumbnails'));

  Future<LibraryDocument> importFile({required String fileName, required List<int> bytes}) async {
    final ext = p.extension(fileName).toLowerCase().replaceFirst('.', '');
    final kind = switch (ext) {
      'pdf' => DocumentKind.pdf,
      'txt' => DocumentKind.text,
      _ => throw UnsupportedDocumentException(fileName),
    };

    final id = _uuid.v4();
    await _documentsDir.create(recursive: true);
    final dest = File(p.join(_documentsDir.path, '$id.$ext'));
    await dest.writeAsBytes(bytes, flush: true);

    var document = LibraryDocument(
      id: id,
      // The reference library shows file names with their extension.
      title: fileName,
      kind: kind,
      filePath: dest.path,
      createdAt: clock(),
    );

    if (kind == DocumentKind.pdf) {
      await _thumbnailsDir.create(recursive: true);
      final result = await thumbnails.createForPdf(dest.path, p.join(_thumbnailsDir.path, '$id.png'));
      document = document.copyWith(thumbnailPath: result.path, pageCount: result.pageCount);
    }
    return document;
  }

  Future<LibraryDocument> importText({required String title, required String text}) async {
    final id = _uuid.v4();
    await _documentsDir.create(recursive: true);
    final dest = File(p.join(_documentsDir.path, '$id.txt'));
    await dest.writeAsString(text, flush: true);
    final trimmed = title.trim();
    return LibraryDocument(
      id: id,
      title: trimmed.isEmpty ? _titleFromText(text) : trimmed,
      kind: DocumentKind.text,
      filePath: dest.path,
      createdAt: clock(),
    );
  }

  static String _titleFromText(String text) {
    final firstLine = text.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Untitled';
    return firstLine.length <= 60 ? firstLine : '${firstLine.substring(0, 57)}...';
  }
}

/// Overridden at startup with the platform's application support directory.
final storageDirProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('storageDirProvider must be overridden'),
);

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) => PdfrxThumbnailService());

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    storageDir: ref.watch(storageDirProvider),
    thumbnails: ref.watch(thumbnailServiceProvider),
    clock: ref.watch(clockProvider),
  );
});
