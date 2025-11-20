# 🔥 FIREBASE STORAGE - GUIDE DE CONFIGURATION COMPLET

**Date**: 20 novembre 2024
**Prérequis**: Projet Firebase créé, `google-services.json` et `GoogleService-Info.plist` configurés

---

## 📋 VUE D'ENSEMBLE

Firebase Storage est utilisé dans HIVMeet pour:
- **Photos de profil** (max 10MB, compression 800x800)
- **Médias chat** (photos/vidéos, max 50MB, compression 1920x1080)
- **Documents vérification** (ID, selfie pour vérification profil)

---

## 1️⃣ ACTIVATION FIREBASE STORAGE

### Étape 1: Console Firebase

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet HIVMeet
3. Menu latéral → **Build** → **Storage**
4. Cliquez "**Get Started**"
5. Choisissez la localisation (recommandé: europe-west1 ou us-central1)
6. Cliquez "**Done**"

Vous devriez voir un bucket créé: `gs://YOUR_PROJECT_ID.appspot.com`

---

## 2️⃣ CONFIGURATION DES RÈGLES DE SÉCURITÉ

### Règles de Base (Development)

**⚠️ TEMPORAIRE - Seulement pour développement initial!**

Dans Firebase Console → Storage → Rules, remplacez par:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Cette règle permet**:
- Upload/download pour utilisateurs authentifiés uniquement
- Pas de restrictions de taille (à ajouter ensuite)

---

### Règles Production (CRITIQUE pour lancement)

**Structure des chemins**:
```
/users/{userId}/profile/{photoId}.jpg     # Photos profil
/users/{userId}/chat/{messageId}.jpg      # Médias chat
/users/{userId}/verification/{docId}.jpg  # Documents vérification
```

**Règles complètes**:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }

    function isVideo() {
      return request.resource.contentType.matches('video/.*');
    }

    function isValidSize(maxSizeMB) {
      return request.resource.size < maxSizeMB * 1024 * 1024;
    }

    // Photos de profil
    match /users/{userId}/profile/{photoId} {
      // Lecture: authentifié OU profil public
      allow read: if isAuthenticated();

      // Écriture: propriétaire only, image only, max 10MB
      allow write: if isOwner(userId)
                   && isImage()
                   && isValidSize(10);

      // Suppression: propriétaire only
      allow delete: if isOwner(userId);
    }

    // Médias chat
    match /users/{userId}/chat/{messageId} {
      // Lecture: authentifié (TODO: ajouter vérification match/conversation)
      allow read: if isAuthenticated();

      // Écriture: propriétaire only, image/video, max 50MB
      allow write: if isOwner(userId)
                   && (isImage() || isVideo())
                   && isValidSize(50);

      // Suppression: propriétaire only
      allow delete: if isOwner(userId);
    }

    // Documents vérification
    match /users/{userId}/verification/{docId} {
      // Lecture: propriétaire only (sensible!)
      allow read: if isOwner(userId);

      // Écriture: propriétaire only, image only, max 10MB
      allow write: if isOwner(userId)
                   && isImage()
                   && isValidSize(10);

      // Pas de suppression (garder historique vérification)
      allow delete: if false;
    }
  }
}
```

**Publication des règles**:
1. Copiez les règles ci-dessus
2. Firebase Console → Storage → Rules
3. Collez dans l'éditeur
4. Cliquez "**Publish**"

---

## 3️⃣ IMPLÉMENTATION DANS L'APP

### Dépendance Flutter

Ajoutez dans `pubspec.yaml`:

```yaml
dependencies:
  firebase_storage: ^11.5.6
```

Puis:
```bash
flutter pub get
```

---

### Service d'Upload

**Créez**: `lib/core/services/storage_service.dart`

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload photo de profil
  /// Retourne l'URL de téléchargement
  Future<String> uploadProfilePhoto(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // Générer nom unique
    final photoId = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = path.extension(imageFile.path);
    final fileName = '$photoId$extension';

    // Chemin dans Storage
    final ref = _storage.ref().child('users/$userId/profile/$fileName');

    // Metadata (type MIME)
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
      },
    );

    // Upload
    final uploadTask = ref.putFile(imageFile, metadata);

    // Progress optionnel
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
    });

    // Attendre fin upload
    final snapshot = await uploadTask;

    // Récupérer URL
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload média chat (photo/vidéo)
  Future<String> uploadChatMedia(File mediaFile, {bool isVideo = false}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = path.extension(mediaFile.path);
    final fileName = '$messageId$extension';

    final ref = _storage.ref().child('users/$userId/chat/$fileName');

    final metadata = SettableMetadata(
      contentType: isVideo ? 'video/mp4' : 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'messageId': messageId,
      },
    );

    final uploadTask = ref.putFile(mediaFile, metadata);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  /// Supprimer photo (par URL)
  Future<void> deletePhoto(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }

  /// Upload document vérification
  Future<String> uploadVerificationDocument(
    File docFile,
    String docType, // 'id_front', 'id_back', 'selfie'
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${docType}_$timestamp.jpg';

    final ref = _storage.ref().child('users/$userId/verification/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'docType': docType,
      },
    );

    final uploadTask = ref.putFile(docFile, metadata);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
}
```

