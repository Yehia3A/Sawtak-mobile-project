// lib/src/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _fb = FirebaseAuth.instance;

  /// Stream of auth changes (signed in / out)
  Stream<User?> get authStateChanges => _fb.authStateChanges();

  /// Sign up with email & password
  Future<UserCredential> signUp(String email, String password) async =>
      _fb.createUserWithEmailAndPassword(email: email, password: password);

  /// Sign in with email & password
  Future<UserCredential> signIn(String email, String password) =>
      _fb.signInWithEmailAndPassword(email: email, password: password);

  /// Sign out
  Future<void> signOut() => _fb.signOut();
}
