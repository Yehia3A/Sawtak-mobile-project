import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      debugPrint('🟢 Signed in: ${cred.user?.uid}');
      // AuthWrapper will auto-redirect based on authStateChanges
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 Sign-in error: ${e.code}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign in failed')));
    } catch (e) {
      debugPrint('🔴 Unexpected error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          Image.asset('assets/signin.jpg', fit: BoxFit.cover),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/logo/logo.png', width: 80),
                    const SizedBox(height: 24),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white70,
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        return emailRegex.hasMatch(v)
                            ? null
                            : 'Enter a valid email';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white70,
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Enter your password'
                                  : null,
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child:
                          _loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('Log in'),
                    ),
                    const SizedBox(height: 16),

                    const Text('Or continue with'),
                    const SizedBox(height: 8),

                    // Social login stubs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.facebook, size: 32),
                        SizedBox(width: 16),
                        Icon(Icons.g_mobiledata, size: 32),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Navigate to SignUp
                    TextButton(
                      onPressed:
                          _loading
                              ? null
                              : () => Navigator.pushNamed(context, '/signup'),
                      child: const Text("Don't have an account? Sign up"),
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
