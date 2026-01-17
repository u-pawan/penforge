import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  // Initialize GoogleSignIn - call this before using Google sign in
  Future<void> initializeGoogleSignIn({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_isInitialized) return;
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _isInitialized = true;
  }

  // Listen to auth changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Anonymous login
  Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return result.user;
  }

  // Google login (upgrade anonymous user)
  Future<User?> signInWithGoogle() async {
    if (!_isInitialized) {
      throw Exception(
        'GoogleSignIn not initialized. Call initializeGoogleSignIn() first.',
      );
    }

    // Use authenticate() for google_sign_in v7+
    final googleUser = await _googleSignIn.authenticate();

    // Get idToken from authentication property
    final authentication = googleUser.authentication;

    // Get accessToken by authorizing scopes
    final authorization = await googleUser.authorizationClient.authorizeScopes([
      'email',
      'profile',
    ]);

    final credential = GoogleAuthProvider.credential(
      accessToken: authorization.accessToken,
      idToken: authentication.idToken,
    );

    final currentUser = _auth.currentUser;

    // 🔥 Upgrade anonymous account
    if (currentUser != null && currentUser.isAnonymous) {
      final result = await currentUser.linkWithCredential(credential);
      return result.user;
    }

    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _auth.signOut();
  }
}
