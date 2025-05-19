import 'package:flutter/material.dart';
import '../services/auth.service.dart';
import '../services/posts.service.dart';
import '../services/user.serivce.dart';
import '../services/advertisement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/posts_screen.dart';

class TopNavBar extends StatelessWidget {
  final VoidCallback? onNotifications;

  const TopNavBar({super.key, this.onNotifications});

  Future<List<Map<String, dynamic>>> _getUnseenNotifications(String uid) async {
    final userService = UserService();
    final seen = await userService.getSeenNotifications(uid);
    final posts = await PostsService().getPosts(userRole: 'citizen').first;
    final ads = await AdvertisementService().getPendingRequests().first;
    final List<Map<String, dynamic>> notifications = [];
    // Announcements
    for (final post in posts) {
      if (post.type.toString().contains('announcement') &&
          !seen.contains(post.id)) {
        notifications.add({
          'type': 'announcement',
          'id': post.id,
          'title': post.title,
        });
      }
      if (post.type.toString().contains('poll') && !seen.contains(post.id)) {
        notifications.add({'type': 'poll', 'id': post.id, 'title': post.title});
      }
    }
    // Ads (accepted only)
    for (final ad in ads) {
      if (ad.status == 'accepted' && !seen.contains(ad.id)) {
        notifications.add({'type': 'ad', 'id': ad.id, 'title': ad.title});
      }
    }
    return notifications;
  }

  void _handleNotificationTap(
    BuildContext context,
    String type,
    String id,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await UserService().addSeenNotification(uid, id);
    }
    if (type == 'announcement') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PostsScreen(
                currentUserId: uid ?? '',
                currentUserName: '', // Optionally fetch name
                userRole: 'citizen',
                initialFilter: 'Announcements',
              ),
        ),
      );
    } else if (type == 'poll') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PostsScreen(
                currentUserId: uid ?? '',
                currentUserName: '', // Optionally fetch name
                userRole: 'citizen',
                initialFilter: 'Polls',
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
                  onPressed:
                      () => Navigator.pushNamed(context, '/emergency-numbers'),
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
                child:
                    uid == null
                        ? const SizedBox.shrink()
                        : FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getUnseenNotifications(uid),
                          builder: (context, snapshot) {
                            final notifications = snapshot.data ?? [];
                            return PopupMenuButton<int>(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: 'Notifications',
                              color: Colors.white,
                              itemBuilder: (context) {
                                final items = <PopupMenuEntry<int>>[];
                                for (final n in notifications) {
                                  if (n['type'] == 'announcement') {
                                    items.add(
                                      PopupMenuItem<int>(
                                        value: 1,
                                        child: ListTile(
                                          title: const Text(
                                            'New announcement, check it out!',
                                          ),
                                          onTap:
                                              () => _handleNotificationTap(
                                                context,
                                                'announcement',
                                                n['id'],
                                              ),
                                        ),
                                      ),
                                    );
                                  } else if (n['type'] == 'poll') {
                                    items.add(
                                      PopupMenuItem<int>(
                                        value: 2,
                                        child: ListTile(
                                          title: const Text(
                                            'Take part in a new poll',
                                          ),
                                          onTap:
                                              () => _handleNotificationTap(
                                                context,
                                                'poll',
                                                n['id'],
                                              ),
                                        ),
                                      ),
                                    );
                                  } else if (n['type'] == 'ad') {
                                    items.add(
                                      PopupMenuItem<int>(
                                        value: 3,
                                        child: ListTile(
                                          title: const Text(
                                            'Check out this new ad',
                                          ),
                                          onTap:
                                              () => _handleNotificationTap(
                                                context,
                                                'ad',
                                                n['id'],
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                                if (items.isEmpty) {
                                  items.add(
                                    const PopupMenuItem<int>(
                                      value: 0,
                                      child: Text('No new notifications'),
                                    ),
                                  );
                                }
                                return items;
                              },
                            );
                          },
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
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/welcome');
                    }
                  },
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
