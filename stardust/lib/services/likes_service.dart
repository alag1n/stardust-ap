import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/like_model.dart';
import 'firebase_service.dart';

/// Service for likes and matches
class LikesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if user can send Super Like
  Future<bool> canSendSuperLike(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;
    
    final data = userDoc.data()!;
    final isPremium = data['isPremium'] ?? false;
    final superLikesToday = data['superLikesToday'] ?? 0;
    final resetDate = data['superLikesResetDate'] != null 
        ? DateTime.parse(data['superLikesResetDate']) 
        : null;
    
    // Проверяем, нужно ли сбросить счётчик
    final now = DateTime.now();
    if (resetDate == null || now.day != resetDate.day) {
      // Новый день - сбрасываем
      await _firestore.collection('users').doc(userId).update({
        'superLikesToday': 0,
        'superLikesResetDate': now.toIso8601String(),
      });
      return isPremium; // Премиум может отправлять
    }
    
    // Не премиум - нельзя
    if (!isPremium) return false;
    
    // Премиум, но лимит исчерпан
    return superLikesToday < 3;
  }
  
  /// Like a user
  Future<bool> likeUser({
    required String fromUserId,
    required String toUserId,
    bool isSuperLike = false,
  }) async {
    // Если Super Like - проверяем лимит
    if (isSuperLike) {
      final canSuperLike = await canSendSuperLike(fromUserId);
      if (!canSuperLike) {
        throw Exception('Превышен лимит Super Like или недоступно');
      }
    }
    
    // Check if the other user already liked us
    final existingLike = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: fromUserId)
        .get();
    
    final isMatch = existingLike.docs.isNotEmpty;
    
    // Create like
    final likeData = {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'isMatch': isMatch,
      'isSuperLike': isSuperLike,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _firestore.collection('likes').add(likeData);
    
    // Если Super Like - увеличиваем счётчик
    if (isSuperLike) {
      await _firestore.collection('users').doc(fromUserId).update({
        'superLikesToday': FieldValue.increment(1),
      });
    }
    
    // If it's a match or superlike, create conversation
    if (isMatch || isSuperLike) {
      await _createMatchConversation(fromUserId, toUserId);
    }
    
    // Update likes count
    await _firestore.collection('users').doc(toUserId).update({
      'likesCount': FieldValue.increment(1),
    });
    
    return isMatch || isSuperLike;
  }
  
  /// Unlike a user
  Future<void> unlikeUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    final like = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();
    
    if (like.docs.isNotEmpty) {
      await _firestore.collection('likes').doc(like.docs.first.id).delete();
    }
  }
  
  /// Get users who liked us
  Future<List<String>> getLikedByUsers(String userId) async {
    final likes = await _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: userId)
        .get();
    
    return likes.docs.map((doc) => doc.data()['fromUserId'] as String).toList();
  }
  
  /// Get our likes
  Future<List<String>> getOurLikes(String userId) async {
    final likes = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .get();
    
    return likes.docs.map((doc) => doc.data()['toUserId'] as String).toList();
  }
  
  /// Get users we've Super Liked
  Future<List<String>> getSuperLikes(String userId) async {
    final likes = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .where('isSuperLike', isEqualTo: true)
        .get();
    
    return likes.docs.map((doc) => doc.data()['toUserId'] as String).toList();
  }
  
  /// Get matches
  Future<List<MatchModel>> getMatches(String userId) async {
    final matches = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    final matches2 = await _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: userId)
        .where('isMatch', isEqualTo: true)
        .get();
    
    final allMatches = [...matches.docs, ...matches2.docs];
    
    return allMatches.map((doc) {
      final data = doc.data();
      final otherUserId = data['fromUserId'] == userId 
          ? data['toUserId'] 
          : data['fromUserId'];
      
      return MatchModel(
        id: doc.id,
        userId1: userId,
        userId2: otherUserId,
        matchedAt: DateTime.parse(data['createdAt']),
      );
    }).toList();
  }
  
  /// Check if user is liked
  Future<bool> isLiked(String fromUserId, String toUserId) async {
    final like = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .get();
    
    return like.docs.isNotEmpty;
  }
  
  /// Check if it's a match
  Future<bool> isMatch(String userId1, String userId2) async {
    final like = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId1)
        .where('toUserId', isEqualTo: userId2)
        .where('isMatch', isEqualTo: true)
        .get();
    
    return like.docs.isNotEmpty;
  }
  
  /// Create conversation for match
  Future<void> _createMatchConversation(String userId1, String userId2) async {
    final conversationData = {
      'participantIds': [userId1, userId2],
      'createdAt': DateTime.now().toIso8601String(),
      'isGroup': false,
      'unreadCount': 0,
    };
    
    await _firestore.collection('conversations').add(conversationData);
    
    // Update match counts
    await _firestore.collection('users').doc(userId1).update({
      'matchesCount': FieldValue.increment(1),
    });
    await _firestore.collection('users').doc(userId2).update({
      'matchesCount': FieldValue.increment(1),
    });
  }
}
