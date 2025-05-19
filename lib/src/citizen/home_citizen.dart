import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_citizen_app/src/screens/posts_screen.dart';
import 'package:gov_citizen_app/src/services/user.serivce.dart';

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
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Feature Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildFeatureCard(
                        context,
                        'Announcements',
                        Icons.campaign,
                        () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final firstName =
                              user != null
                                  ? await UserService().fetchUserFirstName(
                                    user.uid,
                                  )
                                  : 'Anonymous';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PostsScreen(
                                    currentUserId: user?.uid ?? '',
                                    currentUserName: firstName,
                                    userRole: 'citizen',
                                    initialFilter: 'Announcements',
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureCard(
                        context,
                        'Recent Posts',
                        Icons.list_alt,
                        () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final firstName =
                              user != null
                                  ? await UserService().fetchUserFirstName(
                                    user.uid,
                                  )
                                  : 'Anonymous';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PostsScreen(
                                    currentUserId: user?.uid ?? '',
                                    currentUserName: firstName,
                                    userRole: 'citizen',
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        child: const Icon(Icons.chat),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        color: Colors.white.withOpacity(0.9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
