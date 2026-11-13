import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../library/application/library_providers.dart';
import 'import_service.dart';

/// The four "Listen" entry points shown on Home and in the Add menu.
enum ListenSource {
  uploadFile('Upload File', LucideIcons.plus),
  pasteText('Paste Text', LucideIcons.type),
  pasteLink('Paste Link', LucideIcons.link),
  uploadFrom('Upload From', LucideIcons.cloudUpload);

  const ListenSource(this.label, this.icon);

  final String label;
  final IconData icon;
}

Future<void> runListenAction(BuildContext context, WidgetRef ref, ListenSource source) {
  return switch (source) {
    ListenSource.uploadFile => _uploadFile(context, ref),
    ListenSource.pasteText => _pasteText(context, ref),
    ListenSource.pasteLink => showUnavailableDialog(
        context,
        title: 'Paste Link',
        message: 'Reading web pages needs the Narra backend, which fetches and cleans up the page '
            'text. It is scheduled for milestone 4 and is not available in this build.',
      ),
    ListenSource.uploadFrom => showUnavailableDialog(
        context,
        title: 'Upload From',
        message: 'Importing from cloud storage (Google Drive, Dropbox) needs OAuth app credentials '
            'and is scheduled for milestone 4. It is not available in this build.',
      ),
  };
}

Future<void> _uploadFile(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final files = await FilePicker.pickFiles(
    dialogTitle: 'Upload a document',
    type: FileType.custom,
    allowedExtensions: ImportService.supportedExtensions,
  );
  if (files.isEmpty) return;

  final importer = ref.read(importServiceProvider);
  final documents = ref.read(documentsProvider.notifier);
  String? lastId;
  for (final file in files) {
    try {
      final doc = await importer.importFile(fileName: file.name, bytes: await file.readAsBytes());
      await documents.add(doc);
      lastId = doc.id;
    } on UnsupportedDocumentException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not import "${file.name}": $e')));
    }
  }
  if (files.length == 1 && lastId != null) router.go('/reader/$lastId');
}

Future<void> _pasteText(BuildContext context, WidgetRef ref) async {
  final router = GoRouter.of(context);
  final result = await showDialog<({String title, String text})>(
    context: context,
    builder: (_) => const _PasteTextDialog(),
  );
  if (result == null) return;
  final doc = await ref.read(importServiceProvider).importText(title: result.title, text: result.text);
  await ref.read(documentsProvider.notifier).add(doc);
  router.go('/reader/${doc.id}');
}

class _PasteTextDialog extends StatefulWidget {
  const _PasteTextDialog();

  @override
  State<_PasteTextDialog> createState() => _PasteTextDialogState();
}

class _PasteTextDialogState extends State<_PasteTextDialog> {
  final _title = TextEditingController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: narraText(15, color: NarraColors.textSecondary),
        filled: true,
        fillColor: NarraColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paste Text', style: narraText(20, weight: FontWeight.w600, lineHeight: 28)),
              const SizedBox(height: 16),
              TextField(controller: _title, style: narraText(15), decoration: _decoration('Title (optional)')),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                autofocus: true,
                minLines: 8,
                maxLines: 14,
                style: narraText(15, lineHeight: 22),
                decoration: _decoration('Paste or type the text you want to listen to'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: NarraText.button),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: PillButton(
                      icon: LucideIcons.play,
                      label: 'Listen',
                      filled: true,
                      iconSize: 18,
                      onPressed: _text.text.trim().isEmpty
                          ? null
                          : () => Navigator.of(context).pop((title: _title.text, text: _text.text)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains, honestly, that a visible feature depends on a later milestone.
Future<void> showUnavailableDialog(BuildContext context, {required String title, required String message}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: narraText(20, weight: FontWeight.w600, lineHeight: 28)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message, style: narraText(15, color: NarraColors.textSecondary, lineHeight: 22)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK', style: NarraText.button),
        ),
      ],
    ),
  );
}
