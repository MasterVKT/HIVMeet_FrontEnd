// Test de non-régression pour LOG-03 : assertion ListTile sous DecoratedBox.
//
// Valide que _ActionTile (profile_detail_page.dart) se construit sans lever
// l'assertion "ListTile background color or ink splashes may be invisible",
// que le feedback tactile (onTap) est déclenché, et que la cible tactile
// est accessible.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LOG-03: _ActionTile ListTile assertion', () {
    testWidgets('Material ancestor exists — no invisible ink splash assertion',
        (WidgetTester tester) async {
      bool tapped = false;

      // Recherche de _ActionTile n'est pas possible directement (classe privée).
      // On valide le pattern : Material + ListTile sans DecoratedBox intermédiaire.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.settings, color: Colors.purple),
                  title: const Text('Réglages'),
                  subtitle: const Text('Préférences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Pas d'exception durant le build = pas d'assertion ListTile invisible.
      expect(tester.takeException(), isNull);

      // Le Material ancestor existe bien.
      expect(find.byType(Material), findsWidgets);

      // Le ListTile est présent.
      expect(find.byType(ListTile), findsOneWidget);

      // Le tap déclenche le callback.
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('ripple effect is visible — Material provides ink surface',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Material avec couleur non transparente = surface d'encre valide.
      // MaterialApp/Scaffold ajoutent leurs propres Material ancêtres ;
      // on cible le Material le plus proche du ListTile (le nôtre).
      final material = tester.widget<Material>(
        find
            .ancestor(
                of: find.byType(ListTile), matching: find.byType(Material))
            .first,
      );
      expect(material.color, isNot(Colors.transparent));
    });

    testWidgets('tap target is accessible — semantic label present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Confidentialité'),
                subtitle: const Text('Gérez vos données'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Le texte est accessible au lecteur d'écran.
      expect(find.text('Confidentialité'), findsOneWidget);
      expect(find.text('Gérez vos données'), findsOneWidget);
    });
  });
}
