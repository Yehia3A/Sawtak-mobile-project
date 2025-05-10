import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _fs = FirebaseFirestore.instance.collection('users');

  // Create a new user document
  Future<void> createUserDoc(String uid, String email, String role) async {
    try {
      await _fs.doc(uid).set({
        'email': email,
        'role': role, // 'Citizen' | 'Gov Admin' | 'Advertiser'
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      print('✅ User document created successfully');
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  // Get user role
  Future<String> fetchUserRole(String uid) async {
    try {
      final doc = await _fs.doc(uid).get();
      return doc.data()?['role'] as String;
    } catch (e) {
      print('❌ Error fetching user role: $e');
      rethrow;
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _fs.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching all users: $e');
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _fs.doc(uid).update(data);
      print('✅ User updated successfully');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _fs.doc(uid).delete();
      print('✅ User deleted successfully');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // Test method to create a sample user
  Future<void> testCreateUser() async {
    try {
      await createUserDoc(
        'test_user_${DateTime.now().millisecondsSinceEpoch}',
        'test@example.com',
        'Citizen',
      );
      print('✅ Test user created successfully');
    } catch (e) {
      print('❌ Error creating test user: $e');
    }
  }

  // Test method to fetch and print all users
  Future<void> testGetAllUsers() async {
    try {
      final users = await getAllUsers();
      print('📋 All Users:');
      for (var user in users) {
        print('User: ${user['email']} - Role: ${user['role']}');
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    }
  }
}
