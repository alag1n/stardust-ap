import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing matches (unmatch, delete chat)
class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Delete match for current user only (other user keeps it)
  Future<void> deleteMatchForSelf(String currentUserId, String otherUserId) async {
    // Find the match
    final matches = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: otherUserId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    for (final doc in matches.docs) {
      await doc.reference.update({'isMatch': false, 'deletedBy': currentUserId});
    }
    
    // Delete conversation for current user
    await _deleteConversationForUser(currentUserId, otherUserId);
  }
  
  /// Delete match for both users
  Future<void> deleteMatchForBoth(String currentUserId, String otherUserId) async {
    // Find all matching records
    final matches = await _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: otherUserId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    for (final doc in matches.docs) {
      final fromUserId = doc.data()['fromUserId'];
      if (fromUserId == currentUserId) {
        await doc.reference.delete();
      }
    }
    
    // Also check reverse
    final reverseMatches = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: otherUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    for (final doc in reverseMatches.docs) {
      await doc.reference.delete();
    }
    
    // Delete conversation for both
    await _deleteConversationForBoth(currentUserId, otherUserId);
  }
  
  /// Delete conversation for one user (hide from their list)
  Future<void> _deleteConversationForUser(String userId1, String userId2) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId1)
        .get();
    
    for (final doc in conversations.docs) {
      final participants = List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(userId2) && participants.length == 2) {
        // Add user to hidden list or just delete
        await doc.reference.delete();
        break;
      }
    }
  }
  
  /// Delete conversation for both users
  Future<void> _deleteConversationForBoth(String userId1, String userId2) async {
    final conversations = await _firestore
        .collection('conversations')
        .get();
    
    for (final doc in conversations.docs) {
      final participants = List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(userId1) && participants.contains(userId2) && participants.length == 2) {
        // Delete all messages in conversation
        final messages = await _firestore
            .collection('messages')
            .where('conversationId', isEqualTo: doc.id)
            .get();
        
        final batch = _firestore.batch();
        for (final msg in messages.docs) {
          batch.delete(msg.reference);
        }
        await batch.commit();
        
        // Delete conversation
        await doc.reference.delete();
        break;
      }
    }
  }
  
  /// Get all matches for a user
  Future<List<Map<String, dynamic>>> getMatches(String userId) async {
    // Get users who matched with current user
    final likedBy = await _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: userId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    final matches = <Map<String, dynamic>>[];
    
    for (final doc in likedBy.docs) {
      final fromUserId = doc.data()['fromUserId'] as String;
      final userDoc = await _firestore.collection('users').doc(fromUserId).get();
      
      if (userDoc.exists) {
        // Get conversation
        final conversations = await _firestore
            .collection('conversations')
            .where('participantIds', arrayContains: userId)
            .get();
        
        String? conversationId;
        for (final conv in conversations.docs) {
          final participants = List<String>.from(conv.data()['participantIds'] ?? []);
          if (participants.contains(fromUserId)) {
            conversationId = conv.id;
            break;
          }
        }
        
        matches.add({
          'userId': fromUserId,
          'userData': userDoc.data(),
          'conversationId': conversationId,
          'matchedAt': doc.data()['matchedAt'],
        });
      }
    }
    
    return matches;
  }
}
