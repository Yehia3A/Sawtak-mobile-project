// lib/src/app.dart

import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/screens/chat_page.dart';

import 'src/screens/auth_wrapper.dart';
import 'src/screens/welcome_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/signup_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sawtak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        platform: TargetPlatform.android,
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const AuthWrapper(),
              settings: settings,
            );
          case '/welcome':
            return MaterialPageRoute(
              builder: (_) => const WelcomePage(),
              settings: settings,
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: settings,
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => const SignUpScreen(),
              settings: settings,
            );
          case '/chat':
            return MaterialPageRoute(
              builder: (_) => const ChatPage(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const AuthWrapper(),
              settings: settings,
            );
        }
      },
    );
  }
}
