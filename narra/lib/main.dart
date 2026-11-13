import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'features/import/import_service.dart';
import 'features/library/application/library_providers.dart';
import 'features/library/data/sqlite_document_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();

  final storage = await getApplicationSupportDirectory();
  final repository = await SqliteDocumentRepository.open(p.join(storage.path, 'library.db'));

  runApp(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(repository),
        storageDirProvider.overrideWithValue(storage),
      ],
      child: const NarraApp(),
    ),
  );
}
