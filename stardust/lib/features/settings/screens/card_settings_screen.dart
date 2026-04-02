import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class CardSettingsScreen extends StatefulWidget {
  const CardSettingsScreen({super.key});

  @override
  State<CardSettingsScreen> createState() => _CardSettingsScreenState();
}

class _CardSettingsScreenState extends State<CardSettingsScreen> {
  bool _showAge = true;
  bool _showDistance = true;
  bool _showOnlineStatus = true;
  bool _showLastActive = true;
  bool _makeProfileInvisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: false),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Настройка карточки',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Выберите, какую информацию видят другие пользователи',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        _buildSwitch('Показывать возраст', _showAge, (v) => setState(() => _showAge = v)),
                        _buildSwitch('Показывать расстояние', _showDistance, (v) => setState(() => _showDistance = v)),
                        _buildSwitch('Показывать статус онлайн', _showOnlineStatus, (v) => setState(() => _showOnlineStatus = v)),
                        _buildSwitch('Показывать последнюю активность', _showLastActive, (v) => setState(() => _showLastActive = v)),
                        const SizedBox(height: 24),
                        _buildSwitch('Сделать профиль невидимым', _makeProfileInvisible, (v) => setState(() => _makeProfileInvisible = v)),
                        const SizedBox(height: 8),
                        const Text(
                          'Ваш профиль не будет показываться в ленте, но вы сможете им пользоваться',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5)),
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
              'Настройка карточки',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
