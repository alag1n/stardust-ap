import 'dart:math';
import 'package:flutter/material.dart';

class StarBackground extends StatefulWidget {
  final int starCount;
  final bool animate;

  const StarBackground({
    super.key,
    this.starCount = 150,
    this.animate = true,
  });

  @override
  State<StarBackground> createState() => _StarBackgroundState();
}

class _StarBackgroundState extends State<StarBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.starCount, (_) => _createStar());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  Star _createStar() {
    return Star(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 2 + 0.5,
      opacity: _random.nextDouble() * 0.7 + 0.3,
      twinkleSpeed: _random.nextDouble() * 2 + 1,
      twinkleOffset: _random.nextDouble() * 2 * pi,
      // Параметры для появления/исчезновения (быстрее, чтобы было заметно)
      appearSpeed: _random.nextDouble() * 5 + 3,
      appearOffset: _random.nextDouble() * 2 * pi,
      appearDuration: _random.nextDouble() * 0.5 + 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarPainter(
            stars: _stars,
            time: _controller.value * 2 * pi,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double twinkleSpeed;
  final double twinkleOffset;
  // Параметры для появления/исчезновения
  final double appearSpeed;
  final double appearOffset;
  final double appearDuration;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.appearSpeed,
    required this.appearOffset,
    required this.appearDuration,
  });
}

class StarPainter extends CustomPainter {
  final List<Star> stars;
  final double time;

  StarPainter({required this.stars, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Фон - градиент
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F0F1A),
          Color(0xFF1A1A2E),
          Color(0xFF0F0F1A),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Рисуем звезды
    for (final star in stars) {
      final twinkle = (sin(time * star.twinkleSpeed + star.twinkleOffset) + 1) / 2;
      
      // Эффект появления/исчезновения
      final appearCycle = sin(time * star.appearSpeed + star.appearOffset);
      // Звезда появляется и исчезает в пределах от 0 до 1
      final appearFactor = (appearCycle + 1) / 2 * star.appearDuration;
      
      // Итоговая непрозрачность: мерцание + появление/исчезновение
      final opacity = star.opacity * (0.3 + twinkle * 0.7) * appearFactor;

      // Не рисуем звезду если она "исчезла"
      if (opacity < 0.05) continue;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size * (0.8 + twinkle * 0.2),
        paint,
      );

      // Добавляем свечение для ярких звезд
      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }
    }

    // Добавляем nebula эффект
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6B4EFF).withValues(alpha: 0.1),
          const Color(0xFF00D9FF).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.3),
        radius: size.width * 0.4,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.4,
      nebulaPaint,
    );

    final nebulaPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9B7DFF).withValues(alpha: 0.08),
          const Color(0xFF00FFAA).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.7),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      size.width * 0.5,
      nebulaPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
