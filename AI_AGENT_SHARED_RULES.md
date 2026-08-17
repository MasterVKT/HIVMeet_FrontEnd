# HIVMeet - Regles Partagees pour Agents AI

Version: 1.0  
Date: 2026-04-12

## Objectif

Socle commun pour tous les agents AI du projet HIVMeet afin de limiter la duplication des consignes et reduire les tokens charges a chaque requete.

## Contexte Produit

- Application de rencontre pour personnes vivant avec le VIH/SIDA
- Frontend principal: Flutter/Dart
- Backend principal: Django/Python
- Exigences fortes: respect, inclusion, confidentialite, stabilite

## Regles Non Negociables

1. Contrat API strict
- Toujours verifier les endpoints dans [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- Ne jamais deviner un endpoint, un payload, ou un code HTTP

2. Internationalisation obligatoire
- Aucun texte utilisateur en dur
- Utiliser FR/EN via intl et fichiers ARB

3. Configuration centralisee
- Utiliser uniquement la configuration API dans [lib/core/config/constants.dart](lib/core/config/constants.dart)
- Interdiction des URLs hardcodees

4. Non-regression systematique
- Verifier le flux principal corrige
- Verifier les flux connexes impactes
- Corriger immediatement toute regression detectee

5. Confidentialite et securite
- Ne jamais logger de PII (email, token, user id, phone, localisation precise)
- Utiliser flutter_secure_storage pour les tokens

6. Respect des specifications
- Consulter en priorite les specs dans [docs](docs)
- Respecter l'ordre de developpement et les dependances

7. Coordination backend/frontend
- Si un changement backend est necessaire, fournir:
  - endpoint exact
  - methode HTTP
  - payloads request/response complets
  - status codes
  - format d'erreur

8. Sensibilite domaine VIH
- Formulation respectueuse et non stigmatisante
- Parametres de confidentialite utilisateur respectes

## Sources de Reference

- Architecture: [.claude/rules/architecture.md](.claude/rules/architecture.md)
- Integration backend: [.claude/rules/backend-integration.md](.claude/rules/backend-integration.md)
- Specifications: [.claude/rules/specifications.md](.claude/rules/specifications.md)
- Tests: [.claude/rules/testing.md](.claude/rules/testing.md)
- Skills (toutes dans `.agents/skills/`):
  - Routeur/orchestrateur: [.agents/skills/task-router/SKILL.md](.agents/skills/task-router/SKILL.md) ← charger en premier si incertain
  - Frontend Flutter/Dart: [.agents/skills/frontend-development/SKILL.md](.agents/skills/frontend-development/SKILL.md)
  - Correction de bugs: [.agents/skills/bug-fixing/SKILL.md](.agents/skills/bug-fixing/SKILL.md)
  - Audit contrats API: [.agents/skills/api-contract-audit/SKILL.md](.agents/skills/api-contract-audit/SKILL.md)
  - Localisation FR/EN: [.agents/skills/i18n-integrity/SKILL.md](.agents/skills/i18n-integrity/SKILL.md)
  - Non-regression: [.agents/skills/regression-guard/SKILL.md](.agents/skills/regression-guard/SKILL.md)
  - Readiness release: [.agents/skills/release-readiness/SKILL.md](.agents/skills/release-readiness/SKILL.md)
  - Sélection de tests: [.agents/skills/test-impact-selection/SKILL.md](.agents/skills/test-impact-selection/SKILL.md)

## Contrat de Sortie Minimal

Pour toute tache, fournir:
- fichiers modifies
- changements fonctionnels appliques
- verification de conformite aux specifications
- verification de non-regression
- impact backend eventuel
- resume final

## Regle de Documentation Backend

Si un probleme est confirme comme backend (et non corrigeable proprement frontend), creer un fichier racine au format:

BACKEND_[TYPE]_[DESCRIPTION].md

Le contenu doit inclure:
- symptome observable
- cause probable
- impact utilisateur
- demande backend actionnable (endpoint, payloads, statuts)
- criteres de validation
