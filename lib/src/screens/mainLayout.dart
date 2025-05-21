import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../account/change_password_page.dart';

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

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late List<Widget> _pages;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  Widget _buildDrawerItem(String assetPath, String title, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            _currentIndex == index
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          color: _currentIndex == index ? Colors.amber : Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _currentIndex == index ? Colors.amber : Colors.white,
            fontWeight:
                _currentIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: _currentIndex == index,
        onTap: () {
          _onTabTapped(index);
          _scaffoldKey.currentState?.closeDrawer();
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
                ),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sawtak',
                  style: TextStyle(
                    color: Colors.white,
                      fontSize: 32,
                    fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                  widget.role,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ),
              ],
            ),
          ),
            const SizedBox(height: 20),
          if (widget.role == 'Gov Admin') ...[
              _buildDrawerItem('assets/homeButton.svg', 'Home', 0),
              _buildDrawerItem('assets/EyeButton.svg', 'Check Reports', 1),
              _buildDrawerItem(
                'assets/massageButton.svg',
                'Citizens Messages',
                2,
              ),
              _buildDrawerItem(
                'assets/profileButton.svg',
                'User Management',
                3,
              ),
              _buildDrawerItem('assets/EyeButton.svg', 'Posts', 4),
          ] else if (widget.role == 'Advertiser') ...[
              _buildDrawerItem('assets/homeButton.svg', 'Home', 0),
              _buildDrawerItem('assets/EyeButton.svg', 'Check your Ads', 1),
              _buildDrawerItem('assets/massageButton.svg', 'Messages', 2),
              _buildDrawerItem('assets/profileButton.svg', 'Profile', 3),
          ] else ...[
              _buildDrawerItem('assets/homeButton.svg', 'Home', 0),
              _buildDrawerItem('assets/EyeButton.svg', 'Report a Problem', 1),
              _buildDrawerItem(
                'assets/massageButton.svg',
                'Message Government',
                2,
              ),
              _buildDrawerItem('assets/profileButton.svg', 'Profile', 3),
              const Divider(color: Colors.white24),
              _buildDrawerItem('assets/EyeButton.svg', 'Show Ads', 7),
            ],
            const Divider(color: Colors.white24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/welcome');
              }
            },
              ),
          ),
        ],
        ),
      ),
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
          // Background image with parallax effect
          Positioned.fill(
            child: Image.asset('assets/homepage.jpg', fit: BoxFit.cover),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar with glassmorphism effect
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sawtak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.emergency,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: () {
                          _showEmergencyDialog(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          // Notifications functionality
                        },
                      ),
                    ],
                  ),
                ),
                // Main Content with fade animation
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _pages[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isGovAdmin = widget.role == 'Gov Admin';
        return Dialog(
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  minWidth: 300,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: FutureBuilder<List<EmergencyNumber>>(
                        future: fetchEmergencyNumbers(),
                        builder: (context, snapshot) {
                          final numbers = snapshot.data ?? [];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.emergency,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Emergency Numbers',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children:
                                        numbers.isEmpty
                                            ? [
                                              const Text(
                                                'No emergency numbers found.',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ]
                                            : numbers
                                                .map(
                                                  (e) => _buildEmergencyNumber(
                                                    e.service,
                                                    e.number,
                                                    _iconFromName(e.iconName),
                                                    Color(e.colorValue),
                                                  ),
                                                )
                                                .toList(),
                                  ),
                                ),
                              ),
                              if (isGovAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Emergency Number'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await showDialog<
                                        Map<String, dynamic>
                                      >(
                                        context: context,
                                        builder:
                                            (context) =>
                                                _AddEmergencyNumberDialog(),
                                      );
                                      if (result != null) {
                                        final newNumber = EmergencyNumber(
                                          id:
                                              DateTime.now()
                                                  .millisecondsSinceEpoch
                                                  .toString(),
                                          service: result['service'],
                                          number: result['number'],
                                          iconName: result['iconName'],
                                          colorValue: result['colorValue'],
                                        );
                                        await addEmergencyNumber(newNumber);
                                        Navigator.of(context).pop();
                                        _showEmergencyDialog(
                                          context,
                                        ); // Refresh dialog
                                      }
                                    },
                                  ),
                                ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmergencyNumber(
    String service,
    String number,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.phone, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'local_police':
        return Icons.local_police;
      case 'medical_services':
        return Icons.medical_services;
      case 'fire_truck':
        return Icons.fire_truck;
      case 'tour':
        return Icons.tour;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'gas_meter':
        return Icons.gas_meter;
      default:
        return Icons.phone;
    }
  }
}

class EmergencyNumber {
  final String id;
  final String service;
  final String number;
  final String iconName;
  final int colorValue;

  EmergencyNumber({
    required this.id,
    required this.service,
    required this.number,
    required this.iconName,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'service': service,
    'number': number,
    'iconName': iconName,
    'colorValue': colorValue,
  };

  factory EmergencyNumber.fromMap(Map<String, dynamic> map) => EmergencyNumber(
    id: map['id'] ?? '',
    service: map['service'] ?? '',
    number: map['number'] ?? '',
    iconName: map['iconName'] ?? '',
    colorValue: map['colorValue'] ?? 0,
  );
}

Future<List<EmergencyNumber>> fetchEmergencyNumbers() async {
  final snapshot =
      await FirebaseFirestore.instance.collection('emergency_numbers').get();
  return snapshot.docs
      .map((doc) => EmergencyNumber.fromMap(doc.data()))
      .toList();
}

Future<void> addEmergencyNumber(EmergencyNumber number) async {
  await FirebaseFirestore.instance
      .collection('emergency_numbers')
      .doc(number.id)
      .set(number.toMap());
}

class _AddEmergencyNumberDialog extends StatefulWidget {
  @override
  State<_AddEmergencyNumberDialog> createState() =>
      _AddEmergencyNumberDialogState();
}

class _AddEmergencyNumberDialogState extends State<_AddEmergencyNumberDialog> {
  final _serviceController = TextEditingController();
  final _numberController = TextEditingController();
  String _selectedIcon = 'local_police';
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _serviceController,
            decoration: const InputDecoration(labelText: 'Service Name'),
          ),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(labelText: 'Number'),
            keyboardType: TextInputType.phone,
          ),
          DropdownButton<String>(
            value: _selectedIcon,
            items: const [
              DropdownMenuItem(value: 'local_police', child: Text('Police')),
              DropdownMenuItem(
                value: 'medical_services',
                child: Text('Ambulance'),
              ),
              DropdownMenuItem(
                value: 'fire_truck',
                child: Text('Fire Department'),
              ),
              DropdownMenuItem(value: 'tour', child: Text('Tourist Police')),
              DropdownMenuItem(
                value: 'electric_bolt',
                child: Text('Electricity Emergency'),
              ),
              DropdownMenuItem(
                value: 'gas_meter',
                child: Text('Gas Emergency'),
              ),
            ],
            onChanged: (v) => setState(() => _selectedIcon = v!),
          ),
          Row(
            children: [
              const Text('Color: '),
              GestureDetector(
                onTap: () async {
                  final color = await showDialog<Color>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Pick a color'),
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: _selectedColor,
                              onColorChanged:
                                  (c) => Navigator.of(context).pop(c),
                            ),
                          ),
                        ),
                  );
                  if (color != null) setState(() => _selectedColor = color);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black26),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_serviceController.text.isNotEmpty &&
                _numberController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'service': _serviceController.text,
                'number': _numberController.text,
                'iconName': _selectedIcon,
                'colorValue': _selectedColor.value,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
