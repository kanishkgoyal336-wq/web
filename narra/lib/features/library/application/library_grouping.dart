import 'package:intl/intl.dart';

import '../domain/document.dart';

class LibraryGroup {
  const LibraryGroup(this.label, this.documents);

  final String label;
  final List<LibraryDocument> documents;
}

/// Groups documents into date buckets.
///
/// "Today" and "Previous 7 Days" are confirmed by the reference. The later
/// buckets ("Previous 30 Days", then one per month) follow the same pattern
/// but have not been seen in a reference capture yet.
List<LibraryGroup> groupByDate(
  List<LibraryDocument> documents, {
  required DateTime now,
  bool descending = true,
}) {
  final sorted = [...documents]
    ..sort((a, b) => descending
        ? b.activityAt.compareTo(a.activityAt)
        : a.activityAt.compareTo(b.activityAt));

  final startOfToday = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));
  final thirtyDaysAgo = startOfToday.subtract(const Duration(days: 30));
  final monthFormat = DateFormat('MMMM y');

  String bucket(DateTime at) {
    if (!at.isBefore(startOfToday)) return 'Today';
    if (!at.isBefore(sevenDaysAgo)) return 'Previous 7 Days';
    if (!at.isBefore(thirtyDaysAgo)) return 'Previous 30 Days';
    return monthFormat.format(at);
  }

  final groups = <String, List<LibraryDocument>>{};
  for (final doc in sorted) {
    groups.putIfAbsent(bucket(doc.activityAt), () => []).add(doc);
  }
  return [for (final e in groups.entries) LibraryGroup(e.key, e.value)];
}

/// Case-insensitive title filter used by library search.
List<LibraryDocument> filterByQuery(List<LibraryDocument> documents, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return documents;
  return documents.where((d) => d.title.toLowerCase().contains(q)).toList();
}
