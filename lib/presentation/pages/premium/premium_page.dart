// lib/presentation/pages/premium/premium_page.dart

import 'package:flutter/material.dart';
import 'package:hivmeet/core/services/localization_service.dart';

// Change to Stateful
class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  _PremiumPageState createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final String _selectedPlan = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(LocalizationService.translate('premium.title'))),
      body: ListView(
        children: [
          Text(LocalizationService.translate('premium.benefits')),
          // Plans list with onTap to set _selectedPlan
          ElevatedButton(
            onPressed: _selectedPlan.isNotEmpty ? () {} : null,
            child: Text(LocalizationService.translate('premium.subscribe')),
          ),
        ],
      ),
    );
  }
}
