// lib/src/screens/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.service.dart';
import '../services/user.serivce.dart';
import '../citizen/home_citizen.dart';
import '../gov/home_gov.dart';
import '../advertiser/home_advertiser.dart';
import 'mainLayout.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        // Handle connection errors
        if (authSnapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/welcome');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Still waiting on authentication state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final user = authSnapshot.data;
        // Not signed in
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/welcome');
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // Signed in → fetch role from Firestore
        return FutureBuilder<String>(
          future: UserService().fetchUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/welcome');
              });
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }

            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }

            final role = roleSnapshot.data;
            switch (role) {
              case 'Citizen':
                return MainLayout(
                  pages: [const HomeCitizen()],
                  navItems: const [],
                  isLoggedIn: true,
                  role: role ?? 'Citizen',
                );
              case 'Gov Admin':
                return MainLayout(
                  pages: [const HomeGovernment()],
                  navItems: const [],
                  isLoggedIn: true,
                  role: role ?? 'Gov Admin',
                );
              case 'Advertiser':
                return MainLayout(
                  pages: [const HomeAdvertiser()],
                  navItems: const [],
                  isLoggedIn: true,
                  role: role ?? 'Advertiser',
                );
              default:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, '/welcome');
                });
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
