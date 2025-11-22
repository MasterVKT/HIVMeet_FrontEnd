# 🔔 FIREBASE CLOUD MESSAGING (FCM) - GUIDE COMPLET

**Date**: 20 novembre 2024
**Prérequis**: Projet Firebase créé, app iOS/Android configurée

---

## 📋 VUE D'ENSEMBLE

FCM est utilisé dans HIVMeet pour envoyer:
- **Notifications match**: "Vous avez un nouveau match!"
- **Notifications message**: "Jean vous a envoyé un message"
- **Notifications like**: "Marie a liké votre profil"
- **Notifications système**: "Votre profil a été vérifié"

---

## 1️⃣ CONFIGURATION ANDROID

### Étape 1: Télécharger google-services.json

1. Firebase Console → Project Settings
2. Onglet "Your apps" → Icône Android
3. Si app pas encore créée:
   - Cliquez "Add app"
   - Package name: `com.hivmeet.app` (doit matcher `applicationId` dans `build.gradle`)
   - Téléchargez `google-services.json`
4. Placez `google-services.json` dans `android/app/`

---

### Étape 2: Configuration Gradle

**`android/build.gradle`** (projet level):
```gradle
buildscript {
    dependencies {
        // Firebase services plugin
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**`android/app/build.gradle`** (app level):
```gradle
// En haut du fichier
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'  // ← Ajouter cette ligne

android {
    defaultConfig {
        // ... existing config
    }
}

dependencies {
    // Firebase Messaging
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

---

### Étape 3: Permissions & Service

**`android/app/src/main/AndroidManifest.xml`**:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions notifications -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />

    <application>
        <!-- ... existing config -->

        <!-- FCM Service -->
        <service
            android:name=".MyFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>

        <!-- Default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="hivmeet_default_channel"/>

        <!-- Notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification"/>

        <!-- Notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color"/>
    </application>
</manifest>
```

---

### Étape 4: Service Messaging Android (Optionnel - Background)

**Créez**: `android/app/src/main/kotlin/com/hivmeet/app/MyFirebaseMessagingService.kt`

```kotlin
package com.hivmeet.app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d(TAG, "From: ${remoteMessage.from}")

        // Vérifier si message contient données
        remoteMessage.data.isNotEmpty().let {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")

            // Traiter données background
            handleDataPayload(remoteMessage.data)
        }

        // Vérifier si message contient notification
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
            sendNotification(it.title, it.body)
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed token: $token")

        // Envoyer nouveau token au backend
        sendTokenToServer(token)
    }

    private fun handleDataPayload(data: Map<String, String>) {
        val type = data["type"] // "match", "message", "like", etc.
        val userId = data["userId"]
        val messageId = data["messageId"]

        // Logique custom selon type
        when (type) {
            "match" -> {
                // Afficher notification match avec avatar
            }
            "message" -> {
                // Afficher notification message
            }
            "like" -> {
                // Afficher notification like
            }
        }
    }

    private fun sendNotification(title: String?, messageBody: String?) {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val channelId = "hivmeet_default_channel"
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title ?: "HIVMeet")
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Créer channel pour Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "HIVMeet Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }

        notificationManager.notify(0, notificationBuilder.build())
    }

    private fun sendTokenToServer(token: String) {
        // TODO: Appeler API backend pour sauvegarder token
        // POST /api/users/fcm-token avec token
    }

    companion object {
        private const val TAG = "MyFirebaseMsgService"
    }
}
```

---

## 2️⃣ CONFIGURATION iOS

### Étape 1: Télécharger GoogleService-Info.plist

1. Firebase Console → Project Settings
2. Onglet "Your apps" → Icône iOS
3. Si app pas encore créée:
   - Cliquez "Add app"
   - Bundle ID: `com.hivmeet.app` (doit matcher dans Xcode)
   - Téléchargez `GoogleService-Info.plist`
4. Glissez `GoogleService-Info.plist` dans Xcode (dossier `Runner`)
   - **Important**: Cochez "Copy items if needed"

---

### Étape 2: Capabilities Xcode

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez projet Runner → Target Runner
3. Onglet "Signing & Capabilities"
4. Cliquez "+ Capability"
5. Ajoutez:
   - **Push Notifications**
   - **Background Modes** (cochez "Remote notifications")

---

### Étape 3: Certificats APNs

**Générer clé APNs**:
1. Apple Developer Console: https://developer.apple.com
2. Certificates, Identifiers & Profiles
3. Keys → "+" (nouvelle clé)
4. Nom: "HIVMeet APNs Key"
5. Cochez "Apple Push Notifications service (APNs)"
6. Téléchargez le fichier `.p8`
7. **Notez Key ID et Team ID**

**Uploader dans Firebase**:
1. Firebase Console → Project Settings
2. Onglet "Cloud Messaging"
3. Section "Apple app configuration"
4. Uploadez fichier `.p8`
5. Entrez Key ID et Team ID

---

### Étape 4: Code iOS Background Handler (Optionnel)

**`ios/Runner/AppDelegate.swift`**:

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Request permission notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self

      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
    } else {
      let settings: UIUserNotificationSettings =
      UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    // Set messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle token refresh
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")

    let dataDict:[String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)

    // TODO: Send token to backend
  }
}
```

---

## 3️⃣ IMPLÉMENTATION FLUTTER

### Dépendance

