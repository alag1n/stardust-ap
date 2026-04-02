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
    final messageData = {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': now.toIso8601String(),
      'status': 'sent',
      'receiverId': await _getReceiverId(conversationId, senderId),
    };
    
    await _firestore.collection('messages').add(messageData);
    
    // Update conversation with last message
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': content,
      'lastMessageAt': now.toIso8601String(),
    });
  }
  
  Future<String> _getReceiverId(String conversationId, String senderId) async {
    final conv = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(conv.data()?['participantIds'] ?? []);
    return participants.firstWhere((id) => id != senderId, orElse: () => '');
  }
  
  /// Get messages for a conversation
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
  
  /// Mark messages as read
  Future<void> markAsRead(String conversationId, String readerId) async {
    // Get receiver ID to mark their messages
    final conv = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(conv.data()?['participantIds'] ?? []);
    final senderId = participants.firstWhere((id) => id != readerId, orElse: () => '');
    
    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isEqualTo: senderId)
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
    
    // Reset unread count in conversation
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount': 0,
    });
  }
  
  /// Mark message as delivered (called when user opens conversation)
  Future<void> markAsDelivered(String conversationId, String currentUserId) async {
    final conv = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(conv.data()?['participantIds'] ?? []);
    final senderId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('senderId', isEqualTo: senderId)
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
  
  /// Get or create conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    // Check if conversation exists
    final existing = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId1)
        .get();
    
    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participantIds'] ?? []);
      if (participants.contains(userId2) && participants.length == 2) {
        return doc.id;
      }
    }
    
    // Create new conversation
    final convData = {
      'participantIds': [userId1, userId2],
      'createdAt': DateTime.now().toIso8601String(),
      'isGroup': false,
      'unreadCount': 0,
    };
    
    final docRef = await _firestore.collection('conversations').add(convData);
    return docRef.id;
  }
}
