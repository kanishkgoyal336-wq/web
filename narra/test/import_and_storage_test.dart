import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narra/features/import/import_service.dart';
import 'package:narra/features/import/thumbnail_service.dart';
import 'package:narra/features/library/data/sqlite_document_repository.dart';
import 'package:narra/features/library/domain/document.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeThumbnails implements ThumbnailService {
  final calls = <String>[];

  @override
  Future<ThumbnailResult> createForPdf(String pdfPath, String outPath) async {
    calls.add(pdfPath);
    await File(outPath).writeAsBytes([0]);
    return ThumbnailResult(path: outPath, pageCount: 172);
  }
}

void main() {
  late Directory dir;
  final now = DateTime(2026, 11, 13, 18);

  setUpAll(sqfliteFfiInit);
  setUp(() async => dir = await Directory.systemTemp.createTemp('narra_test'));
  tearDown(() async => dir.delete(recursive: true));

  group('ImportService', () {
    test('imports a PDF: copies it, renders a thumbnail, keeps the file name as title', () async {
      final thumbs = FakeThumbnails();
      final service = ImportService(storageDir: dir, thumbnails: thumbs, clock: () => now);
      final doc = await service.importFile(fileName: 'OOP_Theory_Exam_Notes.pdf', bytes: [1, 2, 3]);

      expect(doc.title, 'OOP_Theory_Exam_Notes.pdf');
      expect(doc.kind, DocumentKind.pdf);
      expect(await File(doc.filePath).readAsBytes(), [1, 2, 3]);
      expect(p.isWithin(dir.path, doc.filePath), isTrue);
      expect(doc.thumbnailPath, isNotNull);
      expect(doc.pageCount, 172);
      expect(doc.createdAt, now);
      expect(thumbs.calls, [doc.filePath]);
    });

    test('imports a .txt file without a thumbnail', () async {
      final thumbs = FakeThumbnails();
      final service = ImportService(storageDir: dir, thumbnails: thumbs, clock: () => now);
      final doc = await service.importFile(fileName: 'notes.TXT', bytes: 'hello'.codeUnits);
      expect(doc.kind, DocumentKind.text);
      expect(doc.thumbnailPath, isNull);
      expect(thumbs.calls, isEmpty);
    });

    test('rejects unsupported formats', () async {
      final service = ImportService(storageDir: dir, thumbnails: FakeThumbnails(), clock: () => now);
      expect(
        () => service.importFile(fileName: 'slides.pptx', bytes: [0]),
        throwsA(isA<UnsupportedDocumentException>()),
      );
    });

    test('pasted text without a title is named after its first line', () async {
      final service = ImportService(storageDir: dir, thumbnails: FakeThumbnails(), clock: () => now);
      final doc = await service.importText(title: '  ', text: '\nChapter 1: Abstraction\nBody text');
      expect(doc.title, 'Chapter 1: Abstraction');
      expect(await File(doc.filePath).readAsString(), '\nChapter 1: Abstraction\nBody text');
    });
  });

  group('SqliteDocumentRepository', () {
    test('round-trips documents and deletes their files', () async {
      final repo = await SqliteDocumentRepository.open(p.join(dir.path, 'library.db'), factory: databaseFactoryFfi);
      final file = File(p.join(dir.path, 'a.pdf'))..writeAsBytesSync([1]);
      final thumb = File(p.join(dir.path, 'a.png'))..writeAsBytesSync([1]);
      final doc = LibraryDocument(
        id: 'a',
        title: 'A.pdf',
        kind: DocumentKind.pdf,
        filePath: file.path,
        thumbnailPath: thumb.path,
        pageCount: 3,
        createdAt: now,
        lastOpenedAt: now.add(const Duration(minutes: 1)),
        progress: 0.25,
      );

      await repo.upsert(doc);
      final loaded = (await repo.byId('a'))!;
      expect(loaded.title, 'A.pdf');
      expect(loaded.pageCount, 3);
      expect(loaded.lastOpenedAt, doc.lastOpenedAt);
      expect(loaded.progress, 0.25);

      await repo.upsert(loaded.copyWith(title: 'Renamed.pdf'));
      expect((await repo.all()).single.title, 'Renamed.pdf');

      await repo.delete(['a']);
      expect(await repo.all(), isEmpty);
      expect(file.existsSync(), isFalse);
      expect(thumb.existsSync(), isFalse);
    });
  });
}
