import 'dart:async';
import 'package:flutter/material.dart';

/// Провайдер для передачи scroll position
class ScrollAnimationProvider extends InheritedWidget {
  final double scrollOffset;

  const ScrollAnimationProvider({
    super.key,
    required this.scrollOffset,
    required super.child,
  });

  static double of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ScrollAnimationProvider>();
    return provider?.scrollOffset ?? 0;
  }

  @override
  bool updateShouldNotify(ScrollAnimationProvider oldWidget) {
    return scrollOffset != oldWidget.scrollOffset;
  }
}

/// Виджет для scroll-triggered анимаций
/// Анимирует дочерний элемент когда он появляется в области видимости
class ScrollAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideBegin;
  final double fadeBegin;
  final double scaleBegin;

  const ScrollAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideBegin = const Offset(0, 0.1),
    this.fadeBegin = 0.0,
    this.scaleBegin = 0.9,
  });

  @override
  State<ScrollAnimation> createState() => _ScrollAnimationState();
}

class _ScrollAnimationState extends State<ScrollAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasAnimated = false;
  final GlobalKey _key = GlobalKey();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: widget.fadeBegin,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: widget.scaleBegin,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Слушаем скролл
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_hasAnimated || !mounted) return;
    
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // Пробуем ещё раз позже
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasAnimated) {
          _checkVisibility();
        }
      });
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final itemTop = position.dy;
    final itemBottom = itemTop + renderBox.size.height;

    // Элемент считается видимым, когда его верхняя часть выше нижней границы экрана
    // и нижняя часть ниже верхней границы экрана
    final inView = itemTop < screenHeight && itemBottom > 0;

    if (inView && !_isVisible) {
      _isVisible = true;
      Future.delayed(widget.delay, () {
        if (mounted && !_hasAnimated) {
          _hasAnimated = true;
          _controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем скролл через NotificationListener
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: Container(
        key: _key,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: _slideAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Упрощённая версия с fade + slide анимацией
class ScrollFadeSlide extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const ScrollFadeSlide({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 600),
    this.beginOffset = const Offset(0, 30),
  });

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      delay: delay,
      duration: duration,
      slideBegin: beginOffset,
      fadeBegin: 0.0,
      scaleBegin: 1.0,
      child: child,
    );
  }
}

/// Анимация только с fade (появление)
class ScrollFade extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const ScrollFade({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      delay: delay,
      duration: duration,
      slideBegin: Offset.zero,
      fadeBegin: 0.0,
      scaleBegin: 1.0,
      child: child,
    );
  }
}

/// Анимация scale (пульсация при появлении)
class ScrollScale extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginScale;

  const ScrollScale({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
    this.duration = const Duration(milliseconds: 600),
    this.beginScale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollAnimation(
      delay: delay,
      duration: duration,
      slideBegin: Offset.zero,
      fadeBegin: 1.0,
      scaleBegin: beginScale,
      child: child,
    );
  }
}