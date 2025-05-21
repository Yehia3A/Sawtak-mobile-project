import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.service.dart';
import '../services/posts.service.dart';
import '../services/user.serivce.dart';
import '../services/advertisement_service.dart';
import '../screens/posts_screen.dart';

class TopNavBar extends StatelessWidget {
  final VoidCallback? onNotifications;

  const TopNavBar({super.key, this.onNotifications});

  Future<List<Map<String, dynamic>>> _getUnseenNotifications(String uid) async {
    final seen = await UserService().getSeenNotifications(uid);
    final posts = await PostsService().getPosts(userRole: 'citizen').first;
    final ads = await AdvertisementService().getPendingRequests().first;

    final List<Map<String, dynamic>> notifications = [];

    for (final post in posts) {
      if (!seen.contains(post.id)) {
        if (post.type.toString().contains('announcement')) {
          notifications.add({'type': 'announcement', 'id': post.id, 'title': post.title});
        } else if (post.type.toString().contains('poll')) {
          notifications.add({'type': 'poll', 'id': post.id, 'title': post.title});
        }
      }
    }

    for (final ad in ads) {
      if (ad.status == 'accepted' && !seen.contains(ad.id)) {
        notifications.add({'type': 'ad', 'id': ad.id, 'title': ad.title});
      }
    }

    return notifications;
  }

  void _handleNotificationTap(BuildContext context, String type, String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserService().addSeenNotification(uid, id);
    }

    if (type == 'announcement' || type == 'poll') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostsScreen(
            currentUserId: uid ?? '',
            currentUserName: '',
            userRole: 'citizen',
            initialFilter: type == 'announcement' ? 'Announcements' : 'Polls',
          ),
        ),
      );
    } else if (type == 'ad') {
      Navigator.pushNamed(context, '/check_ads');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
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
          const Text(
            'Sawtak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              letterSpacing: 1.2,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(
                  color: Color.fromARGB(66, 239, 194, 16),
                  offset: Offset(5, 5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Row(
            children: [
              _IconMenu(
                icon: Icons.emergency,
                tooltip: 'Emergency Numbers',
                color: Colors.red.withOpacity(0.2),
                items: [
                  {'title': '911', 'subtitle': 'Worldwide Emergency'},
                  {'title': '122', 'subtitle': 'Emergency'},
                  {'title': '123', 'subtitle': 'Ambulance'},
                  {'title': '125', 'subtitle': 'Fire Brigade'},
                ],
              ),
              const SizedBox(width: 8),
              if (uid != null)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getUnseenNotifications(uid),
                  builder: (context, snapshot) {
                    final notifications = snapshot.data ?? [];
                    return _NotificationMenu(
                      notifications: notifications,
                      onTap: (type, id) => _handleNotificationTap(context, type, id),
                    );
                  },
                ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.logout,
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/welcome');
                  }
                },
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconMenu extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final List<Map<String, String>> items;
  final Color color;

  const _IconMenu({
    required this.icon,
    required this.tooltip,
    required this.items,
    this.color = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: PopupMenuButton<int>(
        icon: Icon(icon, color: Colors.white, size: 28),
        tooltip: tooltip,
        color: Colors.white,
        itemBuilder: (context) => items
            .asMap()
            .entries
            .map(
              (entry) => PopupMenuItem<int>(
                value: entry.key,
                child: ListTile(
                  title: Text(entry.value['title']!),
                  subtitle: Text(entry.value['subtitle']!),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NotificationMenu extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final void Function(String type, String id) onTap;

  const _NotificationMenu({
    required this.notifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: PopupMenuButton<int>(
        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
        tooltip: 'Notifications',
        color: Colors.white,
        itemBuilder: (context) {
          if (notifications.isEmpty) {
            return [const PopupMenuItem<int>(value: 0, child: Text('No new notifications'))];
          }
          return notifications.asMap().entries.map((entry) {
            final n = entry.value;
            final label = {
              'announcement': 'New announcement, check it out!',
              'poll': 'Take part in a new poll',
              'ad': 'Check out this new ad',
            }[n['type']]!;
            return PopupMenuItem<int>(
              value: entry.key,
              child: ListTile(
                title: Text(label),
                onTap: () => onTap(n['type'], n['id']),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}
