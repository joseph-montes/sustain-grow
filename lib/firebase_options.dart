// Firebase configuration for all platforms.
// Android: matches google-services.json (com.sustain.myapp)
// Web:     matches Firebase Console → sustain-grow → Web app

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
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // ── Web ────────────────────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVypfDPtNtswBbVBJ67313CWniN0fHdoc',
    appId: '1:560525748485:web:59f48cec8d995a0305ef6c',
    messagingSenderId: '560525748485',
    projectId: 'sustain-grow',
    authDomain: 'sustain-grow.firebaseapp.com',
    storageBucket: 'sustain-grow.firebasestorage.app',
    measurementId: 'G-3DJS7887CK',
  );

  // ── Android ────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtXT8oL7D6XtUg9h_JOeVKr7UTI8x-re4',
    appId: '1:560525748485:android:2b02bc9ba04060e005ef6c',
    messagingSenderId: '560525748485',
    projectId: 'sustain-grow',
    storageBucket: 'sustain-grow.firebasestorage.app',
  );

  // ── iOS (add GoogleService-Info.plist when iOS app is registered) ──────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtXT8oL7D6XtUg9h_JOeVKr7UTI8x-re4',
    appId: '1:560525748485:ios:REPLACE_IF_IOS_NEEDED',
    messagingSenderId: '560525748485',
    projectId: 'sustain-grow',
    storageBucket: 'sustain-grow.firebasestorage.app',
    iosBundleId: 'com.sustain.myapp',
  );
}
