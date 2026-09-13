import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 2.5 — Upcoming scheduled trips.
class ScheduledTripsScreen extends StatelessWidget {
  const ScheduledTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trips = [...MockData.scheduled]..sort((a, b) => a.time.compareTo(b.time));
    if (trips.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Upcoming Trips')),
        body: const EmptyState(icon: Icons.calendar_month_rounded, title: 'No scheduled trips yet'),
      );
    }
    final next = trips.first;
    final later = trips.skip(1).toList();
    final until = next.time.difference(MockData.now);
    final soon = until.inMinutes <= 30;
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Trips')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.tint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: const Border(left: BorderSide(color: AppColors.primaryBlue, width: 4)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${dayLabel(next.time, now: MockData.now)} · ${timeOf(next.time)}',
                        style: theme.textTheme.titleLarge?.copyWith(fontFeatures: AppText.tabular),
                      ),
                    ),
                    StatusBadge('in ${until.inHours} h ${until.inMinutes % 60} min', kind: BadgeKind.scheduled),
                  ],
                ),
                const SizedBox(height: 10),
                _Route(next),
                const SizedBox(height: 14),
                PrimaryButton(label: 'Start Heading There', onPressed: soon ? () => context.go(Routes.home) : null),
                if (!soon)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Enabled 30 minutes before pickup',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
                    ),
                  ),
                Center(child: LinkText('Cancel', color: AppColors.dangerRed, onTap: () => context.push(Routes.cancelTrip))),
              ],
            ),
          ),
          if (later.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionLabel('Later'),
            for (final t in later)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dayMonth(t.time)} · ${timeOf(t.time)}',
                            style: theme.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t.pickup.area ?? t.pickup.name} → ${t.destination.area ?? t.destination.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(naira(t.fare), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
                    Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            "We'll remind you 30 minutes before each scheduled trip",
            style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Route extends StatelessWidget {
  const _Route(this.t);
  final ScheduledTrip t;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${t.pickup.area ?? t.pickup.name} → ${t.destination.area ?? t.destination.name}',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Text(naira(t.fare), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular)),
        const SizedBox(width: 8),
        StatusBadge(t.category.label, kind: BadgeKind.info),
      ],
    );
  }
}
