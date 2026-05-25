import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:la_pyramide/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Test basique que l'app démarre sans erreur
    await tester.pumpWidget(
      const ProviderScope(
        child: PyraApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsNothing); // MaterialApp.router
  });
}
