import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

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
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
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
}
