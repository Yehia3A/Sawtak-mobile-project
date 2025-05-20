import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_citizen_app/src/screens/posts_screen.dart';
import 'package:gov_citizen_app/src/services/user.serivce.dart';
import 'package:flutter/rendering.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Dark overlay for better text visibility
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Citizen Home',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content - Posts Screen with frosted glass effect
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.10),
                        child: FutureBuilder<String>(
                          future:
                              user != null
                                  ? UserService().fetchUserFirstName(user.uid)
                                  : Future.value('Anonymous'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return PostsScreen(
                              currentUserId: user?.uid ?? '',
                              currentUserName: snapshot.data ?? 'Anonymous',
                              userRole: 'citizen',
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
