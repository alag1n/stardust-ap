import 'package:flutter/material.dart';
import 'package:stardust/core/theme/app_theme.dart';

class PlaceholderAvatar extends StatelessWidget {
  final double size;
  final IconData icon;

  const PlaceholderAvatar({
    super.key,
    this.size = 100,
    this.icon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

class PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PlaceholderImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.image,
        size: 50,
        color: Colors.white,
      ),
    );
  }
}
