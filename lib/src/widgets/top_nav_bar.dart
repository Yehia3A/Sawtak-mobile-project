import 'package:flutter/material.dart';
import '../services/auth.service.dart';

class TopNavBar extends StatelessWidget {
  final VoidCallback? onNotifications;

  const TopNavBar({super.key, this.onNotifications});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout. Please try again.')),
        );
      }
    }
  }

  void _navigateToEmergencyNumbers(BuildContext context) {
    Navigator.pushNamed(context, '/emergency-numbers');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF795003), Color(0xFFDF9306)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Name
          const Text(
            'Sawtak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              letterSpacing: 1.2,
              decoration: TextDecoration.none, // Remove underline
              shadows: [
                Shadow(
                  color: Color.fromARGB(66, 239, 194, 16),
                  offset: Offset(5, 5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          // Action Buttons
          Row(
            children: [
              // Emergency Numbers Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _navigateToEmergencyNumbers(context),
                  tooltip: 'Emergency Numbers',
                ),
              ),
              const SizedBox(width: 8),
              // Notifications Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onNotifications,
                  tooltip: 'Notifications',
                ),
              ),
              const SizedBox(width: 8),
              // Logout Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
