import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:narra/app/app.dart';
import 'package:narra/core/widgets/document_thumbnail.dart';
import 'package:narra/features/import/import_service.dart';
import 'package:narra/features/library/application/library_providers.dart';
import 'package:narra/features/library/data/in_memory_document_repository.dart';
import 'package:narra/features/library/domain/document.dart';

/// Fixed "now" so date groups are deterministic.
final testNow = DateTime(2026, 11, 13, 18);

/// The reference screenshots: 2000 x 1133 device pixels below the browser
/// chrome, at ~1.357 device pixels per logical pixel.
const referencePhysicalSize = Size(2000, 1133);
const referencePixelRatio = 1.357;

bool _fontsLoaded = false;

/// Loads every font in the app's FontManifest (Inter and the Lucide icon font)
/// so golden images render real glyphs instead of the test placeholder font.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

String fixture(String name) => '${Directory.current.path}/test/fixtures/thumbs/$name';

LibraryDocument _doc(String id, String title, String thumb, {required int daysAgo, int? openedMinutesAgo}) {
  return LibraryDocument(
    id: id,
    title: title,
    kind: DocumentKind.pdf,
    filePath: '/nonexistent/$id.pdf',
    thumbnailPath: fixture(thumb),
    createdAt: testNow.subtract(Duration(days: daysAgo, hours: 1)),
    lastOpenedAt: openedMinutesAgo == null ? null : testNow.subtract(Duration(minutes: openedMinutesAgo)),
  );
}

/// Library contents mirroring the reference captures.
List<LibraryDocument> referenceDocuments() => [
      _doc('se', 'Software Engineering — Complete Exam Notes.pdf', 'notes1.png', daysAgo: 0, openedMinutesAgo: 5),
      _doc('oopt', 'OOP_Theory_Exam_Notes.pdf', 'notes2.png', daysAgo: 0, openedMinutesAgo: 20),
      _doc('oopc', 'OOP in C++ Complete Notes (Semester 3).pdf', 'notes3.png', daysAgo: 0, openedMinutesAgo: 40),
      _doc('people', 'Understanding-People.pdf', 'cover_dark.png', daysAgo: 0, openedMinutesAgo: 60),
      _doc('dbms', 'DBMS Complete Exam Notes (25CAT-203).pdf', 'notes4.png', daysAgo: 0, openedMinutesAgo: 90),
      _doc('py', 'Python Programming Notes - BCA (Units 1-3).pdf', 'notes5.png', daysAgo: 0, openedMinutesAgo: 120),
      _doc('ib', 'Investment Banking Made Easy.pdf', 'cover_blue.png', daysAgo: 3),
      _doc('dbms-old', 'DBMS Complete Exam Notes (25CAT-203).pdf', 'notes4.png', daysAgo: 4),
    ];

Future<void> pumpNarra(
  WidgetTester tester, {
  required String location,
  List<LibraryDocument>? documents,
  Size physicalSize = referencePhysicalSize,
  double pixelRatio = referencePixelRatio,
}) async {
  await loadAppFonts();
  final docs = documents ?? referenceDocuments();
  // FileImage never completes decoding under the test harness, so thumbnails
  // are read up front and served from memory.
  final images = <String, MemoryImage>{};
  await tester.runAsync(() async {
    for (final path in docs.map((d) => d.thumbnailPath).whereType<String>()) {
      images[path] ??= MemoryImage(await File(path).readAsBytes());
    }
  });
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(InMemoryDocumentRepository(docs)),
        thumbnailImageResolverProvider.overrideWithValue((path) => images[path]!),
        clockProvider.overrideWithValue(() => testNow),
        storageDirProvider.overrideWithValue(Directory.systemTemp),
      ],
      child: NarraApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  await precacheImages(tester);
}

/// Image decoding happens on a real async boundary, which the fake test clock
/// never reaches on its own.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}
