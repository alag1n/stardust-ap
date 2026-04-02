import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          '1. Общие положения',
                          'Настоящие правила регулируют использование приложения Stardust. Используя приложение, вы соглашаетесь с этими правилами.',
                        ),
                        _buildSection(
                          '2. Требования к пользователям',
                          '• Вам должно быть не менее 18 лет\n'
                          '• Вы должны предоставлять достоверную информацию\n'
                          '• Вы несете ответственность за безопасность своего аккаунта\n'
                          '• Один пользователь — один аккаунт',
                        ),
                        _buildSection(
                          '3. Запрещённый контент',
                          'Запрещено размещать:\n'
                          '• Контент сексуального характера\n'
                          '• Оскорбительные и дискриминационные материалы\n'
                          '• Спам и рекламные материалы\n'
                          '• Контент, нарушающий авторские права\n'
                          '• Ложную или вводящую в заблуждение информацию',
                        ),
                        _buildSection(
                          '4. Поведение пользователей',
                          'Мы ожидаем от всех пользователей:\n'
                          '• Уважительного отношения к другим\n'
                          '• Честности в общении\n'
                          '• Соблюдения границ и согласия\n'
                          '• Немедленного сообщения о нарушениях',
                        ),
                        _buildSection(
                          '5. Конфиденциальность',
                          'Мы заботимся о вашей приватности:\n'
                          '• Ваши данные хранятся в зашифрованном виде\n'
                          '• Вы контролируете видимость профиля\n'
                          '• Мы не передаём данные третьим лицам\n'
                          '• Вы можете удалить аккаунт в любое время',
                        ),
                        _buildSection(
                          '6. Модерация',
                          'Мы оставляем за собой право:\n'
                          '• Удалять контент, нарушающий правила\n'
                          '• Блокировать аккаунты нарушителей\n'
                          '• Ограничивать доступ к приложению\n'
                          '• Изменять правила без предварительного уведомления',
                        ),
                        _buildSection(
                          '7. Ответственность',
                          'Stardust не несёт ответственности за:\n'
                          '• Действия третьих лиц\n'
                          '• Качество общения между пользователями\n'
                          '• Личные встречи пользователей\n'
                          '• Контент, размещаемый пользователями',
                        ),
                        _buildSection(
                          '8. Контактная информация',
                          'По всем вопросам обращайтесь:\n'
                          'Email: support@stardust.app\n'
                          'Служба поддержки работает 24/7',
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Последнее обновление: Январь 2024',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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
              'Правила площадки',
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

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
