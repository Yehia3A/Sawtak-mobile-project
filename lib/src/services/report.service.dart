import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reportsCollection = 'reports';

  Stream<List<Report>> getReports() {
    return _firestore
        .collection(_reportsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList(),
        );
  }

  Future<void> submitReport({
    required String emergencyType,
    required String location,
    required String details,
    List<String>? attachments,
    String? audioPath,
    required String userId,
    required String userName,
  }) async {
    try {
      final reportId = const Uuid().v4();
      final report = {
        'id': reportId,
        'emergencyType': emergencyType,
        'location': location,
        'details': details,
        'attachments': attachments ?? [],
        'audioPath': audioPath,
        'userId': userId,
        'userName': userName,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_reportsCollection).doc(reportId).set(report);
      debugPrint('Report saved to Firestore: $reportId');
    } catch (e) {
      debugPrint('Error saving report: $e');
      throw Exception('Failed to save report: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'status': newStatus,
      });
      debugPrint('Report status updated: $reportId -> $newStatus');
    } catch (e) {
      debugPrint('Error updating report status: $e');
      throw Exception('Failed to update report status: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).delete();
      debugPrint('Report deleted from Firestore: $reportId');
    } catch (e) {
      debugPrint('Error deleting report: $e');
      throw Exception('Failed to delete report: $e');
    }
  }
}
