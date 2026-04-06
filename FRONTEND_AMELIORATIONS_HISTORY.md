# FRONTEND - Améliorations de Visibilité de l'Historique des Interactions

**Version**: 1.0  
**Date**: 24 Mars 2026  
**Priorité**: MOYENNE  
**Module**: UI/UX - Navigation  
**Statut**: À implémenter côté frontend

---

## 📋 Table des Matières

1. [Analyse du Problème](#analyse-du-problème)
2. [Solutions Proposées](#solutions-proposées)
3. [Implémentation - Option 1: Amélioration UI](#implémentation---option-1-amélioration-ui)
4. [Implémentation - Option 2: Ajout Navigation](#implémentation---option-2-ajout-navigation)
5. [Implémentation - Option 3: Visite Guidée](#implémentation---option-3-visite-guidée)
6. [Recommandation Finale](#recommandation-finale)

---

## 🔍 Analyse du Problème

### Situation Actuelle

1. **Accès actuel** : L'historique des likes/passes est accessible uniquement via un bouton dans la barre d'application de la page "Matches" (icône 📜 en haut à droite)

2. **Problème identifié** :
   - L'icône est petite et peut passer inaperçue
   - L'utilisateur doit naviguer vers "Matches" puis trouver le bouton d'historique
   - Pas de标签 ou d'indication visuelle claire

3. **Impact sur l'utilisateur** :
   - L'utilisateur peut ignorer cette fonctionnalité
   - Difficulté à trouver les profils likés ou passés
   - Mauvaise expérience utilisateur

### Observations

La navigation actuelle propose 5 onglets :
- Découverte (swipe)
- Matches
- Messages
- Ressources
- Profil

L'historique n'est accessible que via la page "Matches".

---

## 🛠️ Solutions Proposées

### Option 1 : Amélioration UI (Simple)

Améliorer le bouton d'historique sur la page "Matches" :
- Remplacer l'icône par un texte "Historique"
- Ajouter une couleur distinctive
- Ajouter un badge avec le nombre d'interactions

### Option 2 : Ajout Navigation (Moyen)

Ajouter un 6ème onglet dans la barre de navigation inférieure :
- Nouvel onglet "Historique" ou "Activité"
- Accès direct depuis n'importe où dans l'app
- badge avec le nombre de likes non consultés

### Option 3 : Visite Guidée (Complexe)

Implémenter une visite guidée automatique à la première connexion :
- Presentations des fonctionnalités principales
- Guide vers l'historique
- Option "Ne plus afficher"

---

## 💻 Implémentation - Option 1: Amélioration UI

### Fichier: `lib/presentation/pages/matches/matches_page.dart`

Modifications à apporter :

```dart
// Remplacer l'icône actuelle par un bouton plus visible
AppBar(
  title: const Text('Mes Matches'),
  actions: [
    // Bouton Historique AMÉLIORÉ
    TextButton.icon(
      onPressed: () => context.push(AppRoutes.interactionHistory),
      icon: const Icon(Icons.history, size: 20),
      label: const Text('Historique'),  // ← Ajouter le texte
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,  // ← Couleur distinctive
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    // ... autres boutons
  ],
),
```

### Alternative: Badge avec compteur

```dart
// Avec badge de nombre d'interactions
Stack(
  children: [
    TextButton.icon(
      onPressed: () => context.push(AppRoutes.interactionHistory),
      icon: const Icon(Icons.history),
      label: const Text('Historique'),
    ),
    // Badge optionnel
    Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: const Text(
          '5',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ],
),
```

---

## 💻 Implémentation - Option 2: Ajout Navigation

### Fichier: `lib/presentation/widgets/navigation/hiv_bottom_navigation.dart`

Ajouter un nouvel onglet :

```dart
// Ajouter un nouvel item de navigation
static const activity = HIVNavItem(
  label: 'Activité',
  icon: Icons.favorite_border,  // ou Icons.timeline
  activeIcon: Icons.favorite,
);

// Modifier la liste defaultItems
static List<HIVNavItem> get defaultItems => [
  discover,
  matches,
  activity,  // ← NOUVEL ONGLET
  messages,
  resources,
  profile,
];
```

### Créer une nouvelle page d'activité

```dart
// lib/presentation/pages/activity/activity_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hivmeet/core/config/constants.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Activité'),
      ),
      body: ListView(
        children: [
          // Section Likes reçus
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.pink),
            title: const Text('Likes reçus'),
            subtitle: const Text('Voir qui vous a liké'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/likes-received'),
          ),
          const Divider(),
          
          // Section Mes likes
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.pink),
            title: const Text('Mes Likes'),
            subtitle: const Text('Profils que vous avez likés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.interactionHistory),
          ),
          const Divider(),
          
          // Section Mes passes
          ListTile(
            leading: const Icon(Icons.close, color: Colors.grey),
            title: const Text('Mes Passes'),
            subtitle: const Text('Profils que vous avez passés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my-passes'),
          ),
          const Divider(),
          
          // Section Statistiques
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.blue),
            title: const Text('Statistiques'),
            subtitle: const Text('Votre activité en chiffres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stats'),
          ),
        ],
      ),
    );
  }
}
```

### Mettre à jour les routes

```dart
// lib/core/config/routes.dart

import 'package:hivmeet/presentation/pages/activity/activity_page.dart';

// Dans la liste des routes
GoRoute(
  path: '/activity',
  builder: (context, state) => const ActivityPage(),
),
```

---

## 💻 Implémentation - Option 3: Visite Guidée

### Principe

Une visite guidée qui s'affiche à la première connexion et présente les fonctionnalités principales, y compris l'historique.

### Package recommandé

```yaml
# pubspec.yaml
dependencies:
  flutter_tour_tutorial: ^0.3.0  # ou otro package similaire
```

### Implémentation de base

```dart
// lib/presentation/widgets/onboarding/tour_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_tour_tutorial/flutter_tour_tutorial.dart';

class AppTour {
  static Future<void> showOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTour = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (hasSeenTour) return;
    
    final tourController = TourController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TourTutorial(
        controller: tourController,
        steps: [
          // Étape 1: Découverte
          TourStep(
            target: find.byKey(const Key('discover_tab')),
            message: 'Découvrir de nouveaux profils',
            position: TourPosition.top,
          ),
          // Étape 2: Matches
          TourStep(
            target: find.byKey(const Key('matches_tab')),
            message: 'Voir vos matches',
            position: TourPosition.top,
          ),
          // Étape 3: Historique (le point important!)
          TourStep(
            target: find.byKey(const Key('history_button')),
            message: 'Accédez à votre historique de likes et passes',
            position: TourPosition.left,
          ),
          // Étape 4: Messages
          TourStep(
            target: find.byKey(const Key('messages_tab')),
            message: 'Vos conversations',
            position: TourPosition.top,
          ),
        ],
        onComplete: () async {
          await prefs.setBool('has_seen_onboarding', true);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        onSkip: () async {
          await prefs.setBool('has_seen_onboarding', true);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
```

### Intégration dans l'app

```dart
// Dans splash_page.dart ou main.dart

@override
void initState() {
  super.initState();
  // Afficher la visite guidée après l'authentification
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppTour.showOnboarding(context);
  });
}
```

---

## ✅ Recommandation Finale

### Solution recommandée : **Option 1 + Option 2 combinées**

Pour une meilleure expérience utilisateur, je recommande d'implémenter les deux premières options :

1. **Court terme** : Améliorer le bouton d'historique sur la page Matches (Option 1)
   - Ajouter le texte "Historique" à côté de l'icône
   - Utiliser une couleur distinctive (primaryPurple)
   - Simple à implémenter, impact immédiat

2. **Moyen terme** : Ajouter un onglet "Activité" dans la navigation (Option 2)
   - Accès direct depuis n'importe où
   - Vue centralisée de toutes les activités
   - Badge avec compteur

3. **Long terme** : Visite guidée (Option 3)
   - À considérer pour une version future
   - Nécessite plus de développement

---

## 📝 Checklist d'Implémentation

### Option 1 (Immédiate)

- [ ] Modifier le bouton d'historique dans `matches_page.dart`
- [ ] Ajouter le texte "Historique"
- [ ] Utiliser une couleur distinctive

### Option 2 (Court terme)

- [ ] Créer la page `activity_page.dart`
- [ ] Ajouter l'item de navigation `activity`
- [ ] Mettre à jour les routes
- [ ] Ajouter les badges de compteur

### Option 3 (Optionnel)

- [ ] Installer le package `flutter_tour_tutorial`
- [ ] Créer le widget de visite guidée
- [ ] Intégrer dans le flux de connexion
- [ ] Ajouter la logique "Ne plus afficher"

---

## 🔗 Fichiers Concernés

| Fichier | Action |
|---------|--------|
| `lib/presentation/pages/matches/matches_page.dart` | Modifier le bouton |
| `lib/presentation/widgets/navigation/hiv_bottom_navigation.dart` | Ajouter onglet |
| `lib/presentation/pages/activity/activity_page.dart` | Créer (Option 2) |
| `lib/core/config/routes.dart` | Ajouter routes |
| `lib/presentation/widgets/onboarding/tour_overlay.dart` | Créer (Option 3) |

---

**Dernière mise à jour**: 24 Mars 2026  
**Créé par**: AI Agent (GitHub Copilot)  
**Pour**: Équipe de Développement HIVMeet Frontend
