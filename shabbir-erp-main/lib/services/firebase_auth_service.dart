import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  FirebaseAuthService._();
  static FirebaseAuthService get instance {
    _instance ??= FirebaseAuthService._();
    return _instance!;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleSignIn get _googleSignIn => kIsWeb
      ? GoogleSignIn(
          clientId:
              '533290517471-nha8kqm8p92qb1dfpd81tajc7oqbgmmi.apps.googleusercontent.com',
        )
      : GoogleSignIn(
          serverClientId:
              '533290517471-nha8kqm8p92qb1dfpd81tajc7oqbgmmi.apps.googleusercontent.com',
        );

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  String get userId => _auth.currentUser?.uid ?? 'default';

  String get displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email ??
      'User';

  String? get avatarUrl => _auth.currentUser?.photoURL;

  String get email => _auth.currentUser?.email ?? '';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    final googleSignIn = _googleSignIn;
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
