// lib/src/screens/home_government.dart

import 'package:flutter/material.dart';
import '../services/auth.service.dart';

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
                          'Manage Cases',
                          Icons.cases,
                          () {
                            // TODO: Implement case management
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'User Management',
                          Icons.people,
                          () {
                            // TODO: Implement user management
                          },
                        ),
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
                          'Announcements',
                          Icons.campaign,
                          () {
                            // TODO: Implement announcements
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Reports',
                          Icons.summarize,
                          () {
                            // TODO: Implement reports
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
