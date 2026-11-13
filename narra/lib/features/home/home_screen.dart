import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/document_thumbnail.dart';
import '../../core/widgets/pill_button.dart';
import '../import/import_actions.dart';
import '../library/application/library_providers.dart';
import '../library/domain/document.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(continueDocumentsProvider).when(
          data: (docs) => docs,
          loading: () => const <LibraryDocument>[],
          error: (_, _) => const <LibraryDocument>[],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: NarraSizes.homeContentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: compact ? 16 : 44),
                  if (recents.isNotEmpty) ...[
                    const _SectionHeading('Continue'),
                    const SizedBox(height: 24),
                    _ContinueRow(documents: recents, compact: compact),
                    const SizedBox(height: 35),
                  ],
                  const _SectionHeading('Listen'),
                  const SizedBox(height: 12),
                  _ListenRow(compact: compact),
                  const SizedBox(height: 24),
                  const _SectionHeading('Create'),
                  const SizedBox(height: 12),
                  _CreateGrid(columns: compact ? 1 : 2),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(text, style: NarraText.sectionHeading));
}

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({required this.documents, required this.compact});

  final List<LibraryDocument> documents;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget item(LibraryDocument doc) => _ContinueItem(document: doc);
    if (compact) {
      return SizedBox(
        height: NarraSizes.homeThumbnail.height + 16 + NarraSizes.homeTitleBlockHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [for (final d in documents) SizedBox(width: 150, child: item(d))],
        ),
      );
    }
    // Four equal columns; empty slots keep the grid aligned like the reference.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(child: i < documents.length ? item(documents[i]) : const SizedBox()),
      ],
    );
  }
}

class _ContinueItem extends StatelessWidget {
  const _ContinueItem({required this.document});

  final LibraryDocument document;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue ${document.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go('/reader/${document.id}'),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            children: [
              DocumentThumbnail(document: document, size: NarraSizes.homeThumbnail),
              const SizedBox(height: 16),
              SizedBox(
                height: NarraSizes.homeTitleBlockHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    document.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NarraText.thumbnailTitle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListenRow extends ConsumerWidget {
  const _ListenRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget pill(ListenSource s) => PillButton(
          icon: s.icon,
          label: s.label,
          onPressed: () => runListenAction(context, ref, s),
        );
    const sources = ListenSource.values;
    if (compact) {
      return Column(children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(children: [
            Expanded(child: pill(sources[row * 2])),
            const SizedBox(width: 12),
            Expanded(child: pill(sources[row * 2 + 1])),
          ]),
        ],
      ]);
    }
    return Row(
      children: [
        for (var i = 0; i < sources.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: pill(sources[i])),
        ],
      ],
    );
  }
}

enum CreateKind {
  document(
    'Document',
    'Create a polished document from a topic, file, or notes',
    LucideIcons.fileText,
    NarraColors.documentTile,
    NarraColors.documentIcon,
  ),
  podcast(
    'Podcast',
    'Turn any topic or source into a podcast-style audio summary',
    LucideIcons.micVocal,
    NarraColors.podcastTile,
    NarraColors.podcastIcon,
  ),
  quiz(
    'Quiz',
    'Test understanding with practice questions and review prompts',
    LucideIcons.messageCircleQuestionMark,
    NarraColors.quizTile,
    NarraColors.quizIcon,
  ),
  summary(
    'Summary',
    'Get key points, takeaways, and a quick overview',
    LucideIcons.clipboardList,
    NarraColors.summaryTile,
    NarraColors.summaryIcon,
  );

  const CreateKind(this.title, this.description, this.icon, this.tile, this.iconColor);

  final String title;
  final String description;
  final IconData icon;
  final Color tile;
  final Color iconColor;
}

class _CreateGrid extends StatelessWidget {
  const _CreateGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    const kinds = CreateKind.values;
    final rows = <Widget>[];
    for (var i = 0; i < kinds.length; i += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: 12),
            Expanded(child: i + c < kinds.length ? _CreateCard(kind: kinds[i + c]) : const SizedBox()),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({required this.kind});

  final CreateKind kind;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${kind.title}. ${kind.description}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showUnavailableDialog(
            context,
            title: kind.title,
            message: 'Creating a ${kind.title.toLowerCase()} uses Narra\'s AI backend (Firebase '
                'with the Claude API), which is scheduled for milestone 5. It is not available '
                'in this build.',
          ),
          child: Padding(
            padding: const EdgeInsets.all(NarraSizes.createCardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: NarraSizes.createTile,
                  height: NarraSizes.createTile,
                  decoration: BoxDecoration(
                    color: kind.tile,
                    borderRadius: BorderRadius.circular(NarraSizes.createTileRadius),
                  ),
                  child: Icon(kind.icon, size: 32, color: kind.iconColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.title, style: NarraText.cardTitle),
                        Text(kind.description, style: NarraText.cardBody),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
