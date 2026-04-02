import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

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
                          'API Documentation',
                          'Добро пожаловать в документацию Stardust API',
                          '''
Stardust API предоставляет доступ к функциям приложения для разработчиков.

## Базовая информация

• **Base URL:** https://api.stardust.app/v1
• **Формат:** JSON
• **Аутентификация:** Bearer Token

## Эндпоинты

### Аутентификация

POST /auth/register - Регистрация пользователя
POST /auth/login - Вход в аккаунт
POST /auth/refresh - Обновление токена
POST /auth/logout - Выход из аккаунта

### Профили

GET /users/me - Получить свой профиль
PUT /users/me - Обновить профиль
GET /users/{id} - Получить профиль пользователя
DELETE /users/me - Удалить аккаунт

### Поиск

GET /users/discover - Получить анкеты для свайпа
POST /users/{id}/like - Лайкнуть пользователя
POST /users/{id}/superlike - Суперлайк
POST /users/{id}/pass - Пропустить пользователя

### Лайки

GET /likes - Получить список лайков
GET /matches - Получить взаимные лайки

### Сообщения

GET /conversations - Список чатов
GET /conversations/{id} - Получить сообщения чата
POST /conversations/{id}/messages - Отправить сообщение

## Коды ошибок

200 - Успешно
400 - Неверный запрос
401 - Не авторизован
403 - Запрещено
404 - Не найдено
429 - Слишком много запросов
500 - Ошибка сервера

## Лимиты

• 100 запросов в минуту для API
• Максимальный размер файла: 10MB
• Максимальное количество фото: 6''',
                        ),
                        _buildSection(
                          'Интеграция',
                          'Как интегрировать Stardust в ваше приложение',
                          '''
## Мобильная интеграция (Flutter)

```dart
import 'package:stardust/stardust.dart';

void main() {
  Stardust.initialize(
    apiKey: 'YOUR_API_KEY',
    environment: Environment.production,
  );
}
```

## Web интеграция

```javascript
import { Stardust } from '@stardust/sdk';

const client = new Stardust({
  apiKey: 'YOUR_API_KEY',
});

await client.auth.login(email, password);
```

## Примеры использования

### Получение анкет

```dart
final profiles = await Stardust.users.discover(
  limit: 10,
  filters: {
    'age_min': 18,
    'age_max': 35,
    'distance': 50,
  },
);
```

### Отправка лайка

```dart
await Stardust.users.like(userId);
```

## Webhooks

Настройте webhook для получения уведомлений:

• onMatch - Взаимная симпатия
• onMessage - Новое сообщение
• onLike - Новый лайк
• onSuperLike - Новый суперлайк
''',
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
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_ios),
          ),
          const Expanded(
            child: Text(
              'Документация',
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

  Widget _buildSection(String title, String subtitle, String content) {
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
