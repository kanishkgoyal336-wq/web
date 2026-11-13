import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/brand_logo.dart';
import 'sidebar.dart';

/// Persistent frame around every screen: a fixed sidebar on wide windows,
/// and the same sidebar in a drawer on narrow ones.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= NarraSizes.compactBreakpoint) {
          return Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Sidebar(location: location),
                Expanded(child: widget.child),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            width: NarraSizes.sidebarWidth,
            backgroundColor: NarraColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(),
            child: SafeArea(
              child: Sidebar(
                location: location,
                onNavigate: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Menu',
                        icon: const Icon(LucideIcons.menu, size: 22, color: NarraColors.textPrimary),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      const BrandLogo(height: 20),
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        );
      },
    );
  }
}
