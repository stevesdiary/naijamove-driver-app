import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 8.1 — My performance.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});
  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = MockData.driver;
    final needsTips = d.rating < 4.5 || d.acceptanceRate < 80;
    return Scaffold(
      appBar: AppBar(title: const Text('My Performance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedTabs(labels: const ['This Week', 'This Month', 'All Time'], selected: _period, onChanged: (i) => setState(() => _period = i)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 40),
                const SizedBox(width: 6),
                Text(d.rating.toStringAsFixed(2),
                    style: theme.textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 48, fontFeatures: AppText.tabular)),
              ]),
              Text('Based on ${d.ratings} ratings', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 10),
              StatusBadge('${d.tier.label} Top Driver', kind: BadgeKind.surge, icon: Icons.emoji_events_rounded),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _Stat('Acceptance rate', '${d.acceptanceRate}%', up: true),
              _Stat('Completion rate', '${d.completionRate}%', up: true),
              _Stat('Cancellation rate', '${d.cancellationRate}%', up: false, goodWhenDown: true),
              _Stat('On-time arrival', '${d.onTimeRate}%', up: true),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Star distribution'),
          AppCard(child: StarDistribution(percentages: MockData.starDistribution)),
          const SizedBox(height: 16),
          const SectionLabel('Top compliments'),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final (label, n) in MockData.compliments) SelectChip(label: '$label ($n)', filled: true)]),
          if (needsTips) ...[
            const SizedBox(height: 16),
            const SectionLabel('Tips to improve'),
            const AppCard(child: Text('Accept more requests during peak hours and keep riders updated when running late.')),
          ],
          const SizedBox(height: 16),
          const SectionLabel('Recent feedback'),
          for (final f in MockData.feedback)
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 16, color: i < f.stars ? AppColors.accentGold : context.border),
                  const Spacer(),
                  Text(dayMonth(f.date), style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [for (final t in f.tags) StatusBadge(t, kind: BadgeKind.info)]),
                if (f.comment != null) ...[
                  const SizedBox(height: 6),
                  Text('"${f.comment}"', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {required this.up, this.goodWhenDown = false});
  final String label;
  final String value;
  final bool up;
  final bool goodWhenDown;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final good = up != goodWhenDown;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary)),
        const SizedBox(height: 4),
        Row(children: [
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular)),
          const SizedBox(width: 6),
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 18, color: good ? AppColors.successTeal : AppColors.dangerRed),
        ]),
      ]),
    );
  }
}

/// 8.2 — Top Driver programme.
class TopDriverScreen extends StatelessWidget {
  const TopDriverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = MockData.driver;
    final tier = d.tier;
    final next = tier.next;
    final tripsToNext = next == null ? 0 : (next.minTrips - d.trips).clamp(0, next.minTrips);
    final progress = next == null ? 1.0 : (d.trips / next.minTrips).clamp(0.0, 1.0);
    const benefits = [
      ('Priority trip matching', DriverTier.bronze),
      ('Monthly bonus multiplier', DriverTier.silver),
      ('Reduced platform commission', DriverTier.gold),
      ('Dedicated support line', DriverTier.platinum),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Top Driver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accentGold, Color(0xFFE08E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tier.label, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                Text('Member since ${d.memberSince}', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Your benefits'),
          AppCard(
            child: Column(children: [
              for (final (label, minTier) in benefits)
                IconRow(
                  icon: tier.index >= minTier.index ? Icons.check_circle_rounded : Icons.lock_rounded,
                  iconColor: tier.index >= minTier.index ? AppColors.successTeal : context.textSecondary,
                  iconBg: tier.index >= minTier.index ? AppColors.successTint : context.bg,
                  title: label,
                  subtitle: tier.index >= minTier.index ? null : '${minTier.label} and above',
                  dense: true,
                ),
            ]),
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            SectionLabel('Progress to ${next.label}'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: context.bg, color: AppColors.accentGold),
                ),
                const SizedBox(height: 8),
                Text('$tripsToNext more trips and maintain ${next.minRating}+ rating to reach ${next.label}', style: theme.textTheme.bodyMedium),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Tier requirements', style: theme.textTheme.titleSmall),
              children: [
                for (final t in DriverTier.values)
                  IconRow(
                    icon: Icons.emoji_events_rounded,
                    iconColor: t == tier ? AppColors.accentGoldText : null,
                    iconBg: t == tier ? AppColors.accentGoldTint : null,
                    title: t.label,
                    subtitle: '${t.minTrips}+ trips · ${t.minRating}+ rating · ≤${t.maxCancel}% cancellations',
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: LinkText('How is my tier calculated?', onTap: () => context.push(Routes.faq))),
        ],
      ),
    );
  }
}
