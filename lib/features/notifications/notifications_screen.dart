import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 7.1 — Notifications centre.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filter = 0;
  late List<AppNotification> _items = [...MockData.notifications];

  static const _filters = ['All', 'Trips', 'Earnings', 'Safety', 'Account'];

  @override
  Widget build(BuildContext context) {
    final list = switch (_filter) {
      1 => _items.where((n) => n.kind == NotificationKind.trip),
      2 => _items.where((n) => n.kind == NotificationKind.earnings || n.kind == NotificationKind.bonus),
      3 => _items.where((n) => n.kind == NotificationKind.safety),
      4 => _items.where((n) => n.kind == NotificationKind.account),
      _ => _items,
    }
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: LinkText('Mark all as read', size: 13, onTap: () {
                setState(() => _items = [for (final n in _items) AppNotification(title: n.title, body: n.body, time: n.time, kind: n.kind)]);
              }),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilterTabs(labels: _filters, selected: _filter, onChanged: (i) => setState(() => _filter = i)),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'You are all caught up')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final group in _groupByDay(list)) ...[
                        SectionLabel(dayLabel(group.$1, now: MockData.now)),
                        for (final n in group.$2) _Row(n),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<(DateTime, List<AppNotification>)> _groupByDay(List<AppNotification> items) {
    final map = <DateTime, List<AppNotification>>{};
    for (final n in items) {
      map.putIfAbsent(DateTime(n.time.year, n.time.month, n.time.day), () => []).add(n);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (k, map[k]!)];
  }
}

class _Row extends StatelessWidget {
  const _Row(this.n);
  final AppNotification n;
  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (n.kind) {
      NotificationKind.trip => (Icons.directions_car_rounded, AppColors.primaryBlue, context.tint),
      NotificationKind.earnings => (Icons.account_balance_wallet_rounded, AppColors.earningsGreen, AppColors.earningsTint),
      NotificationKind.bonus => (Icons.star_rounded, AppColors.accentGoldText, AppColors.accentGoldTint),
      NotificationKind.safety => (Icons.shield_rounded, AppColors.dangerRed, AppColors.dangerTint),
      NotificationKind.account => (Icons.person_rounded, AppColors.primaryBlue, context.tint),
    };
    return IconRow(
      icon: icon,
      iconColor: color,
      iconBg: bg,
      title: n.title,
      subtitle: '${n.body}\n${relative(n.time, now: MockData.now)}',
      trailing: n.unread ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle)) : null,
      titleColor: n.unread ? context.textPrimary : null,
      onTap: () {},
    );
  }
}
