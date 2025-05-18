import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_citizen_app/src/screens/posts_screen.dart';
import 'package:gov_citizen_app/src/services/user.serivce.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

  // Dummy announcements data
  final List<Map<String, String>> _announcements = const [];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/homepage.jpg', fit: BoxFit.cover),
          ),
          // Main content with SafeArea
          SafeArea(
            child: Column(
              children: [
                // Posts Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Show all posts
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                // Posts List
                Expanded(
                  child: FutureBuilder<String>(
                    future:
                        user != null
                            ? UserService().fetchUserFirstName(user.uid)
                            : Future.value('Anonymous'),
                    builder: (context, snapshot) {
                      final firstName =
                          (snapshot.connectionState == ConnectionState.done &&
                                  snapshot.hasData)
                              ? snapshot.data!
                              : 'Anonymous';
                      return PostsScreen(
                        currentUserId: user?.uid ?? '',
                        currentUserName: firstName,
                        userRole: 'citizen',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        child: Icon(Icons.chat),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
