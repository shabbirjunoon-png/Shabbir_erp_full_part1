import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWZUec_0vrLOsIfPEIU68hQ7RwqTs1iz0',
    appId: '1:533290517471:android:9839d8b3dab8204348ba6a',
    messagingSenderId: '533290517471',
    projectId: 'shabbirer-eca8d',
    storageBucket: 'shabbirer-eca8d.firebasestorage.app',
  );
}
