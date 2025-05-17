import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advertisement_request.dart';

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'advertisement_requests';

  // Create a new advertisement request
  Future<void> createRequest(AdvertisementRequest request) async {
    // Get user's name from users collection
    final userDoc =
        await _firestore.collection('users').doc(request.posterId).get();
    final firstName = userDoc.data()?['firstName'] ?? '';
    final lastName = userDoc.data()?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    final requestData = request.toMap();
    requestData['posterName'] = fullName.isNotEmpty ? fullName : 'Unknown';

    await _firestore.collection(_collection).doc(request.id).set(requestData);
  }

  // Get all requests for a specific advertiser
  Stream<List<AdvertisementRequest>> getAdvertiserRequests(
    String advertiserId,
  ) {
    return _firestore
        .collection(_collection)
        .where('posterId', isEqualTo: advertiserId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AdvertisementRequest.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Update an existing request (only if pending)
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    final doc = await _firestore.collection(_collection).doc(requestId).get();
    if (!doc.exists) throw Exception('Request not found');

    final currentStatus = doc.data()?['status'];
    if (currentStatus != 'pending') {
      throw Exception('Can only update pending requests');
    }

    // Remove empty/null values from updates
    updates.removeWhere((key, value) => value == null || value == '');

    await _firestore.collection(_collection).doc(requestId).update(updates);
  }

  // Delete a request
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection(_collection).doc(requestId).delete();
  }

  // Get request by ID
  Future<AdvertisementRequest?> getRequestById(String requestId) async {
    final doc = await _firestore.collection(_collection).doc(requestId).get();
    if (!doc.exists) return null;
    return AdvertisementRequest.fromMap(doc.data()!);
  }
}
