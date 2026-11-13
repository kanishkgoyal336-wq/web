import '../domain/document.dart';
import '../domain/document_repository.dart';

/// Repository used by tests and previews.
class InMemoryDocumentRepository implements DocumentRepository {
  InMemoryDocumentRepository([Iterable<LibraryDocument> seed = const []]) {
    for (final doc in seed) {
      _docs[doc.id] = doc;
    }
  }

  final _docs = <String, LibraryDocument>{};

  @override
  Future<List<LibraryDocument>> all() async => _docs.values.toList();

  @override
  Future<LibraryDocument?> byId(String id) async => _docs[id];

  @override
  Future<void> upsert(LibraryDocument document) async => _docs[document.id] = document;

  @override
  Future<void> delete(Iterable<String> ids) async => ids.forEach(_docs.remove);
}
