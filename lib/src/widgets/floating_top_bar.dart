import 'package:flutter/material.dart';
import '../services/auth.service.dart';

class FloatingTopBar extends StatefulWidget {
  final VoidCallback? onNotifications;

  const FloatingTopBar({super.key, this.onNotifications});

  @override
  State<FloatingTopBar> createState() => _FloatingTopBarState();
}

class _FloatingTopBarState extends State<FloatingTopBar> {
  Offset position = const Offset(0, 0);

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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.dy == 0 ? 16 : position.dy,
      left:
          position.dx == 0
              ? MediaQuery.of(context).size.width / 2 - 120
              : position.dx,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: widget.onNotifications,
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
