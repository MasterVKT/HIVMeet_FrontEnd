import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hivmeet/core/services/network_connectivity_service.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/injection.dart';

/// Widget de diagnostic de connectivité pour le debugging
class ConnectivityDiagnosticWidget extends StatefulWidget {
  const ConnectivityDiagnosticWidget({super.key});

  @override
  State<ConnectivityDiagnosticWidget> createState() =>
      _ConnectivityDiagnosticWidgetState();
}

class _ConnectivityDiagnosticWidgetState
    extends State<ConnectivityDiagnosticWidget> {
  final NetworkConnectivityService _connectivityService =
      getIt<NetworkConnectivityService>();

  bool _isRunning = false;
  ConnectivityDiagnostic? _lastDiagnostic;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    // N'afficher qu'en mode debug
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.network_check, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Diagnostic Connectivité',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDiagnostic,
                  child: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test'),
                ),
              ],
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.slate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (_lastDiagnostic != null) ...[
              const SizedBox(height: 16),
              _buildDiagnosticResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticResults() {
    if (_lastDiagnostic == null) return const SizedBox.shrink();

    final diagnostic = _lastDiagnostic!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTestResult(
          'Connexion Internet',
          diagnostic.internetAccess,
          diagnostic.internetAccess
              ? 'Accès internet disponible'
              : 'Pas d\'accès internet',
        ),
        const SizedBox(height: 8),
        _buildTestResult(
          'Serveur Django',
          diagnostic.serverAccess,
          diagnostic.serverAccess
              ? 'Serveur Django accessible'
              : diagnostic.serverError ?? 'Serveur inaccessible',
        ),
        const SizedBox(height: 8),
        _buildTestResult(
          'API Django',
          diagnostic.apiAccess,
          diagnostic.apiAccess
              ? 'API Django opérationnelle'
              : diagnostic.apiError ?? 'API inaccessible',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: diagnostic.overallSuccess
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: diagnostic.overallSuccess ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                diagnostic.overallSuccess ? Icons.check_circle : Icons.error,
                color: diagnostic.overallSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diagnostic.overallSuccess
                      ? 'Connectivité OK - Le backend est accessible'
                      : 'Problème de connectivité - Vérifiez le backend',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diagnostic.overallSuccess
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Détails techniques'),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                diagnostic.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestResult(String title, bool success, String message) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          color: success ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _statusMessage = 'Démarrage du diagnostic...';
      _lastDiagnostic = null;
    });

    try {
      setState(() => _statusMessage = 'Test de connectivité internet...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _statusMessage = 'Test d\'accès au serveur Django...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _statusMessage = 'Test des API Django...');
      await Future.delayed(const Duration(milliseconds: 500));

      final diagnostic = await _connectivityService.performDiagnostic();

      setState(() {
        _lastDiagnostic = diagnostic;
        _statusMessage = diagnostic.overallSuccess
            ? 'Diagnostic terminé - Tout fonctionne !'
            : 'Diagnostic terminé - Problèmes détectés';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors du diagnostic: $e';
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }
}

/// Widget compact de statut de connectivité
class ConnectivityStatusWidget extends StatefulWidget {
  const ConnectivityStatusWidget({super.key});

  @override
  State<ConnectivityStatusWidget> createState() =>
      _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  final NetworkConnectivityService _connectivityService =
      getIt<NetworkConnectivityService>();

  bool? _isConnected;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (!mounted) return;

    setState(() => _isChecking = true);

    try {
      final isReachable = await _connectivityService.isBackendReachable();
      if (mounted) {
        setState(() {
          _isConnected = isReachable;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // N'afficher qu'en mode debug
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_isChecking) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Vérification...';
    } else if (_isConnected == true) {
      statusColor = Colors.green;
      statusIcon = Icons.cloud_done;
      statusText = 'Backend OK';
    } else if (_isConnected == false) {
      statusColor = Colors.red;
      statusIcon = Icons.cloud_off;
      statusText = 'Backend KO';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help;
      statusText = 'Inconnu';
    }

    return GestureDetector(
      onTap: _checkConnectivity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 14),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 