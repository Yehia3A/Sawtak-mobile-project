import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String role; // 'Citizen', 'Gov Admin', 'Advertiser'

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  List<_NavBarButton> _buildButtons() {
    switch (role) {
      case 'Gov Admin':
        return [
          _NavBarButton(
            assetPath: 'assets/homeButton.svg',
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarButton(
            assetPath: 'assets/EyeButton.svg',
            label: 'Check Reports',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavBarButton(
            assetPath: 'assets/massageButton.svg',
            label: 'Citizens Messages',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavBarButton(
            assetPath: 'assets/profileButton.svg',
            label: 'User Management',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ];
      case 'Advertiser':
        return [
          _NavBarButton(
            assetPath: 'assets/homeButton.svg',
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarButton(
            assetPath: 'assets/EyeButton.svg',
            label: 'Check your Ads',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavBarButton(
            assetPath: 'assets/massageButton.svg',
            label: 'Views Analytic',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavBarButton(
            assetPath: 'assets/profileButton.svg',
            label: 'Profile',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ];
      case 'Citizen':
      default:
        return [
          _NavBarButton(
            assetPath: 'assets/homeButton.svg',
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarButton(
            assetPath: 'assets/EyeButton.svg',
            label: 'Report a Problem',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavBarButton(
            assetPath: 'assets/massageButton.svg',
            label: 'Massage the Government',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavBarButton(
            assetPath: 'assets/profileButton.svg',
            label: 'Profile',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _NavBarBackgroundPainter()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _buildButtons()
                      .map((button) => Expanded(child: button))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        selected
            ? const Color(0xFFFFB300) // Vibrant gold
            : const Color(0xCCFFFFFF); // Soft white with transparency
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          selected
              ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(assetPath, width: 26, height: 26),
              )
              : SvgPicture.asset(assetPath, width: 24, height: 24),
          const SizedBox(height: 6),
          selected
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.brown[900],
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 1.2,
                    fontFamily: 'Montserrat', // Use a rounded font if available
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              : Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 1.1,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        ],
      ),
    );
  }
}

class _NavBarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF795003), Color(0xFFDF9306)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, 30);
    path.quadraticBezierTo(size.width * 0.05, 0, size.width * 0.18, 0);
    path.lineTo(size.width * 0.82, 0);
    path.quadraticBezierTo(size.width * 0.95, 0, size.width, 30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
