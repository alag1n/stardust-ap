import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Service for messages/chat functionality
class MessagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    final now = DateTime.now();
    final otherUserId = _getReceiverIdSimple(conversationId, senderId);
    
    final messageData = {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': now.toIso8601String(),
      'status': 'sent',
      'receiverId': otherUserId,
    };
    
    await _firestore.collection('messages').add(messageData);
  }
    
  String _getReceiverIdSimple(String conversationId, String senderId) {
    // conversationId format: "userId1-userId2"
    final parts = conversationId.split('-');
    return parts.firstWhere((id) => id != senderId, orElse: () => senderId);
  }
  
  /// Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }
  
  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String readerId) async {
    // Get messages from other user
    final otherUserId = conversationId.split('-').firstWhere((id) => id != readerId, orElse: () => readerId);
    
    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isEqualTo: otherUserId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    
    final now = DateTime.now().toIso8601String();
    final batch = _firestore.batch();
    
    for (final doc in messages.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readAt': now,
      });
    }
    
    await batch.commit();
  }
    
  /// Mark message as delivered (called when user opens conversation)
  Future<void> markAsDelivered(String conversationId, String currentUserId) async {
    final otherUserId = conversationId.split('-').firstWhere((id) => id != currentUserId, orElse: () => currentUserId);

    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isEqualTo: otherUserId)
        .where('status', isEqualTo: 'sent')
        .get();
    
    final batch = _firestore.batch();
    
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }
    
    await batch.commit();
  }
  
  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
  }
}
  
