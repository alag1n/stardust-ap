import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for blocking users
class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Block a user
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    String? reason,
  }) async {
    final blockData = {
      'blockerId': blockerId,
      'blockedId': blockedId,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _firestore.collection('blocks').add(blockData);
  }
  
  /// Unblock a user
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final block = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();
    
    if (block.docs.isNotEmpty) {
      await _firestore.collection('blocks').doc(block.docs.first.id).delete();
    }
  }
  
  /// Check if user is blocked
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    final block = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();
    
    return block.docs.isNotEmpty;
  }
  
  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUserIds(String userId) async {
    final blocks = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: userId)
        .get();
    
    return blocks.docs.map((doc) => doc.data()['blockedId'] as String).toList();
  }
  
  /// Get blocked users (full data)
  Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
    final blocks = await _firestore
        .collection('blocks')
        .where('blockerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    final blockedUsers = <Map<String, dynamic>>[];
    
    for (final doc in blocks.docs) {
      final blockedId = doc.data()['blockedId'] as String;
      final userDoc = await _firestore.collection('users').doc(blockedId).get();
      
      if (userDoc.exists) {
        blockedUsers.add({
          'id': blockedId,
          'data': userDoc.data(),
          'blockedAt': doc.data()['createdAt'],
          'reason': doc.data()['reason'],
        });
      }
    }
    
    return blockedUsers;
  }
}
