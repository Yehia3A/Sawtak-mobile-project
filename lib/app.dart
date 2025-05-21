// lib/src/app.dart

import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/citizen/report_screen.dart';
import 'package:gov_citizen_app/src/screens/chat_page.dart';
import 'package:provider/provider.dart';

import 'src/providers/announcement_provider.dart';
import 'src/providers/report_provider.dart';
import 'src/providers/post_provider.dart';
import 'src/providers/posts_provider.dart';
import 'src/services/report.service.dart';
import 'src/screens/auth_wrapper.dart';
import 'src/screens/welcome_page.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/signup_screen.dart';
import 'src/citizen/profile_citizen.dart';
import 'src/gov/profile_gov_admin.dart';
import 'src/advertiser/profile_advertiser.dart';
import 'src/account/edit_account_page.dart';
import 'src/account/change_password_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider(ReportService())),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        // Add other providers here as needed
      ],
      child: MaterialApp(
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
            case '/profile_citizen':
              return MaterialPageRoute(
                builder: (_) => CitizenProfile(),
                settings: settings,
              );
            case '/profile_gov_admin':
              return MaterialPageRoute(
                builder: (_) => GovAdminProfile(),
                settings: settings,
              );
            case '/profile_advertiser':
              return MaterialPageRoute(
                builder: (_) => ProfileAdvertiser(),
                settings: settings,
              );
            case '/edit_account':
              return MaterialPageRoute(
                builder: (_) => const EditAccountPage(),
                settings: settings,
              );
            case '/change_password':
              return MaterialPageRoute(
                builder: (_) => const ChangePasswordPage(),
                settings: settings,
              );
            case '/report':
              return MaterialPageRoute(
                builder: (context) => ReportScreen(),
                settings: settings,
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const AuthWrapper(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}
