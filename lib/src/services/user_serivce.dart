import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _fs = FirebaseFirestore.instance.collection('users');

  Future<void> createUserDoc(String uid, String email, String role) =>
      _fs.doc(uid).set({
        'email': email,
        'role': role,            // 'Citizen' | 'Gov Admin' | 'Advertiser'
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<String> fetchUserRole(String uid) async {
    final doc = await _fs.doc(uid).get();
    return doc.data()?['role'] as String;
  }
}
