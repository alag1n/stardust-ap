import 'package:cloud_firestore/cloud_firestore.dart';

/// Report reasons
class ReportReason {
  static const String spam = 'spam';
  static const String harassment = 'harassment';
  static const String fakeProfile = 'fake_profile';
  static const String inappropriate = 'inappropriate';
  static const String other = 'other';
  
  static List<String> get all => [
    spam,
    harassment,
    fakeProfile,
    inappropriate,
    other,
  ];
  
  static String getLabel(String reason) {
    switch (reason) {
      case spam:
        return 'Спам';
      case harassment:
        return 'Оскорбления / домогательства';
      case fakeProfile:
        return 'Фейковый профиль';
      case inappropriate:
        return 'Неуместный контент';
      case other:
        return 'Другое';
      default:
        return reason;
    }
  }
}

/// Service for reporting users
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? description,
  }) async {
    final reportData = {
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'description': description,
      'status': 'pending', // pending, reviewed, resolved
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _firestore.collection('reports').add(reportData);
  }
  
  /// Get reports for a user (for admin)
  Future<List<Map<String, dynamic>>> getReportsForUser(String userId) async {
    final reports = await _firestore
        .collection('reports')
        .where('reportedId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return reports.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
  
  /// Check if user was already reported by current user
  Future<bool> hasReported(String reporterId, String reportedId) async {
    final report = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: reporterId)
        .where('reportedId', isEqualTo: reportedId)
        .get();
    
    return report.docs.isNotEmpty;
  }
}
