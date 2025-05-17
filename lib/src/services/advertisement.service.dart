import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/advertisement.dart';
import 'dart:io';
import 'dart:typed_data';

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'advertisements';

  AdvertisementService() {
    if (kIsWeb) {
      // Configure Firebase Storage for web
      _storage.setCustomMetadata({
        'cacheControl': 'public,max-age=3600',
        'contentType': 'image/jpeg',
      });
    }
  }

  // Create a new advertisement
  Future<Advertisement> createAdvertisement({
    required String title,
    required String description,
    required String userId,
    required String advertiserName,
    required dynamic image,
    required String city,
    required String area,
    required String location,
    required String link,
  }) async {
    try {
      final id = const Uuid().v4();

      // Upload image to Firebase Storage
      final imageRef = _storage.ref().child('advertisements/$id.jpg');
      late final TaskSnapshot uploadSnapshot;

      try {
        if (kIsWeb) {
          // For web, upload bytes with metadata
          if (image is! Uint8List) {
            throw Exception('Invalid image format for web upload');
          }

          uploadSnapshot = await imageRef.putData(
            image,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploaded-by': userId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          );
        } else {
          // For mobile, upload file
          if (image is! File) {
            throw Exception('Invalid image format for mobile upload');
          }

          uploadSnapshot = await imageRef.putFile(
            image,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploaded-by': userId,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ),
          );
        }

        final imageUrl = await uploadSnapshot.ref.getDownloadURL();

        final advertisement = Advertisement(
          id: id,
          title: title,
          description: description,
          userId: userId,
          advertiserName: advertiserName,
          imageUrl: imageUrl,
          city: city,
          area: area,
          location: location,
          link: link,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_collection)
            .doc(id)
            .set(advertisement.toMap());

        return advertisement;
      } catch (uploadError) {
        // If upload fails, attempt to clean up the storage reference
        try {
          await imageRef.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
        throw Exception('Failed to upload image: $uploadError');
      }
    } catch (e) {
      throw Exception('Failed to create advertisement: $e');
    }
  }

  // Get advertisements for a specific user
  Stream<List<Advertisement>> getUserAdvertisements(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Advertisement.fromMap(doc.data()))
              .toList();
        });
  }

  // Get all pending advertisements (for admin)
  Stream<List<Advertisement>> getPendingAdvertisements() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Advertisement.fromMap(doc.data()))
              .toList();
        });
  }

  // Update advertisement status
  Future<void> updateAdvertisementStatus(String id, String status) async {
    if (!['pending', 'accepted', 'rejected'].contains(status)) {
      throw Exception('Invalid status');
    }

    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update advertisement status: $e');
    }
  }

  // Delete advertisement
  Future<void> deleteAdvertisement(String id) async {
    try {
      // Delete image from storage
      await _storage.ref().child('advertisements/$id.jpg').delete();
      // Delete document from Firestore
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete advertisement: $e');
    }
  }
}
