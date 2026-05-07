import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/models/message_model.dart';
import 'package:stardust/services/messages_service.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/message_status_service.dart';
import 'package:stardust/services/match_service.dart';
import 'package:stardust/models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String userName;
  final String? userId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.userName,
    this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesService _messagesService = MessagesService();
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  UserModel? _otherUser;
  String? _conversationId;
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No user authenticated');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
          );
        }
        return;
      }

      // Формируем conversationId из отсортированных ID
      // widget.userId может быть null если не передан в URL
      final otherUserId = widget.userId ?? widget.conversationId;
      final ids = [currentUserId, otherUserId]..sort();
      final conversationId = ids.join('-');
      print('📝 Conversation ID: $conversationId');
      
      // Получаем данные пользователя
      _otherUser = await _authService.getUserData(otherUserId);
      if (_otherUser == null) {
        print('❌ User data not found for: $otherUserId');
      }
      
      // Получаем статус онлайн
      if (_otherUser != null) {
        _lastSeen = _otherUser!.lastActive;
        _isOnline = _isUserOnline(_lastSeen);
      }
      
      setState(() {
        _conversationId = conversationId;
        _isLoading = false;
      });

      print('🔔 Subscribing to messages for: $conversationId');
      
      // Подписка на сообщения с обработкой ошибок
      _messagesService.getMessages(conversationId).listen(
        (msgs) {
          if (mounted) {
            setState(() {
              _messages = msgs;
            });
            // Прокрутка к низу при новом сообщении
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        },
        onError: (error) {
          print('❌ Error listening to messages: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка загрузки сообщений: $error')),
            );
          }
        },
      );

      // Отмечаем сообщения как доставленные
      try {
        await _messagesService.markAsDelivered(conversationId, currentUserId);
        print('✅ Messages marked as delivered');
      } catch (e) {
        print('⚠️ Error marking as delivered: $e');
      }
      
      // Отмечаем как прочитанные
      try {
        await _messagesService.markAsRead(conversationId, currentUserId);
        print('✅ Messages marked as read');
      } catch (e) {
        print('⚠️ Error marking as read: $e');
      }
      
    } catch (e, stackTrace) {
      print('❌ Error in _initChat: $e');
      print(stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _messagesService.sendMessage(
        conversationId: _conversationId!,
        senderId: currentUserId,
        content: text,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: Column(
              children: [
                // Хедер
                _buildHeader(context),
                // Сообщения
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_messages.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Начните разговор!',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                        final isMe = message.senderId == currentUserId;
                        return _buildMessageBubble(message, index, isMe);
                      },
                    ),
                  ),
                // Поле ввода
                _buildInputField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = _otherUser?.name ?? widget.userName;
    final photoUrl = _otherUser?.photoUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/messages');
              }
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            child: _buildUserAvatar(_otherUser, displayName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isOnline ? 'В сети' : _formatLastSeen(_lastSeen),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOnline ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surface,
            onSelected: (value) {
              switch (value) {
                case 'delete_for_me':
                  _showDeleteDialog(forBoth: false);
                  break;
                case 'delete_for_both':
                  _showDeleteDialog(forBoth: true);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_for_me',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 12),
                    Text('Удалить у меня', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_for_both',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Удалить у обоих', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Был(а) давно';
    
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    
    if (diff.inMinutes < 1) return 'Был(а) только что';
    if (diff.inMinutes < 60) return 'Был(а) ${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return 'Был(а) ${diff.inHours} ч назад';
    if (diff.inDays < 7) return 'Был(а) ${diff.inDays} дн назад';
    
    return 'Был(а) давно';
  }

  bool _isUserOnline(DateTime? lastActive) {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive).inMinutes < 5;
  }

  Widget _buildUserAvatar(UserModel? user, String displayName) {
    // Сначала проверяем photoUrl, затем берём первое фото из массива photos
    String? photoUrl = user?.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      if (user?.photos != null && user!.photos!.isNotEmpty) {
        photoUrl = user.photos!.first;
      }
    }
    
    print('🖼️ Chat Avatar photoUrl: ${photoUrl?.substring(0, 50) ?? 'null'}');
    
    if (photoUrl == null || photoUrl.isEmpty) {
      return Text(
        displayName[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    
    // Проверка на base64
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Part = photoUrl.split(',').last;
        final bytes = base64Decode(base64Part);
        return ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } catch (e) {
        print('❌ Error decoding base64: $e');
        return Text(
          displayName[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
    
    // Обычная URL
    return ClipOval(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Text(
          displayName[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog({required bool forBoth}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              forBoth ? Icons.delete_forever : Icons.delete_outline,
              color: forBoth ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              forBoth ? 'Удалить у обоих' : 'Удалить у меня',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          forBoth
              ? 'Чат будет удалён у вас и у собеседника. Это действие нельзя отменить.'
              : 'Чат будет удалён только у вас. Собеседник сохранит переписку.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat(forBoth: forBoth);
            },
            style: TextButton.styleFrom(
              foregroundColor: forBoth ? AppColors.error : AppColors.primary,
            ),
            child: Text(forBoth ? 'Удалить' : 'Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat({required bool forBoth}) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      if (forBoth) {
        await _matchService.deleteMatchForBoth(currentUserId, widget.userId ?? '');
      } else {
        await _matchService.deleteMatchForSelf(currentUserId, widget.userId ?? '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(forBoth ? 'Чат удалён у обоих' : 'Чат удалён'),
            backgroundColor: AppColors.success,
          ),
        );
        
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/messages');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(MessageModel message, int index, bool isMe) {
    final time = _formatTime(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white60 : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: isMe ? 0.1 : -0.1);
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.done,
          size: 14,
          color: Colors.white60,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white60,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlueAccent,
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return '${time.day}.${time.month}';
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Написать сообщение...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}
