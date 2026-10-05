import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/widgets/chat/message_bubble.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr');
    final locator = GetIt.instance;
    await locator.reset();
    final localization = LocalizationService();
    await localization.initialize();
    locator.registerSingleton<LocalizationService>(localization);
  });

  tearDownAll(() => GetIt.instance.reset());

  Widget subject(Message message, {bool selected = false}) => MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isOwnMessage: true,
            isSelected: selected,
            selectionMode: selected,
          ),
        ),
      );

  Message mediaMessage({String? localMediaPath, int? uploadProgress}) =>
      Message(
        id: 'temporary-media',
        conversationId: 'conversation',
        senderId: 'sender',
        isMine: true,
        content: '',
        type: MessageType.image,
        createdAt: DateTime(2026, 1, 1),
        localMediaPath: localMediaPath,
        uploadProgress: uploadProgress,
        isSending: true,
        status: MessageStatus.sending,
      );

  testWidgets('optimistic image with no server URL never throws a null check',
      (tester) async {
    await tester.pumpWidget(subject(mediaMessage()));
    await tester.pump();

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection uses a one-pixel outline around the payload only',
      (tester) async {
    await tester.pumpWidget(subject(mediaMessage(), selected: true));
    await tester.pump();

    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      decorations.any((decoration) => decoration.border?.top.width == 1),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending media displays the multipart upload percentage',
      (tester) async {
    await tester.pumpWidget(subject(mediaMessage(uploadProgress: 65)));
    await tester.pump();

    expect(find.text('65%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
