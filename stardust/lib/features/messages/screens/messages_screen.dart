import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/models/user_model.dart';
import 'package:stardust/models/message_model.dart';
import 'package:stardust/services/likes_service.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/match_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final LikesService _likesService = LikesService();
  final AuthService _authService = AuthService();
  final MatchService _matchService = MatchService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Получаем мэтчи
      final matches = await _likesService.getMatches(userId);
      
      final chatsData = <Map<String, dynamic>>[];
      
      for (final match in matches) {
        // ID другого пользователя
        final otherUserId = match.userId1 == userId ? match.userId2 : match.userId1;
        
        // Получаем данные пользователя
        final user = await _authService.getUserData(otherUserId);
        if (user == null) continue;
        
        // Получаем последнее сообщение
        final messages = await _firestore
            .collection('messages')
            .where('conversationId', isEqualTo: match.id)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        
        String lastMessage = '';
        String lastTime = '';
        int unreadCount = 0;
        
        if (messages.docs.isNotEmpty) {
          final msgData = messages.docs.first.data();
          lastMessage = msgData['content'] ?? '';
          if (msgData['createdAt'] != null) {
            final msgTime = DateTime.parse(msgData['createdAt']);
            lastTime = _formatTime(msgTime);
          }
          unreadCount = msgData['isRead'] == false && msgData['senderId'] != userId 
              ? 1 
              : 0;
        } else {
          lastMessage = 'Новый мэтч! Напишите первым 👋';
        }
        
        chatsData.add({
          'id': match.id,
          'userId': otherUserId,
          'user': user,
          'lastMessage': lastMessage,
          'lastTime': lastTime.isEmpty ? 'Сейчас' : lastTime,
          'unread': unreadCount,
        });
      }
      
      // Сортируем по времени
      chatsData.sort((a, b) {
        if (a['unread'] > b['unread']) return -1;
        if (a['unread'] < b['unread']) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _chats = chatsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Сейчас';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    if (diff.inDays < 7) return '${diff.inDays} дн';
    
    return '${time.day}.${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final totalUnread = _chats.fold<int>(0, (sum, chat) => sum + (chat['unread'] as int));

    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Сообщения',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalUnread новых',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),
                
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_chats.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Нет чатов',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Лайкайте анкеты, чтобы найти мэтчи',
                            style: TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadChats,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          return _buildChatItem(context, chat, index);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, int index) {
    final user = chat['user'] as UserModel;
    final hasUnread = (chat['unread'] as int) > 0;

    return Dismissible(
      key: Key(chat['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, user.name);
      },
      onDismissed: (direction) {
        _deleteChat(chat);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/chat/${chat['id']}?name=${user.name}&userId=${chat['userId']}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Аватар
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          image: user.photoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(user.photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.photoUrl == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              chat['lastTime'],
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat['lastMessage'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${chat['unread']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String userName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Удалить чат', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Удалить чат с $userName? Вы можете восстановить матч позже.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(Map<String, dynamic> chat) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _matchService.deleteMatchForSelf(userId, chat['userId'] as String);
      
      if (mounted) {
        setState(() {
          _chats.removeWhere((c) => c['id'] == chat['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Чат удалён'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Отмена',
              textColor: Colors.white,
              onPressed: () {
                // Здесь можно добавить восстановление
                _loadChats();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}
