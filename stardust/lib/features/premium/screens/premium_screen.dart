import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/star_background.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/services/auth_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final AuthService _authService = AuthService();
  bool _isAnnual = false;
  bool _isPremium = false;
  bool _isLoading = true;
  
  // Цены
  static const double _monthlyPrice = 399.0;
  static const double _annualPrice = 1299.0;
  static const double _monthlyIfAnnual = _annualPrice / 12; // ~108 руб/мес
  
  String get _currentPrice => _isAnnual 
      ? '${_annualPrice.toInt()} ₽/год' 
      : '${_monthlyPrice.toInt()} ₽/мес';
  
  String get _savingsPercent => _isAnnual ? '73%' : '';

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final user = await _authService.getUserData(userId);
      if (mounted && user != null) {
        setState(() {
          _isPremium = user.isPremium;
          _isLoading = false;
        });
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(animate: true),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_isPremium) _buildCurrentSubscription(),
                        _buildTitle(),
                        const SizedBox(height: 32),
                        _buildToggle(),
                        const SizedBox(height: 24),
                        _buildPricingCards(),
                        const SizedBox(height: 32),
                        _buildFeaturesList(),
                        const SizedBox(height: 32),
                        _buildPurchaseButton(),
                        const SizedBox(height: 16),
                        _buildRestoreButton(),
                        const SizedBox(height: 24),
                        _buildTermsText(),
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

  Widget _buildCurrentSubscription() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.superLikeGold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Premium активен',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Спасибо за поддержку! Вы получаете все преимущества Premium.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _handleManageSubscription,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Управление подпиской',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  void _handleManageSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.premiumGold),
            SizedBox(width: 8),
            Text('Управление подпиской', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Вы можете отменить подписку в настройках вашего аккаунта в магазине приложений.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
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
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Stardust Premium',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isPremium)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Подписка активна',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.star, color: Colors.white, size: 40),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          'Откройте все возможности',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'Получите безлимитные лайки и суперлайки',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '1 месяц',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !_isAnnual ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isAnnual ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '1 год',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isAnnual ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    if (_isAnnual) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '-73%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildPricingCards() {
    return Column(
      children: [
        // Основная карточка
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: _isAnnual 
                ? AppColors.primaryGradient 
                : LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceLight.withValues(alpha: 0.5),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAnnual 
                  ? Colors.transparent 
                  : AppColors.surfaceLight,
            ),
            boxShadow: _isAnnual ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              if (_isAnnual) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ЛУЧШАЯ ЦЕНА',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(
                _isAnnual ? '${_annualPrice.toInt()}' : '${_monthlyPrice.toInt()}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _isAnnual ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                _isAnnual ? 'рублей в год' : 'рублей в месяц',
                style: TextStyle(
                  fontSize: 14,
                  color: _isAnnual 
                      ? Colors.white.withValues(alpha: 0.8) 
                      : AppColors.textSecondary,
                ),
              ),
              if (_isAnnual) ...[
                const SizedBox(height: 8),
                Text(
                  '≈ ${_monthlyIfAnnual.toInt()} ₽/мес',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (!_isAnnual) ...[
                const SizedBox(height: 8),
                Text(
                  '1299 ₽/год со скидкой 73%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.favorite, 'title': 'Безлимитные лайки', 'desc': 'Лайкайте сколько угодно'},
      {'icon': Icons.star, 'title': '5 суперлайков в день', 'desc': 'Повысьте шансы на матч'},
      {'icon': Icons.location_on, 'title': 'Изменение локации', 'desc': 'Меняйте местоположение'},
      {'icon': Icons.visibility_off, 'title': 'Невидимый режим', 'desc': 'Смотрите анкеты незаметно'},
      {'icon': Icons.arrow_upward, 'title': 'Топ в поиске', 'desc': 'Будьте первыми'},
      {'icon': Icons.analytics, 'title': 'Расширенные фильтры', 'desc': 'Больше критериев поиска'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Что входит в подписку:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        feature['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 600 + index * 50)).slideX(begin: -0.1);
        }),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    final buttonText = _isPremium 
        ? 'Продлить подписку — $_currentPrice'
        : 'Купить $_currentPrice';
    
    return CosmicButton(
      text: buttonText,
      onPressed: _handlePurchase,
      width: double.infinity,
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2);
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _handleRestore,
      child: Text(
        'Восстановить покупки',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildTermsText() {
    return Text(
      'Подписка продлевается автоматически. '
      'Отменить можно в любой момент в настройках.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textMuted,
      ),
    ).animate().fadeIn(delay: 1100.ms);
  }

  void _handlePurchase() {
    // Здесь будет интеграция с платёжной системой
    // Для примера покажем диалог
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.shopping_cart, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Покупка', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          _isAnnual 
              ? 'Приобрести Premium на 1 год за $_annualPrice ₽?'
              : 'Приобрести Premium на 1 месяц за $_monthlyPrice ₽?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog();
            },
            child: const Text('Купить'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Поздравляем!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Premium активирован',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }

  void _handleRestore() {
    // Восстановление покупок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Восстановление покупок...'),
      ),
    );
  }
}
