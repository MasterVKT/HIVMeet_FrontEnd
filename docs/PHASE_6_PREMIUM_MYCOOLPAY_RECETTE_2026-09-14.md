# Phase 6 — Recette Premium et My-CoolPay

Date d'audit initial : 14 septembre 2026  
Reprise sur appareils et sandbox réelle : 15 septembre 2026
Clôture de l'audit de non-régression : 16 septembre 2026

## Clôture du 16 septembre

Le dernier double contrôle a exécuté les 262 tests backend avec le module de
réglages de test canonique : tous réussissent en 62,397 secondes. L'audit a
également supprimé deux sources de non-déterminisme sans modifier la
configuration de production : le channel layer des tests utilise désormais la
mémoire plutôt qu'un Redis local, et les workers du test de charge ferment
leurs connexions PostgreSQL. Enfin, le reçu de lecture par lot traite
correctement deux messages ayant exactement le même horodatage, au lieu de
dépendre de l'ordre aléatoire de leurs UUID.

## Complément de recette réelle du 16 septembre

Le parcours Mensuel/XAF a été exécuté jusqu'à un état terminal sur l'appareil
physique avec le numéro d'exemple publié par My-CoolPay :

- le Paylink hébergé a affiché le bon produit et le bon montant de 5 241 FCFA ;
- My-CoolPay a renvoyé l'échec contrôlé « solde du compte du payeur
  insuffisant » ;
- `checkStatus` a confirmé `FAILED` avec la même référence, le même montant et
  la même devise ;
- Django a conservé `fulfilled=false` et `is_premium=false` ;
- au retour au premier plan, Flutter a interrogé le statut authentifié,
  supprimé l'attente terminale et affiché la carte persistante « Paiement
  échoué », avec une action de réessai ;
- aucun redémarrage ni aucune reconnexion n'a été nécessaire.

Cette recette a aussi révélé une différence réelle entre le fournisseur et ses
exemples : juste après la création d'un Paylink, `checkStatus` peut retourner
`transaction_status=CREATED` avec `transaction_operator` vide. Le backend
accepte désormais l'opérateur vide uniquement pour `CREATED` et `PENDING`, puis
normalise `CREATED` en attente locale. Les états terminaux exigent toujours un
opérateur reconnu. Un test dédié interdit qu'un `SUCCESS` sans opérateur accorde
un droit Premium. La suite complète de 262 tests Django et les 15 tests Flutter
ciblés paiement/propagation sont verts après cette correction.

Le projet de référence ne fournit aucun moyen supplémentaire pour homologuer
un succès : son parcours ancien s'arrêtait à la création du Paylink, puis une
route authentifiée activait le Premium sur déclaration du client. Ce mécanisme
non sûr n'a pas été repris. La clé publique retrouvée ouvre bien le sandbox,
mais le numéro d'exemple n'a pas de solde suffisant pour le tarif HIVMeet ; aucun
compte de test approvisionné, secret de callback ou accès au tableau de bord
marchand n'est présent dans le projet.

## Résultats de la reprise du 15 septembre

La recette a progressé jusqu'au maximum permis par les éléments marchands
disponibles :

- l'appareil physique Android 11 et l'émulateur Android 12 sont visibles par
  ADB ;
- le projet Django de référence fourni contient une clé **publique** marchande
  encore acceptée par le sandbox, mais aucune clé privée My-CoolPay et aucun
  accès au tableau de bord marchand ;
- le backend HIVMeet crée réellement un Paylink Mensuel/XAF et un Paylink
  Annuel/EUR sur `my-coolpay.com` ; la page sandbox Mensuel/XAF a été affichée
  sur l'appareil physique avec le bon montant de 5 241 FCFA ;
- la répétition d'un achat avec la même clé d'idempotence restitue la même
  transaction (`201`, puis `200`) ;
- `checkStatus` renvoie actuellement `CREATED`. HIVMeet le normalise en
  `pending`, conserve `fulfilled=false` et ne débloque aucun droit Premium ;
- l'endpoint de capacités expose honnêtement `available=true`,
  `confirmation_mode=polling_only`,
  `callback_verification_available=false` et
  `automatic_return_available=false` ;
- Flutter affiche désormais une consigne FR/EN expliquant de revenir dans
  HIVMeet après le paiement. Le retour au premier plan déclenche alors la
  vérification backend sans faire confiance au navigateur ;
- une clé Android release durable RSA 3072 a été créée dans les fichiers locaux
  ignorés par Git. L'APK release de 66,1 Mo est signé par HIVMeet et vérifié par
  `apksigner` avec le schéma v2 ;
