import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/widgets/chat/message_input.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final locator = GetIt.instance;
    await locator.reset();
    final localization = LocalizationService();
    await localization.initialize();
    locator.registerSingleton<LocalizationService>(localization);
  });

  tearDownAll(() => GetIt.instance.reset());

  Widget buildSubject(
    Size size, {
    TextScaler textScaler = TextScaler.noScaling,
  }) =>
      MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageInput(
                onSendMessage: (_, __) {},
                onSendMediaMessage: (File _, MessageType __) {},
                onStartTyping: () {},
                onStopTyping: () {},
              ),
            ),
          ),
        ),
      );

  testWidgets('composer keeps a one-to-four-line field and send affordance',
      (tester) async {
    await tester.pumpWidget(buildSubject(const Size(320, 640)));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLines, 4);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsOneWidget);
    expect(find.byIcon(Icons.emoji_emotions), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildSubject(const Size(720, 1280)));
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      buildSubject(
        const Size(320, 640),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.enterText(
      find.byType(TextField),
      'une\ndeux\ntrois\nquatre\ncinq',
    );
    await tester.pump();

    final scaledField = tester.widget<TextField>(find.byType(TextField));
    expect(scaledField.maxLines, 4);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
