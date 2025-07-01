// lib/presentation/pages/legal/terms_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Html(
          data: _termsContent,
          style: {
            'h1': Style(
              fontSize: FontSize(24),
              fontWeight: FontWeight.bold,
              margin: Margins.only(bottom: 16),
            ),
            'h2': Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              margin: Margins.only(top: 16, bottom: 8),
            ),
            'p': Style(
              fontSize: FontSize(16),
              lineHeight: LineHeight(1.6),
              margin: Margins.only(bottom: 12),
            ),
            'li': Style(
              margin: Margins.only(bottom: 8),
            ),
          },
        ),
      ),
    );
  }

  static const String _termsContent = '''
    <h1>Conditions d'utilisation HIVMeet</h1>
    <p>Dernière mise à jour : Janvier 2025</p>
    
    <h2>1. Acceptation des conditions</h2>
    <p>En utilisant HIVMeet, vous acceptez d'être lié par ces conditions d'utilisation. Si vous n'acceptez pas ces conditions, vous ne devez pas utiliser l'application.</p>
    
    <h2>2. Admissibilité</h2>
    <p>Vous devez avoir au moins 18 ans pour utiliser HIVMeet. En créant un compte, vous certifiez que vous avez l'âge légal requis.</p>
    
    <h2>3. Utilisation appropriée</h2>
    <p>Vous vous engagez à :</p>
    <ul>
      <li>Fournir des informations exactes et véridiques</li>
      <li>Respecter les autres utilisateurs</li>
      <li>Ne pas partager de contenu inapproprié</li>
      <li>Ne pas utiliser l'application à des fins illégales</li>
    </ul>
    
    <h2>4. Confidentialité et sécurité</h2>
    <p>La protection de vos données personnelles est notre priorité. Consultez notre politique de confidentialité pour comprendre comment nous collectons et utilisons vos informations.</p>
    
    <h2>5. Vérification du profil</h2>
    <p>La vérification est optionnelle mais recommandée. Les documents soumis sont traités de manière confidentielle et supprimés après vérification.</p>
    
    <h2>6. Abonnement Premium</h2>
    <p>L'abonnement Premium est renouvelé automatiquement. Vous pouvez annuler à tout moment depuis les paramètres de l'application.</p>
    
    <h2>7. Résiliation</h2>
    <p>Nous nous réservons le droit de suspendre ou résilier votre compte en cas de violation de ces conditions.</p>
    
    <h2>8. Limitation de responsabilité</h2>
    <p>HIVMeet n'est pas responsable des interactions entre utilisateurs. Utilisez l'application avec prudence et bon sens.</p>
    
    <h2>9. Modifications</h2>
    <p>Nous pouvons modifier ces conditions à tout moment. Les modifications prennent effet dès leur publication.</p>
    
    <h2>10. Contact</h2>
    <p>Pour toute question, contactez-nous à support@hivmeet.com</p>
  ''';
}