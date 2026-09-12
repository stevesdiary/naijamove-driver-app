import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'buttons.dart';

/// White card, 16pt radius, subtle border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? context.border),
      ),
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
      elevation: shadow ? 6 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum BadgeKind {
  completed,
  cancelled,
  inProgress,
  scheduled,
  surge,
  open,
  pending,
  resolved,
  closed,
  info,
  danger,
}

/// Status badge per the spec's colour table.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.kind, this.icon});
  final String label;
  final BadgeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (kind) {
      BadgeKind.completed ||
      BadgeKind.resolved => (AppColors.successTeal, Colors.white),
      BadgeKind.cancelled ||
      BadgeKind.danger => (AppColors.dangerTint, AppColors.dangerRed),
      BadgeKind.inProgress ||
      BadgeKind.open => (AppColors.primaryBlue, Colors.white),
      BadgeKind.scheduled || BadgeKind.info => (
        context.tint,
        context.isDark ? Colors.white : AppColors.primaryDark,
      ),
      BadgeKind.surge ||
      BadgeKind.pending => (AppColors.accentGold, AppColors.primaryDark),
      BadgeKind.closed => (context.border, context.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet surface with drag handle, 24pt top radius, soft shadow.
class SheetSurface extends StatelessWidget {
  const SheetSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.handle = true,
    this.safeBottom = true,
    this.scrollable = false,
    this.expand = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool handle;
  final bool safeBottom;

  /// When the sheet sits inside a bounded-height parent, scroll rather than overflow.
  final bool scrollable;

  /// Fill the bounded height given by the parent (lets children use Flexible/Expanded).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: context.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: safeBottom,
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (handle)
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (scrollable)
              Flexible(
                child: SingleChildScrollView(padding: padding, child: child),
              )
            else if (expand)
              Expanded(
                child: Padding(padding: padding, child: child),
              )
            else
              Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Section label (Text Secondary, 12pt, uppercase).
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.label, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 8),
  });
  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontSize: 12,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Circular avatar with initials fallback.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.size = 48,
    this.color,
    this.showEdit = false,
    this.onEdit,
  });
  final String name;
  final double size;
  final Color? color;
  final bool showEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join()
        .toUpperCase();
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? context.tint,
        shape: BoxShape.circle,
        border: Border.all(color: context.surface, width: size > 60 ? 3 : 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryBlue,
          letterSpacing: -0.5,
        ),
      ),
    );
    if (!showEdit) return avatar;
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: context.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: size * 0.16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row with leading icon in a Primary Light circle, title, optional subtitle and trailing.
class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBg,
    this.titleColor,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBg;
  final Color? titleColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg ?? context.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Empty state: line-art icon + heading + sub-copy + optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: context.tint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: PrimaryButton(label: ctaLabel!, onPressed: onCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success Teal animated checkmark.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 96});
  final double size;
  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeOutBack.transform(_c.value.clamp(0, 1));
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 1.3,
              height: widget.size * 1.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successTeal.withValues(alpha: 0.12 * _c.value),
              ),
            ),
            Transform.scale(
              scale: t,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  color: AppColors.successTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: widget.size * 0.55,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shimmer skeleton block (Primary Light → Border Subtle).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });
  final double? width;
  final double height;
  final double radius;
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(context.tint, context.border, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Persistent "No internet connection" bar.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.visible = false});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: visible
          ? Container(
              width: double.infinity,
              color: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

enum ToastKind { success, error, info }

/// Toast / snackbar: Primary Dark background with a 4pt coloured left border.
void showToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
}) {
  final color = switch (kind) {
    ToastKind.success => AppColors.successTeal,
    ToastKind.error => AppColors.dangerRed,
    ToastKind.info => AppColors.primaryBlue,
  };
  final icon = switch (kind) {
    ToastKind.success => Icons.check_circle_rounded,
    ToastKind.error => Icons.error_rounded,
    ToastKind.info => Icons.info_rounded,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// Progress indicator "Step 1 of 2" with segments.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});
  final int step;
  final int total;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < step ? AppColors.primaryBlue : context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Step $step of $total',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Interactive 5-star row. Empty: Border Subtle outline; filled: Accent Gold.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 48,
    this.spacing = 8,
  });
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i + 1),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: filled ? 1.08 : 1,
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: filled ? AppColors.accentGold : context.border,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Horizontal star distribution bar chart (5★ … 1★).
class StarDistribution extends StatelessWidget {
  const StarDistribution({super.key, required this.percentages});

  /// Percentages for 5★ down to 1★.
  final List<int> percentages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(5, (i) {
        final stars = 5 - i;
        final pct = percentages[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('$stars★', style: theme.textTheme.labelMedium),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: context.tint,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '$pct%',
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Pickup / destination dot indicator.
class RouteDot extends StatelessWidget {
  const RouteDot({
    super.key,
    required this.color,
    this.size = 12,
    this.square = false,
  });
  final Color color;
  final double size;
  final bool square;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(2) : null,
        border: Border.all(color: context.surface, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
        ],
      ),
    );
  }
}

/// Pickup → (stops) → destination vertical address list.
class RouteSummary extends StatelessWidget {
  const RouteSummary({
    super.key,
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.onEditPickup,
    this.onEditDestination,
    this.dense = false,
  });
  final String pickup;
  final String destination;
  final List<String> stops;
  final VoidCallback? onEditPickup;
  final VoidCallback? onEditDestination;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(
      Color color,
      String text, {
      bool square = false,
      VoidCallback? onEdit,
      bool last = false,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              RouteDot(color: color, square: square),
              if (!last)
                Container(
                  width: 2,
                  height: dense ? 18 : 24,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: context.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : (dense ? 8 : 12)),
              child: Text(
                text,
                style: dense
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: context.textPrimary,
                      )
                    : theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: context.textSecondary,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        row(AppColors.primaryBlue, pickup, onEdit: onEditPickup),
        for (var i = 0; i < stops.length; i++)
          row(AppColors.textSecondary, stops[i]),
        row(
          AppColors.dangerRed,
          destination,
          square: true,
          onEdit: onEditDestination,
          last: true,
        ),
      ],
    );
  }
}

/// Fare breakdown card with itemised rows and bold total.
class FareBreakdown extends StatelessWidget {
  const FareBreakdown({
    super.key,
    required this.rows,
    this.total,
    this.totalLabel = 'Total',
  });
  final List<(String, String)> rows;
  final String? total;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in rows) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: AppText.tabular,
                    fontWeight: FontWeight.w600,
                    // Discounts (−₦) read as credits.
                    color: value.startsWith('−') ? AppColors.successTeal : null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        if (total != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(totalLabel, style: theme.textTheme.titleMedium),
                ),
                Text(total!, style: AppText.fare(context, size: 18)),
              ],
            ),
          ),
      ],
    );
  }
}
