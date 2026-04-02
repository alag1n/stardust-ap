import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase service for authentication, database, and storage
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Collections
  static const String usersCollection = 'users';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String storiesCollection = 'stories';
  static const String stickersCollection = 'stickers';
  static const String sessionsCollection = 'sessions';
  
  // Auth
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  
  // Firestore
  static FirebaseFirestore get firestore => _firestore;
  
  // Storage
  static FirebaseStorage get storage => _storage;
  
  // Collection references
  static CollectionReference get users => _firestore.collection(usersCollection);
  static CollectionReference get conversations => _firestore.collection(conversationsCollection);
  static CollectionReference get messages => _firestore.collection(messagesCollection);
  static CollectionReference get stories => _firestore.collection(storiesCollection);
  static CollectionReference get stickers => _firestore.collection(stickersCollection);
  static CollectionReference get sessions => _firestore.collection(sessionsCollection);
}
