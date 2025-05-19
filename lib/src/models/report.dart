import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String emergencyType;
  final String location;
  final String details;
  final List<String> attachments;
  final String? audioPath;
  final String userId;
  final String userName;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.emergencyType,
    required this.location,
    required this.details,
    required this.attachments,
    this.audioPath,
    required this.userId,
    required this.userName,
    required this.status,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emergencyType': emergencyType,
      'location': location,
      'details': details,
      'attachments': attachments,
      'audioPath': audioPath,
      'userId': userId,
      'userName': userName,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      print('Invalid date type: $value (${value.runtimeType})');
      return DateTime.now();
    }

    return Report(
      id: data['id'] ?? '',
      emergencyType: data['emergencyType'] ?? '',
      location: data['location'] ?? '',
      details: data['details'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      audioPath: data['audioPath'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      status: data['status'] ?? 'Pending',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      createdAt: parseDate(data['createdAt']),
    );
  }
}
