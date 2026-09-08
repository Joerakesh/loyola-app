import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration used on web (and as a fallback). On Android/iOS the
/// SDK reads the native config files (google-services.json /
/// GoogleService-Info.plist) and no options are needed.
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

  /// Android uses the same Firebase project. The value comes from the web app
  /// config as a fallback when google-services.json is not yet present.
  static const FirebaseOptions androidOptions = webOptions;
}

/// Initialises Firebase once before the app starts.
///
/// On web the options are passed explicitly. On Android the SDK picks up the
/// native config if google-services.json is present, otherwise falls back to
/// the explicit options so the app can still start.
Future<FirebaseApp> initialiseFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return Firebase.apps.first;
  }

  try {
    return await Firebase.initializeApp(options: FirebaseConfig.webOptions);
  } on FirebaseException catch (error) {
    // Handles hot reload/restart: the native app survives the restart but the
    // new Dart isolate starts with an empty apps list.
    if (error.code == 'duplicate-app') {
      return Firebase.apps.first;
    }
    rethrow;
  }
}