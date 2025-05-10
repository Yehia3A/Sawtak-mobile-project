// lib/src/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_serivce.dart';
import 'welcome_page.dart';
import 'home_citizen.dart';
import 'home_gov.dart';
import 'home_advertiser.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        // Still waiting on authentication state
        if (authSnapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        // Not signed in
        if (user == null) {
          return const WelcomePage();
        }

        // Signed in → fetch role from Firestore
        return FutureBuilder<String>(
          future: UserService().fetchUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnapshot.data;
            switch (role) {
              case 'Citizen':
                return const HomeCitizen();
              case 'Gov Admin':
                return const HomeGovernment();
              case 'Advertiser':
                return const HomeAdvertiser();
              default:
                return const Scaffold(
                  body: Center(child: Text('Unknown role')),
                );
            }
          },
        );
      },
    );
  }
}
