import 'package:cloud_firestore/cloud_firestore.dart';

class Advertisement {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String advertiserName;
  final String imageUrl;
  final String city;
  final String area;
  final String location; // Changed from GeoPoint to String for Google Maps URL
  final String link;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.advertiserName,
    required this.imageUrl,
    required this.city,
    required this.area,
    required this.location,
    required this.link,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
      'advertiserName': advertiserName,
      'imageUrl': imageUrl,
      'city': city,
      'area': area,
      'location': location,
      'link': link,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Advertisement.fromMap(Map<String, dynamic> map) {
    return Advertisement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      userId: map['userId'] as String,
      advertiserName: map['advertiserName'] as String,
      imageUrl: map['imageUrl'] as String,
      city: map['city'] as String,
      area: map['area'] as String,
      location: map['location'] as String,
      link: map['link'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
