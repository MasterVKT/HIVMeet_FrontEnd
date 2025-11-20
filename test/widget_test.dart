// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hivmeet/main.dart';

void main() {
  testWidgets('HIVMeet app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HIVMeetApp());

    // Verify that our app loads correctly
    expect(find.text('Bienvenue sur HIVMeet Dev'), findsOneWidget);
    expect(find.text('Tester l\'application'), findsOneWidget);

    // Tap the test button and trigger a frame.
    await tester.tap(find.text('Tester l\'application'));
    await tester.pump();

    // Wait for dialog animation
    await tester.pumpAndSettle();

    // Verify that the dialog appears
    expect(find.text('🎉 Test Réussi !'), findsOneWidget);
  });
}
