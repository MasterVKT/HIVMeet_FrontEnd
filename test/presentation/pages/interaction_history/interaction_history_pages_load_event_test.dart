import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_event.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_state.dart';
import 'package:hivmeet/presentation/pages/interaction_history/my_likes_page.dart';
import 'package:hivmeet/presentation/pages/interaction_history/my_passes_page.dart';
import 'package:mocktail/mocktail.dart';

class MockInteractionHistoryBloc extends Mock
    implements InteractionHistoryBloc {}

void main() {
  late MockInteractionHistoryBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const LoadLikes());
    registerFallbackValue(const LoadPasses());
  });

  setUp(() async {
    mockBloc = MockInteractionHistoryBloc();

    when(() => mockBloc.state).thenReturn(InteractionHistoryInitial());
    when(() => mockBloc.stream)
        .thenAnswer((_) => const Stream<InteractionHistoryState>.empty());
    when(() => mockBloc.add(any())).thenReturn(null);
    when(() => mockBloc.close()).thenAnswer((_) async {});

    await getIt.reset();
    getIt.registerFactory<InteractionHistoryBloc>(() => mockBloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('MyLikesPage dispatch LoadLikes(refresh: true) on init',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyLikesPage(),
      ),
    );

    await tester.pump();

    verify(
      () => mockBloc.add(
        const LoadLikes(refresh: true),
      ),
    ).called(1);
  });

  testWidgets('MyPassesPage dispatch LoadPasses(refresh: true) on init',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyPassesPage(),
      ),
    );

    await tester.pump();

    verify(
      () => mockBloc.add(
        const LoadPasses(refresh: true),
      ),
    ).called(1);
  });
}
