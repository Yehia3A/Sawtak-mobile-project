// lib/src/screens/home_citizen.dart

import 'package:flutter/material.dart';

class HomeCitizen extends StatelessWidget {
  const HomeCitizen({Key? key}) : super(key: key);

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
        title: const Text('Sawtak – Citizen'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildButton(Icons.announcement, 'Check Announcements'),
            const SizedBox(height: 12),
            buildButton(Icons.how_to_vote, 'Vote in Polls'),
            const SizedBox(height: 12),
            buildButton(Icons.chat, 'Send Message to Government'),
            const SizedBox(height: 12),
            buildButton(Icons.report_problem, 'Report a Problem'),
            const SizedBox(height: 12),
            buildButton(Icons.local_hospital, 'Emergency Numbers'),
          ],
        ),
      ),
    );
  }
}
