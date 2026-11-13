import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class NarraApp extends StatefulWidget {
  const NarraApp({super.key, this.initialLocation = '/home'});

  final String initialLocation;

  @override
  State<NarraApp> createState() => _NarraAppState();
}

class _NarraAppState extends State<NarraApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Narra',
      debugShowCheckedModeBanner: false,
      theme: buildNarraTheme(),
      routerConfig: _router,
    );
  }
}
