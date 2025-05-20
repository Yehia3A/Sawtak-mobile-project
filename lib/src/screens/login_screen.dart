import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  StreamSubscription? _linkSubscription;
  final AuthService _authService = AuthService();
  late AppLinks _appLinks;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _aniController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _aniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _aniController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _aniController, curve: Curves.easeOutCubic),
    );

    _aniController.forward();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? link) {
        if (link != null) {
          _handleDeepLink(link.toString());
        }
      },
      onError: (err) {
        print('Error handling deep link: $err');
      },
    );
  }

  Future<void> _handleDeepLink(String link) async {
    try {
      // First check if this is a verification link
      if (link.contains('oobCode=')) {
        final success = await _authService.handleVerificationLink(link);
        if (success && mounted) {
          // Get the email from the link
          final uri = Uri.parse(link);
          final email = uri.queryParameters['email'];

          if (email != null) {
            // Get the stored password from Firestore
            final verificationDoc =
                await FirebaseFirestore.instance
                    .collection('emailVerification')
                    .doc(email)
                    .get();

            if (verificationDoc.exists) {
              final data = verificationDoc.data();
              final password = data?['password'] as String?;

              if (password != null) {
                // Try to sign in with the stored credentials
                try {
                  await _authService.signIn(email, password);
                  if (mounted) {
                    // Navigate to home page after successful login
                    Navigator.pushReplacementNamed(context, '/');
                    return;
                  }
                } catch (e) {
                  print('Error during auto-login: $e');
                }
              }
            }
          }

          // If auto-login fails, show a message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified. Please sign in again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error handling verification link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _aniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Try later.';
      default:
        return 'Sign in failed: $code';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final cred = await _authService.signIn(email, password);
      final uid = cred.user?.uid;

      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = userDoc.data();
<<<<<<< Updated upstream

        if (data != null && data['is2faEnabled'] == true) {
          // Check if there's already an active verification
          final hasActiveVerification = await _authService
              .hasActiveVerification(email);

          if (!hasActiveVerification) {
            // Sign out and send verification email with password for auto-login
            await FirebaseAuth.instance.signOut();
            await _authService.sendEmailVerification(
              email,
              password: password,
              isLogin: true, // This is a login verification
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please check your email to complete 2FA verification',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }

          // Start polling for verification
          StreamSubscription? subscription;
          subscription = _authService
              .pollEmailVerification(email)
              .listen(
                (isPending) async {
                  if (!isPending && mounted) {
                    // Verification is complete
                    // Cancel subscription
                    await subscription?.cancel();

                    // Check if we're already logged in
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.pushReplacementNamed(context, '/');
                    } else {
                      // Try to log in again
                      try {
                        await _authService.signIn(email, password);
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      } catch (e) {
                        print('Error during auto-login: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Verification successful. Please try logging in again.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                onError: (e) {
                  print('Error polling verification status: $e');
                  subscription?.cancel();
                },
                onDone: () {
                  subscription?.cancel();
=======
        if (data != null &&
            data['is2faEnabled'] == true &&
            data['phone'] != null &&
            data['phone'].toString().isNotEmpty) {
          final phone = data['phone'];
          await FirebaseAuth.instance
              .signOut(); // Sign out to allow phone verification
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: phone,
            verificationCompleted: (PhoneAuthCredential credential) async {
              await FirebaseAuth.instance.signInWithCredential(credential);
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            verificationFailed: (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('2FA failed: ${e.message}')),
                );
              }
            },
            codeSent: (verificationId, resendToken) async {
              final code = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('Enter OTP'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OTP Code'),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            () => Navigator.of(context).pop(controller.text),
                        child: const Text('Verify'),
                      ),
                    ],
                  );
>>>>>>> Stashed changes
                },
              );
        } else {
          // No 2FA required, proceed with login
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.code)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with overlay
          Image.asset('assets/signin.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Welcome Text
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Sign in to continue',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white70,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black87,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Sign Up Link
                          TextButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              'Don\'t have an account? Sign Up',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
