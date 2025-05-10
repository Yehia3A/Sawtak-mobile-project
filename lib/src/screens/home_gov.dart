// lib/src/screens/home_government.dart

import 'package:flutter/material.dart';

class HomeGovernment extends StatelessWidget {
  const HomeGovernment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buildButton(IconData icon, String label) {
      return ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sawtak – Government'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildButton(Icons.announcement, 'Post Announcements'),
            const SizedBox(height: 12),
            buildButton(Icons.poll, 'Create Polls'),
            const SizedBox(height: 12),
            buildButton(Icons.message, 'View Citizen Messages'),
            const SizedBox(height: 12),
            buildButton(Icons.phone, 'Manage Phone Numbers & Ads'),
          ],
        ),
      ),
    );
  }
}
