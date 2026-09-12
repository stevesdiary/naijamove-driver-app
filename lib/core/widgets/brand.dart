import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Logo mark: rounded tile with a car glyph and an Accent Gold dot.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 48,
    this.tileColor,
    this.iconColor = Colors.white,
  });
  final double size;
  final Color? tileColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: tileColor ?? AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: Icon(
            Icons.local_taxi_rounded,
            color: iconColor,
            size: size * 0.55,
          ),
        ),
        Positioned(
          right: size * 0.14,
          top: size * 0.14,
          child: Container(
            width: size * 0.16,
            height: size * 0.16,
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// "NaijaMove" wordmark.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 22, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c =
        color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.primaryDark);
    return Text(
      'NaijaMove',
      style: TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: c,
        letterSpacing: -0.8,
      ),
    );
  }
}

/// Mark + wordmark inline (top bars).
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        SizedBox(width: size * 0.35),
        BrandWordmark(size: size * 0.75),
      ],
    );
  }
}
