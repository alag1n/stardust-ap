import 'dart:convert';
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
      if (userId == null) {
        print('❌ No user authenticated');
        setState(() => _isLoading = false);
        return;
      }

      print('📱 Loading chats for user: $userId');
      
      // Получаем ВСЕ лайки
      print('🔍 Fetching all likes from Firestore...');
      final allLikes = await _firestore.collection('likes').get();
      print('🔥 Total likes in DB: ${allLikes.docs.length}');
      
      // Фильтруем взаимные лайки (где оба лайкнули друг друга)
      final matchedUserIds = <String>{};
      
      for (final likeDoc in allLikes.docs) {
        final likeData = likeDoc.data();
        final fromUserId = likeData['fromUserId'] as String;
        final toUserId = likeData['toUserId'] as String;
        
        // Если это лайк ОТ текущего пользователя
        if (fromUserId == userId) {
          // Проверяем есть ли обратный лайк
          final hasBackLike = allLikes.docs.any((doc) {
            final data = doc.data();
            return data['fromUserId'] == toUserId && 
                   data['toUserId'] == userId;
          });
          if (hasBackLike) {
            matchedUserIds.add(toUserId);
            print('✅ Mutual match found with: $toUserId');
          }
        }
      }
      
      print('🔥 Found ${matchedUserIds.length} mutual matches');
      
      final chatsData = <Map<String, dynamic>>[];
      
      for (final otherUserId in matchedUserIds) {
        print('🔹 Processing match: $otherUserId');
        
        // Получаем данные пользователя
        final user = await _authService.getUserData(otherUserId);
        if (user == null) {
          print('❌ User data not found for: $otherUserId');
          continue;
        }
        print('✅ User found: ${user.name}');
        
        // conversationId = отсортированные ID пользователей через '-'
        final ids = [userId, otherUserId]..sort();
        final conversationId = ids.join('-');
        print('📝 Conversation ID: $conversationId');
        
        // Получаем последнее сообщение с try-catch
        String lastMessage = 'Новый мэтч! Напишите первым 👋';
        String lastTime = 'Сейчас';
        int unreadCount = 0;
        
        try {
          final messages = await _firestore
              .collection('messages')
              .where('conversationId', isEqualTo: conversationId)
              .get();
          
          // Находим последнее сообщение
          if (messages.docs.isNotEmpty) {
            // Сортируем на клиенте
            final sorted = messages.docs.toList()
              ..sort((a, b) {
                final aTime = DateTime.tryParse(a.data()['createdAt'] ?? '') ?? DateTime(0);
                final bTime = DateTime.tryParse(b.data()['createdAt'] ?? '') ?? DateTime(0);
                return bTime.compareTo(aTime);
              });
            
            final msgData = sorted.first.data();
            lastMessage = msgData['content'] ?? 'Новый мэтч! Напишите первым 👋';
            if (msgData['createdAt'] != null) {
              try {
                final msgTime = DateTime.parse(msgData['createdAt']);
                lastTime = _formatTime(msgTime);
              } catch (e) {
                print('⚠️ Error parsing time: $e');
              }
            }
            unreadCount = (msgData['isRead'] == false && msgData['senderId'] != userId) 
                ? 1 
                : 0;
          }
        } catch (e) {
          print('⚠️ Error loading messages: $e');
          // Продолжаем без сообщений
        }
        
        chatsData.add({
          'id': conversationId,
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
        print('✅ Chats loaded: ${_chats.length}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading chats: $e');
      print(stackTrace);
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

  Widget _buildUserAvatar(UserModel user) {
    // Сначала проверяем photoUrl, затем берём первое фото из массива photos
    String? photoUrl = user.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      if (user.photos != null && user.photos!.isNotEmpty) {
        photoUrl = user.photos!.first;
      }
    }
    
    print('🖼️ Avatar photoUrl: ${photoUrl?.substring(0, 50) ?? 'null'}');
    
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Icon(Icons.person, color: Colors.white, size: 28);
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
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28),
          ),
        );
      } catch (e) {
        print('❌ Error decoding base64: $e');
        return const Icon(Icons.person, color: Colors.white, size: 28);
      }
    }
    
    // Обычная URL
    return ClipOval(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 56,
        height: 56,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 28),
      ),
    );
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
                        ),
                        child: _buildUserAvatar(user),
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
