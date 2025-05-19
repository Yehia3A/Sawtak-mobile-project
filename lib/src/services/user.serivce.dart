import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user role as a stream
  Stream<String?> getUserRole(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String?);
  }

  // Fetch user role
  Future<String> fetchUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'Citizen';
  }

  // Fetch user first name
  Future<String> fetchUserFirstName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['firstName'] ?? '';
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  // Create new user
  Future<void> createUser({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String role = 'Citizen',
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Create a new user document
  Future<void> createUserDoc(
    String uid,
    String email,
    String role,
    String firstName,
    String lastName,
    String password, {
    required String city,
    required String area,
    required String phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        'role': role, // 'Citizen' | 'Gov Admin' | 'Advertiser'
        'city': city,
        'area': area,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      print('✅ User document created successfully');
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('✅ User updated successfully');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Get seen notifications for a user
  Future<List<String>> getSeenNotifications(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['seenNotifications'] == null) return [];
    return List<String>.from(data['seenNotifications']);
  }

  // Add a notification to seenNotifications
  Future<void> addSeenNotification(String uid, String notificationId) async {
    await _firestore.collection('users').doc(uid).update({
      'seenNotifications': FieldValue.arrayUnion([notificationId]),
    });
  }

  // Check if a notification is unseen
  Future<bool> isNotificationUnseen(String uid, String notificationId) async {
    final seen = await getSeenNotifications(uid);
    return !seen.contains(notificationId);
  }

  // Test method to create a sample user
}
