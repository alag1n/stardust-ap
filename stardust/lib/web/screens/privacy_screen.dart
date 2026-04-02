import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                          '1. Введение',
                          'Мы в Stardust серьёзно относимся к конфиденциальности и защите ваших персональных данных. Эта политика объясняет, как мы собираем, используем и защищаем вашу информацию.',
                        ),
                        _buildSection(
                          '2. Какие данные мы собираем',
                          '''
Мы собираем следующие данные:

**Личные данные:**
• Имя и фамилия
• Дата рождения
• Email и телефон
• Геолокация
• Фотографии профиля
• Информация о себе

**Технические данные:**
• IP-адрес
• Тип устройства и ОС
• История использования приложения
• Куки и аналогичные технологии
''',
                        ),
                        _buildSection(
                          '3. Как мы используем данные',
                          '''
Ваши данные используются для:

• Предоставления услуг приложения
• Подбора анкет по вашим предпочтениям
• Улучшения качества сервиса
• Обеспечения безопасности
• Коммуникации с пользователями
• Аналитики и статистики

Мы НЕ продаём ваши персональные данные третьим лицам.
''',
                        ),
                        _buildSection(
                          '4. Защита данных',
                          '''
Мы применяем следующие меры защиты:

• Шифрование данных (SSL/TLS)
• Хранение паролей в хэшированном виде
• Регулярные аудиты безопасности
• Ограниченный доступ к данным
• Двухфакторная аутентификация
• Защита от несанкционированного доступа
''',
                        ),
                        _buildSection(
                          '5. Ваши права',
                          '''
Вы имеете право на:

• **Доступ** - получить копию ваших данных
• **Исправление** - исправить неточные данные
• **Удаление** - удалить ваш аккаунт
• **Ограничение** - ограничить обработку
• **Перенос** - получить данные в удобном формате
• **Отзыв согласия** - в любое время

Для реализации прав обращайтесь: privacy@stardust.app
''',
                        ),
                        _buildSection(
                          '6. Cookies и технологии отслеживания',
                          '''
Мы используем:

• **Необходимые cookies** - для работы приложения
• **Функциональные cookies** - для запоминания настроек
• **Аналитические cookies** - для улучшения сервиса
• **Рекламные cookies** - для персонализации (только с согласия)

Вы можете отключить cookies в настройках браузера.
''',
                        ),
                        _buildSection(
                          '7. Передача данных',
                          '''
Ваши данные могут передаваться:
• При регистрации в другой стране
• Партнёрам для обработки (соглашение о конфиденциальности)
• По требованию закона

Мы обеспечиваем защиту при любой передаче данных.
''',
                        ),
                        _buildSection(
                          '8. Срок хранения',
                          '''
• Активный аккаунт - пока вы не удалите
• После удаления - 30 дней для восстановления
• Логи входа - 12 месяцев
• Аналитика - 24 месяца (анонимизированная)

По истечении срока данные удаляются безвозвратно.
''',
                        ),
                        _buildSection(
                          '9. Контакты',
                          '''
**Stardust LLC**
Email: privacy@stardust.app
Support: support@stardust.app

**DPO (ответственный за данные):**
dpo@stardust.app

По вопросам обращайтесь в любое время. Мы отвечаем в течение 72 часов.
''',
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
              'Политика конфиденциальности',
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
