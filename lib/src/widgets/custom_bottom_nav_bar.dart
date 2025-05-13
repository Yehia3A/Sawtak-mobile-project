import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Curved, gradient background
        Positioned.fill(
          child: CustomPaint(painter: _NavBarBackgroundPainter()),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarButton(
                assetPath: 'assets/homeButton.svg',
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavBarButton(
                assetPath: 'assets/EyeButton.svg',
                label: 'Announcements',
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
                label: 'Profile',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ],
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
    final labelColor = selected ? const Color(0xFFFFC107) : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          selected
              ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFC107),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(assetPath, width: 28, height: 28),
              )
              : SvgPicture.asset(assetPath, width: 28, height: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
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
          ..shader = LinearGradient(
            colors: [const Color(0xFF2D1400), const Color(0xFFFFC107)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.05, 0, size.width * 0.18, 0);
    path.lineTo(size.width * 0.82, 0);
    path.quadraticBezierTo(size.width * 0.95, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
