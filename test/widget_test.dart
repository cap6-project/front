import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_dot/screens/home_screen.dart';

void main() {
  testWidgets('PuzzleDot Navigation Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });
}
