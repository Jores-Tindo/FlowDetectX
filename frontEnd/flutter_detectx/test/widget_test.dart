import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowdetectx/main.dart';
import 'package:flowdetectx/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create AuthProvider instance
    final authProvider = AuthProvider();

    // Build our app with required providers
    await tester.pumpWidget(
      FlowDetectXApp(authProvider: authProvider),
    );

    // Verify that the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
