import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/services/discovery_service.dart';
import 'package:stardust/services/block_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final BlockService _blockService = BlockService();
  
  bool _isLoading = true;
  bool _isVisible = true;
  bool _showOnlineStatus = true;
  bool _showDistance = true;
  int _likesCount = 0;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // В реальном приложении получить ID текущего пользователя
    const userId = 'test_user';
    
    final prefs = await _discoveryService.getUserPreferences(userId);
    final blockedUsers = await _blockService.getBlockedUsers(userId);
    
    setState(() {
      _isVisible = prefs?['isVisible'] ?? true;
      _likesCount = prefs?['likesCount'] ?? 0;
      _blockedUsers = blockedUsers;
      _isLoading = false;
    });
  }

  Future<void> _toggleVisibility(bool value) async {
    const userId = 'test_user';
    await _discoveryService.updateUserPreferences(userId, preferredGender: value ? 'all' : 'none');
    setState(() => _isVisible = value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
              ? 'Теперь вас видят в поиске' 
              : 'Ваш профиль скрыт от поиска'),
          backgroundColor: AppColors.success,
        ),
      );
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Видимость профиля'),
                              _buildSwitchTile(
                                title: 'Показывать в поиске',
                                subtitle: 'Разрешить другим пользователям находить вас',
                                value: _isVisible,
                                onChanged: _toggleVisibility,
                                index: 0,
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Информация о вас'),
                              _buildInfoTile(
                                title: 'Показывать расстояние',
                                subtitle: 'Другие видят, как далеко вы находитесь',
                                trailing: Switch(
                                  value: _showDistance,
                                  onChanged: (v) => setState(() => _showDistance = v),
                                  activeColor: AppColors.primary,
                                ),
                                index: 1,
                              ),
                              _buildInfoTile(
                                title: 'Показывать онлайн-статус',
                                subtitle: 'Видеть, когда пользователи были в сети',
                                trailing: Switch(
                                  value: _showOnlineStatus,
                                  onChanged: (v) => setState(() => _showOnlineStatus = v),
                                  activeColor: AppColors.primary,
                                ),
                                index: 2,
                              ),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Заблокированные пользователи'),
                              _buildBlockedUsersSection(),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Опасная зона'),
                              _buildDangerTile(
                                title: 'Удалить аккаунт',
                                subtitle: 'Удалить профиль и все данные безвозвратно',
                                icon: Icons.delete_forever,
                                onTap: () => _showDeleteAccountDialog(context),
                                index: 3,
                              ),
                              const SizedBox(height: 32),
                            ],
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

  Widget _buildHeader(BuildContext context) {
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
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Expanded(
            child: Text(
              'Приватность',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: -0.1);
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: -0.1);
  }

  Widget _buildDangerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.error, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: -0.1);
  }

  Widget _buildBlockedUsersSection() {
    if (_blockedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.block, color: AppColors.textMuted, size: 40),
              SizedBox(height: 8),
              Text(
                'Заблокированных пользователей нет',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          '${_blockedUsers.length} пользователей заблокировано',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_blockedUsers.length, (index) {
          final user = _blockedUsers[index];
          final userData = user['data'] as Map<String, dynamic>?;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                backgroundImage: userData?['photoUrl'] != null
                    ? NetworkImage(userData!['photoUrl'])
                    : null,
                child: userData?['photoUrl'] == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(
                userData?['name'] ?? 'Пользователь',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: TextButton(
                onPressed: () => _unblockUser(user['id']),
                child: const Text('Разблокировать'),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index));
        }),
      ],
    );
  }

  Future<void> _unblockUser(String userId) async {
    const currentUserId = 'test_user';
    await _blockService.unblockUser(blockerId: currentUserId, blockedId: userId);
    _loadSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пользователь разблокирован'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Удаление аккаунта', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Вы уверены, что хотите удалить аккаунт? '
          'Это действие нельзя отменить. Все ваши данные, матчи и сообщения будут удалены.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Введите пароль', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Пароль',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // Здесь должна быть логика удаления аккаунта
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Аккаунт удалён'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
