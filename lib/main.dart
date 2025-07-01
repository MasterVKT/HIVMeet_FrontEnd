import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const HIVMeetApp());
}

class HIVMeetApp extends StatelessWidget {
  const HIVMeetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false;

  void _testApplication() {
    setState(() {
      _isPressed = true;
    });

    // Afficher un dialog plus visible
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '🎉 Test Réussi !',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 15),
              Text(
                'HIVMeet est correctement configuré !',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Mode: ${AppConfig.enableLogs ? "Développement" : "Production"}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                'API: ${AppConfig.apiBaseUrl}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isPressed = false;
                });
              },
              child: const Text('Parfait !'),
            ),
          ],
        );
      },
    );

    // Aussi afficher le SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Application configurée et fonctionnelle !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Bienvenue sur ${AppConfig.appName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Mode: ${AppConfig.enableLogs ? "Développement" : "Production"}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'API: ${AppConfig.apiBaseUrl}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
              child: ElevatedButton.icon(
                onPressed: _testApplication,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'Tester l\'application',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cliquez sur le bouton pour tester la configuration',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
