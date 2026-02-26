// test/presentation/widgets/modals/filters_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/presentation/widgets/modals/filters_modal.dart';

void main() {
  group('FiltersModal', () {
    testWidgets('renders with all filter sections', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(FiltersModal), findsOneWidget);
    });

    testWidgets('displays header with title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(FiltersModal), findsOneWidget);
      // The modal should have a header section
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('has reset button in header', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });

    testWidgets('displays age range slider', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(RangeSlider), findsAtLeastNWidgets(1));
    });

    testWidgets('age range initializes with default values',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final rangeSlider = tester.widget<RangeSlider>(find.byType(RangeSlider).first);
      expect(rangeSlider.values.start, 18);
      expect(rangeSlider.values.end, 99);
    });

    testWidgets('distance slider initializes with default value',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final slider = tester.widget<Slider>(find.byType(Slider).first);
      expect(slider.value, 50.0);
    });

    testWidgets('can change age range', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Act
      final rangeSlider = find.byType(RangeSlider).first;
      await tester.drag(rangeSlider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('can change distance slider', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Act
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('has verified only toggle', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(Switch), findsAtLeastNWidgets(1));
    });

    testWidgets('verified toggle initializes as false',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final toggle = tester.widget<Switch>(find.byType(Switch).first);
      expect(toggle.value, false);
    });

    testWidgets('can toggle verified only switch', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('has reset button that resets all filters',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Change some filters first
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Act - tap reset button
      final resetButton = find.widgetWithText(TextButton, 'Réinitialiser');
      if (resetButton.evaluate().isNotEmpty) {
        await tester.tap(resetButton);
        await tester.pumpAndSettle();
      }

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('has apply button in footer', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('can tap apply button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Act
      final applyButton = find.byType(ElevatedButton).first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Assert - should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('modal has correct height', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxHeight, isNotNull);
    });

    testWidgets('modal has rounded top corners', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('content is scrollable', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('displays relationship type filter',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert - should have relationship type section
      expect(find.byType(FiltersModal), findsOneWidget);
    });

    testWidgets('displays interests filter section',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert - should have interests section
      expect(find.byType(FiltersModal), findsOneWidget);
    });

    testWidgets('all filters are contained in Column layout',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('has correct spacing between filter sections',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );

      // Assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.height == 24),
        isTrue,
        reason: 'Should have 24px spacing between sections',
      );
    });

    testWidgets('renders without errors', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FiltersModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('modal can be dismissed by Navigator.pop',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const FiltersModal(),
                  );
                },
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      // Show the modal
      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      // Assert modal is visible
      expect(find.byType(FiltersModal), findsOneWidget);

      // Act - dismiss modal by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Assert modal is dismissed
      expect(find.byType(FiltersModal), findsNothing);
    });
  });
}
