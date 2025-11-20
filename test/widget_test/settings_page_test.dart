// test/widget_test/settings_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hivmeet/presentation/pages/settings/settings_page.dart';
import 'package:hivmeet/presentation/blocs/settings/settings_bloc.dart';
// Ne pas importer les parts directement; seulement le bloc expose types
import 'package:get_it/get_it.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

class FakeSettingsState extends Fake implements SettingsState {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  late MockSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    final sl = GetIt.instance;
    if (sl.isRegistered<SettingsBloc>()) {
      sl.unregister<SettingsBloc>();
    }
    sl.registerFactory<SettingsBloc>(() => mockSettingsBloc);
    // Mock le stream et la méthode close pour éviter les erreurs de type.
    when(() => mockSettingsBloc.stream)
        .thenAnswer((_) => const Stream<SettingsState>.empty());
    when(() => mockSettingsBloc.close()).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(FakeSettingsState());
    registerFallbackValue(FakeSettingsEvent());
  });

  tearDown(() {
    GetIt.instance.reset(dispose: false);
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
    expect(find.text('Compte'), findsWidgets);
    expect(find.text('Confidentialité'), findsWidgets);
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Support'), findsWidgets);
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
