enum DocumentKind {
  pdf('pdf'),
  text('txt');

  const DocumentKind(this.label);

  /// Short type label shown under library items ("pdf" in the reference).
  final String label;

  static DocumentKind fromName(String name) =>
      DocumentKind.values.firstWhere((k) => k.name == name, orElse: () => DocumentKind.pdf);
}

/// A document in the user's library.
class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.title,
    required this.kind,
    required this.filePath,
    required this.createdAt,
    this.thumbnailPath,
    this.pageCount,
    this.lastOpenedAt,
    this.progress = 0,
  });

  final String id;
  final String title;
  final DocumentKind kind;

  /// Absolute path of the app-owned copy of the document.
  final String filePath;
  final String? thumbnailPath;
  final int? pageCount;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  /// Reading position from 0 to 1.
  final double progress;

  /// The date the library sorts and groups by: last opened, else added.
  DateTime get activityAt => lastOpenedAt ?? createdAt;

  LibraryDocument copyWith({
    String? title,
    String? thumbnailPath,
    int? pageCount,
    DateTime? lastOpenedAt,
    double? progress,
  }) {
    return LibraryDocument(
      id: id,
      title: title ?? this.title,
      kind: kind,
      filePath: filePath,
      createdAt: createdAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      progress: progress ?? this.progress,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'file_path': filePath,
        'thumbnail_path': thumbnailPath,
        'page_count': pageCount,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
        'progress': progress,
      };

  factory LibraryDocument.fromRow(Map<String, Object?> row) {
    final lastOpened = row['last_opened_at'] as int?;
    return LibraryDocument(
      id: row['id']! as String,
      title: row['title']! as String,
      kind: DocumentKind.fromName(row['kind']! as String),
      filePath: row['file_path']! as String,
      thumbnailPath: row['thumbnail_path'] as String?,
      pageCount: row['page_count'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      lastOpenedAt: lastOpened == null ? null : DateTime.fromMillisecondsSinceEpoch(lastOpened),
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
    );
  }
}
