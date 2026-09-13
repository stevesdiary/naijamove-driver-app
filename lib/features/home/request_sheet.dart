import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/components.dart';
import '../../data/models.dart';

/// 2.3 — Incoming trip request. 15 s countdown ring; pops `true` on accept,
/// `false` on decline or timeout.
class TripRequestSheet extends StatefulWidget {
  const TripRequestSheet({super.key, required this.request, this.seconds = 15});
  final TripRequest request;
  final int seconds;
  @override
  State<TripRequestSheet> createState() => _TripRequestSheetState();
}

class _TripRequestSheetState extends State<TripRequestSheet> with TickerProviderStateMixin {
  late final _ring = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))..forward();
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  Timer? _tick;
  late int _left = widget.seconds;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ring.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.request;
    final urgent = _left <= 5;
    return SheetSurface(
      handle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, _) => CircularProgressIndicator(
                      value: 1 - _ring.value,
                      strokeWidth: 5,
                      color: urgent ? AppColors.dangerRed : AppColors.primaryBlue,
                      backgroundColor: context.border,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$_left',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 28,
                        fontFeatures: AppText.tabular,
                        color: urgent ? AppColors.dangerRed : context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  naira(r.fare),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.earningsGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ),
              if (r.surge != null) ...[
                StatusBadge('${r.surge}× surge', kind: BadgeKind.surge, icon: Icons.bolt_rounded),
                const SizedBox(width: 6),
              ],
              StatusBadge(r.category.label, kind: BadgeKind.info),
            ],
          ),
          const SizedBox(height: 14),
          _Line(color: AppColors.primaryBlue, title: r.pickup.name, trailing: '${r.distanceToPickupKm} km away'),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(width: 2, height: 14, color: context.border),
          ),
          _Line(
            color: AppColors.dangerRed,
            title: r.destination.area ?? r.destination.name,
            trailing: '${r.distanceKm} km · ${r.durationMin} min',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                const SizedBox(width: 4),
                Text('${r.rider.rating}', style: theme.textTheme.labelLarge),
                const SizedBox(width: 10),
                Text('${r.rider.trips} trips', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                const Spacer(),
                Icon(r.rider.payment.icon, size: 16, color: context.textSecondary),
                const SizedBox(width: 6),
                Text(r.rider.payment.label, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerRed,
                      side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.color, required this.title, required this.trailing});
  final Color color;
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        RouteDot(color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(trailing, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
      ],
    );
  }
}
