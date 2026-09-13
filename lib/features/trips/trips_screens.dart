import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/api/api_config.dart';
import '../../data/api/wire.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/trips_repository.dart';

/// Live history when a backend is configured; mock rows otherwise.
final tripHistoryProvider = FutureProvider<List<Trip>>((ref) async {
  if (ApiConfig.useMock) return MockData.trips;
  final rows = await ref.watch(tripsRepositoryProvider).history(limit: 50);
  return rows.map(_fromWire).toList();
});

Trip _fromWire(DriverTrip t) {
  final gross = t.fareKobo ~/ 100;
  final net = t.driverAmountKobo ~/ 100;
  return Trip(
    id: t.id,
    pickup: Place(name: t.pickupAddress.split(',').first, address: t.pickupAddress, area: t.pickupAddress.split(',').last.trim()),
    destination: Place(name: t.destinationAddress.split(',').first, address: t.destinationAddress, area: t.destinationAddress.split(',').last.trim()),
    date: t.createdAt,
    status: switch (t.status) {
      WireTripStatus.completed => TripStatus.completed,
      WireTripStatus.cancelled => t.cancelledBy == 'driver'
          ? TripStatus.cancelledByDriver
          : t.cancelledBy == 'rider'
              ? TripStatus.cancelledByRider
              : TripStatus.cancelledBySystem,
      WireTripStatus.inProgress => TripStatus.inProgress,
      WireTripStatus.driverArrived => TripStatus.arrived,
      _ => TripStatus.navigating,
    },
    distanceKm: (t.distanceMeters / 100).round() / 10,
    durationMin: (t.durationSeconds / 60).round(),
    gross: gross,
    commission: gross - net,
    tip: t.tipKobo ~/ 100,
    category: VehicleCategory.economy,
    rider: const Rider(firstName: 'Rider', rating: 5, trips: 0, payment: PaymentMethodType.card),
    cancelledBy: t.cancelledBy,
    cancelReason: t.cancellationReason,
    baseFare: 0,
    bookingFee: 0,
  );
}

/// 5.1 — Trip history.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});
  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(tripHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Trips'),
        actions: [TextButton(onPressed: () => showToast(context, 'Statement will be emailed to you'), child: const Text('Download')), const SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilterTabs(labels: const ['All', 'Completed', 'Cancelled', 'Disputed'], selected: _filter, onChanged: (i) => setState(() => _filter = i)),
          ),
          Expanded(
            child: history.when(
              loading: () => ListView(padding: const EdgeInsets.all(16), children: const [SkeletonBox(height: 120), SizedBox(height: 12), SkeletonBox(height: 120)]),
              error: (e, _) => EmptyState(icon: Icons.cloud_off_rounded, title: "Couldn't load trips", subtitle: '$e', ctaLabel: 'Retry', onCta: () => ref.invalidate(tripHistoryProvider)),
              data: (all) {
                final list = switch (_filter) {
                  1 => all.where((t) => t.status == TripStatus.completed),
                  2 => all.where((t) => t.isCancelled),
                  3 => all.where((t) => t.status == TripStatus.disputed),
                  _ => all,
                }
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.directions_car_rounded, title: 'No trips yet', subtitle: 'Go online to start.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(tripHistoryProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final group in _groupByDay(list)) ...[
                        SectionLabel(dayLabel(group.$1, now: ApiConfig.useMock ? MockData.now : null)),
                        for (final t in group.$2) _TripCard(trip: t),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<(DateTime, List<Trip>)> _groupByDay(List<Trip> trips) {
    final map = <DateTime, List<Trip>>{};
    for (final t in trips) {
      map.putIfAbsent(DateTime(t.date.year, t.date.month, t.date.day), () => []).add(t);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (k, map[k]!)];
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, kind) = switch (trip.status) {
      TripStatus.completed => ('Completed', BadgeKind.completed),
      TripStatus.disputed => ('Disputed', BadgeKind.surge),
      TripStatus.inProgress || TripStatus.arrived || TripStatus.navigating || TripStatus.accepted => ('In progress', BadgeKind.inProgress),
      _ => ('Cancelled', BadgeKind.cancelled),
    };
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(trip.isCancelled ? Routes.tripDetail(trip.id) : Routes.tripEarnings(trip.id)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 72,
              height: 72,
              child: MapCanvas(pickup: trip.pickup.at ?? const Offset(0.3, 0.6), destination: trip.isCancelled ? null : (trip.destination.at ?? const Offset(0.7, 0.3)), showRoute: !trip.isCancelled),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.routeLabel, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${timeOf(trip.date)} · ${trip.durationMin} min · ${trip.distanceKm} km',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
                const SizedBox(height: 6),
                Row(children: [
                  StatusBadge(label, kind: kind),
                  const Spacer(),
                  Text(
                    trip.isCancelled ? (trip.cancellationFee > 0 ? naira(trip.cancellationFee) : '—') : naira(trip.net),
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular),
                  ),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.textSecondary),
        ],
      ),
    );
  }
}

/// 5.2 — Cancelled trip detail.
class CancelledTripScreen extends ConsumerWidget {
  const CancelledTripScreen({super.key, required this.tripId});
  final String tripId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trips = ref.watch(tripHistoryProvider).value ?? MockData.trips;
    final t = trips.firstWhere((t) => t.id == tripId, orElse: () => trips.firstWhere((t) => t.isCancelled, orElse: () => trips.first));
    final by = switch (t.status) {
      TripStatus.cancelledByDriver => 'You',
      TripStatus.cancelledByRider => 'Rider',
      TripStatus.noShow => 'You (rider no-show)',
      _ => t.cancelledBy ?? 'System',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Cancelled Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(height: 150, child: MapCanvas(pickup: t.pickup.at ?? const Offset(0.4, 0.5))),
          ),
          const SizedBox(height: 14),
          Text('${fullDate(t.date)} · ${timeOf(t.date)}', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(t.pickup.address, style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              IconRow(icon: Icons.cancel_rounded, iconColor: AppColors.dangerRed, iconBg: AppColors.dangerTint, title: 'Cancelled by', trailing: Text(by, style: theme.textTheme.titleSmall), dense: true),
              if (t.cancelReason != null) IconRow(icon: Icons.notes_rounded, title: 'Reason', subtitle: t.cancelReason, dense: true),
              if (t.waitedSeconds != null) IconRow(icon: Icons.timer_rounded, title: 'Waited', trailing: Text('${(t.waitedSeconds! / 60).round()} min', style: theme.textTheme.titleSmall), dense: true),
              IconRow(
                icon: Icons.payments_rounded,
                iconColor: t.cancellationFee > 0 ? AppColors.earningsGreen : null,
                iconBg: t.cancellationFee > 0 ? AppColors.earningsTint : null,
                title: 'Cancellation fee',
                trailing: Text(
                  t.cancellationFee > 0 ? naira(t.cancellationFee) : 'No fee applied',
                  style: theme.textTheme.titleSmall?.copyWith(color: t.cancellationFee > 0 ? AppColors.earningsGreen : context.textSecondary, fontFeatures: AppText.tabular),
                ),
                dense: true,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Center(child: LinkText('Report an Issue', onTap: () => context.push(Routes.supportCategories))),
        ],
      ),
    );
  }
}
