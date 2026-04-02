import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/features/settings/screens/notification_settings_screen.dart';
import 'package:stardust/features/settings/screens/privacy_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                // Настройки
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Аккаунт'),
                        _buildSettingsTile(
                          icon: Icons.person_outline,
                          title: 'Личные данные',
                          subtitle: 'Имя, email, телефон',
                          onTap: () => context.push('/edit-profile'),
                          index: 0,
                        ),
                        _buildSettingsTile(
                          icon: Icons.credit_card_outlined,
                          title: 'Подписка',
                          subtitle: 'Stardust Premium',
                          onTap: () => context.push('/premium'),
                          isPremium: true,
                          index: 1,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Приложение'),
                        _buildSettingsTile(
                          icon: Icons.tune,
                          title: 'Предпочтения поиска',
                          subtitle: 'Пол, возраст, расстояние',
                          onTap: () => context.push('/search-preferences'),
                          index: 2,
                        ),
                        _buildSettingsTile(
                          icon: Icons.visibility_outlined,
                          title: 'Настройка карточки',
                          subtitle: 'Что видят другие',
                          onTap: () => context.push('/card-settings'),
                          index: 3,
                        ),
                        _buildSettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Уведомления',
                          subtitle: 'Push-уведомления, email',
                          onTap: () => context.push('/notifications'),
                          index: 4,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Безопасность'),
                        _buildSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Приватность',
                          subtitle: 'Кто видит ваш профиль',
                          onTap: () => context.push('/privacy'),
                          index: 5,
                        ),
                        _buildSettingsTile(
                          icon: Icons.lock_outline,
                          title: 'Изменить пароль',
                          subtitle: 'Обезопасить аккаунт',
                          onTap: () => _showChangePasswordDialog(context),
                          index: 6,
                        ),
                        _buildSettingsTile(
                          icon: Icons.login_outlined,
                          title: 'Вход через соцсети',
                          subtitle: 'Google, Apple, Facebook',
                          onTap: () => _showSocialLoginInfo(context),
                          index: 7,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('О приложении'),
                        _buildSettingsTile(
                          icon: Icons.help_outline,
                          title: 'Помощь',
                          subtitle: 'FAQ и поддержка',
                          onTap: () => context.push('/about'),
                          index: 8,
                        ),
                        _buildSettingsTile(
                          icon: Icons.description_outlined,
                          title: 'Правила',
                          subtitle: 'Правила площадки',
                          onTap: () => context.push('/rules'),
                          index: 9,
                        ),
                        _buildSettingsTile(
                          icon: Icons.policy_outlined,
                          title: 'Политика конфиденциальности',
                          subtitle: 'Как мы обрабатываем данные',
                          onTap: () => context.push('/privacy'),
                          index: 10,
                        ),
                        _buildSettingsTile(
                          icon: Icons.info_outline,
                          title: 'О приложении',
                          subtitle: 'Версия 1.0.0',
                          onTap: () => context.push('/about'),
                          index: 11,
                        ),
                        const SizedBox(height: 24),
                        // Кнопка выхода
                        _buildLogoutButton(context),
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

  void _showPremiumInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.star, color: AppColors.accent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Stardust Premium',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Получите безлимитные лайки, суперлайки и возможность находиться в топе!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            _buildPremiumFeature('✨', 'Безлимитные лайки'),
            _buildPremiumFeature('⭐', '5 суперлайков в день'),
            _buildPremiumFeature('📍', 'Изменение локации'),
            _buildPremiumFeature('🔒', 'Невидимый режим'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Скоро доступно'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Изменение пароля', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите email, указанный при регистрации. Мы отправим вам ссылку для сброса пароля.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Ваш email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              // Здесь будет логика отправки письма для сброса пароля
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ссылка для сброса пароля отправлена на email'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showSocialLoginInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Вход через соцсети',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Скоро вы сможете входить в приложение через Google, Apple и Facebook.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(Icons.g_mobiledata, 'Google'),
                _buildSocialButton(Icons.apple, 'Apple'),
                _buildSocialButton(Icons.facebook, 'Facebook'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Expanded(
            child: Text(
              'Настройки',
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPremium = false,
    required int index,
  }) {
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
            color: isPremium
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isPremium ? AppColors.accent : AppColors.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: -0.1);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Выход'),
              content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Выйти'),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Выйти из аккаунта'),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
