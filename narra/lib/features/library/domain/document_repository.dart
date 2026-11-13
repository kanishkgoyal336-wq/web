import 'document.dart';

/// Persistence boundary for library documents.
///
/// The local SQLite implementation is the source of truth on device; the
/// Firebase sync layer (milestone 6) will mirror it.
abstract interface class DocumentRepository {
  Future<List<LibraryDocument>> all();
  Future<LibraryDocument?> byId(String id);
  Future<void> upsert(LibraryDocument document);
  Future<void> delete(Iterable<String> ids);
}
