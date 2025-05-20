import 'package:flutter/material.dart';
import '../widgets/profile_base.dart';

class ProfileAdvertiser extends StatelessWidget {
  const ProfileAdvertiser({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileBase(
      userType: UserType.advertiser,
      title: 'Advertiser Profile',
      profileIcon: Icons.business_center,
    );
  }
}