import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/models/user_model.dart';
import 'package:stardust/services/likes_service.dart';
import 'package:stardust/services/auth_service.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final LikesService _likesService = LikesService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<UserModel> _likedByUsers = []; // Кто лайкнул нас
  List<UserModel> _ourLikes = []; // Кого лайкнули мы
  Set<String> _superLikedUserIds = {}; // Кто отправил Super Like
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLikes();
  }

  Future<void> _likeUser(UserModel user) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final isMatch = await _likesService.likeUser(
        fromUserId: userId,
        toUserId: user.id,
      );
      
      // Перезагружаем данные
      await _loadLikes();
      
      if (isMatch && mounted) {
        _showMatchDialog(user);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лайк отправлен!'),
            backgroundColor: AppColors.success,
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
    
  void _skipUser(UserModel user) {
    // Просто ничего не делаем - можно потом лайкнуть
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user.name} пропущен'),
        backgroundColor: AppColors.surfaceLight,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showMatchDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: 60,
            ).animate().scale(duration: 500.ms).then().shake(),
            const SizedBox(height: 16),
            const Text(
              'Это мэтч! 💫',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Вы и ${user.name} лайкнули друг друга!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CosmicButton(
              text: 'Отправить сообщение',
              onPressed: () {
                Navigator.pop(context);
                context.push('/chat/${user.id}?name=${user.name}');
              },
              width: double.infinity,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Позже'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadLikes() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      print('🔍 Loading likes for user: $userId');
      
      // Получаем список ID пользователей, которые нас лайкнули
      final likedByIds = await _likesService.getLikedByUsers(userId);
      
      print('📊 Found ${likedByIds.length} likes from users: $likedByIds');
      
      // Получаем данные этих пользователей
      final likedByUsers = <UserModel>[];
      final superLikedUserIds = <String>{};
      
      for (final id in likedByIds) {
        // Проверяем, есть ли Super Like от этого пользователя
        final superLikeQuery = await _firestore
            .collection('likes')
            .where('fromUserId', isEqualTo: id)
            .where('toUserId', isEqualTo: userId)
            .where('isSuperLike', isEqualTo: true)
            .get();
        
        if (superLikeQuery.docs.isNotEmpty) {
          superLikedUserIds.add(id);
        }
        
        final user = await _authService.getUserData(id);
        if (user != null) {
          likedByUsers.add(user);
          print('✅ Added user: ${user.name}');
        } else {
          print('❌ User data not found for: $id');
        }
      }

      // Получаем наши лайки
      final ourLikeIds = await _likesService.getOurLikes(userId);
      print('👍 Our likes: $ourLikeIds');
      final ourLikes = <UserModel>[];
      for (final id in ourLikeIds) {
        final user = await _authService.getUserData(id);
        if (user != null) {
          ourLikes.add(user);
        }
      }

      // Фильтруем взаимные лайки (те, кого мы лайкнули и они нас)
      final mutualLikes = <UserModel>[];
      for (final user in ourLikes) {
        if (likedByIds.contains(user.id)) {
          mutualLikes.add(user);
        }
      }

      if (mounted) {
        setState(() {
          _likedByUsers = likedByUsers;
          _ourLikes = ourLikes;
          // Сортируем: сначала Super Like, потом взаимные, потом остальные
          _likedByUsers.sort((a, b) {
            final aIsSuperLike = superLikedUserIds.contains(a.id);
            final bIsSuperLike = superLikedUserIds.contains(b.id);
            final aIsMutual = ourLikeIds.contains(a.id);
            final bIsMutual = ourLikeIds.contains(b.id);
            
            // Super Like первыми
            if (aIsSuperLike && !bIsSuperLike) return -1;
            if (!aIsSuperLike && bIsSuperLike) return 1;
            
            // Потом взаимные
            if (aIsMutual && !bIsMutual) return -1;
            if (!aIsMutual && bIsMutual) return 1;
            
            return 0;
          });
          print('📝 Final loaded ${_likedByUsers.length} users, ${mutualLikes.length} mutual');
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading likes: $e');
      print(stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  bool _isMutual(String userId) {
    return _ourLikes.any((u) => u.id == userId);
  }

  @override
  Widget build(BuildContext context) {
    final mutualCount = _likedByUsers.where((u) => _isMutual(u.id)).length;

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
                        'Лайки',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$mutualCount взаимных',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),
                
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_likedByUsers.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Пока нет лайков',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Лайкайте анкеты, чтобы получить взаимность',
                            style: TextStyle(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Взаимные лайки
                  if (mutualCount > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$mutualCount взаимных лайков!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Откройте чат и начните общение',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
                    const SizedBox(height: 16),
                  ],
                  
                  // Список
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadLikes,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _likedByUsers.length,
                        itemBuilder: (context, index) {
                          final user = _likedByUsers[index];
                          return _buildLikeItem(context, user, index);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    // Сначала проверяем photoUrl, затем берём первое фото из массива photos
    String? photoUrl = user.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      if (user.photos != null && user.photos!.isNotEmpty) {
        photoUrl = user.photos!.first;
      }
    }
    
    if (photoUrl == null || photoUrl.isEmpty) {
      return const Icon(Icons.person, color: Colors.white, size: 30);
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
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 30),
          ),
        );
      } catch (e) {
        return const Icon(Icons.person, color: Colors.white, size: 30);
      }
    }
    
    // Обычная URL
    return ClipOval(
      child: Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildLikeItem(BuildContext context, UserModel user, int index) {
    final isMutual = _isMutual(user.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isMutual
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Фото
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: _buildUserAvatar(user),
                    ),
                    if (isMutual)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
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
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.age}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isMutual) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Взаимно',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (user.location != null)
                            Text(
                              user.location!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Кнопка
                if (isMutual)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.push('/chat/${user.id}?name=${user.name}');
                      },
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => _skipUser(user),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => _likeUser(user),
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }
}
