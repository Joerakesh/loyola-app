import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public web client configuration. Android/iOS should read their native
/// client configuration generated from google-services.json / plist.
class FirebaseConfig {
  FirebaseConfig._();

  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyDBi2gZ9bB8mALpUBgAAFJcYrJYe8ZYLqo',
    authDomain: 'loyola-app-803a6.firebaseapp.com',
    projectId: 'loyola-app-803a6',
    storageBucket: 'loyola-app-803a6.firebasestorage.app',
    messagingSenderId: '816257307604',
    appId: '1:816257307604:web:405474e31f3d5eaae2bc41',
    measurementId: 'G-BCFWM37PYC',
  );

  /// Fallback for local Android builds that do not yet have native config.
  static const FirebaseOptions androidOptions = webOptions;
}

/// Initialises Firebase once before the app starts.
///
/// Web uses explicit public options. Native platforms prefer their platform
/// config; Android falls back to the public web app options for local setup.
Future<FirebaseApp> initialiseFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.apps.first;
  }

  try {
    if (kIsWeb) {
      return await Firebase.initializeApp(options: FirebaseConfig.webOptions);
    }

    try {
      return await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          (error.code == 'no-app' || error.code == 'core/no-app')) {
        return await Firebase.initializeApp(
          options: FirebaseConfig.androidOptions,
        );
      }
      rethrow;
    }
  } on FirebaseException catch (error) {
    // Handles hot reload/restart: the native app survives the restart but the
    // new Dart isolate starts with an empty apps list.
    if (error.code == 'duplicate-app') {
      return Firebase.apps.first;
    }
    rethrow;
  }
}
