// Asteroids Flutter widget tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asteroids_flutter/main.dart';

void main() {
  testWidgets('Asteroids app loads without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AsteroidsApp());

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Check for game screen
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('Game UI elements are present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AsteroidsApp());
    await tester.pump();

    // Check for score display
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.textContaining('Lives:'), findsOneWidget);
    expect(find.textContaining('High:'), findsOneWidget);
  });
}
