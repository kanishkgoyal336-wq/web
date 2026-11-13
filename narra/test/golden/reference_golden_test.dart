@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:narra/app/app.dart';

import '../support/test_app.dart';

/// Renders each screen at the reference capture size. Compare the outputs with
/// the reference captures using tool/compare_reference.py.
void main() {
  testWidgets('home matches reference layout', (tester) async {
    await pumpNarra(tester, location: '/home');
    await expectLater(find.byType(NarraApp), matchesGoldenFile('goldens/home.png'));
  });

  testWidgets('library matches reference layout', (tester) async {
    await pumpNarra(tester, location: '/library');
    await expectLater(find.byType(NarraApp), matchesGoldenFile('goldens/library.png'));
  });

  testWidgets('home on a phone', (tester) async {
    await pumpNarra(tester, location: '/home', physicalSize: const Size(1170, 2532), pixelRatio: 3);
    await expectLater(find.byType(NarraApp), matchesGoldenFile('goldens/home_phone.png'));
  });
}
