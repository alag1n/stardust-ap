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
    print('💖 Creating like: from=$fromUserId to=$toUserId, superLike=$isSuperLike');
    
    try {
      // Если Super Like - проверяем лимит
      if (isSuperLike) {
        final canSuperLike = await canSendSuperLike(fromUserId);
        if (!canSuperLike) {
          throw Exception('Превышен лимит Super Like или недоступно');
        }
      }
      
      print('✅ SuperLike check passed');
      
      // Check if the other user already liked us
      final existingLikes = await _firestore
          .collection('likes')
          .get();
      
      final isMatch = existingLikes.docs.any((doc) {
        final data = doc.data();
        return data['fromUserId'] == toUserId && data['toUserId'] == fromUserId;
      });
      
      print('🔍 Found ${existingLikes.docs.length} total likes, isMatch: $isMatch');
      
      // Create like
      final likeData = {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'isMatch': isMatch,
        'isSuperLike': isSuperLike,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('📝 Saving like to Firestore...');
      final likeDoc = await _firestore.collection('likes').add(likeData);
      print('✅ Like created in Firestore with ID: ${likeDoc.id}');
      
      // Если Super Like - увеличиваем счётчик
      if (isSuperLike) {
        await _firestore.collection('users').doc(fromUserId).update({
          'superLikesToday': FieldValue.increment(1),
        });
        print('✅ SuperLike counter updated');
      }
      
      // If it's a match or superlike, create conversation
      if (isMatch || isSuperLike) {
        print('🤝 Creating match conversation...');
        await _createMatchConversation(fromUserId, toUserId);
        print('✅ Match conversation created');
      }
      
      // Update likes count
      print('📈 Updating likesCount for user $toUserId...');
      await _firestore.collection('users').doc(toUserId).update({
        'likesCount': FieldValue.increment(1),
      });
      print('✅ Updated likesCount for user $toUserId');
      
      return isMatch || isSuperLike;
    } catch (e, stackTrace) {
      print('❌ Error in likeUser: $e');
      print(stackTrace);
      rethrow;
    }
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
    print('🔍 getLikedByUsers called for: $userId');
    
    // Получаем ВСЕ лайки и фильтруем на клиенте (без orderBy чтобы не было проблем с индексами)
    final likes = await _firestore.collection('likes').get();
    
    final result = likes.docs
        .where((doc) => doc.data()['toUserId'] == userId)
        .map((doc) => doc.data()['fromUserId'] as String)
        .toList();
    
    print('📊 getLikedByUsers returned ${result.length} users: $result');
    return result;
  }
  
  /// Get our likes
  Future<List<String>> getOurLikes(String userId) async {
    print('🔍 getOurLikes called for: $userId');
    
    // Получаем ВСЕ лайки и фильтруем на клиенте
    final likes = await _firestore.collection('likes').get();
    
    final result = likes.docs
        .where((doc) => doc.data()['fromUserId'] == userId)
        .map((doc) => doc.data()['toUserId'] as String)
        .toList();
    
    print('📊 getOurLikes returned ${result.length} users: $result');
    return result;
  }
  
  /// Get users we've Super Liked
  Future<List<String>> getSuperLikes(String userId) async {
    print('🔍 getSuperLikes called for: $userId');
    
    // Получаем ВСЕ лайки и фильтруем на клиенте
    final likes = await _firestore.collection('likes').get();
    
    final result = likes.docs
        .where((doc) => 
            doc.data()['fromUserId'] == userId && 
            doc.data()['isSuperLike'] == true)
        .map((doc) => doc.data()['toUserId'] as String)
        .toList();
    
    print('📊 getSuperLikes returned ${result.length} users: $result');
    return result;
  }
  
  /// Get matches
  Future<List<MatchModel>> getMatches(String userId) async {
    // Получаем ВСЕ лайки и фильтруем на клиенте
    final likes = await _firestore.collection('likes').get();
    
    // Фильтруем: где isMatch=true и userId участвует
    final matchLikes = likes.docs.where((doc) {
      final data = doc.data();
      return data['isMatch'] == true &&
             (data['fromUserId'] == userId || data['toUserId'] == userId);
    }).toList();
    
    print('🔥 getMatches found ${matchLikes.length} matches for user $userId');
    
    return matchLikes.map((doc) {
      final data = doc.data();
      final otherUserId = data['fromUserId'] == userId 
          ? data['toUserId'] 
          : data['fromUserId'];
      
      return MatchModel(
        id: doc.id,
        userId1: userId,
        userId2: otherUserId,
        matchedAt: DateTime.now(),
      );
    }).toList();
  }
  
  /// Check if user is liked
  Future<bool> isLiked(String fromUserId, String toUserId) async {
    // Получаем ВСЕ лайки и фильтруем на клиенте
    final likes = await _firestore.collection('likes').get();
    
    final result = likes.docs.any((doc) => 
        doc.data()['fromUserId'] == fromUserId && 
        doc.data()['toUserId'] == toUserId);
    
    return result;
  }
  
  /// Check if it's a match
  Future<bool> isMatch(String userId1, String userId2) async {
    // Получаем ВСЕ лайки и фильтруем на клиенте
    final likes = await _firestore.collection('likes').get();
    
    final result = likes.docs.any((doc) {
      final data = doc.data();
      return (data['fromUserId'] == userId1 && data['toUserId'] == userId2 && data['isMatch'] == true) ||
             (data['fromUserId'] == userId2 && data['toUserId'] == userId1 && data['isMatch'] == true);
    });
    
    return result;
  }
  
  /// Create conversation for match
  Future<void> _createMatchConversation(String userId1, String userId2) async {
    // Проверка на существование match через client-side filtering
    final matches = await _firestore.collection('matches').get();
    
    final existingMatch = matches.docs.any((doc) {
      final data = doc.data();
      final userIds = data['userIds'] as List<dynamic>;
      return userIds.contains(userId1) && userIds.contains(userId2);
    });
    
    if (existingMatch) {
      print('🤝 Match conversation already exists');
      return;
    }
    
    // Создаем match
    await _firestore.collection('matches').add({
      'userIds': [userId1, userId2],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Match conversation created');
  }
}
