import 'package:flutter/material.dart';

class HomeAdvertiser extends StatelessWidget {
  const HomeAdvertiser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // 1) Background
      body: Stack(
        children: [
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(color: Colors.black.withOpacity(0.4)),

          SafeArea(
            child: Column(
              children: [
                // 2) Gold header
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFB8860B),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.notifications, color: Colors.white),
                      Spacer(),
                      Text(
                        'Sawtak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Welcome, Yehia',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // 3) Prompt box
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Create Advertisements posts for your Shop to people 1 step close to you!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // 4) Section title
                const Text(
                  'Create Advertisement Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 5) Upload area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {},
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image, color: Colors.white70, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Upload Photo/Video',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 6) Title field
                _buildInputField('Title *', false),

                const SizedBox(height: 16),
                // 7) Description field
                _buildInputField('Description *', true, maxLines: 4),
                const SizedBox(height: 16),

                // 8) Location field with Change button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Location (optional)',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white70,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 9) Post button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),

      // 10) Bottom nav
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFB8860B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _NavItem(icon: Icons.home, label: 'Home', selected: false),
            _NavItem(icon: Icons.campaign, label: 'Your Ads', selected: true),
            _NavItem(
              icon: Icons.bar_chart,
              label: 'Analytics',
              selected: false,
            ),
            _NavItem(icon: Icons.person, label: 'Profile', selected: false),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, bool isMulti, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        maxLines: isMulti ? maxLines : 1,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white70,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMulti ? 12 : 30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
