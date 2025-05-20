import 'package:flutter/material.dart';
import '../services/auth.service.dart';

class FloatingTopBar extends StatelessWidget {
  final VoidCallback? onNotifications;

  const FloatingTopBar({super.key, this.onNotifications});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to logout. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB06AB3), Color(0xFFFEDC3D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sawtak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.1,
              ),
            ),
            Row(
              children: [
                _FloatingBarIconButton(
                  icon: Icons.notifications_none,
                  onTap: onNotifications,
                ),
                const SizedBox(width: 8),
                _FloatingBarIconButton(
                  icon: Icons.logout,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _FloatingBarIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
