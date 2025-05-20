import 'package:flutter/material.dart';
import '../widgets/profile_base.dart';

class GovAdminProfile extends StatelessWidget {
  const GovAdminProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileBase(
      userType: UserType.govAdmin,
      title: 'Government Admin Profile',
      profileIcon: Icons.admin_panel_settings,
    );
  }
}