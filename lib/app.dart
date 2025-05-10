// lib/src/app.dart

import 'package:flutter/material.dart';

import 'src/screens/auth_wrapper.dart';
import 'src/screens/welcome_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/signup_screen.dart';
import 'src/screens/test_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sawtak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => const AuthWrapper(),
        WelcomePage.routeName: (_) => const WelcomePage(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        TestScreen.routeName: (_) => const TestScreen(),
      },
    );
  }
}
