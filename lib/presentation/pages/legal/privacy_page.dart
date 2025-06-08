// lib/presentation/pages/legal/privacy_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Html(
          data: _privacyContent,
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
            'h3': Style(
              fontSize: FontSize(18),
              fontWeight: FontWeight.w600,
              margin: Margins.only(top: 12, bottom: 6),
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

  static const String _privacyContent = '''
    <h1>Politique de Confidentialité HIVMeet</h1>
    <p>Dernière mise à jour : Janvier 2025</p>
    
    <h2>1. Introduction</h2>
    <p>HIVMeet s'engage à protéger votre vie privée. Cette politique explique comment nous collectons, utilisons et protégeons vos informations personnelles.</p>
    
    <h2>2. Informations collectées</h2>
    <h3>2.1 Informations fournies par vous</h3>
    <ul>
      <li>Nom et prénom</li>
      <li>Date de naissance</li>
      <li>Photos de profil</li>
      <li>Localisation (avec votre permission)</li>
      <li>Préférences de rencontre</li>
    </ul>
    
    <h3>2.2 Informations collectées automatiquement</h3>
    <ul>
      <li>Données d'utilisation de l'application</li>
      <li>Informations de l'appareil</li>
      <li>Journaux de connexion</li>
    </ul>
    
    <h2>3. Utilisation des informations</h2>
    <p>Nous utilisons vos informations pour :</p>
    <ul>
      <li>Fournir et améliorer nos services</li>
      <li>Faciliter les connexions entre utilisateurs</li>
      <li>Assurer la sécurité de la plateforme</li>
      <li>Communiquer avec vous</li>
    </ul>
    
    <h2>4. Partage des informations</h2>
    <p>Nous ne vendons jamais vos données personnelles. Nous partageons vos informations uniquement :</p>
    <ul>
      <li>Avec votre consentement</li>
      <li>Pour se conformer aux obligations légales</li>
      <li>Pour protéger nos droits et ceux des utilisateurs</li>
    </ul>
    
    <h2>5. Sécurité des données</h2>
    <p>Nous utilisons des mesures de sécurité avancées pour protéger vos informations :</p>
    <ul>
      <li>Chiffrement des données sensibles</li>
      <li>Accès restreint aux informations personnelles</li>
      <li>Audits de sécurité réguliers</li>
    </ul>
    
    <h2>6. Vos droits</h2>
    <p>Vous avez le droit de :</p>
    <ul>
      <li>Accéder à vos données personnelles</li>
      <li>Corriger les informations inexactes</li>
      <li>Demander la suppression de vos données</li>
      <li>Vous opposer au traitement de vos données</li>
    </ul>
    
    <h2>7. Conservation des données</h2>
    <p>Nous conservons vos données tant que votre compte est actif. Après suppression de votre compte, certaines données peuvent être conservées pour des raisons légales.</p>
    
    <h2>8. Modifications</h2>
    <p>Nous pouvons mettre à jour cette politique. Nous vous informerons de tout changement important.</p>
    
    <h2>9. Contact</h2>
    <p>Pour toute question sur la confidentialité : privacy@hivmeet.com</p>
  ''';
}