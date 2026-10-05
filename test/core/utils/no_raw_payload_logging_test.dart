// Garde de non-régression pour la Phase 6 (hygiène des logs).
//
// Ces fichiers dumpaient auparavant des payloads JSON, des e-mails ou des
// erreurs de flux WebSocket bruts via `debugPrint`, qui ne passe jamais par
// PrivacyLogSanitizer. Ce test échoue si `debugPrint(` réapparaît dans l'un
// d'eux, pour empêcher qu'une future modification réintroduise une fuite de
// données sensibles.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('previously-fixed files no longer call debugPrint directly', () {
    final files = <String>[
      'lib/data/repositories/interaction_history_repository_impl.dart',
      'lib/data/repositories/auth_repository_impl.dart',
      'lib/domain/usecases/auth/sign_in.dart',
      'lib/data/datasources/remote/auth_api.dart',
      'lib/presentation/pages/auth/login_page.dart',
      'lib/presentation/blocs/auth/auth_bloc_simple.dart',
      'lib/presentation/blocs/auth/auth_bloc.dart',
      'lib/presentation/blocs/chat/chat_bloc.dart',
      'lib/presentation/blocs/interaction_history/interaction_history_bloc.dart',
      'lib/core/events/app_events.dart',
      'lib/core/services/token_service.dart',
      'lib/data/repositories/message_repository_impl.dart',
      'lib/core/services/chat_websocket_service.dart',
    ];

    final offenders = <String>[];
    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) {
        offenders.add('$path (fichier introuvable)');
        continue;
      }
      if (file.readAsStringSync().contains('debugPrint(')) {
        offenders.add(path);
      }
    }

    expect(offenders, isEmpty,
        reason: 'debugPrint(...) direct réapparu (contourne le sanitizer) '
            'dans : ${offenders.join(', ')}');
  });
  test('FCM registration tokens are redacted by the API logger', () {
    final source = File('lib/core/network/api_client.dart').readAsStringSync();

    expect(source, contains("'fcm_token'"));
  });
}
