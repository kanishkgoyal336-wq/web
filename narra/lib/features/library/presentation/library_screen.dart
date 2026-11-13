import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/document_thumbnail.dart';
import '../../../core/widgets/pill_button.dart';
import '../../import/import_actions.dart';
import '../application/library_grouping.dart';
import '../application/library_providers.dart';
import '../domain/document.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(libraryGroupsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LibraryHeader(),
        _SortRow(groups: groups),
        const Divider(),
        Expanded(
          child: groups.when(
            loading: () => const Center(
              child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => _LibraryMessage(
              title: 'Your library could not be loaded',
              detail: '$error',
              action: PillButton(
                icon: LucideIcons.rotateCw,
                label: 'Try again',
                onPressed: () => ref.invalidate(documentsProvider),
              ),
            ),
            data: (data) => _LibraryBody(groups: data),
          ),
        ),
      ],
    );
  }
}

class _LibraryHeader extends ConsumerStatefulWidget {
  const _LibraryHeader();

  @override
  ConsumerState<_LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends ConsumerState<_LibraryHeader> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(libraryViewProvider);
    final controller = ref.read(libraryViewProvider.notifier);

    Widget iconButton(IconData icon, String tooltip, VoidCallback onPressed, {bool selected = false}) {
      return IconButton(
        tooltip: tooltip,
        isSelected: selected,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          fixedSize: const Size(40, 40),
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          hoverColor: NarraColors.surfaceMuted,
        ),
        icon: Icon(icon, size: 20, color: NarraColors.textPrimary),
      );
    }

    return SizedBox(
      height: NarraSizes.libraryHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 16),
        child: Row(
          children: [
            if (view.searchOpen)
              Expanded(
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: controller.setQuery,
                  style: narraText(15),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search your library',
                    hintStyle: narraText(15, color: NarraColors.textSecondary),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: NarraColors.textSecondary),
                    filled: true,
                    fillColor: NarraColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              )
            else ...[
              Text('Library', style: NarraText.pageTitle),
              const Spacer(),
              const _RecentsMenu(),
              const SizedBox(width: 15),
            ],
            iconButton(LucideIcons.alignJustify, 'List view', () => controller.setLayout(LibraryLayout.list),
                selected: view.layout == LibraryLayout.list),
            iconButton(LucideIcons.layoutGrid, 'Grid view', () => controller.setLayout(LibraryLayout.grid),
                selected: view.layout == LibraryLayout.grid),
            if (view.searchOpen)
              iconButton(LucideIcons.x, 'Close search', () {
                _search.clear();
                controller.closeSearch();
              })
            else
              iconButton(LucideIcons.search, 'Search', controller.openSearch),
          ],
        ),
      ),
    );
  }
}

/// "Recents" view selector. The reference shows only this option so far; the
/// other options will be added once a capture of the open menu is available.
class _RecentsMenu extends StatelessWidget {
  const _RecentsMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'View',
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'recents',
          child: Row(children: [
            Text('Recents', style: NarraText.control),
            const Spacer(),
            const Icon(LucideIcons.check, size: 16),
          ]),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recents', style: NarraText.control),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 16, color: NarraColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends ConsumerWidget {
  const _SortRow({required this.groups});

  final AsyncValue<List<LibraryGroup>> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(libraryViewProvider);
    final controller = ref.read(libraryViewProvider.notifier);
    final ids = groups.when(
      data: (g) => [for (final group in g) ...group.documents.map((d) => d.id)],
      loading: () => const <String>[],
      error: (_, _) => const <String>[],
    );
    final allSelected = ids.isNotEmpty && ids.every(view.selected.contains);
    final someSelected = view.selected.isNotEmpty;

    return SizedBox(
      height: NarraSizes.librarySortRowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          children: [
            SelectBox(
              value: allSelected ? true : (someSelected ? null : false),
              semanticLabel: 'Select all',
              onChanged: ids.isEmpty ? null : () => controller.setAllSelected(ids, !allSelected),
            ),
            const SizedBox(width: 13),
            if (someSelected) ...[
              Text('${view.selected.length} selected', style: NarraText.control),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref, view.selected),
                icon: const Icon(LucideIcons.trash2, size: 16, color: NarraColors.textPrimary),
                label: Text('Delete', style: NarraText.control),
              ),
            ] else
              InkWell(
                onTap: controller.toggleSortDirection,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Date', style: NarraText.control),
                      const SizedBox(width: 4),
                      Icon(
                        view.descending ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                        size: 17,
                        color: NarraColors.textPrimary,
                        semanticLabel: view.descending ? 'Newest first' : 'Oldest first',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Set<String> ids) async {
    final count = ids.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${count == 1 ? 'this item' : '$count items'}?',
            style: narraText(20, weight: FontWeight.w600, lineHeight: 28)),
        content: Text('This removes them from your library and deletes the saved copies.',
            style: narraText(15, color: NarraColors.textSecondary, lineHeight: 22)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: NarraText.button)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: NarraText.button.copyWith(color: const Color(0xFFD92D20))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(documentsProvider.notifier).delete(ids);
    ref.read(libraryViewProvider.notifier).clearSelection();
  }
}

/// 16px square checkbox with the reference's light grey border.
class SelectBox extends StatelessWidget {
  const SelectBox({super.key, required this.value, required this.onChanged, required this.semanticLabel});

