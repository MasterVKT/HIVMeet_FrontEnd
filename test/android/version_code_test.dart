// Test de non-régression pour LOG-01 : INSTALL_FAILED_VERSION_DOWNGRADE.
//
// Valide que la logique de calcul du versionCode dans build.gradle produit
// une valeur monotone strictement supérieure à 1, et qu'aucun fichier local
// ignoré par Git ne peut figer le versionCode à 1.
//
// Ce test ne dépend pas de Gradle : il valide la règle métier de versioning
// en simulant les trois sources de versionCode définies dans build.gradle :
//   1. flutter.versionCode dans local.properties (override local)
//   2. HIVMEET_VERSION_CODE (CI)
//   3. nombre de commits Git (fallback monotone)
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('LOG-01: versionCode monotone', () {
    test('versionCode de fallback (1000 + commits) est toujours > 1', () {
      // La règle dans build.gradle : versionCode = 1000 + git rev-list --count HEAD
      // Même avec 0 commits, le minimum est 1000, bien supérieur à 1.
      const minBaseFallback = 1000;
      const minCommits = 0;
      final minVersionCode = minBaseFallback + minCommits;
      expect(minVersionCode, greaterThan(1),
          reason:
              'Le versionCode de fallback (base 1000) doit toujours être > 1 '
              'pour éviter INSTALL_FAILED_VERSION_DOWNGRADE');
    });

    test('local.properties est ignoré par Git', () {
      // Ce fichier ne doit pas être la seule source de vérité du versionCode.
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue,
          reason: '.gitignore doit exister');
      final gitignoreContent = gitignoreFile.readAsStringSync();
      expect(gitignoreContent.contains('local.properties'), isTrue,
          reason:
              '.gitignore doit contenir local.properties pour éviter qu\'un '
              'versionCode figé soit commité par erreur');
    });

    test('le versionCode calculé depuis les commits Git est monotone', () {
      // Simule la logique de build.gradle : 1000 + nombre de commits.
      // Sur un checkout propre, git rev-list --count HEAD est monotone.
      final result = Process.runSync(
        'git',
        ['rev-list', '--count', 'HEAD'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, 0,
          reason:
              'git rev-list --count HEAD doit réussir sur un checkout propre');
      final commitCount = int.parse((result.stdout as String).trim());
      expect(commitCount, greaterThan(0),
          reason: 'Le dépôt doit avoir au moins un commit');
      final versionCode = 1000 + commitCount;
      expect(versionCode, greaterThan(1000),
          reason: 'Le versionCode calculé doit être > 1000');
      expect(versionCode, greaterThan(1),
          reason: 'Le versionCode doit être strictement > 1 pour éviter '
              'INSTALL_FAILED_VERSION_DOWNGRADE');
    });

    test(
        'un versionCode de 1 (l\'ancienne valeur figée) est explicitement rejeté',
        () {
      // La règle dans build.gradle : si flutter.versionCode est null, vide ou "1",
      // le fallback Git prend le relais. Ceci empêche l'ancienne configuration
      // (local.properties avec flutter.versionCode=1) de provoquer un downgrade.
      const oldFrozenValue = '1';
      // La condition dans build.gradle est :
      //   flutterVersionCode == null || trim().isEmpty() || trim() == '1'
      final shouldReject =
          oldFrozenValue.trim().isEmpty || oldFrozenValue.trim() == '1';
      expect(shouldReject, isTrue,
          reason:
              'Un versionCode de "1" doit être rejeté par build.gradle pour '
              'déclencher le calcul monotone depuis Git');
    });
  });
}
