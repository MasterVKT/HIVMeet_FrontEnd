// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_Osga8cc7BEyXYP7hEsmH1yE4i5tctgo',
    appId: '1:634137235718:android:bd7e7f742a74112f50ce87',
    messagingSenderId: '634137235718',
    projectId: 'hivmeet-f76f8',
    storageBucket: 'hivmeet-f76f8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAx3xEZgPGY3nTqdPngEgaVhZ1eQb2SE-U',
    appId: '1:634137235718:ios:e7ccba0933b1b1f050ce87',
    messagingSenderId: '634137235718',
    projectId: 'hivmeet-f76f8',
    storageBucket: 'hivmeet-f76f8.firebasestorage.app',
    androidClientId: '634137235718-0e8npjn2m2qa5uohi813nb8jc4b3d5oc.apps.googleusercontent.com',
    iosClientId: '634137235718-bnisegqlgjai9qmol9um8u0mtb7j3iud.apps.googleusercontent.com',
    iosBundleId: 'com.hivmeet.hivmeet',
  );

}