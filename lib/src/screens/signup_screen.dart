import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_serivce.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _role;
  bool _loading = false;

  // Controllers for all fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose a role')));
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Sign up with Firebase Auth
      final cred = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      debugPrint('🟢 Signed up: ${cred.user?.uid}');

      // 2) Create Firestore user doc
      await UserService().createUserDoc(
        cred.user!.uid,
        _emailController.text.trim(),
        _role!,
      );

      // 3) Navigate to the root (AuthWrapper will pick up and redirect)
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 Sign-up error: ${e.code}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Sawtak',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 40),

                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white70,
                      hintText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Enter your first name'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white70,
                      hintText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Enter your last name'
                                : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
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

                  // Password
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
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      return v.length >= 6 ? null : 'Password must be 6+ chars';
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white70,
                      hintText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    value: _role,
                    hint: const Text('Choose your role'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Citizen',
                        child: Text('Citizen'),
                      ),
                      DropdownMenuItem(
                        value: 'Gov Admin',
                        child: Text('Gov Admin'),
                      ),
                      DropdownMenuItem(
                        value: 'Advertiser',
                        child: Text('Advertiser'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _role = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white70,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up button
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
                            : const Text('Sign up'),
                  ),

                  const SizedBox(height: 16),
                  const Text('Or continue with'),
                  const SizedBox(height: 8),

                  // Social icons (just UI stubs)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.facebook, size: 32),
                      SizedBox(width: 16),
                      Icon(Icons.g_mobiledata, size: 32),
                    ],
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
