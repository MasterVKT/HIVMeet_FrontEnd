import 'package:flutter/material.dart';

/// Widget de débogage pour forcer l'affichage d'un écran visible
/// Utilisé pour diagnostiquer les problèmes d'écran blanc
class DebugScreen extends StatelessWidget {
  final String message;
  final Color backgroundColor;

  const DebugScreen({
    super.key,
    this.message = 'DEBUG SCREEN',
    this.backgroundColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Ce screen de debug s\'affiche correctement',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
