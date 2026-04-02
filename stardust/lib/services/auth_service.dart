import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

/// Authentication service using Firebase Auth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Register with email and password
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user document in Firestore
    if (credential.user != null) {
      await _createUserDocument(credential.user!);
    }
    
    return credential;
  }
  
  /// Login with email and password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    }
  }
  
  /// Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
      age: 0,
      gender: '',
      createdAt: DateTime.now(),
    );
    
    await FirebaseService.users.doc(user.uid).set(userModel.toFirestore());
  }
  
  /// Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    final doc = await FirebaseService.users.doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data is Map) {
        return UserModel.fromFirestore(Map<String, dynamic>.from(data), doc.id);
      }
    }
    return null;
  }
  
  /// Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await FirebaseService.users.doc(userId).update(data);
  }
  
  /// Toggle profile visibility in search
  Future<bool> toggleProfileVisibility(String userId) async {
    final doc = await FirebaseService.users.doc(userId).get();
    if (doc.exists) {
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      final currentVisible = data?['isVisible'] == true;
      final newVisible = !currentVisible;
      await FirebaseService.users.doc(userId).update({
        'isVisible': newVisible,
      });
      return newVisible;
    }
    return false;
  }
  
  /// Get profile visibility status
  Future<bool> isProfileVisible(String userId) async {
    final doc = await FirebaseService.users.doc(userId).get();
    if (doc.exists) {
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?['isVisible'] == true;
    }
    return true;
  }
  
  /// Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user document
      await FirebaseService.users.doc(user.uid).delete();
      // Delete auth account
      await user.delete();
    }
  }
}
