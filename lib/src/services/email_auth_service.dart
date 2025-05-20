import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthService {
  final _auth = FirebaseAuth.instance;

  // Send email link
  Future<void> sendSignInLink(String email) async {
    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://your-app.page.link/verify',
          handleCodeInApp: true,
          androidPackageName: 'com.sawtak.app',
          androidMinimumVersion: '1',
          iOSBundleId: 'gov.project',
        ),
      );
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Sign in with email link
  Future<UserCredential> signInWithEmailLink(String email, String emailLink) async {
    try {
      return await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
    } catch (e) {
      throw Exception('Failed to sign in with email link: $e');
    }
  }
} 