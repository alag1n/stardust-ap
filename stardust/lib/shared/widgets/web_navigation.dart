import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stardust/core/theme/app_theme.dart';

class WebNavigation extends StatefulWidget {
  final Widget child;

  const WebNavigation({super.key, required this.child});

  @override
  State<WebNavigation> createState() => _WebNavigationState();
}

class _WebNavigationState extends State<WebNavigation> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // На мобильных используем нижнюю навигацию
    if (!kIsWeb) {
      return widget.child;
    }

    return Scaffold(
      body: Row(
        children: [
          // Боковая панель
          MouseRegion(
            onEnter: (_) => setState(() => _isExpanded = true),
            onExit: (_) => setState(() => _isExpanded = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isExpanded ? 220 : 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Пункты навигации
                  _buildNavItem(
                    icon: Icons.explore,
                    label: 'Поиск',
                    route: '/home',
                  ),
                  _buildNavItem(
                    icon: Icons.favorite,
                    label: 'Лайки',
                    route: '/likes',
                  ),
                  _buildNavItem(
                    icon: Icons.chat_bubble,
                    label: 'Сообщения',
                    route: '/messages',
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Профиль',
                    route: '/profile',
                  ),
                  const Spacer(),
                  // Настройки внизу
                  _buildNavItem(
                    icon: Icons.settings,
                    label: 'Настройки',
                    route: '/settings',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Контент
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute == route;

    return Tooltip(
      message: _isExpanded ? '' : label,
      preferBelow: false,
      child: InkWell(
        onTap: () => context.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
