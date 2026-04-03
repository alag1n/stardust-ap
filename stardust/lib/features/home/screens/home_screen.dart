import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/models/user_model.dart';
import 'package:stardust/services/discovery_service.dart';
import 'package:stardust/services/likes_service.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/report_service.dart';
import 'package:stardust/utils/image_proxy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController _cardController = CardSwiperController();
  final DiscoveryService _discoveryService = DiscoveryService();
  final LikesService _likesService = LikesService();
  final AuthService _authService = AuthService();
  
  List<UserModel> _profiles = [];
  Set<String> _likedUserIds = {};
  Set<String> _superLikedUserIds = {}; // ID пользователей, которым отправлен Super Like
  bool _isLoading = true;
  bool _isSwiping = false;

  // Фильтры
  RangeValues _ageRange = const RangeValues(18, 45);
  double _distance = 50;
  bool _showFilters = false;
  String _interestedIn = 'all'; // all, male, female

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Получаем настройки поиска пользователя
      final prefs = await _discoveryService.getUserPreferences(userId);
      
      // Получаем координаты пользователя
      double? userLat;
      double? userLng;
      if (prefs != null && prefs['latitude'] != null) {
        userLat = prefs['latitude']?.toDouble();
        userLng = prefs['longitude']?.toDouble();
      }

      // Получаем список уже лайкнутых пользователей
      final likedIds = await _likesService.getOurLikes(userId);
      _likedUserIds = Set<String>.from(likedIds);

      // Получаем список Super Like
      final superLikedIds = await _likesService.getSuperLikes(userId);
      _superLikedUserIds = Set<String>.from(superLikedIds);

      // Получаем пользователей для свайпов с учётом настроек
      final users = await _discoveryService.getDiscoveryUsers(
        currentUserId: userId,
        likedUserIds: _likedUserIds.toList(),
        limit: 20,
        gender: prefs?['preferredGender'] ?? 'all',
        ageMin: prefs?['preferredAgeMin'] ?? 18,
        ageMax: prefs?['preferredAgeMax'] ?? 45,
        maxDistanceKm: prefs?['preferredDistance']?.toDouble(),
        userLatitude: userLat,
        userLongitude: userLng,
      );

      if (mounted) {
        setState(() {
          _profiles = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (_isSwiping || previousIndex >= _profiles.length) return false;
    
    setState(() => _isSwiping = true);
    
    final profile = _profiles[previousIndex];
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      setState(() => _isSwiping = false);
      return false;
    }

    if (direction == CardSwiperDirection.right) {
      // Лайк
      try {
        final isMatch = await _likesService.likeUser(
          fromUserId: userId,
          toUserId: profile.id,
        );
        
        _likedUserIds.add(profile.id);
        
        if (isMatch && mounted) {
          _showMatchDialog(profile);
        }
      } catch (e) {
        // Ошибка при лайке
      }
    } else if (direction == CardSwiperDirection.left) {
      // Дизлайк — просто пропускаем
    } else if (direction == CardSwiperDirection.top) {
      // Суперлайк - только для Premium
      try {
        final isMatch = await _likesService.likeUser(
          fromUserId: userId,
          toUserId: profile.id,
          isSuperLike: true,
        );
        
        _likedUserIds.add(profile.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Суперлайк отправлен! ⭐'),
              backgroundColor: AppColors.accent,
            ),
          );
          _showMatchDialog(profile);
        }
      } catch (e) {
        if (mounted) {
          String message = 'Ошибка отправки';
          if (e.toString().contains('Превышен лимит')) {
            message = 'Лимит Super Like исчерпан (3 в день)';
          } else if (e.toString().contains('недоступно')) {
            message = 'Super Like доступен для Premium';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    }

    setState(() => _isSwiping = false);
    return true;
  }

  void _showMatchDialog(UserModel profile) {
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
              'Вы и ${profile.name} лайкнули друг друга!',
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
                // Переход в чат
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

  Future<void> _applyFilters() async {
    setState(() {
      _showFilters = false;
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      List<UserModel> users;
      
      if (_interestedIn == 'all') {
        users = await _discoveryService.getDiscoveryUsers(
          currentUserId: userId,
          likedUserIds: _likedUserIds.toList(),
          limit: 20,
        );
      } else {
        users = await _discoveryService.getRecommendedUsers(
          currentUserId: userId,
          gender: _interestedIn,
          ageMin: _ageRange.start.round(),
          ageMax: _ageRange.end.round(),
          likedUserIds: _likedUserIds.toList(),
          limit: 20,
        );
      }

      if (mounted) {
        setState(() {
          _profiles = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
                _buildHeader(context),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _profiles.isEmpty
                              ? _buildEmptyState()
                              : _buildSwiper(),
                    ),
                  ),
                ),
                if (!_isLoading && _profiles.isNotEmpty) _buildActionButtons(),
              ],
            ),
          ),
          if (_showFilters) _buildFiltersOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Image(
                  image: AssetImage('assets/stardust_icon.png'),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stardust',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(
                  Icons.tune,
                  color: _showFilters ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSwiper() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CardSwiper(
        controller: _cardController,
        cardsCount: _profiles.length,
        numberOfCardsDisplayed: _profiles.length > 2 ? 3 : _profiles.length,
        backCardOffset: const Offset(0, 40),
        padding: EdgeInsets.zero,
        onSwipe: _onSwipe,
        onUndo: _onUndo,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          if (index >= _profiles.length) return const SizedBox();
          final profile = _profiles[index];
          final isSuperLiked = _superLikedUserIds.contains(profile.id);
          return _buildProfileCard(profile, isSuperLiked: isSuperLiked);
        },
      ),
    );
  }

  Widget _buildProfileCard(UserModel profile, {bool isSuperLiked = false}) {
    final interests = profile.interestedIn?.split(', ') ?? [];
    final allPhotos = [
      if (profile.photoUrl != null) profile.photoUrl!,
      ...profile.photos,
    ];
    
    final bool isPremium = profile.isPremium;
    
    // Золотая подсветка для Premium, фиолетовая для обычных
    final Color glowColor = isPremium 
        ? AppColors.superLikeGold 
        : AppColors.premiumPurple;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: 60,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Контент карточки
            Positioned.fill(
              child: allPhotos.length > 1
                  ? _buildCarouselCard(profile, allPhotos, interests)
                  : _buildSinglePhotoCard(profile, interests),
            ),
            // Бейдж Premium
            if (isPremium)
              Positioned(
                top: 16,
                left: 16,
                child: _buildPremiumBadge(),
              ),
            // Бейдж Super Like (если пользователь отправил суперлайк)
            if (isSuperLiked)
              Positioned(
                top: 16,
                right: 16,
                child: _buildSuperLikeBadge(),
              ),
          ],
        ),
      ),
    ).animate(onPlay: (controller) {
      controller.repeat(reverse: true);
    }).custom(
      duration: 2000.ms,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.3 + (value * 0.3)),
                blurRadius: 30 + (value * 20),
                spreadRadius: 2 + (value * 3),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumPurple.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildSuperLikeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.superLikeGold.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Super Like',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildSinglePhotoCard(UserModel profile, List<String> interests) {
    final photoUrl = ImageProxy.getProxyUrl(profile.photoUrl);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Фото
        photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(),
              )
            : _buildPlaceholderPhoto(),
        // Градиент
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Кнопка жалобы
        Positioned(
          top: MediaQuery.of(context).padding.top + 50,
          right: 16,
          child: _buildReportButton(profile),
        ),
        // Информация
        _buildProfileInfo(profile, interests),
      ],
    );
  }

  Widget _buildCarouselCard(UserModel profile, List<String> allPhotos, List<String> interests) {
    final PageController pageController = PageController();
    
    // Convert to proxy URLs
    final proxyPhotos = allPhotos.map((url) => ImageProxy.getProxyUrl(url) ?? url).toList();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Карусель фото
        PageView.builder(
          controller: pageController,
          itemCount: proxyPhotos.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  proxyPhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(),
                ),
                // Индикаторы страниц
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(proxyPhotos.length, (i) {
                      return Container(
                        width: i == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == index 
                              ? Colors.white 
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
        // Градиент
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        // Кнопка жалобы
        Positioned(
          top: MediaQuery.of(context).padding.top + 50,
          right: 16,
          child: _buildReportButton(profile),
        ),
        // Информация
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${profile.name}, ${profile.age}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (profile.location != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(profile.location!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              if (profile.bio != null) ...[
                const SizedBox(height: 8),
                Text(profile.bio!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: interests.take(4).map((i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(i.trim(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                )).toList()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(UserModel profile, List<String> interests) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.name}, ${profile.age}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (profile.location != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(profile.location!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: interests.take(4).map((i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(i.trim(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            )).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderPhoto() {
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

  Widget _buildReportButton(UserModel profile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReportDialog(profile),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showReportDialog(UserModel profile) {
    String selectedReason = ReportReason.spam;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.flag, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'Пожаловаться',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Вы собираетесь пожаловаться на ${profile.name}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Причина:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...ReportReason.all.map((reason) => RadioListTile<String>(
                title: Text(
                  ReportReason.getLabel(reason),
                  style: const TextStyle(color: AppColors.textPrimary),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _submitReport(profile.id, selectedReason);
                        // Свайп влево после жалобы
                        _cardController.swipe(CardSwiperDirection.left);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Отправить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport(String userId, String reason) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final reportService = ReportService();
    
    try {
      await reportService.reportUser(
        reporterId: currentUserId,
        reportedId: userId,
        reason: reason,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Жалоба отправлена. Спасибо!'),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Дизлайк
          CosmicIconButton(
            icon: Icons.close,
            onPressed: () => _cardController.swipe(CardSwiperDirection.left),
            color: AppColors.error,
            size: 60,
          ),
          // Суперлайк
          CosmicIconButton(
            icon: Icons.star,
            onPressed: () => _cardController.swipe(CardSwiperDirection.top),
            color: AppColors.accent,
            size: 50,
          ),
          // Лайк
          CosmicIconButton(
            icon: Icons.favorite,
            onPressed: () => _cardController.swipe(CardSwiperDirection.right),
            color: AppColors.success,
            size: 60,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('assets/stardust_icon.png'),
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'Новые анкеты',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Возвращайтесь позже',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CosmicButton(
            text: 'Расширить поиск',
            onPressed: () {},
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showFilters = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Фильтры',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _showFilters = false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Пол
                  const Text(
                    'Кого ищете',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderFilterChip('all', 'Все'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGenderFilterChip('female', 'Девушки'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildGenderFilterChip('male', 'Мужчины'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Возраст
                  const Text(
                    'Возраст',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 65,
                    divisions: 47,
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setState(() => _ageRange = values);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  // Расстояние
                  const Text(
                    'Расстояние',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: _distance,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: '${_distance.round()} км',
                    onChanged: (value) {
                      setState(() => _distance = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  CosmicButton(
                    text: 'Применить',
                    onPressed: _applyFilters,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderFilterChip(String value, String label) {
    final isSelected = _interestedIn == value;
    return GestureDetector(
      onTap: () => setState(() => _interestedIn = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    return true;
  }
}
