import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/pill_button.dart';
import '../import/import_actions.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.location, this.onNavigate});

  /// Current route path, used to highlight the active item.
  final String location;

  /// Called after a navigation item is chosen (closes the drawer on mobile).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryActive = location.startsWith('/library') || location.startsWith('/reader');
    final homeActive = !libraryActive;

    void go(String path) {
      onNavigate?.call();
      context.go(path);
    }

    return Container(
      width: NarraSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: NarraColors.surface,
        border: Border(right: BorderSide(color: NarraColors.sidebarBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 13, top: 21, bottom: 17),
            child: Align(alignment: Alignment.centerLeft, child: BrandLogo()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NarraSizes.sidebarPadding),
            child: Builder(
              builder: (buttonContext) => PillButton(
                icon: LucideIcons.plus,
                label: 'Add',
                filled: true,
                onPressed: () => _showAddMenu(buttonContext, ref),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NavItem(
            icon: LucideIcons.house,
            label: 'Home',
            active: homeActive,
            onTap: () => go('/home'),
          ),
          const SizedBox(height: NarraSizes.navItemGap),
          _NavItem(
            icon: LucideIcons.bookCopy,
            label: 'Library',
            active: libraryActive,
            onTap: () => go('/library'),
          ),
          const Spacer(),
          const _ProfileTile(),
        ],
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext buttonContext, WidgetRef ref) async {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(buttonContext).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset(0, box.size.height + 6), ancestor: overlay);
    final source = await showMenu<ListenSource>(
      context: buttonContext,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - topLeft.dx - box.size.width,
        0,
      ),
      constraints: BoxConstraints.tightFor(width: box.size.width),
      items: [
        for (final s in ListenSource.values)
          PopupMenuItem(
            value: s,
            height: 44,
            child: Row(children: [
              Icon(s.icon, size: 20, color: NarraColors.textPrimary),
              const SizedBox(width: 10),
              Text(s.label, style: NarraText.button),
            ]),
          ),
      ],
    );
    if (source != null && buttonContext.mounted) {
      onNavigate?.call();
      await runListenAction(buttonContext, ref, source);
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NarraSizes.sidebarPadding),
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: active ? NarraColors.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: NarraSizes.controlHeight,
              child: Row(
                children: [
                  const SizedBox(width: 19),
                  Icon(icon, size: 22, color: NarraColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(label, style: NarraText.nav),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Account summary. Until sign-in (milestone 6) the app runs as a local guest.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: NarraSizes.profileHeight,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: NarraColors.sidebarBorder))),
      padding: const EdgeInsets.only(left: 21, right: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: NarraColors.avatar, shape: BoxShape.circle),
            child: Text('G', style: narraText(16, weight: FontWeight.w500, color: NarraColors.onPrimary)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest', style: NarraText.profileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Free', style: NarraText.profilePlan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
