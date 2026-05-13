import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBWZUec_0vrLOsIfPEIU68hQ7RwqTs1iz0',
    appId: '1:533290517471:web:9839d8b3dab8204348ba6a',
    messagingSenderId: '533290517471',
    projectId: 'shabbirer-eca8d',
    storageBucket: 'shabbirer-eca8d.firebasestorage.app',
    authDomain: 'shabbirer-eca8d.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWZUec_0vrLOsIfPEIU68hQ7RwqTs1iz0',
    appId: '1:533290517471:android:9839d8b3dab8204348ba6a',
    messagingSenderId: '533290517471',
    projectId: 'shabbirer-eca8d',
    storageBucket: 'shabbirer-eca8d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWZUec_0vrLOsIfPEIU68hQ7RwqTs1iz0',
    appId: '1:533290517471:ios:9839d8b3dab8204348ba6a',
    messagingSenderId: '533290517471',
    projectId: 'shabbirer-eca8d',
    storageBucket: 'shabbirer-eca8d.firebasestorage.app',
    iosBundleId: 'com.shabbir.erp',
  );
}
