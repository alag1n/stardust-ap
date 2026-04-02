import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for account management (delete, password reset, etc.)
class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  /// Update password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }
  
  /// Delete account (with all data)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final userId = user.uid;
    
    // Delete all user data from Firestore
    await _deleteUserData(userId);
    
    // Delete Firebase Auth account
    await user.delete();
  }
  
  /// Delete all user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    // Delete likes where user is involved
    final likesWhereFrom = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: userId)
        .get();
    for (final doc in likesWhereFrom.docs) {
      await doc.reference.delete();
    }
    
    final likesWhereTo = await _firestore
        .collection('likes')
        .where('toUserId', isEqualTo: userId)
        .get();
    for (final doc in likesWhereTo.docs) {
      await doc.reference.delete();
    }
    
    // Delete conversations where user is participant
    final conversations = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();
    for (final convDoc in conversations.docs) {
      // Delete all messages in conversation
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: convDoc.id)
          .get();
      for (final msgDoc in messages.docs) {
        await msgDoc.reference.delete();
      }
      await convDoc.reference.delete();
    }
    
    // Delete user document
    await _firestore.collection('users').doc(userId).delete();
    
    // Delete notification settings
    await _firestore.collection('notification_settings').doc(userId).delete();
  }
  
  /// Update email
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateEmail(newEmail);
      // Also update in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
      });
    }
  }
  
  /// Re-authenticate user (required for sensitive operations)
  Future<bool> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }
}
