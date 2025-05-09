import 'package:flutter/material.dart';
import 'src/screens/welcome_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/signup_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sawtak',
      theme: ThemeData.dark(),
      initialRoute: WelcomePage.routeName,
      routes: {
        WelcomePage.routeName: (_) => const WelcomePage(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
      },
    );
  }
}
