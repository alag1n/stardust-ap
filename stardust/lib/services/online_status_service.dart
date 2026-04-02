import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user online status
class OnlineStatusService {
  FirebaseFirestore? _firestore;
  Timer? _heartbeatTimer;
  
  FirebaseFirestore get firestore {
    try {
      _firestore ??= FirebaseFirestore.instance;
      return _firestore!;
    } catch (e) {
      debugPrint('FirebaseFirestore not initialized: $e');
      rethrow;
    }
  }
  
  /// Start tracking online status
  void startTracking() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Update immediately
    _updateOnlineStatus(userId, true);
    
    // Update every 30 seconds (heartbeat)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateOnlineStatus(userId, true);
    });
  }
  
  /// Stop tracking (user went offline)
  void stopTracking() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _updateOnlineStatus(userId, false);
    }
  }
  
  /// Update online status in Firestore
  Future<void> _updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastActive': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
      // Document might not exist yet
    }
  }
  
  /// Get user's online status as stream
  Stream<Map<String, dynamic>?> getUserStatus(String userId) {
    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return {
          'isOnline': doc.data()?['isOnline'] ?? false,
          'lastActive': doc.data()?['lastActive'] != null 
              ? DateTime.parse(doc.data()!['lastActive'])
              : null,
        };
      }
      return null;
    });
  }
  
  /// Check if user is currently online
  Future<bool> isUserOnline(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final isOnline = doc.data()?['isOnline'] ?? false;
      final lastActive = doc.data()?['lastActive'];
      
      // If not explicitly online, check lastActive time
      if (!isOnline && lastActive != null) {
        final lastTime = DateTime.parse(lastActive);
        final diff = DateTime.now().difference(lastTime);
        // Consider online if last active < 5 minutes
        return diff.inMinutes < 5;
      }
      
      return isOnline;
    }
    return false;
  }
  
  /// Format last active time to human readable string
  static String formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Неизвестно';
    
    final now = DateTime.now();
    final diff = now.difference(lastActive);
    
    if (diff.inSeconds < 60) return 'Онлайн';
    if (diff.inMinutes < 60) return 'Был(а) ${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return 'Был(а) ${diff.inHours} ч назад';
    if (diff.inDays < 7) return 'Был(а) ${diff.inDays} дн назад';
    
    return 'Был(а) давно';
  }
  
  /// Check if user is currently online (for display)
  static bool isOnline(DateTime? lastActive) {
    if (lastActive == null) return false;
    final diff = DateTime.now().difference(lastActive);
    return diff.inMinutes < 5;
  }
}