---

### Intégration dans injection.dart

```dart
// Dans lib/injection.dart, section services
getIt.registerSingleton<StorageService>(
  StorageService(),
);
```

---

### Utilisation dans ProfileRepository

**Modifiez**: `lib/data/repositories/profile_repository_impl.dart`

```dart
import 'package:hivmeet/core/services/storage_service.dart';
import 'package:hivmeet/core/services/image_compression_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _api;
  final StorageService _storage;
  final ImageCompressionService _compression;

  ProfileRepositoryImpl(
    this._api,
    this._storage,
    this._compression,
  );

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required File photo,
    bool isMain = false,
    bool isPrivate = false,
  }) async {
    try {
      // 1. Compresser l'image
      final compressedPhoto = await _compression.compressProfilePhoto(photo);

      // 2. Upload vers Firebase Storage
      final photoUrl = await _storage.uploadProfilePhoto(compressedPhoto);

      // 3. Enregistrer l'URL dans le backend
      await _api.addProfilePhoto(
        photoUrl: photoUrl,
        isMain: isMain,
        isPrivate: isPrivate,
      );

      return Right(photoUrl);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: 'Upload échoué: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur upload: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfilePhoto(String photoUrl) async {
    try {
      // 1. Supprimer du backend
      await _api.deleteProfilePhoto(photoUrl: photoUrl);

      // 2. Supprimer de Storage
      await _storage.deletePhoto(photoUrl);

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: 'Suppression échouée: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Erreur suppression: $e'));
    }
  }
}
```

---

## 4️⃣ TESTS & VÉRIFICATION

### Test Upload Photo

```dart
// Exemple test dans ProfileBloc
void testUploadPhoto() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final file = File(image.path);

    // Trigger l'événement
    profileBloc.add(UploadPhoto(
      photo: file,
      isMain: true,
      isPrivate: false,
    ));
  }
}
```

### Vérification Console Firebase

1. Firebase Console → Storage
2. Naviguez vers `users/{userId}/profile/`
3. Vérifiez que la photo est présente
4. Cliquez sur la photo → Voir les metadata
5. Vérifiez type MIME, taille, etc.

---

## 5️⃣ MONITORING & MAINTENANCE

### Quotas Firebase Storage

**Plan Gratuit (Spark)**:
- 5 GB stockage total
- 1 GB download/jour
- 20,000 uploads/jour

**Plan Payant (Blaze)**:
- $0.026/GB stockage
- $0.12/GB download
- Uploads gratuits

### Nettoyage Automatique

**Cloud Functions pour supprimer vieux fichiers**:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Supprimer photos non référencées après 30 jours
exports.cleanupOrphanedPhotos = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: 'users/' });

    const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);

    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const uploadDate = new Date(metadata.timeCreated).getTime();

      if (uploadDate < thirtyDaysAgo) {
        // Vérifier si référencé dans Firestore
        const isReferenced = await checkIfReferenced(file.name);

        if (!isReferenced) {
          await file.delete();
          console.log(`Deleted orphaned file: ${file.name}`);
        }
      }
    }
  });
```

---

## 6️⃣ SÉCURITÉ AVANCÉE

### CORS Configuration

Si accès depuis web, configurez CORS:

**Créez**: `cors.json`
```json
[
  {
    "origin": ["https://hivmeet.com", "https://www.hivmeet.com"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

**Appliquez**:
```bash
gsutil cors set cors.json gs://YOUR_PROJECT_ID.appspot.com
```

### Virus Scanning (Optionnel)

Pour scanner les uploads:
1. Activez Cloud Functions
2. Utilisez ClamAV ou service tiers
3. Scannez lors de l'événement `onFinalize`

---

## 7️⃣ DÉPANNAGE

### Erreur: "User does not have permission"

**Solution**: Vérifiez que:
1. `FirebaseAuth.instance.currentUser` n'est pas null
2. Les règles Storage autorisent `request.auth.uid`
3. Le chemin respecte `/users/{userId}/...`

### Upload lent

**Solutions**:
1. Compressez d'abord (ImageCompressionService)
2. Vérifiez connexion internet
3. Utilisez Firebase Performance Monitoring

### Photo ne s'affiche pas

**Solutions**:
1. Vérifiez l'URL retournée
2. Vérifiez règles Storage (read access)
3. Utilisez `cached_network_image` pour cache

---

**Firebase Storage configuré! Passez au FCM (notifications).** ✅
