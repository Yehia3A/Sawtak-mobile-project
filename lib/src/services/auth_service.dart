import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email/password sign-in
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Register new user
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
      return cred;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Update displayName / photoURL
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    try {
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoURL != null)  await user.updatePhotoURL(photoURL);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //                     SIMPLE PHONE-OTP 2FA METHODS
  // After calling these, prompt the user for the SMS code in your UI.
  // ────────────────────────────────────────────────────────────────────────────

  /// 1) Fires off the SMS to [phoneNumber] and returns the [verificationId].
  Future<String> sendPhoneCode(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Automatically on Android—reauthenticate immediately
        await _auth.currentUser?.reauthenticateWithCredential(cred);
        // Returning `"auto"` is optional; UI can treat it as success.
        if (!completer.isCompleted) completer.complete('auto');
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out.
      },
    );

    return completer.future;
  }

  /// 2) Once the user enters [smsCode], call this with the [verificationId]
  ///    returned from sendPhoneCode().  This will re-authenticate the
  ///    currently signed-in user and complete 2FA.
  Future<void> verifyPhoneCode(
    String verificationId,
    String smsCode,
  ) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    try {
      await _auth.currentUser
          ?.reauthenticateWithCredential(cred);
    } catch (e) {
      throw Exception('Failed to verify SMS code: $e');
    }
  }
}
