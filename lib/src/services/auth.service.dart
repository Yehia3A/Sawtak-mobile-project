// lib/src/services/auth_service.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of auth changes (signed in / out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign up with email & password
  Future<UserCredential> signUp(String email, String password) async =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  /// Sign in with email & password
  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Sign out
  Future<void> signOut() => _auth.signOut();

  /// Check if email verification can be sent (rate limiting)
  Future<bool> _canSendVerificationEmail(String email) async {
    try {
      // Get all verification attempts in the last hour
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Check daily attempts first
      final dailyAttempts =
          await _firestore
              .collection('emailVerificationAttempts')
              .where(
                'lastAttempt',
                isGreaterThan: Timestamp.fromDate(oneDayAgo),
              )
              .get();

      if (dailyAttempts.docs.length >= 20) {
        // Daily limit
        throw Exception(
          'Daily verification limit reached. Please try again tomorrow or contact support.',
        );
      }

      // Check hourly attempts
      final hourlyAttempts =
          await _firestore
              .collection('emailVerificationAttempts')
              .where(
                'lastAttempt',
                isGreaterThan: Timestamp.fromDate(oneHourAgo),
              )
              .get();

      if (hourlyAttempts.docs.length >= 5) {
        // Hourly limit
        throw Exception(
          'Too many verification attempts. Please wait at least 1 hour before trying again.',
        );
      }

      // Check individual user's last attempt
      final userDoc =
          await _firestore
              .collection('emailVerificationAttempts')
              .doc(email)
              .get();

      if (userDoc.exists) {
        final lastAttempt = userDoc.data()?['lastAttempt'] as Timestamp?;
        if (lastAttempt != null) {
          // Allow one attempt per 5 minutes per email
          final minutesSinceLastAttempt =
              now.difference(lastAttempt.toDate()).inMinutes;
          if (minutesSinceLastAttempt < 5) {
            throw Exception(
              'Please wait ${5 - minutesSinceLastAttempt} minutes before requesting another verification email.',
            );
          }
        }
      }

      return true;
    } catch (e) {
      if (e is Exception) {
        rethrow; // Re-throw rate limiting exceptions
      }
      print('❌ Error checking verification rate limit: $e');
      return false; // If check fails, don't allow attempt
    }
  }

  /// Update last verification attempt timestamp
  Future<void> _updateVerificationAttempt(String email) async {
    final now = Timestamp.now();
    await _firestore.collection('emailVerificationAttempts').doc(email).set({
      'email': email,
      'lastAttempt': now,
      'attempts': FieldValue.increment(1),
      'hourlyPeriod': now.toDate().hour, // Track hourly periods
    }, SetOptions(merge: true));
  }

  /// Handle verification link click
  Future<bool> handleVerificationLink(String link) async {
    try {
      // Check if this is a valid email verification link
      if (!_auth.isSignInWithEmailLink(link)) return false;

      // Get the email from verification document
      final actionCode = Uri.parse(link).queryParameters['oobCode'];
      if (actionCode == null) return false;

      // Get the email info
      final info = await _auth.checkActionCode(actionCode);
      final email = info.data?['email'] as String?;
      if (email == null) return false;

      // Get verification document
      final verificationDoc =
          await _firestore.collection('emailVerification').doc(email).get();

      if (!verificationDoc.exists) return false;

      final data = verificationDoc.data();
      final uid = data?['uid'] as String?;
      final storedPassword = data?['password'] as String?;
      final isLogin = data?['isLogin'] as bool? ?? false;

      if (isLogin && storedPassword != null) {
        // Sign in the user
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: storedPassword,
        );

        // Apply the verification code
        await _auth.applyActionCode(actionCode);

        // Update user's 2FA status
        await _firestore.collection('users').doc(uid).update({
          'is2faEnabled': true,
          'twoFactorMethod': 'email',
          'verifiedEmail': email,
        });

        // Mark verification as complete
        await verificationDoc.reference.update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'password': FieldValue.delete(), // Clean up password
        });

        return true;
      }

      return false;
    } catch (e) {
      print('Error handling verification link: $e');
      return false;
    }
  }

  /// Send email verification link
  Future<void> sendEmailVerification(
    String email, {
    String? password,
    bool isLogin = false,
  }) async {
    try {
      // Check rate limiting
      try {
        await _canSendVerificationEmail(email);
      } catch (e) {
        throw Exception(e.toString()); // Forward rate limiting errors
      }

      // Configure action code settings
      final actionCodeSettings = ActionCodeSettings(
        url: 'http://localhost:3000', // Updated URL as requested
        handleCodeInApp: true,
        androidPackageName: 'com.sawtak.app',
        androidMinimumVersion: '1',
        iOSBundleId: 'gov.project',
      );

      // First ensure we have a signed in user
      User? user = _auth.currentUser;

      // If no user is signed in, try to sign in with the provided email
      if (user == null && password != null) {
        try {
          final userCred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          user = userCred.user;
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'too-many-requests') {
            throw Exception(
              'Too many sign-in attempts. Please try again later.',
            );
          }
          rethrow;
        }
      }

      if (user == null) {
        throw Exception('Failed to authenticate user');
      }

      // Check if 2FA is enabled for the user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final is2faEnabled = data?['is2faEnabled'] ?? false;

      // Only proceed with email verification if 2FA is enabled
      if (!is2faEnabled) {
        throw Exception('2FA is not enabled for this user');
      }

      // Send verification email
      try {
        await user.sendEmailVerification(actionCodeSettings);
      } catch (e) {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'too-many-requests':
              throw Exception(
                'Too many verification attempts. Please try again later.',
              );
            case 'quota-exceeded':
              throw Exception(
                'Daily verification quota exceeded. Please try again tomorrow.',
              );
            default:
              throw Exception(
                'Failed to send verification email: ${e.message}',
              );
          }
        }
        rethrow;
      }

      // Update rate limiting record
      await _updateVerificationAttempt(email);

      // Store the email in Firestore for verification with additional data
      await _firestore.collection('emailVerification').doc(email).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'uid': user.uid,
        'password': isLogin ? password : null,
        'isLogin': isLogin,
      });
    } catch (e) {
      throw Exception(
        e.toString().replaceAll('Exception: ', ''),
      ); // Clean up error message
    }
  }

  /// Verify email link and enable 2FA
  Future<void> verifyEmailLink(String email, String emailLink) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Update user's 2FA status in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'is2faEnabled': true,
        'twoFactorMethod': 'email',
        'verifiedEmail': email,
      });

      // Mark email as verified
      await _firestore.collection('emailVerification').doc(email).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to verify email: $e');
    }
  }

  /// Check if email verification is pending and handle auto-login
  Future<bool> isEmailVerificationPending(String email) async {
    try {
      // Get verification document first
      final verificationDoc =
          await _firestore.collection('emailVerification').doc(email).get();

      if (!verificationDoc.exists) return false;

      final data = verificationDoc.data();
      final uid = data?['uid'] as String?;
      final storedPassword = data?['password'] as String?;
      final isLogin = data?['isLogin'] as bool? ?? false;

      // Check if user is verified
      User? user = _auth.currentUser;

      // Try to sign in if this is a login verification and no user is logged in
      if (isLogin && storedPassword != null) {
        try {
          if (user == null) {
            final userCred = await _auth.signInWithEmailAndPassword(
              email: email,
              password: storedPassword,
            );
            user = userCred.user;
          }

          // Reload user to get latest verification status
          await user?.reload();
          user = _auth.currentUser; // Get fresh user instance

          if (user?.emailVerified == true && uid != null) {
            // Update user's 2FA status
            await _firestore.collection('users').doc(uid).update({
              'is2faEnabled': true,
              'twoFactorMethod': 'email',
              'verifiedEmail': email,
            });

            // Mark verification as complete
            await verificationDoc.reference.update({
              'verified': true,
              'verifiedAt': FieldValue.serverTimestamp(),
              'password': FieldValue.delete(), // Clean up password
            });

            return false; // Stop polling and proceed with login
          }
        } catch (e) {
          print('Error during verification check: $e');
        }
      }

      // Still pending verification
      return true;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }

  /// Check if user has a pending verification
  Future<bool> hasActiveVerification(String email) async {
    try {
      final doc =
          await _firestore.collection('emailVerification').doc(email).get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final verified = data['verified'] as bool? ?? false;
      final createdAt = data['createdAt'] as Timestamp?;

      if (createdAt == null) return false;

      // Check if verification is less than 1 hour old
      final age = DateTime.now().difference(createdAt.toDate());
      return !verified && age.inHours < 1;
    } catch (e) {
      print('Error checking verification status: $e');
      return false;
    }
  }

  /// Start polling for email verification
  Stream<bool> pollEmailVerification(String email) {
    // Poll every second for quicker response
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => isEmailVerificationPending(email))
        .takeWhile(
          (isPending) => isPending,
        ) // Continue while verification is pending
        .asBroadcastStream();
  }
}
