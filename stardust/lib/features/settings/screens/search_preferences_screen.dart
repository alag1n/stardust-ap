import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';

class SearchPreferencesScreen extends StatefulWidget {
  const SearchPreferencesScreen({super.key});

  @override
  State<SearchPreferencesScreen> createState() => _SearchPreferencesScreenState();
}

class _SearchPreferencesScreenState extends State<SearchPreferencesScreen> {
  String _selectedGender = 'Любой';
  int _minAge = 18;
  int _maxAge = 50;
  int _maxDistance = 50;
  bool _showWithPhoto = true;

  final List<String> _genders = ['Любой', 'Мужчины', 'Женщины', 'Не указано'];

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
                        _buildSection(
                          'Пол',
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: AppColors.surface,
                            items: _genders.map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: const TextStyle(color: AppColors.textPrimary)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedGender = v!),
                          ),
                        ),
                        _buildSection(
                          'Возраст: $_minAge - $_maxAge лет',
                          Column(
                            children: [
                              RangeSlider(
                                values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                                min: 18,
                                max: 100,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.surfaceLight,
                                onChanged: (v) => setState(() {
                                  _minAge = v.start.round();
                                  _maxAge = v.end.round();
                                }),
                              ),
                            ],
                          ),
                        ),
                        _buildSection(
                          'Максимальное расстояние: $_maxDistance км',
                          Column(
                            children: [
                              Slider(
                                value: _maxDistance.toDouble(),
                                min: 1,
                                max: 500,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.surfaceLight,
                                onChanged: (v) => setState(() => _maxDistance = v.round()),
                              ),
                            ],
                          ),
                        ),
                        _buildSwitch(
                          'Показывать только с фото',
                          _showWithPhoto,
                          (v) => setState(() => _showWithPhoto = v),
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
              'Предпочтения поиска',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
