// File generated for DramaPop Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your DramaPop Firebase apps.
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
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwlIpx2xh3nP55y69SBwe6OAkxyJZ4vws',
    appId: '1:324442220312:web:dramapopweb',
    messagingSenderId: '324442220312',
    projectId: 'fir-28d8f',
    authDomain: 'fir-28d8f.firebaseapp.com',
    storageBucket: 'fir-28d8f.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwlIpx2xh3nP55y69SBwe6OAkxyJZ4vws',
    appId: '1:324442220312:android:2f59b90c6da2d6259fe06d',
    messagingSenderId: '324442220312',
    projectId: 'fir-28d8f',
    storageBucket: 'fir-28d8f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArZU5c42NOS3z4FrCQeeuJ1wHNckWNsv4',
    appId: '1:324442220312:ios:e22f3d675e47d1479fe06d',
    messagingSenderId: '324442220312',
    projectId: 'fir-28d8f',
    storageBucket: 'fir-28d8f.firebasestorage.app',
    iosBundleId: 'com.dramapop.app.series.shorts.dramas',
  );
}
