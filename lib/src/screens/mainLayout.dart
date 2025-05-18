import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_citizen_app/src/advertiser/profile_advertiser.dart';
import 'package:gov_citizen_app/src/citizen/profile_citizen.dart';
import 'package:gov_citizen_app/src/gov/home_gov.dart';
import 'package:gov_citizen_app/src/gov/profile_gov_admin.dart';
import 'package:gov_citizen_app/src/widgets/top_nav_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/floating_top_bar.dart';
import '../services/user.serivce.dart';
import '../advertiser/home_advertiser.dart';
import '../screens/check_ads_screen.dart';
import '../screens/chat_page.dart';
import '../citizen/home_citizen.dart';

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
  if (widget.role == 'Gov Admin') {
    _pages = [
      const HomeGovernment(),
      const Placeholder(), // Other page (e.g., Check Reports)
      ChatPage(),
      GovAdminProfile(),
    ];
  } else if (widget.role == 'Advertiser') {
    _pages = [
      const HomeAdvertiser(),
      CheckAdsScreen(),
      ChatPage(),
      ProfileAdvertiser(),
    ];
  } else {
    _pages = [
      const HomeCitizen(),
      const Placeholder(),
      ChatPage(),
      CitizenProfile(),
    ];
  }
}

  void _onTabTapped(int index) {
  if (index < 0 || index >= _pages.length) {
    debugPrint('Invalid index tapped: $index');
    return;
  }
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
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: FutureBuilder<String>(
            //     future:
            //         user != null
            //             ? UserService().fetchUserFirstName(user.uid)
            //             : Future.value(''),
            //     builder: (context, snapshot) {
            //       final name =
            //           (snapshot.connectionState == ConnectionState.done &&
            //                   snapshot.hasData)
            //               ? snapshot.data!
            //               : '';
            //       return FloatingTopBar();
            //     },
            //   ),
            // ),
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
            // top bar
            Positioned(top: 0, left: 0, right: 0, child: TopNavBar()),
          ],
        ),
      ),
    );
  }
}
