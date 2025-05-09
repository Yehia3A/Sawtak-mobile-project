import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _role;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/welcome.jpg', fit: BoxFit.cover),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo/logo.png', width: 80),
              const SizedBox(height: 24),
              ...[
                'First Name',
                'Last Name',
                'Email',
                'Password',
                'Confirm Password'
              ].map((label) {
                final isPassword = label.toLowerCase().contains('password');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    obscureText: isPassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: label,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // call your AuthService.register(...)
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 16),
              const Text('Or continue with'),
              const SizedBox(height: 8),
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
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Already have an account? Log in'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
