import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/theme/tokens.dart';
import '../library/application/library_providers.dart';
import '../library/domain/document.dart';

/// Milestone 1 reader: the document's top bar and its pages. The menu bar,
/// tool rail, outline and floating player arrive in milestones 2 and 3.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final Future<LibraryDocument?> _document = _open();

  Future<LibraryDocument?> _open() async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = await repo.byId(widget.documentId);
    if (doc != null) await ref.read(documentsProvider.notifier).markOpened(doc.id);
    return doc;
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LibraryDocument?>(
      future: _document,
      builder: (context, snapshot) {
        final doc = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReaderTopBar(title: doc?.title ?? '', onClose: _close),
            Expanded(
              child: ColoredBox(
                color: NarraColors.surfaceMuted,
                child: switch (snapshot.connectionState) {
                  ConnectionState.done when doc == null => const _ReaderMessage('This document is no longer in your library.'),
                  ConnectionState.done => _DocumentBody(document: doc!),
                  _ => const Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NarraSizes.readerTopBarHeight,
      padding: const EdgeInsets.only(left: 18, right: 12),
      decoration: const BoxDecoration(
        color: NarraColors.surface,
        border: Border(bottom: BorderSide(color: NarraColors.sidebarBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: NarraText.readerTitle),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 20, color: NarraColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DocumentBody extends StatelessWidget {
  const _DocumentBody({required this.document});

  final LibraryDocument document;

  @override
  Widget build(BuildContext context) {
    if (!File(document.filePath).existsSync()) {
      return const _ReaderMessage('The saved copy of this document is missing.');
    }
    return switch (document.kind) {
      DocumentKind.pdf => PdfViewer.file(
          document.filePath,
          params: PdfViewerParams(
            backgroundColor: NarraColors.surfaceMuted,
            margin: 8,
            pageDropShadow: null,
            errorBannerBuilder: (context, error, stackTrace, documentRef) =>
                _ReaderMessage('This PDF could not be opened: $error'),
          ),
        ),
      DocumentKind.text => _TextDocument(path: document.filePath),
    };
  }
}

class _TextDocument extends StatelessWidget {
  const _TextDocument({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: File(path).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ReaderMessage('This text could not be read: ${snapshot.error}');
        if (!snapshot.hasData) return const SizedBox();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Container(
              width: 596,
              constraints: const BoxConstraints(minHeight: 842),
              color: NarraColors.surface,
              padding: const EdgeInsets.fromLTRB(46, 48, 46, 48),
              child: SelectableText(snapshot.data!, style: NarraText.body),
            ),
          ),
        );
      },
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center, style: NarraText.cardBody),
        ),
      );
}
