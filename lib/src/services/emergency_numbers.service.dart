import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmergencyNumber {
  final String id;
  final String name;
  final String number;
  final String description;
  final IconData icon;
  final Color color;

  EmergencyNumber({
    required this.id,
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'description': description,
    };
  }

  factory EmergencyNumber.fromMap(Map<String, dynamic> map) {
    return EmergencyNumber(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconFromName(map['name'] ?? ''),
      color: _getColorFromName(map['name'] ?? ''),
    );
  }

  static IconData _getIconFromName(String name) {
    switch (name.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.medical_services;
      case 'fire department':
        return Icons.fire_truck;
      case 'tourist police':
        return Icons.tour;
      case 'electricity emergency':
        return Icons.electric_bolt;
      case 'gas emergency':
        return Icons.gas_meter;
      default:
        return Icons.emergency;
    }
  }

  static Color _getColorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.red;
      case 'fire department':
        return Colors.orange;
      case 'tourist police':
        return Colors.green;
      case 'electricity emergency':
        return Colors.yellow;
      case 'gas emergency':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

class EmergencyNumbersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'emergencyNumbers';

  // Get all emergency numbers (readable by all users)
  Stream<List<EmergencyNumber>> getEmergencyNumbers() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => EmergencyNumber.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Add new emergency number (only for gov admin)
  Future<void> addEmergencyNumber(EmergencyNumber number) async {
    // Check if user is gov admin
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'] as String?;

    if (role != 'Gov Admin') {
      throw Exception(
        'Only government administrators can add emergency numbers',
      );
    }

    await _firestore.collection(_collection).doc(number.id).set(number.toMap());
  }

  // Delete emergency number (only for gov admin)
  Future<void> deleteEmergencyNumber(String id) async {
    // Check if user is gov admin
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'] as String?;

    if (role != 'Gov Admin') {
      throw Exception(
        'Only government administrators can delete emergency numbers',
      );
    }

    await _firestore.collection(_collection).doc(id).delete();
  }

  // Update emergency number (only for gov admin)
  Future<void> updateEmergencyNumber(EmergencyNumber number) async {
    // Check if user is gov admin
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role'] as String?;

    if (role != 'Gov Admin') {
      throw Exception(
        'Only government administrators can update emergency numbers',
      );
    }

    await _firestore
        .collection(_collection)
        .doc(number.id)
        .update(number.toMap());
  }
}
