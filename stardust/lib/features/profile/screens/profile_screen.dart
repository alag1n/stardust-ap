import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/services/auth_service.dart';
import 'package:stardust/services/image_upload_service.dart';
import 'package:stardust/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _imageService = ImageUploadService();
  UserModel? _user;
  bool _isLoading = true;
  bool _isVisible = true;
  bool _isTogglingVisibility = false;
  bool _isUploadingPhoto = false;
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final user = await _authService.getUserData(userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isVisible = user?.isVisible ?? true;
          _photos = user?.photos ?? [];
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isTogglingVisibility = true);

    try {
      final newVisibility = await _authService.toggleProfileVisibility(userId);
      if (mounted) {
        setState(() => _isVisible = newVisibility);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newVisibility 
                ? 'Ваша анкета теперь видна в поиске' 
                : 'Ваша анкета скрыта от поиска',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка изменения видимости')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingVisibility = false);
      }
    }
  }

  void _showAddPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(fromCamera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    if (_photos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Максимум 6 фото')),
      );
      return;
    }
    
    setState(() => _isUploadingPhoto = true);
    
    try {
      final file = fromCamera 
          ? await _imageService.pickFromCamera()
          : await _imageService.pickFromGallery();
      
      if (file.isNotEmpty) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          final url = await _imageService.uploadImage(
            file: file[0],
            userId: userId,
            folder: 'photos',
          );
          
          if (mounted) {
            setState(() {
              _photos.add(url);
            });
            
            // Сохраняем фото в Firebase
            await _authService.updateUserData(userId, {'photos': _photos});
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Фото добавлено')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _removePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Удалить фото'),
        content: const Text('Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                setState(() {
                  _photos.removeAt(index);
                });
                await _authService.updateUserData(userId, {'photos': _photos});
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock данные пользователя (пока нет данных из Firestore)
    final user = <String, dynamic>{
      'name': _user?.name ?? 'Пользователь',
      'age': _user?.age ?? 25,
      'city': _user?.location ?? 'Город',
      'bio': _user?.bio ?? 'Расскажите о себе',
      'photo': _user?.photoUrl ?? '',
      'interests': _user?.interests ?? <String>['Космос', 'Астрономия', 'Музыка', 'Путешествия', 'Фотография'],
      'likesCount': _user?.likesCount ?? 0,
      'matchesCount': _user?.matchesCount ?? 0,
    };

    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // Хедер профиля
                      SliverToBoxAdapter(
                        child: _buildHeader(context),
                      ),
                      // Статистика
                      SliverToBoxAdapter(
                        child: _buildStats(user),
                      ),
                      // О себе
                      SliverToBoxAdapter(
                        child: _buildBioSection(user['bio']),
                      ),
                      // Интересы
                      SliverToBoxAdapter(
                        child: _buildInterestsSection(user['interests'] as List<String>),
                      ),
                      // Фотогалерея
                      SliverToBoxAdapter(
                        child: _buildPhotosSection(),
                      ),
                      // Настройки профиля
                      SliverToBoxAdapter(
                        child: _buildSettingsSection(context),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final userName = _user?.name ?? 'Пользователь';
    final userAge = _user?.age ?? 25;
    final userCity = _user?.location ?? 'Город';
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Профиль',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Аватар
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _photos.isNotEmpty
                      ? _buildMainPhoto(_photos.first)
                      : Container(
                          width: 114,
                          height: 114,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 3,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().scale(),
          const SizedBox(height: 16),
          // Имя и город
          Text(
            '$userName, $userAge',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                userCity,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Лайков', '${user['likesCount']}'),
            _buildDivider(),
            _buildStatItem('Суперлайков', '0'),
            _buildDivider(),
            _buildStatItem('Matches', '${user['matchesCount']}'),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.surfaceLight,
    );
  }

  Widget _buildBioSection(String bio) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1);
  }

  Widget _buildInterestsSection(List<String> interests) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildPhotosSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фотогалерея',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: _photos.isEmpty && _isUploadingPhoto
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _photos.length) {
                        return _buildAddPhotoButton();
                      }
                      return _buildPhotoItem(index);
                    },
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1);
  }

  Widget _buildPhotoItem(int index) {
    final photoUrl = _photos[index];
    final isMainPhoto = index == 0; // Первое фото - главное
    
    return GestureDetector(
      onTap: () => _showPhotoViewer(index),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surfaceLight,
              border: isMainPhoto
                  ? Border.all(color: AppColors.primary, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  _buildPhotoImage(photoUrl),
                  if (isMainPhoto)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Главное',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showPhotoOptions(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMainPhoto ? Icons.star : Icons.more_vert,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(String photoUrl) {
    return _buildMainPhoto(photoUrl);
  }

  Widget _buildMainPhoto(String photoUrl) {
    // Проверка на base64
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Part = photoUrl.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
        );
      } catch (e) {
        return _buildPlaceholderAvatar();
      }
    }
    
    // Обычная URL
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 114,
      height: 114,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  void _showPhotoOptions(int index) {
    final isMainPhoto = index == 0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMainPhoto)
                ListTile(
                  leading: const Icon(Icons.star, color: AppColors.primary),
                  title: const Text('Сделать главным фото'),
                  onTap: () {
                    Navigator.pop(context);
                    _setMainPhoto(index);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: AppColors.accent),
                title: const Text('Просмотр'),
                onTap: () {
                  Navigator.pop(context);
                  _showPhotoViewer(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setMainPhoto(int index) async {
    if (index == 0) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    setState(() {
      final mainPhoto = _photos[index];
      _photos.removeAt(index);
      _photos.insert(0, mainPhoto);
    });
    
    await _authService.updateUserData(userId, {'photos': _photos});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото установлено как главное')),
      );
    }
  }

  void _showPhotoViewer(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _photos[index],
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _showAddPhotoOptions,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _photos.length >= 6 ? AppColors.surfaceLight : AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _isUploadingPhoto
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _photos.length >= 6 ? Icons.lock : Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: _photos.length >= 6 ? AppColors.textMuted : AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _photos.length >= 6 ? 'Максимум' : 'Добавить',
                    style: TextStyle(
                      fontSize: 12,
                      color: _photos.length >= 6 ? AppColors.textMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Настройки профиля',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Переключатель видимости анкеты
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isVisible 
                    ? Colors.green.withValues(alpha: 0.15) 
                    : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isVisible ? Icons.visibility : Icons.visibility_off,
                  color: _isVisible ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              title: Text(
                _isVisible ? 'Анкета активна' : 'Анкета скрыта',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                _isVisible 
                  ? 'Вашу анкету видят другие пользователи' 
                  : 'Ваша анкета не показывается в поиске',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              trailing: _isTogglingVisibility
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _isVisible,
                      onChanged: (_) => _toggleVisibility(),
                      activeColor: Colors.green,
                    ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 550.ms),
          _buildSettingsTile(
            icon: Icons.visibility_outlined,
            title: 'Настройка карточки',
            subtitle: 'Что видят другие пользователи',
            onTap: () => context.push('/card-settings'),
          ),
          _buildSettingsTile(
            icon: Icons.tune,
            title: 'Предпочтения поиска',
            subtitle: 'Кого вы ищете',
            onTap: () => context.push('/search-preferences'),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            subtitle: 'Настройка уведомлений',
            onTap: () => context.push('/notifications'),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Приватность',
            subtitle: 'Управление доступом',
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: 16),
          // Кнопка выхода
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Выйти из аккаунта',
            subtitle: 'Завершить сессию',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? Colors.red : AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.withValues(alpha: 0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: Icon(
          isDestructive ? Icons.logout : Icons.chevron_right,
          color: isDestructive ? Colors.red : AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
