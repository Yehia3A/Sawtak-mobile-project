import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_citizen_app/src/advertiser/profile_advertiser.dart';
import 'package:gov_citizen_app/src/citizen/profile_citizen.dart';
import 'package:gov_citizen_app/src/citizen/report_screen.dart'
    show ReportScreen;
import 'package:gov_citizen_app/src/gov/home_gov.dart';
import 'package:gov_citizen_app/src/gov/profile_gov_admin.dart';
import 'package:gov_citizen_app/src/gov/show_reports.dart'
    show ShowReportsScreen;
import 'package:gov_citizen_app/src/screens/posts_screen.dart';
import 'package:gov_citizen_app/src/widgets/top_nav_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/floating_top_bar.dart';
import '../services/user.serivce.dart';
import '../advertiser/home_advertiser.dart';
import '../screens/check_ads_screen.dart';
import '../screens/chat_page.dart';
import '../citizen/home_citizen.dart';
import '../services/auth.service.dart';
import '../services/emergency_numbers.service.dart';

class MainLayout extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> navItems;
  final bool isLoggedIn;
  final String role;

  const MainLayout({
    super.key,
    required this.pages,
    required this.navItems,
    required this.isLoggedIn,
    required this.role,
  });

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EmergencyNumbersService _emergencyService = EmergencyNumbersService();

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    if (widget.role == 'Gov Admin') {
      _pages = [
        const HomeGovernment(),
        ShowReportsScreen(),
        ChatPage(),
        GovAdminProfile(),
        PostsScreen(
          currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? '',
          userRole: widget.role,
        ),
      ];
    } else if (widget.role == 'Advertiser') {
      _pages = [
        const HomeAdvertiser(),
        CheckAdsScreen(userRole: widget.role),
        ChatPage(),
        ProfileAdvertiser(),
      ];
    } else {
      _pages = [
        const HomeCitizen(),
        ReportScreen(),
        ChatPage(),
        CitizenProfile(),
        PostsScreen(
          currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          currentUserName: FirebaseAuth.instance.currentUser?.displayName ?? '',
          userRole: widget.role,
        ),
      ];
    }
  }

  void _onTabTapped(int index) async {
    if (index < 0) {
      debugPrint('Invalid index tapped: $index');
      return;
    }

    // Handle special cases for citizen role
    if (widget.role == 'Citizen' && index > 4) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final firstName = await UserService().fetchUserFirstName(user.uid);

      if (!mounted) return;

      switch (index) {
        case 5: // Announcements
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PostsScreen(
                    currentUserId: user.uid,
                    currentUserName: firstName,
                    userRole: 'Citizen',
                    initialFilter: 'Announcements',
                  ),
            ),
          );
          return;
        case 6: // Recent Posts
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PostsScreen(
                    currentUserId: user.uid,
                    currentUserName: firstName,
                    userRole: 'Citizen',
                  ),
            ),
          );
          return;
        case 7: // Show Ads
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CheckAdsScreen(
                    userRole: 'Citizen',
                    showAcceptedOnly: true,
                  ),
            ),
          );
          return;
      }
    }

    // Handle regular page navigation
    if (index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showEmergencyNumbers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Emergency Numbers',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: StreamBuilder<List<EmergencyNumber>>(
            stream: _emergencyService.getEmergencyNumbers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final numbers = snapshot.data!;

              if (numbers.isEmpty) {
                return const Center(
                  child: Text(
                    'No emergency numbers available',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      numbers.map((number) {
                        return Column(
                          children: [
                            _buildEmergencyNumber(
                              number.name,
                              number.number,
                              number.icon,
                              number.color,
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sawtak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.role,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          if (widget.role == 'Gov Admin') ...[
            _buildDrawerItem(Icons.home, 'Home', 0),
            _buildDrawerItem(Icons.visibility, 'Check Reports', 1),
            _buildDrawerItem(Icons.chat, 'Citizens Messages', 2),
            _buildDrawerItem(Icons.person, 'User Management', 3),
            _buildDrawerItem(Icons.announcement, 'Posts', 4),
          ] else if (widget.role == 'Advertiser') ...[
            _buildDrawerItem(Icons.home, 'Home', 0),
            _buildDrawerItem(Icons.visibility, 'Check your Ads', 1),
            _buildDrawerItem(Icons.chat, 'Messages', 2),
            _buildDrawerItem(Icons.person, 'Profile', 3),
          ] else ...[
            _buildDrawerItem(Icons.home, 'Home', 0),
            _buildDrawerItem(Icons.report, 'Report a Problem', 1),
            _buildDrawerItem(Icons.chat, 'Message Government', 2),
            _buildDrawerItem(Icons.person, 'Profile', 3),
            const Divider(color: Colors.white24),
            _buildDrawerItem(Icons.verified, 'Show Ads', 7),
          ],
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      selected: _currentIndex == index,
      selectedColor: Colors.amber,
      onTap: () {
        _onTabTapped(index);
        _scaffoldKey.currentState?.closeDrawer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/homepage.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.7)),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const Text(
                        'Sawtak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.emergency, color: Colors.red),
                        onPressed: _showEmergencyNumbers,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Notifications functionality
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await AuthService().signOut();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/welcome');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumber(
    String service,
    String number,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // You can add functionality to call the number here
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.phone, color: color),
          ],
        ),
      ),
    );
  }
}
