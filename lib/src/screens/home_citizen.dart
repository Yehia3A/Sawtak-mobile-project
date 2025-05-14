import 'package:flutter/material.dart';
import '../services/user.serivce.dart';
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
          '🍲 Free Meals Available for Those in Need\nIf you or someone you know needs a warm meal, our community kitchen at "GR3G+6FF, Bharati-katunj -2, Erandwane, Pune, Maharashtra 411004" is serving free lunch from 12 PM – 3 PM today. No registration needed—just come by! ❤️',
    },
    {
      'author': 'Rajesh Deshmukh',
      'date': '19-01-25',
      'image': 'assets/free_meals_banner2.jpg',
      'text':
          '🍲 Free Meals Available for Those in Need\nIf you or someone you know needs a warm meal, our community kitchen at "GR3G+6FF, Bharati-katunj -2, Erandwane, Pune, Maharashtra 411004" is serving free lunch from 12 PM – 3 PM today. No registration needed—just come by! ❤️',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/homepage.jpg', fit: BoxFit.cover),
          ),
          // Floating top-left button
          Positioned(
            top: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, color: Colors.yellowAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main content with SafeArea
          SafeArea(
            child: Column(
              children: [
                // Modern top bar with gradient and rounded corners

                // Search-style prompt box
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Check new places in the hayy',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Announcements list (scrollable)
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  // Use placeholder if the image does not exist
                                  ann['image'] ==
                                              'assets/free_meals_banner1.jpg' ||
                                          ann['image'] ==
                                              'assets/free_meals_banner2.jpg'
                                      ? 'assets/homepage.jpg'
                                      : ann['image']!,
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

          // Floating navbar
        ],
      ),
    );
  }
}
