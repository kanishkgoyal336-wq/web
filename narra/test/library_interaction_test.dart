import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('sidebar navigates between Home and Library', (tester) async {
    await pumpNarra(tester, location: '/home');
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Previous 7 Days'), findsOneWidget);
  });

  testWidgets('Continue shows the four most recently opened documents', (tester) async {
    await pumpNarra(tester, location: '/home');
    expect(find.text('Software Engineering — Complete Exam Notes.pdf'), findsOneWidget);
    expect(find.text('Understanding-People.pdf'), findsOneWidget);
    // Fifth most recent is not shown.
    expect(find.text('DBMS Complete Exam Notes (25CAT-203).pdf'), findsNothing);
  });

  testWidgets('library search filters documents', (tester) async {
    await pumpNarra(tester, location: '/library');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'oop');
    await tester.pumpAndSettle();
    await precacheImages(tester);

    expect(find.text('OOP_Theory_Exam_Notes.pdf'), findsOneWidget);
    expect(find.text('Investment Banking Made Easy.pdf'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('date sort toggles direction', (tester) async {
    await pumpNarra(tester, location: '/library');
    expect(find.byIcon(LucideIcons.arrowDown), findsOneWidget);
    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
    // Oldest group first.
    final prev = tester.getTopLeft(find.text('Previous 7 Days'));
    final today = tester.getTopLeft(find.text('Today'));
    expect(prev.dy, lessThan(today.dy));
  });

  testWidgets('select all and delete removes documents after confirmation', (tester) async {
    await pumpNarra(tester, location: '/library');
    await tester.tap(find.bySemanticsLabel('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('8 selected'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty'), findsOneWidget);
  });

  testWidgets('features that need the backend explain why instead of doing nothing', (tester) async {
    await pumpNarra(tester, location: '/home');
    await tester.tap(find.bySemanticsLabel('Paste Link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('milestone 4'), findsOneWidget);
  });
}
