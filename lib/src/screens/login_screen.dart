import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/welcome.jpg', fit: BoxFit.cover),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(children: [
                Image.asset('assets/logo/logo.png', width: 80),
                const SizedBox(height: 24),
                ...['Email', 'Password'].map((label) {
                  final isPassword = label == 'Password';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      obscureText: isPassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white70,
                        hintText: label,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );
                }),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // call your AuthService.signIn(...)
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Log in'),
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
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
