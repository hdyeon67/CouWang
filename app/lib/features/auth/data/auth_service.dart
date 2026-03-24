import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/firebase_bootstrap.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  User? get currentUser {
    if (!FirebaseBootstrap.isInitialized) {
      return null;
    }

    return _auth.currentUser;
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      throw UnsupportedError('웹 Google 로그인은 아직 설정되지 않았어요.');
    }

    if (!FirebaseBootstrap.isInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase 초기화가 완료되지 않았어요.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google ID 토큰을 가져오지 못했어요.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait<void>([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
