// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sleep_sync/main.dart';
import 'package:sleep_sync/state/app_state.dart';

void main() {
  testWidgets('app launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: AppState(),
        child: const SleepTrackerApp(),
      ),
    );

    expect(find.text('Last night\'s sleep'), findsOneWidget);

    // The greeting includes the time-of-day prefix (Good morning/afternoon/evening)
    // which depends on the current clock. Match by user name for stability.
    final nameFinder = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').contains('Jeicel'),
    );
    expect(nameFinder, findsOneWidget);
  });
}
