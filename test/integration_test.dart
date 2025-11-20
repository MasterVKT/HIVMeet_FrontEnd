import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hivmeet/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-end test: Login to Chat', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Simulate login
    await tester.enterText(find.byType(TextField).first, 'test@email.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Navigate to discovery, swipe, then to chat
    await tester.tap(find.text('Discovery'));
    await tester.pumpAndSettle();
    // Assume swipe gesture
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Message'), findsOneWidget); // Verify chat loaded
  });
}
