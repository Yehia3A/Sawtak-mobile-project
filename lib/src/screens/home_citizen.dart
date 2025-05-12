import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_serivce.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({super.key});

  // Dummy announcements data
  final List<Map<String, String>> _announcements = const [
    {
      'author': 'Pravin Rao',
      'date': '21-01-25',
      'image': 'assets/free_meals_banner1.jpg',
      'text':
      '🍲 Free Meals Available for Those in Need\nIf you or someone you know needs a warm meal, our community kitchen at "GR3G+6FF, Bharati-katunj -2, Erandwane, Pune, Maharashtra 411004" is serving free lunch from 12 PM – 3 PM today. No registration needed—just come by! ❤️'
    },
    {
      'author': 'Rajesh Deshmukh',
      'date': '19-01-25',
      'image': 'assets/free_meals_banner2.jpg',
      'text':
      '🍲 Free Meals Available for Those in Need\nIf you or someone you know needs a warm meal, our community kitchen at "GR3G+6FF, Bharati-katunj -2, Erandwane, Pune, Maharashtra 411004" is serving free lunch from 12 PM – 3 PM today. No registration needed—just come by! ❤️'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Make scaffold background transparent so our image shines through
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        // 1) Background image
        Image.asset(
          'assets/homepage.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        // 2) Dark overlay
        Container(color: Colors.black.withOpacity(0.4)),

        SafeArea(
          child: Column(
            children: [
              // 3) Top bar (gold with rounded bottom corners)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFB8860B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // left bell icon
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {},
                    ),
                    // centered title
                    Expanded(
                      child: Center(
                        child: Text(
                          'Sawtak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Display user's first name
                    FutureBuilder<String>(
                      future: UserService().fetchUserFirstName(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            'Welcome!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return Text(
                          'Welcome, ${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 4) Search‐style prompt box
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Check new places in the hayy',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 5) Announcements list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _announcements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final ann = _announcements[i];
                    return Card(
                      color: Colors.black.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // header row: author, date, menu icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ann['author']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ann['date']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // image banner (use your real assets here)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                ann['image']!,
                                fit: BoxFit.cover,
                                height: 140,
                                width: double.infinity,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // body text
                            Text(
                              ann['text']!,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ]),

      // 6) Bottom navigation bar (gold with rounded top corners)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFB8860B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _NavItem(icon: Icons.home, label: 'Home'),
            _NavItem(icon: Icons.campaign, label: 'Announcements'),
            _NavItem(icon: Icons.mail_outline, label: 'Messages'),
            _NavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// small widget for nav items
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
