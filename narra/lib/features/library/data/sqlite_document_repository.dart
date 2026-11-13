import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/document.dart';
import '../domain/document_repository.dart';

class SqliteDocumentRepository implements DocumentRepository {
  SqliteDocumentRepository(this._db);

  final Database _db;

  static const _table = 'documents';

  /// Opens (and migrates) the library database at [path].
  static Future<SqliteDocumentRepository> open(String path, {DatabaseFactory? factory}) async {
    final dbFactory = factory ?? databaseFactory;
    final db = await dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              kind TEXT NOT NULL,
              file_path TEXT NOT NULL,
              thumbnail_path TEXT,
              page_count INTEGER,
              created_at INTEGER NOT NULL,
              last_opened_at INTEGER,
              progress REAL NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    return SqliteDocumentRepository(db);
  }

  @override
  Future<List<LibraryDocument>> all() async {
    final rows = await _db.query(_table);
    return rows.map(LibraryDocument.fromRow).toList();
  }

  @override
  Future<LibraryDocument?> byId(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : LibraryDocument.fromRow(rows.single);
  }

  @override
  Future<void> upsert(LibraryDocument document) async {
    await _db.insert(_table, document.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    final docs = await Future.wait(idList.map(byId));
    await _db.delete(
      _table,
      where: 'id IN (${List.filled(idList.length, '?').join(',')})',
      whereArgs: idList,
    );
    // Remove the app-owned copies and thumbnails as well.
    for (final doc in docs.whereType<LibraryDocument>()) {
      for (final path in [doc.filePath, doc.thumbnailPath]) {
        if (path == null) continue;
        final file = File(path);
        if (await file.exists() && p.isAbsolute(path)) await file.delete();
      }
    }
  }
}
