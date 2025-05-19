import 'package:flutter/material.dart';
import 'package:gov_citizen_app/src/screens/posts_screen.dart';
import '../screens/check_ads_screen.dart';
import '../services/auth.service.dart';
import 'create_announcement_screen.dart';
import 'create_poll_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeGovernment extends StatelessWidget {
  const HomeGovernment({super.key});

  @override
  Widget build(BuildContext context) {
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
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await AuthService().signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildStatCard('Active Cases', '24', Colors.blue),
                      const SizedBox(width: 16),
                      _buildStatCard('Resolved', '156', Colors.green),
                      const SizedBox(width: 16),
                      _buildStatCard('Pending', '8', Colors.orange),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildFeatureCard(
                          context,
                          'Analytics',
                          Icons.analytics,
                          () {
                            // TODO: Implement analytics
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Create Announcement',
                          Icons.campaign,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const CreateAnnouncementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Create Poll',
                          Icons.poll,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePollScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Show All Posts',
                          Icons.list_alt,
                          () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PostsScreen(
                                      currentUserId: user.uid,
                                      currentUserName: user.displayName ?? '',
                                      userRole: 'gov_admin',
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          // Add this card here
                          context,
                          'Show All Ad Requests',
                          Icons.monetization_on, // Choose an appropriate icon
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CheckAdsScreen(
                                      userRole: 'gov_admin',
                                    ), // Use CheckAdsScreen
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Settings',
                          Icons.admin_panel_settings,
                          () {
                            // TODO: Implement settings
                          },
                        ),
                      ],
                    ),
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