  /// true = checked, null = partially checked, false = empty.
  final bool? value;
  final VoidCallback? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final active = value != false;
    return Semantics(
      checked: value == true,
      mixed: value == null,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onChanged,
        child: MouseRegion(
          cursor: onChanged == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: active ? NarraColors.primary : NarraColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: active ? NarraColors.primary : NarraColors.checkboxBorder, width: 1.5),
            ),
            child: active
                ? Icon(value == null ? LucideIcons.minus : LucideIcons.check, size: 12, color: NarraColors.onPrimary)
                : null,
          ),
        ),
      ),
    );
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody({required this.groups});

  final List<LibraryGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(libraryViewProvider);
    if (groups.isEmpty) {
      if (view.query.isNotEmpty) {
        return _LibraryMessage(title: 'No results', detail: 'Nothing in your library matches "${view.query}".');
      }
      return _LibraryMessage(
        title: 'Your library is empty',
        detail: 'Upload a PDF or text file, or paste text, to start listening.',
        action: PillButton(
          icon: LucideIcons.plus,
          label: 'Upload File',
          filled: true,
          onPressed: () => runListenAction(context, ref, ListenSource.uploadFile),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - NarraSizes.libraryGridPadding * 2;
        // Columns target 234px; the small tolerance keeps the reference's five
        // columns when the window is a pixel or two narrower.
        final columns = math.max(1, ((usable + 8) / NarraSizes.libraryColumnWidth).floor());
        final cellWidth = usable / columns;
        return ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 48),
          children: [
            for (var g = 0; g < groups.length; g++) ...[
              if (g > 0) const SizedBox(height: NarraSizes.libraryRunSpacing),
              Padding(
                padding: const EdgeInsets.only(left: 33),
                child: Semantics(header: true, child: Text(groups[g].label, style: NarraText.groupHeading)),
              ),
              if (view.layout == LibraryLayout.grid) ...[
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NarraSizes.libraryGridPadding),
                  child: Wrap(
                    runSpacing: NarraSizes.libraryRunSpacing,
                    children: [
                      for (final doc in groups[g].documents)
                        SizedBox(width: cellWidth, child: _GridItem(document: doc)),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                for (final doc in groups[g].documents) _ListItem(document: doc),
              ],
            ],
          ],
        );
      },
    );
  }
}

void _openOrToggle(BuildContext context, WidgetRef ref, LibraryDocument doc) {
  final view = ref.read(libraryViewProvider);
  if (view.selected.isNotEmpty) {
    ref.read(libraryViewProvider.notifier).toggleSelected(doc.id);
  } else {
    context.go('/reader/${doc.id}');
  }
}

class _GridItem extends ConsumerStatefulWidget {
  const _GridItem({required this.document});

  final LibraryDocument document;

  @override
  ConsumerState<_GridItem> createState() => _GridItemState();
}

class _GridItemState extends ConsumerState<_GridItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final view = ref.watch(libraryViewProvider);
    final selected = view.selected.contains(doc.id);
    final showCheck = _hover || view.selected.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openOrToggle(context, ref, doc),
        onLongPress: () => ref.read(libraryViewProvider.notifier).toggleSelected(doc.id),
        child: Semantics(
          button: true,
          selected: selected,
          label: '${doc.title}, ${doc.kind.label}',
          excludeSemantics: true,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: selected ? Border.all(color: NarraColors.primary, width: 2) : null,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: DocumentThumbnail(document: doc, size: NarraSizes.libraryThumbnail),
                  ),
                  if (showCheck)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: SelectBox(
                        value: selected,
                        semanticLabel: 'Select ${doc.title}',
                        onChanged: () => ref.read(libraryViewProvider.notifier).toggleSelected(doc.id),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: NarraSizes.libraryTitleMaxWidth),
                child: Text(
                  doc.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: NarraText.libraryTitle,
                ),
              ),
              const SizedBox(height: 2),
              Text(doc.kind.label, style: NarraText.libraryMeta),
            ],
          ),
        ),
      ),
    );
  }
}

/// List layout. Its exact styling has not been captured yet; it reuses the
/// grid's type scale and spacing.
class _ListItem extends ConsumerWidget {
  const _ListItem({required this.document});

  final LibraryDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(libraryViewProvider);
    final selected = view.selected.contains(document.id);
    return InkWell(
      onTap: () => _openOrToggle(context, ref, document),
      onLongPress: () => ref.read(libraryViewProvider.notifier).toggleSelected(document.id),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: selected ? NarraColors.sentenceHighlight : null,
        child: Row(
          children: [
            SelectBox(
              value: selected,
              semanticLabel: 'Select ${document.title}',
              onChanged: () => ref.read(libraryViewProvider.notifier).toggleSelected(document.id),
            ),
            const SizedBox(width: 17),
            DocumentThumbnail(document: document, size: const Size(30, 42)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: NarraText.libraryTitle),
            ),
            const SizedBox(width: 16),
            SizedBox(width: 48, child: Text(document.kind.label, style: NarraText.libraryMeta)),
            SizedBox(
              width: 120,
              child: Text(
                DateFormat.yMMMd().format(document.activityAt),
                textAlign: TextAlign.right,
                style: NarraText.libraryMeta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({required this.title, required this.detail, this.action});

  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center, style: narraText(18, weight: FontWeight.w600, lineHeight: 24)),
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center, style: NarraText.cardBody),
              if (action != null) ...[
                const SizedBox(height: 20),
                SizedBox(width: 180, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
