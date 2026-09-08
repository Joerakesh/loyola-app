import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the Firebase Google sign-in flow and returns a Firebase ID token
/// that the backend can verify via firebase-admin.
class GoogleAuthService {
  GoogleAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static bool _initialised = false;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Initialises the Google Sign In plugin. Fire-and-forget-safe: the plugin
  /// requires exact-once initialization before other calls.
  Future<void> ensureInitialised() async {
    if (_initialised) {
      return;
    }

    await _googleSignIn.initialize();
    _initialised = true;
  }

  /// Signs in with Google and returns the Firebase ID token.
  Future<String> signInWithGoogle() async {
    await ensureInitialised();

    final account = await _googleSignIn.authenticate();

    final googleAuth = account.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google sign-in failed: missing ID token');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user == null) {
      throw Exception('Google sign-in failed: no Firebase user');
    }

    final firebaseIdToken = await userCredential.user!.getIdToken();

    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Unable to obtain Firebase ID token');
    }

    return firebaseIdToken;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase sign-out error: $e');
    }
  }
}