- la suite complète actuelle est verte : 270 tests Flutter réussis (1 live
  ignoré), 261 tests Django réussis, analyse Flutter sans problème, checks
  Django sans problème et aucune migration de code manquante.

Deux anomalies de recette ont aussi été qualifiées :

- le `301` de connexion provenait de `SECURE_SSL_REDIRECT` actif dans le serveur
  local utilisé par `adb reverse`. La recette locale est maintenant lancée avec
  `DEBUG=True`; les variantes `/auth/login` et `/auth/login/` répondent sans
  redirection, sans modifier la politique HTTPS de production ;
- le premier démarrage rouge venait d'une récursion de `debugPrint` dans le
  filtre de confidentialité. La référence native est désormais capturée avant
  installation du wrapper et un test de non-récursion protège ce chemin.

L'appareil physique valide le démarrage, la connexion, Découverte, Profil, la
devise AUTO/XAF, la page Premium, la consigne polling, le Paylink hébergé et le
deep link à chaud. L'émulateur a affiché l'application après « Wait », mais son
système Android est ensuite resté saturé (`surfaceflinger` et clavier système)
et un démarrage à froid de l'AVD n'a pas terminé. Aucune pile HIVMeet bloquée ni
exception fatale n'a été enregistrée par Android ; cette preuve reste donc une
limitation de l'AVD, pas une validation négative de l'application.

L'activation Premium terminale et le retour fournisseur automatique ne peuvent
pas être homologués avec la seule clé publique du projet de référence. Ils
nécessitent la clé privée de l'application marchande et l'accès à son tableau de
bord pour configurer les quatre URL HTTPS. Le mode polling livré reste sûr et
testable : seul le statut authentifié My-CoolPay peut finaliser la transaction.

## Verdict initial du 14 septembre (remplacé par la reprise ci-dessus)

La conformité logicielle locale est validée : contrats Flutter/Django, sécurité
du callback, idempotence, réconciliation, propagation immédiate des droits,
navigation Android et build debug sont verts. Le build release échoue désormais
explicitement tant qu'aucun keystore sécurisé n'est fourni, au lieu de produire
silencieusement un APK non signé.

L'homologation externe n'est pas encore prononçable. Deux prérequis absents de
la machine empêchent les deux dernières preuves réelles :

- aucun appareil physique n'est visible par ADB ; seul `emulator-5554` est
  connecté ;
- l'environnement backend local ne contient ni clés marchandes My-CoolPay ni
  URLs publiques HTTPS configurées. La capacité calculée est donc
  `mycoolpay_configured=False`, conformément au comportement sécurisé attendu ;
- aucun keystore Android release n'est configuré sur cette machine.

La mise en production du paiement reste **NO-GO** tant qu'un paiement sandbox
réel et la recette sur appareil physique n'ont pas été exécutés avec ces
prérequis.

## Preuves de l'audit initial du 14 septembre (historique)

Les résultats de cette section expliquent la situation avant la reprise. Ils
sont conservés pour la traçabilité, mais les totaux, l'état de la signature
Android et la recette sur appareil figurant dans la section du 15 septembre
font foi.

### Backend Django/DRF

- Suite complète : 259 tests réussis, aucun échec.
- Seconde exécution isolée avec les versions déclarées par le projet : Django
  4.2.7 et DRF 3.14.0, 259 tests réussis en 100,865 secondes.
- Tests ciblés Premium/paiement : 82 réussis.
- Suite applicative ciblée : 225 réussis.
- `manage.py check` : aucun problème.
- `makemigrations --check --dry-run` : aucun changement manquant.
- `migrate --plan` : aucune opération en attente.

La matrice automatique couvre notamment :

- catalogue Mensuel/Annuel, plans historiques non achetables et refus des
  identifiants vides ;
- devises `AUTO`, `XAF` et `EUR`, arrondi XAF et économie annuelle ;
- montant et devise recalculés côté serveur ;
- création idempotente, double clic concurrent et reprise après réponse perdue ;
- transaction inaccessible à un autre utilisateur ;
- callback falsifié, IP et signature invalides, montant/devise/référence
  incohérents, callback tardif et callback dupliqué ;
- finalisation atomique, `fulfilled`, période d'abonnement et réconciliation
  d'un callback perdu ;
- droits Premium, cinq rewinds quotidiens sans restitution du swipe, super
  likes, expiration et absence de déblocage sur un simple retour navigateur ;