**`pubspec.yaml`**:
```yaml
dependencies:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0  # Pour afficher notifs localement
```

```bash
flutter pub get
```

---

### Service Notifications

**Créez**: `lib/core/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hivmeet/data/datasources/remote/auth_api.dart';

// Handler background (doit être top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Traiter message même si app fermée
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Créer channel Android
    const androidChannel = AndroidNotificationChannel(
      'hivmeet_default_channel',
      'HIVMeet Notifications',
      description: 'Notifications pour matches, messages, likes',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Obtenir token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Envoyer token au backend
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Écouter changements token
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message tap (app ouverte depuis notif)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Vérifier si app ouverte depuis notif
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    // TODO: Appeler AuthApi pour sauvegarder token
    // await authApi.registerFcmToken(token);
    print('Token sent to backend: $token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // Afficher notification locale
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');

    // Navigation selon type
    final type = message.data['type'];
    switch (type) {
      case 'match':
        // Navigator.pushNamed(context, '/matches');
        break;
      case 'message':
        final conversationId = message.data['conversationId'];
        // Navigator.pushNamed(context, '/chat', arguments: conversationId);
        break;
      case 'like':
        // Navigator.pushNamed(context, '/likes-received');
        break;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'hivmeet_default_channel',
      'HIVMeet Notifications',
      channelDescription: 'Notifications pour matches, messages, likes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'HIVMeet',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigation
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
```

---

### Intégration main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp());
}
```

---

## 4️⃣ BACKEND - ENVOI NOTIFICATIONS

### Depuis Backend Node.js

**Installation**:
```bash
npm install firebase-admin
```

**Code**:
```javascript
const admin = require('firebase-admin');

// Initialize (une seule fois)
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Envoyer notification match
async function sendMatchNotification(userToken, matchedUserName, matchedUserPhoto) {
  const message = {
    notification: {
      title: 'Nouveau match! 💕',
      body: `Vous avez matché avec ${matchedUserName}!`,
      imageUrl: matchedUserPhoto,
    },
    data: {
      type: 'match',
      matchedUserId: matchedUserId,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    token: userToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.log('Error sending message:', error);
  }
}

// Envoyer notification message
async function sendMessageNotification(recipientToken, senderName, messagePreview) {
  const message = {
    notification: {
      title: senderName,
      body: messagePreview,
    },
    data: {
      type: 'message',
      senderId: senderId,
      conversationId: conversationId,
    },
    token: recipientToken,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  await admin.messaging().send(message);
}
```

---

## 5️⃣ TESTS

### Test Token Récupération

```dart
// Dans n'importe quel écran
TextButton(
  onPressed: () async {
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // Copier dans clipboard
    await Clipboard.setData(ClipboardData(text: token ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Token copié!')),
    );
  },
  child: Text('Obtenir FCM Token'),
)
```

### Test Envoi via Console Firebase

1. Firebase Console → Cloud Messaging
2. Cliquez "Send your first message"
3. Notification title: "Test HIVMeet"
4. Notification text: "Ceci est un test"
5. Section "Target": Collez votre FCM token
6. Cliquez "Test"

Vérifiez que la notification apparaît!

---

## 6️⃣ TYPES DE NOTIFICATIONS HIVMEET

### Format Data Payload

**Match**:
```json
{
  "type": "match",
  "matchId": "abc123",
  "matchedUserId": "user456",
  "matchedUserName": "Jean",
  "matchedUserPhoto": "https://...",
  "compatibilityScore": 87
}
```

**Message**:
```json
{
  "type": "message",
  "conversationId": "conv789",
  "senderId": "user456",
  "senderName": "Jean",
  "messagePreview": "Salut! Comment ça va?",
  "messageType": "text"
}
```

**Like**:
```json
{
  "type": "like",
  "likerId": "user456",
  "likerName": "Marie",
  "likerPhoto": "https://...",
  "isMatch": false
}
```

---

## 7️⃣ OPTIMISATIONS

### Badge Count (iOS)

```dart
// Incrémenter badge
await FirebaseMessaging.instance.setApplicationIconBadgeNumber(5);

// Reset badge
await FirebaseMessaging.instance.setApplicationIconBadgeNumber(0);
```

### Notification Channels Android

Créez plusieurs channels pour différentes priorités:

```dart
const highPriorityChannel = AndroidNotificationChannel(
  'hivmeet_high_priority',
  'Matches & Messages',
  importance: Importance.high,
  sound: RawResourceAndroidNotificationSound('notification_sound'),
);

const lowPriorityChannel = AndroidNotificationChannel(
  'hivmeet_low_priority',
  'Likes & Updates',
  importance: Importance.low,
);
```

---

## 8️⃣ DÉPANNAGE

### Token null

**Causes**:
- `google-services.json` ou `GoogleService-Info.plist` manquant
- Permissions refusées

**Solution**: Vérifier logs, réinstaller app

### Notifications pas reçues

**Vérifications**:
1. Token valide et envoyé au backend?
2. App en foreground ou background?
3. Permissions accordées?
4. Certificats APNs valides (iOS)?

### iOS notifications ne marchent pas

**Solutions**:
1. Vérifier `.p8` uploadé dans Firebase
2. Vérifier Bundle ID exact
3. Vérifier capabilities Push Notifications
4. Tester sur device réel (pas simulateur!)

---

**FCM configuré! Votre app peut recevoir notifications push.** 🔔✅
