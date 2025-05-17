import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/floating_top_bar.dart';
import '../services/user.serivce.dart';
import '../advertiser/home_advertiser.dart';
import '../screens/check_ads_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    if (widget.role == 'Advertiser') {
      _pages = [
        const HomeAdvertiser(),
        CheckAdsScreen(),
        const Placeholder(), // Views Analytics
        const Placeholder(), // Profile
      ];
    } else {
      _pages = widget.pages;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      color: Colors.black, // Replace with your app background
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _pages[_currentIndex]),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FutureBuilder<String>(
                future:
                    user != null
                        ? UserService().fetchUserFirstName(user.uid)
                        : Future.value(''),
                builder: (context, snapshot) {
                  final name =
                      (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData)
                          ? snapshot.data!
                          : '';
                  return FloatingTopBar(userName: name);
                },
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                role: widget.role,
              ),
            ),

            // ✅ Always show the chat button
            Positioned(
              right: 16,
              bottom: 110,
              child: FloatingActionButton(
                heroTag: 'main-chat-fab',
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                backgroundColor: Colors.amber,
                child: const Icon(Icons.chat),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