- non-régression découverte, like/dislike, quota gratuit, historique,
  authentification, notifications, messagerie, profil et export RGPD ;
- pseudonymisation des emails, UUID et identifiants dans les nouveaux logs.

### Flutter

- `flutter test --no-pub` : 269 tests réussis, 1 test live ignoré, 0 échec. Le
  test ignoré exige explicitement `DISCOVERY_TEST_BASE_URL` et
  `DISCOVERY_TEST_ACCESS_TOKEN`.
- `flutter analyze --no-pub` : aucun problème.
- APK debug final construit et installé sur l'émulateur.
- La chaîne release compile et optimise l'application, mais l'ancien artefact
  final de 66,1 Mo était dépourvu de certificat et Android l'a refusé avec
  `INSTALL_PARSE_FAILED_NO_CERTIFICATES`. Cet artefact invalide a été supprimé.
- `android/app/build.gradle` exige maintenant une configuration de signature
  complète et un keystore existant. Sans eux, `flutter build apk --release`
  échoue explicitement avant de laisser un artefact trompeur.
- Le chemin positif a été validé avec un keystore RSA 2048 jetable transmis par
  les quatre variables CI : la release a été construite puis vérifiée par
  `apksigner` avec le schéma v2. L'APK déclare `minSdkVersion=24`, compatible
  avec ce schéma. La clé et cet APK de test ont ensuite été supprimés.
- Aucun usage direct de `CupertinoIcons` ou de `cupertino_icons` n'existe dans le
  code ou le manifeste de dépendances ; l'avertissement de tree-shaking émis par
  une dépendance transitive n'affecte pas le build.

La matrice automatique couvre notamment :

- route Premium canonique et redirection de compatibilité `/subscription` ;
- toutes les destinations `returnTo` autorisées ;
- persistance sécurisée avant ouverture du navigateur ;
- rejet d'un identifiant de paiement altéré et d'une URL hors My-CoolPay ;
- double appui, retry réseau et réutilisation de la transaction ;
- succès, attente, annulation, échec, perte réseau et polling borné ;
- confirmation exclusivement par le statut backend authentifié ;
- rechargement utilisateur avant publication de `subscriptionChanged` ;
- rafraîchissement immédiat de Découverte, Profil et Ressources ;
- changement de filtre Conversations sans recherche résiduelle et application de
  la dernière page serveur malgré les gardes de concurrence ;
- contrats de notifications, messages, compteurs et localisation Premium.

### Android sur émulateur — audit initial

- L'application `com.hivmeet.hivmeet` démarre à froid sans exception fatale.
- Retour à chaud validé avec
  `hivmeet://payment/result?status=cancelled` vers l'activité courante.
- Retour à froid validé après arrêt forcé avec
  `hivmeet://payment/result?status=success` vers une nouvelle `MainActivity`.
- Le manifeste Android n'enregistre que le schéma, l'hôte et le chemin attendus :
  `hivmeet://payment/result`.

L'émulateur a subi une forte pression mémoire et une ANR de l'application Google
Quick Search, sans crash ni exception fatale du processus HIVMeet. Cet incident
n'est pas attribuable à l'application testée.

## Recette externe restant obligatoire pour le webhook signé

Suivre le runbook backend
`docs/MYCOOLPAY_TEST_MERCHANT_RUNBOOK.md`, sans placer de secret dans Git, les
logs, Flutter ou ce rapport.

Les prérequis locaux appareil et signature Android sont désormais satisfaits.
Pour homologuer le webhook signé et le retour automatique fournisseur :

1. injecter les clés de l'application marchande de test dans le gestionnaire de
   secrets backend ;
2. déployer le callback et les trois pages de retour sur le domaine HTTPS public
   configuré dans le tableau de bord My-CoolPay ;
3. vérifier avec un JWT de recette que
   `GET /api/v1/subscriptions/payment-capabilities/` retourne `available=true`
   et `callback_verification_available=true` ;
4. exécuter, sur émulateur puis appareil physique, Mensuel et Annuel pour
   `AUTO`, `XAF` et `EUR`, avec succès, attente, annulation, échec, fermeture de
   l'application, callback perdu et double validation ;
5. confirmer après chaque succès que les droits sont actifs sans reconnexion ni
   redémarrage, puis rejouer les tentatives de callback malveillant depuis
   l'infrastructure de recette.

L'homologation devient **GO** seulement si cette matrice réelle réussit et si les
journaux My-CoolPay et HIVMeet partagent les mêmes références de corrélation,
montants, devises et états terminaux.
