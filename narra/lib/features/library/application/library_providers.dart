import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/document.dart';
import '../domain/document_repository.dart';
import 'library_grouping.dart';

/// Overridden at startup with the platform repository.
final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => throw UnimplementedError('documentRepositoryProvider must be overridden'),
);

/// Injectable clock so date grouping is deterministic in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class DocumentsController extends AsyncNotifier<List<LibraryDocument>> {
  DocumentRepository get _repo => ref.read(documentRepositoryProvider);

  @override
  Future<List<LibraryDocument>> build() => _repo.all();

  Future<void> add(LibraryDocument document) async {
    await _repo.upsert(document);
    ref.invalidateSelf();
    await future;
  }

  Future<void> markOpened(String id) async {
    final doc = await _repo.byId(id);
    if (doc == null) return;
    await _repo.upsert(doc.copyWith(lastOpenedAt: ref.read(clockProvider)()));
    ref.invalidateSelf();
  }

  Future<void> delete(Iterable<String> ids) async {
    await _repo.delete(ids);
    ref.invalidateSelf();
    await future;
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsController, List<LibraryDocument>>(DocumentsController.new);

/// Documents for the Home "Continue" row: the four most recently opened.
final continueDocumentsProvider = Provider<AsyncValue<List<LibraryDocument>>>((ref) {
  return ref.watch(documentsProvider).whenData((docs) {
    final opened = docs.where((d) => d.lastOpenedAt != null).toList()
      ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    return opened.take(4).toList();
  });
});

enum LibraryLayout { grid, list }

class LibraryViewState {
  const LibraryViewState({
    this.layout = LibraryLayout.grid,
    this.descending = true,
    this.searchOpen = false,
    this.query = '',
    this.selected = const {},
  });

  final LibraryLayout layout;
  final bool descending;
  final bool searchOpen;
  final String query;
  final Set<String> selected;

  LibraryViewState copyWith({
    LibraryLayout? layout,
    bool? descending,
    bool? searchOpen,
    String? query,
    Set<String>? selected,
  }) {
    return LibraryViewState(
      layout: layout ?? this.layout,
      descending: descending ?? this.descending,
      searchOpen: searchOpen ?? this.searchOpen,
      query: query ?? this.query,
      selected: selected ?? this.selected,
    );
  }
}

class LibraryViewController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryViewState();

  void setLayout(LibraryLayout layout) => state = state.copyWith(layout: layout);
  void toggleSortDirection() => state = state.copyWith(descending: !state.descending);
  void openSearch() => state = state.copyWith(searchOpen: true);
  void closeSearch() => state = state.copyWith(searchOpen: false, query: '');
  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleSelected(String id) {
    final next = {...state.selected};
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(selected: next);
  }

  void setAllSelected(Iterable<String> ids, bool selected) {
    state = state.copyWith(selected: selected ? ids.toSet() : <String>{});
  }

  void clearSelection() => state = state.copyWith(selected: <String>{});
}

final libraryViewProvider =
    NotifierProvider<LibraryViewController, LibraryViewState>(LibraryViewController.new);

/// Documents after search, as date groups in the chosen sort direction.
final libraryGroupsProvider = Provider<AsyncValue<List<LibraryGroup>>>((ref) {
  final view = ref.watch(libraryViewProvider);
  final now = ref.watch(clockProvider)();
  return ref.watch(documentsProvider).whenData(
        (docs) => groupByDate(filterByQuery(docs, view.query), now: now, descending: view.descending),
      );
});
