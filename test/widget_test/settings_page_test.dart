// test/widget_test/settings_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/presentation/pages/settings/settings_page.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_bloc.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_event.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_state.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<SettingsBloc>.value(
        value: mockSettingsBloc,
        child: const SettingsPage(),
      ),
    );
  }

  testWidgets('SettingsPage displays all sections', (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsLoaded(
        email: 'test@example.com',
        isPremium: false,
        isProfileVisible: true,
        shareLocation: true,
        showOnlineStatus: true,
        notifyNewMatches: true,
        notifyMessages: true,
        notifyLikes: false,
        notifyNews: true,
        language: 'fr',
        country: 'France',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Confidentialité'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets('Toggle switches update settings', (tester) async {
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsLoaded(
        email: 'test@example.com',
        isPremium: false,
        isProfileVisible: true,
        shareLocation: true,
        showOnlineStatus: true,
        notifyNewMatches: true,
        notifyMessages: true,
        notifyLikes: false,
        notifyNews: true,
        language: 'fr',
        country: 'France',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    final profileVisibilitySwitch = find.byType(Switch).first;
    await tester.tap(profileVisibilitySwitch);
    await tester.pump();

    verify(() => mockSettingsBloc.add(
          const UpdateProfileVisibility(isVisible: false),
        )).called(1);
  });
}
