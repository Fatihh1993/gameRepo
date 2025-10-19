import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_quiz_game/main.dart';

void main() {
  testWidgets('App renders root widget', (WidgetTester tester) async {
    await tester.pumpWidget(const CodeQuizGame());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
