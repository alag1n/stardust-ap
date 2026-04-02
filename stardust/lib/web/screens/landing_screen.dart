import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stardust/core/theme/app_theme.dart';
import 'package:stardust/core/widgets/cosmic_button.dart';
import 'package:stardust/core/widgets/star_background.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();

  // Ключи для секций
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();
  
  // Состояния анимации
  bool _featuresAnimated = false;
  bool _howItWorksAnimated = false;
  bool _testimonialsAnimated = false;
  bool _ctaAnimated = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Проверяем видимость каждой секции
    _checkSectionVisibility(_featuresKey, _featuresAnimated, (animated) {
      _featuresAnimated = animated;
    });
    _checkSectionVisibility(_howItWorksKey, _howItWorksAnimated, (animated) {
      _howItWorksAnimated = animated;
    });
    _checkSectionVisibility(_testimonialsKey, _testimonialsAnimated, (animated) {
      _testimonialsAnimated = animated;
    });
    _checkSectionVisibility(_ctaKey, _ctaAnimated, (animated) {
      _ctaAnimated = animated;
    });
  }

  void _checkSectionVisibility(GlobalKey key, bool alreadyAnimated, Function(bool) setAnimated) {
    if (alreadyAnimated) return;
    
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Секция видима, когда её верхняя часть выше середины экрана
    if (position.dy < screenHeight * 0.8) {
      setAnimated(true);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const StarBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        _buildHeroSection(context),
                        // Features
                        Container(
                          key: _featuresKey,
                          child: AnimatedOpacity(
                            opacity: _featuresAnimated ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: AnimatedSlide(
                              offset: _featuresAnimated ? Offset.zero : const Offset(0, 0.1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: _buildFeaturesSection(),
                            ),
                          ),
                        ),
                        // How it works
                        Container(
                          key: _howItWorksKey,
                          child: AnimatedOpacity(
                            opacity: _howItWorksAnimated ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: AnimatedSlide(
                              offset: _howItWorksAnimated ? Offset.zero : const Offset(0, 0.1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: _buildHowItWorksSection(),
                            ),
                          ),
                        ),
                        // Testimonials
                        Container(
                          key: _testimonialsKey,
                          child: AnimatedOpacity(
                            opacity: _testimonialsAnimated ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: AnimatedSlide(
                              offset: _testimonialsAnimated ? Offset.zero : const Offset(0, 0.1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: _buildTestimonialsSection(),
                            ),
                          ),
                        ),
                        // CTA
                        Container(
                          key: _ctaKey,
                          child: AnimatedOpacity(
                            opacity: _ctaAnimated ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: AnimatedSlide(
                              offset: _ctaAnimated ? Offset.zero : const Offset(0, 0.1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              child: _buildCtaSection(context),
                            ),
                          ),
                        ),
                        _buildFooter(context),
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
}
  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Image(
                  image: AssetImage('assets/stardust_icon.png'),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Stardust',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              CosmicButton(
                text: 'Вход',
                onPressed: () => context.go('/login'),
                isOutlined: true,
                width: 100,
              ),
              const SizedBox(width: 12),
              CosmicButton(
                text: 'Регистрация',
                onPressed: () => context.go('/register'),
                width: 150,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          '✨ Найди свою звезду',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      Text(
                        'Найди свою\nзвезду',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          'Stardust',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 24),
                      Text(
                        'Найди того, кто зажжёт твоё небо.\nКосмические знакомства для тех,\nкто верит в любовь среди звёзд.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 32),
                      CosmicButton(
                        text: 'Начать',
                        onPressed: () => context.go('/register'),
                        width: double.infinity,
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('1M+', 'Пользователей'),
                          _buildStat('500K+', 'Свиданий'),
                          _buildStat('4.8★', 'Рейтинг'),
                        ],
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: const DecorationImage(
                            image: AssetImage('assets/stardust_icon.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(),
                ),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          '✨ Найди свою звезду',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),
                      Text(
                        'Найди свою\nзвезду',
                        style: GoogleFonts.montserrat(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          'Stardust',
                          style: GoogleFonts.montserrat(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                      const SizedBox(height: 24),
                      Text(
                        'Найди того, кто зажжёт твоё небо.\nКосмические знакомства для тех,\nкто верит в любовь среди звёзд.',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                      const SizedBox(height: 40),
                      CosmicButton(
                        text: 'Начать',
                        onPressed: () => context.go('/register'),
                        width: double.infinity,
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          _buildStat('1M+', 'Пользователей'),
                          const SizedBox(width: 40),
                          _buildStat('500K+', 'Успешных свиданий'),
                          const SizedBox(width: 40),
                          _buildStat('4.8★', 'Рейтинг'),
                        ],
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 80),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          width: 280,
                          height: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: const DecorationImage(
                              image: AssetImage('assets/icon_1.jpg'),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).scale(),
                      Positioned(
                        right: 20,
                        child: Transform.rotate(
                          angle: 0.1,
                          child: Container(
                            width: 200,
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: const DecorationImage(
                                image: AssetImage('assets/icon_2.jpg'),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms).scale(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 80),
      child: Column(
        children: [
          const Text(
            'Почему Stardust?',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Мы создали идеальное пространство для знакомств',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.auto_awesome,
                      title: 'Умные алгоритмы',
                      description: 'AI подбирает идеальные совпадения на основе ваших предпочтений',
                      index: 0,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.security,
                      title: 'Безопасность',
                      description: 'Верификация профилей и защита данных на высшем уровне',
                      index: 1,
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.forum,
                      title: 'Удобный чат',
                      description: 'Общайтесь без ограничений с мгновенными сообщениями',
                      index: 2,
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureCard(
                    icon: Icons.auto_awesome,
                    title: 'Умные алгоритмы',
                    description: 'AI подбирает идеальные совпадения на основе ваших предпочтений',
                    index: 0,
                  ),
                  _buildFeatureCard(
                    icon: Icons.security,
                    title: 'Безопасность',
                    description: 'Верификация профилей и защита данных на высшем уровне',
                    index: 1,
                  ),
                  _buildFeatureCard(
                    icon: Icons.forum,
                    title: 'Удобный чат',
                    description: 'Общайтесь без ограничений с мгновенными сообщениями',
                    index: 2,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 80),
      color: AppColors.surface.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Text(
            'Как это работает?',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildStep('1', 'Создай профиль', 'Загрузи фото и расскажи о себе'),
                    const SizedBox(height: 24),
                    _buildStep('2', 'Настрой поиск', 'Укажи предпочтения и критерии'),
                    const SizedBox(height: 24),
                    _buildStep('3', 'Свайпай', 'Знакомься с новыми людьми'),
                    const SizedBox(height: 24),
                    _buildStep('4', 'Общайся', 'Начни разговор при симпатии'),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStep('1', 'Создай профиль', 'Загрузи фото и расскажи о себе'),
                  _buildStep('2', 'Настрой поиск', 'Укажи предпочтения и критерии'),
                  _buildStep('3', 'Свайпай', 'Знакомься с новыми людьми'),
                  _buildStep('4', 'Общайся', 'Начни разговор при симпатии'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 80),
      child: Column(
        children: [
          const Text(
            'Истории успеха',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    _buildTestimonial(
                      'Анна и Мария',
                      'Мы встретились на Stardust и теперь вместе уже год!',
                      0,
                    ),
                    const SizedBox(height: 16),
                    _buildTestimonial(
                      'Екатерина и Дмитрий',
                      'Сначала переписывались, потом решили встретиться. Всё стало сразу ясно!',
                      1,
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTestimonial(
                    'Анна и Мария',
                    'Мы встретились на Stardust и теперь вместе уже год!',
                    0,
                  ),
                  _buildTestimonial(
                    'Екатерина и Дмитрий',
                    'Сначала переписывались, потом решили встретиться. Всё стало сразу ясно!',
                    1,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial(String names, String text, int index) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: index == 0 ? AppColors.primaryGradient : AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  const Text(
                    'Готов найти свою любовь?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Присоединяйся к миллионам счастливых пар',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CosmicButton(
                    text: 'Зарегистрироваться',
                    onPressed: () => context.go('/register'),
                    width: double.infinity,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Готов найти свою любовь?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Присоединяйся к миллионам счастливых пар',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                CosmicButton(
                  text: 'Зарегистрироваться',
                  onPressed: () => context.go('/register'),
                  width: 220,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Image(
                            image: AssetImage('assets/stardust_icon.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stardust',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/rules'),
                          child: const Text('Правила'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/privacy'),
                          child: const Text('Политика'),
                        ),
                        TextButton(
                          onPressed: () => context.push('/docs'),
                          child: const Text('Документация'),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Image(
                          image: AssetImage('assets/stardust_icon.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stardust',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/rules'),
                        child: const Text('Правила'),
                      ),
                      TextButton(
                        onPressed: () => context.push('/privacy'),
                        child: const Text('Политика'),
                      ),
                      TextButton(
                        onPressed: () => context.push('/docs'),
                        child: const Text('Документация'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '© 2024 Stardust. Все права защищены.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }