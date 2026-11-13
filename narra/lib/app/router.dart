import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/home/home_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/shell/app_shell.dart';

/// Screens swap in place inside the shell without a transition, like the
/// reference web app.
GoRouter buildRouter({String initialLocation = '/home'}) {
  Page<void> page(GoRouterState state, Widget child) => NoTransitionPage(key: state.pageKey, child: child);

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (_, state) => page(state, const HomeScreen())),
          GoRoute(path: '/library', pageBuilder: (_, state) => page(state, const LibraryScreen())),
          GoRoute(
            path: '/reader/:id',
            pageBuilder: (_, state) => page(state, ReaderScreen(documentId: state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );
}
