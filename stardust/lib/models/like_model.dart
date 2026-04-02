/// Like/Match model for Firestore
class LikeModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final bool isMatch;
  final bool isSuperLike;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.isMatch = false,
    this.isSuperLike = false,
    required this.createdAt,
  });

  factory LikeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LikeModel(
      id: id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      isMatch: data['isMatch'] ?? false,
      isSuperLike: data['isSuperLike'] ?? false,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'isMatch': isMatch,
      'isSuperLike': isSuperLike,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Match model (when two users like each other)
class MatchModel {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  MatchModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory MatchModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MatchModel(
      id: id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      matchedAt: data['matchedAt'] != null 
          ? DateTime.parse(data['matchedAt'])
          : DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null 
          ? DateTime.parse(data['lastMessageAt'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'matchedAt': matchedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }
}
