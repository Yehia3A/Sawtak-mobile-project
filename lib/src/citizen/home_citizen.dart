import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'posts_screen.dart';
import '../services/user.serivce.dart';

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
          // Floating top-left button
          Positioned(
            top: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, color: Colors.yellowAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content with SafeArea
          SafeArea(
            child: Column(
              children: [
                // Search-style prompt box
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Check new places in the hayy',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
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
