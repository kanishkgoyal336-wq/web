import 'package:flutter_test/flutter_test.dart';
import 'package:narra/features/library/application/library_grouping.dart';
import 'package:narra/features/library/domain/document.dart';

LibraryDocument doc(String id, DateTime created, {DateTime? opened, String? title}) => LibraryDocument(
      id: id,
      title: title ?? id,
      kind: DocumentKind.pdf,
      filePath: '/$id.pdf',
      createdAt: created,
      lastOpenedAt: opened,
    );

void main() {
  final now = DateTime(2026, 11, 13, 18);

  test('groups into Today / Previous 7 Days / Previous 30 Days / months', () {
    final groups = groupByDate([
      doc('today', now.subtract(const Duration(hours: 2))),
      doc('yesterday', now.subtract(const Duration(days: 1))),
      doc('week', now.subtract(const Duration(days: 6))),
      doc('month', now.subtract(const Duration(days: 20))),
      doc('old', DateTime(2026, 8, 2)),
    ], now: now);

    expect(groups.map((g) => g.label), ['Today', 'Previous 7 Days', 'Previous 30 Days', 'August 2026']);
    expect(groups[1].documents.map((d) => d.id), ['yesterday', 'week']);
  });

  test('uses last opened date ahead of the added date', () {
    final groups = groupByDate([
      doc('reopened', DateTime(2026, 1, 1), opened: now.subtract(const Duration(minutes: 5))),
    ], now: now);
    expect(groups.single.label, 'Today');
  });

  test('sort direction flips order within and across groups', () {
    final docs = [
      doc('a', now.subtract(const Duration(hours: 1))),
      doc('b', now.subtract(const Duration(hours: 3))),
      doc('c', now.subtract(const Duration(days: 3))),
    ];
    final desc = groupByDate(docs, now: now);
    final asc = groupByDate(docs, now: now, descending: false);
    expect(desc.expand((g) => g.documents).map((d) => d.id), ['a', 'b', 'c']);
    expect(asc.expand((g) => g.documents).map((d) => d.id), ['c', 'b', 'a']);
    expect(asc.first.label, 'Previous 7 Days');
  });

  test('search filters by title, case-insensitively', () {
    final docs = [doc('1', now, title: 'OOP in C++ Notes'), doc('2', now, title: 'DBMS Notes')];
    expect(filterByQuery(docs, 'oop').map((d) => d.id), ['1']);
    expect(filterByQuery(docs, '  ').length, 2);
    expect(filterByQuery(docs, 'missing'), isEmpty);
  });
}
