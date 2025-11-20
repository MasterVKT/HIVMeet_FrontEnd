import 'dart:io';
import 'dart:convert';

/// Script de test pour vérifier les endpoints corrigés
/// Usage: dart test_endpoints_correction.dart

class EndpointTester {
  static String get baseUrl {
    final env = Platform.environment['HIVMEET_BACKEND_BASE_URL'];
    // Par défaut pour exécution sur l'hôte Windows (backend local)
    return (env != null && env.isNotEmpty) ? env : 'http://127.0.0.1:8000';
  }

  static final Map<String, Map<String, dynamic>> endpoints = {
    'auth/refresh-token': {
      'method': 'POST',
      'data': {'refresh_token': 'test_refresh_token'},
      'expected_status': [
        400,
        401
      ], // 400 si token invalide, 401 si format incorrect
    },
    'auth/firebase-exchange/': {
      'method': 'POST',
      'data': {'firebase_token': 'test_firebase_token'},
      'expected_status': [
        400,
        401
      ], // 400 si token invalide, 401 si format incorrect
    },
  };

  static Future<void> testEndpoint(
      String endpoint, Map<String, dynamic> config) async {
    try {
      print('🧪 Test de l\'endpoint: $endpoint');

      final url = '$baseUrl/api/v1/$endpoint';
      final method = config['method'] as String;
      final data = config['data'] as Map<String, dynamic>;
      final expectedStatus = config['expected_status'] as List<int>;

      final request = HttpClient();

      final httpRequest = await request.openUrl(method, Uri.parse(url));
      httpRequest.headers.set('Content-Type', 'application/json');
      httpRequest.headers.set('Accept', 'application/json');

      httpRequest.write(jsonEncode(data));

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('📊 Status: ${response.statusCode}');
      print('📄 Response: $responseBody');

      if (expectedStatus.contains(response.statusCode)) {
        print('✅ Endpoint accessible (status attendu)');
      } else {
        print('⚠️ Endpoint accessible mais status inattendu');
      }

      request.close();
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        print(
            '❌ Serveur non accessible - Vérifiez que le backend Django est démarré');
      } else if (e.toString().contains('404')) {
        print('❌ Endpoint non trouvé - Vérifiez la configuration Django');
      } else {
        print('❌ Erreur: $e');
      }
    }

    print('---');
  }

  static Future<void> runTests() async {
    print('🚀 Démarrage des tests d\'endpoints...\n');

    for (final entry in endpoints.entries) {
      await testEndpoint(entry.key, entry.value);
    }

    print('✅ Tests terminés');
  }
}

void main() async {
  await EndpointTester.runTests();
}
