import 'package:flutter/material.dart';
import '../widgets/profile_base.dart';

class CitizenProfile extends StatelessWidget {
  const CitizenProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileBase(
      userType: UserType.citizen,
      title: 'Profile',
      profileIcon: Icons.account_circle,
    );
  }
}