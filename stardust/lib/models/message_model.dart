/// Conversation/Chat model for Firestore
class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;

  ConversationModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    this.isGroup = false,
    this.groupName,
    this.groupPhoto,
  });

  factory ConversationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ConversationModel(
      id: id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageAt: data['lastMessageAt'] != null 
          ? DateTime.parse(data['lastMessageAt'])
          : null,
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupPhoto: data['groupPhoto'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhoto': groupPhoto,
    };
  }
}

/// Message status enum
enum MessageStatus {
  sending,   // Отправляется
  sent,      // Отправлено (одна серая галочка)
  delivered, // Доставлено (две серые галочки)
  read,      // Прочитано (две синие галочки)
}

/// Message model for Firestore
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'sticker'
  final DateTime createdAt;
  final MessageStatus status;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.readAt,
  });

  /// For backward compatibility - checks if message is read
  bool get isRead => status == MessageStatus.read;

  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse status from string
    MessageStatus messageStatus;
    final statusStr = data['status'] as String?;
    switch (statusStr) {
      case 'delivered':
        messageStatus = MessageStatus.delivered;
        break;
      case 'read':
        messageStatus = MessageStatus.read;
        break;
      case 'sending':
        messageStatus = MessageStatus.sending;
        break;
      default:
        messageStatus = MessageStatus.sent;
    }

    return MessageModel(
      id: id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      status: messageStatus,
      readAt: data['readAt'] != null 
          ? DateTime.parse(data['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'readAt': readAt?.toIso8601String(),
    };
  }
}
