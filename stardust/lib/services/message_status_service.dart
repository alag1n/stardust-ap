import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for chat message status (sent, delivered, read)
class MessageStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Mark message as delivered
  Future<void> markAsDelivered(String messageId, String conversationId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'status': 'delivered',
    });
    
    // Update conversation's last activity
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastActivity': DateTime.now().toIso8601String(),
    });
  }
  
  /// Mark message as read
  Future<void> markAsRead(String messageId, String conversationId, String readerId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'status': 'read',
      'readBy': readerId,
      'readAt': DateTime.now().toIso8601String(),
    });
  }
  
  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(String conversationId, String readerId) async {
    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: readerId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    
    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    
    for (final doc in messages.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readBy': readerId,
        'readAt': now,
      });
    }
    
    await batch.commit();
  }
  
  /// Get unread message count for a user
  Future<int> getUnreadCount(String userId, String conversationId) async {
    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    
    return messages.docs.length;
  }
  
  /// Stream of unread count
  Stream<int> unreadCountStream(String userId, String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: userId)
        .where('status', whereIn: ['sent', 'delivered'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
