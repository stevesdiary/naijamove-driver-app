import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

const _kButtonHeight = 52.0;

/// Primary: full width, Primary Blue fill, soft blue shadow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fill = color ?? AppColors.primaryBlue;
    return SizedBox(
      height: _kButtonHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: fill,
            disabledBackgroundColor: fill.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Destructive: Danger Red fill.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => PrimaryButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    color: AppColors.dangerRed,
  );
}

/// Secondary: white fill, Primary Blue 1.5pt border + text.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primaryBlue;
    return SizedBox(
      height: _kButtonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.surface,
          foregroundColor: c,
          side: BorderSide(color: c, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: c),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Ghost: transparent, Text Secondary — for Skip / Cancel styled as buttons.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kButtonHeight,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color ?? context.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Icon button: 48×48, circular, Primary Light fill, Primary Blue icon.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.fill,
    this.iconColor,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final Color? fill;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: fill ?? context.tint,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryBlue,
            size: size * 0.46,
          ),
        ),
      ),
    );
    if (label == null) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(label!, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Floating circular button over the map (My Location, back, etc.).
class MapFab extends StatelessWidget {
  const MapFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size = 48,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? context.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor ?? AppColors.primaryBlue,
          size: size * 0.46,
        ),
      ),
    );
  }
}

/// Text link in Primary Blue.
class LinkText extends StatelessWidget {
  const LinkText(
    this.label, {
    super.key,
    this.onTap,
    this.color,
    this.size = 14,
  });
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color ?? AppColors.primaryBlue,
            fontSize: size,
          ),
        ),
      ),
    );
  }
}
