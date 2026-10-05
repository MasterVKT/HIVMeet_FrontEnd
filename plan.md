Anomalies nouvelles trouvées dans les journaux
Plan de résolution proposé, par priorité :
1. P0 — Mauvais artefact installé
   Les deux appareils signalent INSTALL_FAILED_VERSION_DOWNGRADE : [émulateur (line 7)](D:/Projets/HIVMeet/hivmeet/emulator_run.md:7), [appareil physique (line 7)](D:/Projets/HIVMeet/hivmeet/device_run copy.md:7).
   Il faudra imposer un versionCode croissant, reconstruire, contrôler le code de l’APK et celui installé, puis refaire la recette. Les sessions actuelles ont potentiellement exécuté une ancienne version.
2. P1 — Défauts UI/localisation
   Clé discovery.gender absente et assertion Flutter sur un ListTile sans ancêtre Material adapté : [journal appareil (line 152)](D:/Projets/HIVMeet/hivmeet/device_run copy.md:152).
   Correction prévue : clé FR/EN cohérente, composant Material/Ink, tests widgets.
3. P1 — Polices dépendantes du réseau
   OpenSans et Pacifico échouent depuis Google Fonts.
   Correction prévue : embarquer les fichiers de polices dans l’APK et vérifier l’application hors ligne.
4. P1 — Photos de profil en 404
   Le backend sert /profile_photos/... au lieu de /media/profile_photos/... : [journal backend (line 117)](D:/Projets/HIVMeet/hivmeet/backend_run.md:117).
   Correction prévue : normalisation du sérialiseur, migration des anciennes valeurs et fallback pour les fichiers réellement absents.
5. P1 — Notifications
   FCM retourne SERVICE_NOT_AVAILABLE sans retry sur l’émulateur : [journal émulateur (line 17)](D:/Projets/HIVMeet/hivmeet/emulator_run.md:17).
   Correction prévue : retry borné après retour réseau/token refresh, contrôle Play Services et test foreground/background.
6. P2 — Performance et configuration de développement
   Jusqu’à 2 265 frames sont sautées, et Celery revient implicitement vers localhost.
   Correction prévue : d’abord déployer le bon APK et embarquer les polices, puis profiler le démarrage en mode profile ; rendre également le broker de développement explicite.