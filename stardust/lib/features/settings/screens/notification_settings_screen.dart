import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _newMatch = true;
  bool _newMessage = true;
  bool _newLike = true;
  bool _newSuperLike = true;
  bool _emailEnabled = true;

  void _showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Настройки сохранены'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 1),
      ),
    );
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Push-уведомления'),
                        _buildSwitch(
                          title: 'Включить push-уведомления',
                          subtitle: 'Получать уведомления на устройство',
                          value: _pushEnabled,
                          onChanged: (value) {
                            setState(() => _pushEnabled = value);
                            _showSavedMessage();
                          },
                          index: 0,
                        ),
                        const Divider(color: AppColors.surfaceLight),
                        _buildSwitch(
                          title: 'Новые матчи',
                          subtitle: 'Когда кто-то лайкнул вас взаимно',
                          value: _newMatch,
                          onChanged: _pushEnabled 
                              ? (value) {
                                  setState(() => _newMatch = value);
                                  _showSavedMessage();
                                }
                              : null,
                          index: 1,
                        ),
                        _buildSwitch(
                          title: 'Новые сообщения',
                          subtitle: 'Когда приходит новое сообщение',
                          value: _newMessage,
                          onChanged: _pushEnabled 
                              ? (value) {
                                  setState(() => _newMessage = value);
                                  _showSavedMessage();
                                }
                              : null,
                          index: 2,
                        ),
                        _buildSwitch(
                          title: 'Новые лайки',
                          subtitle: 'Кто-то лайкнул ваш профиль',
                          value: _newLike,
                          onChanged: _pushEnabled 
                              ? (value) {
                                  setState(() => _newLike = value);
                                  _showSavedMessage();
                                }
                              : null,
                          index: 3,
                        ),
                        _buildSwitch(
                          title: 'Суперлайки',
                          subtitle: 'Кто-то отправил суперлайк',
                          value: _newSuperLike,
                          onChanged: _pushEnabled 
                              ? (value) {
                                  setState(() => _newSuperLike = value);
                                  _showSavedMessage();
                                }
                              : null,
                          index: 4,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Email-уведомления'),
                        _buildSwitch(
                          title: 'Включить email-рассылку',
                          subtitle: 'Получать новости и обновления на email',
                          value: _emailEnabled,
                          onChanged: (value) {
                            setState(() => _emailEnabled = value);
                            _showSavedMessage();
                          },
                          index: 5,
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
              'Уведомления',
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
      padding: const EdgeInsets.only(bottom: 16, top: 8),
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

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required int index,
  }) {
    final isDisabled = onChanged == null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        enabled: !isDisabled,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDisabled 
                ? AppColors.textMuted 
                : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDisabled 
                ? AppColors.textMuted.withValues(alpha: 0.5)
                : AppColors.textMuted,
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
}
