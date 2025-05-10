// lib/src/screens/home_advertiser.dart

import 'package:flutter/material.dart';

class HomeAdvertiser extends StatelessWidget {
  const HomeAdvertiser({super.key});

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
        title: const Text('Sawtak – Advertiser'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [buildButton(Icons.campaign, 'Post Advertisement')],
        ),
      ),
    );
  }
}
