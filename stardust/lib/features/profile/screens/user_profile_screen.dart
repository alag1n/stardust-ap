import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/models/user_model.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/likes_service.dart';
import 'package:stardust/services/block_service.dart';
import 'package:stardust/services/report_service.dart';
import 'package:stardust/utils/image_proxy.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? photoUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
    this.photoUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  final LikesService _likesService = LikesService();
  final BlockService _blockService = BlockService();
  final ReportService _reportService = ReportService();
  
  UserModel? _user;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getUserData(widget.userId);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUserId != null) {
        _isLiked = await _likesService.isLiked(currentUserId, widget.userId);
        _isMatch = await _likesService.isMatch(currentUserId, widget.userId);
      }
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLike() async {
    if (_isLiked) return;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final isMatch = await _likesService.likeUser(
        fromUserId: currentUserId,
        toUserId: widget.userId,
      );

      setState(() {
        _isLiked = true;
        _isMatch = isMatch;
      });

      if (isMatch && mounted) {
        _showMatchDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showMatchDialog() {
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
              'Вы и ${_user?.name} лайкнули друг друга!',
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
                context.push('/chat/${widget.userId}?name=${_user?.name}&userId=${widget.userId}');
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

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.block, color: AppColors.error),
            SizedBox(width: 8),
            Text('Заблокировать', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Вы уверены, что хотите заблокировать ${_user?.name ?? 'этого пользователя'}? '
          'Вы больше не будете видеть друг друга.',
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
              await _blockUser();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _blockService.blockUser(
        blockerId: currentUserId,
        blockedId: widget.userId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пользователь заблокирован'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showReportDialog() {
    String selectedReason = ReportReason.spam;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.flag, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Пожаловаться', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Причина жалобы:',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                ...ReportReason.all.map((reason) => RadioListTile<String>(
                  title: Text(
                    ReportReason.getLabel(reason),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() => selectedReason = value!);
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Дополнительные детали (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _submitReport(selectedReason, descriptionController.text);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason, String description) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _reportService.reportUser(
        reporterId: currentUserId,
        reportedId: widget.userId,
        reason: reason,
        description: description.isNotEmpty ? description : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Жалоба отправлена. Спасибо за помощь!'),
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

  String _formatOnlineStatus(DateTime? lastActive) {
    if (lastActive == null) return 'Неизвестно';
    
    final now = DateTime.now();
    final diff = now.difference(lastActive);
    
    if (diff.inMinutes < 1) return 'Онлайн';
    if (diff.inMinutes < 60) return 'Был(а) ${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return 'Был(а) ${diff.inHours} ч назад';
    if (diff.inDays < 7) return 'Был(а) ${diff.inDays} дн назад';
    
    return 'Был(а) давно';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final name = user?.name ?? widget.userName ?? 'Пользователь';
    final photoUrl = user?.photoUrl ?? widget.photoUrl;

    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Фото
                      SliverToBoxAdapter(
                        child: _buildPhotoSection(photoUrl),
                      ),
                      // Информация
                      SliverToBoxAdapter(
                        child: _buildInfoSection(user, name),
                      ),
                      // О себе
                      if (user?.bio != null && user!.bio!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildBioSection(user.bio!),
                        ),
                      // Интересы
                      if (user?.interestedIn != null && user!.interestedIn!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildInterestsSection(user.interestedIn!.split(', ')),
                        ),
                      // Кнопки действий
                      SliverToBoxAdapter(
                        child: _buildActionsSection(),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
          ),
          // Кнопка назад и меню
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: AppColors.surface,
                    onSelected: (value) {
                      switch (value) {
                        case 'block':
                          _showBlockDialog();
                          break;
                        case 'report':
                          _showReportDialog();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: AppColors.error, size: 20),
                            SizedBox(width: 12),
                            Text('Заблокировать', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: AppColors.warning, size: 20),
                            SizedBox(width: 12),
                            Text('Пожаловаться', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String? photoUrl) {
    final allPhotos = [
      if (photoUrl != null) photoUrl,
      ...?(_user?.photos),
    ];
    
    // Convert to proxy URLs
    final proxyPhotos = allPhotos.map((url) => ImageProxy.getProxyUrl(url) ?? url).toList();
    
    if (proxyPhotos.isEmpty) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: _buildPlaceholder(),
      );
    }
    
    if (proxyPhotos.length == 1) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(proxyPhotos[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Карусель с индикаторами
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: proxyPhotos.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(proxyPhotos[index], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()),
                  // Индикаторы
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(proxyPhotos.length, (i) => Container(
                        width: i == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ),
                ],
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.accent.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 120,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildInfoSection(UserModel? user, String name) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${name}${user != null && user.age > 0 ? ', ${user.age}' : ''}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (user?.isPremium == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
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
          const SizedBox(height: 8),
          // Онлайн статус
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isOnline(user?.lastActive) ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatOnlineStatus(user?.lastActive),
                style: TextStyle(
                  color: _isOnline(user?.lastActive) ? AppColors.success : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              if (user?.location != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  user!.location!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  bool _isOnline(DateTime? lastActive) {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive).inMinutes < 5;
  }

  Widget _buildBioSection(String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'О себе',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildInterestsSection(List<String> interests) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Интересы',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  interest.trim(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Дизлайк
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Лайк
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _isLiked 
                    ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isLiked ? null : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isLiked ? null : _handleLike,
                icon: Icon(
                  _isMatch ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
