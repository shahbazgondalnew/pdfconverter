import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1A1012),
                  AppColors.darkBg,
                  Color(0xFF161018),
                ]
              : const [
                  Color(0xFFFFF5F5),
                  AppColors.lightBg,
                  Color(0xFFF7F2F0),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Blob(
              size: 220,
              color: (isDark ? AppColors.brand : AppColors.brand)
                  .withValues(alpha: isDark ? 0.18 : 0.10),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _Blob(
              size: 180,
              color: AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
