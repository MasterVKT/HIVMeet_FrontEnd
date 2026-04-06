import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/profile.dart';
import 'package:hivmeet/domain/entities/search_filters.dart';
import 'package:hivmeet/presentation/widgets/modals/filters_modal.dart';

void main() {
  Future<SearchFilters?> openModalAndApply(
    WidgetTester tester,
    SearchPreferences initialFilters,
  ) async {
    SearchFilters? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<SearchFilters>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        FiltersModal(initialFilters: initialFilters),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'common.apply'));
    await tester.pumpAndSettle();

    return result;
  }

  group('FiltersModal', () {
    testWidgets('returns normalized empty arrays when all chips are selected',
        (tester) async {
      const initial = SearchPreferences(
        minAge: 18,
        maxAge: 99,
        maxDistance: 25,
        interestedIn: <String>[],
        relationshipTypes: <String>[],
        showVerifiedOnly: false,
        showOnlineOnly: false,
      );

      final result = await openModalAndApply(tester, initial);

      expect(result, isNotNull);
      expect(result!.genders, isEmpty);
      expect(result.relationshipTypes, isEmpty);
      expect(result.verifiedOnly, isFalse);
      expect(result.onlineOnly, isFalse);
    });

    testWidgets('supports combinations of filters deterministically',
        (tester) async {
      const initial = SearchPreferences(
        minAge: 20,
        maxAge: 35,
        maxDistance: 30,
        interestedIn: <String>[],
        relationshipTypes: <String>[],
        showVerifiedOnly: false,
        showOnlineOnly: false,
      );

      SearchFilters? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<SearchFilters>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => FiltersModal(initialFilters: initial),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(switches.at(1));
      await tester.pumpAndSettle();
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Amitié'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Amitié'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Femmes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Femmes'));
      await tester.pumpAndSettle();

      await tester
          .ensureVisible(find.widgetWithText(ElevatedButton, 'common.apply'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'common.apply'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final finalResult = result!;
      expect(finalResult.minAge, 20);
      expect(finalResult.maxAge, 35);
      expect(finalResult.maxDistance, 30);
      expect(finalResult.genders, equals(const <String>['female']));
      expect(
        finalResult.relationshipTypes,
        equals(const <String>['friendship']),
      );
      expect(finalResult.verifiedOnly, isTrue);
      expect(finalResult.onlineOnly, isTrue);
    });
  });
}
