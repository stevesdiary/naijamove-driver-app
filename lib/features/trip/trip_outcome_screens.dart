import 'dart:async';

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
import '../../data/api/api_client.dart';
import '../../data/mock_data.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/trips_repository.dart';
import 'trip_state.dart';

/// Shared "Go Online Again / Take a Break" footer used by every outcome screen.
class _OutcomeFooter extends ConsumerWidget {
  const _OutcomeFooter();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> finish(bool online) async {
      ref.read(activeTripProvider.notifier).clear();
      if (!online) await ref.read(driverAccountProvider.notifier).setOnline(false);
      if (context.mounted) context.go(Routes.home);
    }

    return Column(
      children: [
        PrimaryButton(label: 'Go Online Again', color: AppColors.successTeal, onPressed: () => finish(true)),
        const SizedBox(height: 4),
        GhostButton(label: 'Take a Break', onPressed: () => finish(false)),
      ],
    );
  }
}

/// 3.4 — Trip completed: hero fare, breakdown, inline rider rating.
class TripCompletedScreen extends ConsumerStatefulWidget {
  const TripCompletedScreen({super.key});
  @override
  ConsumerState<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends ConsumerState<TripCompletedScreen> {
  int _stars = 0;
  final _tags = <String>{};
  bool _rated = false;

  Future<void> _submit(String tripId) async {
    try {
      await ref.read(tripsRepositoryProvider).rateRider(tripId, rating: _stars, comment: _tags.join(', '));
      setState(() => _rated = true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = ref.watch(activeTripProvider);
    final r = trip?.request ?? MockData.request;
    final gross = trip?.finalFareKobo != null ? trip!.finalFareKobo! ~/ 100 : r.fare;
    final net = trip?.driverAmountKobo != null ? trip!.driverAmountKobo! ~/ 100 : (gross * 0.8).round();
    final commission = gross - net;
    const base = 600;
    const booking = 200;
    final perKm = gross - base - booking;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: MapCanvas(pickup: r.pickup.at, destination: r.destination.at, showRoute: true, dimmed: true)),
            Align(
              alignment: Alignment.bottomCenter,
              child: SheetSurface(
                scrollable: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(child: SuccessCheck(size: 72)),
                    const SizedBox(height: 8),
                    Text('Trip Complete!', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      naira(net),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.earningsGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                        fontFeatures: AppText.tabular,
                      ),
                    ),
                    Text('earned on this trip', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FareBreakdown(
                      rows: [
                        ('Base fare', naira(base)),
                        ('Distance (${r.distanceKm} km)', naira(perKm)),
                        ('Booking fee', naira(booking)),
                        ('Platform commission', '− ${naira(commission)}'),
                      ],
                      total: naira(net),
                      totalLabel: 'Net to you',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Stat(label: 'Distance', value: '${r.distanceKm} km'),
                        _Stat(label: 'Duration', value: '${r.durationMin} min'),
                        _Stat(label: 'Route', value: '${r.pickup.area ?? r.pickup.name} → ${r.destination.area ?? r.destination.name}', flex: 2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: context.border),
                    const SizedBox(height: 8),
                    if (_rated)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.successTeal, size: 18),
                          const SizedBox(width: 6),
                          Text('Thanks for rating ${r.rider.firstName}', style: theme.textTheme.labelLarge),
                        ],
                      )
                    else ...[
                      Text('How was ${r.rider.firstName}?', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Center(child: StarRating(value: _stars, size: 36, onChanged: (v) => setState(() => _stars = v))),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in MockData.riderFeedbackTags)
                            SelectChip(
                              label: t,
                              selected: _tags.contains(t),
                              onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinkText('Skip', color: context.textSecondary, onTap: () => setState(() => _rated = true)),
                          const SizedBox(width: 24),
                          LinkText('Submit', onTap: _stars > 0 && trip != null ? () => _submit(trip.tripId) : null),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _OutcomeFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.flex = 1});
  final String label;
  final String value;
  final int flex;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
          Text(value, style: theme.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// 3.9 — Cancel trip (driver-initiated).
class CancelTripScreen extends ConsumerStatefulWidget {
  const CancelTripScreen({super.key});
  @override
  ConsumerState<CancelTripScreen> createState() => _CancelTripScreenState();
}

class _CancelTripScreenState extends ConsumerState<CancelTripScreen> {
  String? _reason;
  final _other = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final reason = _reason == 'Other' ? _other.text.trim() : _reason!;
    setState(() => _busy = true);
    try {
      final ctrl = ref.read(activeTripProvider.notifier);
      if (ref.read(activeTripProvider) != null) await ctrl.cancel(reason);
      if (!mounted) return;
      showToast(context, 'Trip cancelled', kind: ToastKind.error);
      context.go(Routes.home);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _reason != null && (_reason != 'Other' || _other.text.trim().isNotEmpty);
    return Scaffold(
      appBar: AppBar(title: const Text('Cancel this trip?')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.accentGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your cancellation rate is ${MockData.driver.cancellationRate}%. Cancelling often can affect your Top Driver tier.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final reason in MockData.cancelReasons)
                    InkWell(
                      onTap: () => setState(() => _reason = reason),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            Icon(
                              _reason == reason ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: _reason == reason ? AppColors.primaryBlue : context.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(reason, style: theme.textTheme.bodyLarge)),
                          ],
                        ),
                      ),
                    ),
                  if (_reason == 'Other')
                    AppTextField(hint: 'Tell us briefly', controller: _other, maxLength: 200, maxLines: 2, onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: SecondaryButton(label: 'Keep Trip', onPressed: () => context.pop())),
                  const SizedBox(width: 12),
                  Expanded(child: DestructiveButton(label: 'Cancel Trip', onPressed: valid && !_busy ? _cancel : null)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3.6 — SOS overlay.
class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trip = ref.watch(activeTripProvider);
    final rider = trip?.request.rider.firstName ?? '—';
    const options = [
      (Icons.phone_in_talk_rounded, 'Call Emergency Services (112)'),
      (Icons.share_location_rounded, 'Share My Location with NaijaMove Safety Team'),
      (Icons.notifications_active_rounded, 'Alert NaijaMove Safety Team'),
      (Icons.group_rounded, 'Notify Emergency Contact'),
    ];
    return Scaffold(
      backgroundColor: AppColors.dangerRed.withValues(alpha: 0.96),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('EMERGENCY',
                  style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: 2),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              for (final (icon, label) in options) ...[
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    onTap: () => showToast(context, 'Sent — the Safety Team has your location', kind: ToastKind.success),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Icon(icon, color: AppColors.dangerRed),
                          const SizedBox(width: 14),
                          Expanded(child: Text(label, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary))),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              Text(
                'Rider: $rider · Trip ${trip?.tripId ?? '—'}\nLocation shared: Victoria Island, Lagos',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.dangerRed,
                    side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text("I'm Safe — Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3.7 — Rider no-show.
class NoShowScreen extends ConsumerStatefulWidget {
  const NoShowScreen({super.key});
  @override
  ConsumerState<NoShowScreen> createState() => _NoShowScreenState();
}

class _NoShowScreenState extends ConsumerState<NoShowScreen> {
  Timer? _clock;
  bool _confirmed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _markNoShow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Marking a no-show will cancel this trip.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Waiting')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Trip'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(activeTripProvider.notifier).cancel('Rider no-show');
      setState(() => _confirmed = true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = ref.watch(activeTripProvider);
    final r = trip?.request ?? MockData.request;
    final waited = DateTime.now().difference(trip?.arrivedAt ?? DateTime.now().subtract(const Duration(minutes: 5)));
    final canMark = waited.inMinutes >= 5;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: MapCanvas(pickup: r.pickup.at, currentLocation: r.pickup.at)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SheetSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _confirmed
                    ? [
                        Row(children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.successTeal),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Trip cancelled — no-show fee applied', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.successTeal))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('Cancellation fee earned', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                          const Spacer(),
                          Text(naira(200), style: theme.textTheme.titleLarge?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
                        ]),
                        const SizedBox(height: 16),
                        const _OutcomeFooter(),
                      ]
                    : [
                        Text('Waiting for rider…', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text("You've been waiting ${waited.inMinutes} min",
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Avatar(name: r.rider.firstName, size: 44),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r.rider.firstName, style: theme.textTheme.titleMedium)),
                          AppIconButton(icon: Icons.call_rounded, fill: AppColors.primaryBlue, iconColor: Colors.white, onPressed: () {}),
                        ]),
                        const SizedBox(height: 16),
                        DestructiveButton(label: 'Mark as No-Show', onPressed: canMark && !_busy ? _markNoShow : null),
                        if (!canMark)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Available after 5 minutes of waiting',
                                style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
                          ),
                        const SizedBox(height: 4),
                        GhostButton(label: 'Keep Waiting', onPressed: () => context.pop()),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3.10 — Rider cancelled interrupt.
class RiderCancelledScreen extends ConsumerStatefulWidget {
  const RiderCancelledScreen({super.key});
  @override
  ConsumerState<RiderCancelledScreen> createState() => _RiderCancelledScreenState();
}

class _RiderCancelledScreenState extends ConsumerState<RiderCancelledScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = ref.watch(activeTripProvider);
    final r = trip?.request ?? MockData.request;
    final feeEarned = trip?.phase == TripPhase.arrived ||
        (trip?.acceptedAt != null && DateTime.now().difference(trip!.acceptedAt!).inMinutes >= 2);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: MapCanvas(pickup: r.pickup.at, dimmed: true)),
          Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppCard(
                  shadow: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('${r.rider.firstName} cancelled the trip', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text("You don't need to do anything else.",
                          style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: feeEarned ? AppColors.successTint : context.bg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(feeEarned ? Icons.payments_rounded : Icons.info_outline_rounded,
                                color: feeEarned ? AppColors.earningsGreen : context.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feeEarned ? 'Cancellation fee earned · ${naira(200)}' : 'No fee for this cancellation',
                                style: theme.textTheme.labelLarge?.copyWith(color: feeEarned ? AppColors.earningsGreen : context.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('${r.pickup.area ?? r.pickup.name} · 3 min · 1.1 km driven toward pickup',
                          style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      const _OutcomeFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
