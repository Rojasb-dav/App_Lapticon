import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// DefaultOptions for Firebase generated/extracted from google-services.json (project: lapticon-eba31).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAuh64b_I2OtC7KYuubCVx9plEe2pojp2M',
    appId: '1:919252353880:android:66bd206ed07a36da5d5b2d',
    messagingSenderId: '919252353880',
    projectId: 'lapticon-eba31',
    storageBucket: 'lapticon-eba31.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAuh64b_I2OtC7KYuubCVx9plEe2pojp2M',
    appId: '1:919252353880:ios:abcdef123456',
    messagingSenderId: '919252353880',
    projectId: 'lapticon-eba31',
    storageBucket: 'lapticon-eba31.firebasestorage.app',
    iosBundleId: 'com.example.lapticonClean',
  );
}
