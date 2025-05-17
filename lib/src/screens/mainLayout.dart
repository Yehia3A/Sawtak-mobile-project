import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/floating_top_bar.dart';
import '../services/user.serivce.dart';

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
            // Main content
            Positioned.fill(child: widget.pages[_currentIndex]),

            // Floating top bar with username
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

            // Bottom navigation bar
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
          ],
        ),
      ),
    );
  }
}
