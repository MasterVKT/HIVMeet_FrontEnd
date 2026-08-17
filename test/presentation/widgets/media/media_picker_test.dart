import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/message.dart';
import 'package:hivmeet/presentation/widgets/media/media_picker.dart';

void main() {
  testWidgets('s’adapte à un écran étroit sans débordement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: MediaPicker(
                onMediaSelected: (File _, MessageType __) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
