// lib/src/screens/home_citizen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

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
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
            ),
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
                        'Welcome, Citizen',
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
                          'Submit Complaint',
                          Icons.report_problem,
                          () {
                            // TODO: Implement complaint submission
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Track Status',
                          Icons.track_changes,
                          () {
                            // TODO: Implement status tracking
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'View History',
                          Icons.history,
                          () {
                            // TODO: Implement history view
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Notifications',
                          Icons.notifications,
                          () {
                            // TODO: Implement notifications
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Profile',
                          Icons.person,
                          () {
                            // TODO: Implement profile view
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Settings',
                          Icons.settings,
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
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
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
    );
  }
}
