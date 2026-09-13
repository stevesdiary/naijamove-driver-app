import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/models.dart';
import 'trip_state.dart';

/// 2.4 + 3.1 + 3.2 + 3.3 + 3.5 — one screen, phase-driven.
/// Map fills the screen; the bottom sheet changes with [TripPhase].
class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key, this.justAccepted = false});
  final bool justAccepted;
  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  bool _confirming = false;
  bool _expanded = false;
  bool _busy = false;
  Timer? _progressTimer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    if (widget.justAccepted) {
      _confirming = true;
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _confirming = false);
      });
    }
    // Simulated route progress so the marker moves on the stylised map.
    _progressTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      final t = ref.read(activeTripProvider);
      if (t == null || !mounted) return;
      if (t.phase == TripPhase.navigating || t.phase == TripPhase.inProgress) {
        setState(() => _progress = (_progress + 0.02).clamp(0, 1));
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _arrived() => _run(() async {
        await ref.read(activeTripProvider.notifier).arrived();
        setState(() {
          _progress = 0;
          _expanded = true;
        });
      });

  Future<void> _complete() async {
    final ok = await _confirm('End this trip?', 'Make sure you have reached the destination.', 'End Trip');
    if (ok != true) return;
    await _run(() async {
      await ref.read(activeTripProvider.notifier).complete();
      if (mounted) context.pushReplacement(Routes.tripCompleted);
    });
  }

  Future<bool?> _confirm(String title, String body, String action) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider);
    if (trip == null) {
      // Trip was cleared (rider cancelled / no-show) while this screen was up.
      return const Scaffold(body: SizedBox.shrink());
    }
    final r = trip.request;
    final phase = trip.phase;
    final toPickup = phase == TripPhase.navigating || phase == TripPhase.arrived;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: MapCanvas(
                pickup: r.pickup.at,
                destination: toPickup ? null : r.destination.at,
                stops: toPickup ? const [] : [for (final s in r.stops) if (s.at != null) s.at!],
                showRoute: true,
                routeProgress: phase == TripPhase.arrived ? 1 : _progress,
                currentLocation: toPickup ? null : r.pickup.at,
                dimmed: _confirming,
              ),
            ),
            // Floating top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TopBar(trip: trip, progress: _progress),
              ),
            ),
            // SOS (in-progress only)
            if (phase == TripPhase.inProgress)
              Positioned(
                right: 16,
                bottom: 200,
                child: _SosButton(onTriggered: () => context.push(Routes.sos)),
              ),
            // Bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _confirming
                    ? _AcceptedSheet(request: r)
                    : switch (phase) {
                        TripPhase.navigating => _NavigatingSheet(
                            trip: trip,
                            expanded: _expanded,
                            busy: _busy,
                            onToggle: () => setState(() => _expanded = !_expanded),
                            onArrived: _arrived,
                          ),
                        TripPhase.arrived => _ArrivedSheet(trip: trip, busy: _busy, onStarted: () => setState(() => _progress = 0)),
                        TripPhase.inProgress => _InProgressSheet(
                            trip: trip,
                            expanded: _expanded,
                            busy: _busy,
                            onToggle: () => setState(() => _expanded = !_expanded),
                            onComplete: _complete,
                          ),
                        TripPhase.completed => const SizedBox.shrink(),
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.trip, required this.progress});
  final ActiveTrip trip;
  final double progress;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = trip.request;
    final inProgress = trip.phase == TripPhase.inProgress;
    final etaMin = inProgress ? (r.durationMin * (1 - progress)).ceil() : (4 * (1 - progress)).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: inProgress ? AppColors.textPrimary.withValues(alpha: 0.85) : context.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          if (!inProgress) ...[
            Avatar(name: r.rider.firstName, size: 32),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inProgress ? (r.destination.area ?? r.destination.name) : r.rider.firstName,
                  style: theme.textTheme.titleSmall?.copyWith(color: inProgress ? Colors.white : context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!inProgress)
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                    const SizedBox(width: 2),
                    Text('${r.rider.rating}', style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary)),
                  ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.phase == TripPhase.arrived ? 'Here' : '$etaMin min',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: AppText.tabular,
                  color: inProgress ? Colors.white : AppColors.primaryBlue,
                ),
              ),
              Text(
                inProgress ? 'to destination' : 'to pickup',
                style: theme.textTheme.labelSmall?.copyWith(color: inProgress ? Colors.white70 : context.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Turn-by-turn strip pinned above the sheet.
class _NavBar extends StatelessWidget {
  const _NavBar({required this.instruction, required this.distance});
  final String instruction;
  final String distance;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.turn_right_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(distance, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontFeatures: AppText.tabular)),
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider, this.compact = false});
  final Rider rider;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Avatar(name: rider.firstName, size: compact ? 40 : 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rider.firstName, style: theme.textTheme.titleMedium),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                const SizedBox(width: 2),
                Text('${rider.rating} · ${rider.trips} trips',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
              ]),
            ],
          ),
        ),
        Icon(rider.payment.icon, size: 18, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(rider.payment.label, style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary)),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({this.sos = false, this.maps = true});
  final bool sos;
  final bool maps;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AppIconButton(icon: Icons.call_rounded, label: 'Call', onPressed: () {})),
        Expanded(child: AppIconButton(icon: Icons.chat_bubble_rounded, label: 'Message', onPressed: () => context.push(Routes.riderChat))),
        if (maps) Expanded(child: AppIconButton(icon: Icons.map_rounded, label: 'Maps', onPressed: () {})),
        if (sos)
          Expanded(
            child: AppIconButton(
              icon: Icons.sos_rounded,
              label: 'SOS',
              fill: AppColors.dangerTint,
              iconColor: AppColors.dangerRed,
              onPressed: () => context.push(Routes.sos),
            ),
          ),
      ],
    );
  }
}

/// 2.4 — brief confirmation before navigation begins.
class _AcceptedSheet extends StatelessWidget {
  const _AcceptedSheet({required this.request});
  final TripRequest request;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetSurface(
      key: const ValueKey('accepted'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.successTeal, size: 32),
            const SizedBox(width: 10),
            Text('Trip accepted!', style: theme.textTheme.headlineMedium),
          ]),
          const SizedBox(height: 4),
          Text('Navigating to pickup…', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 14),
          Text('Pickup: ${request.rider.firstName}', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(request.pickup.address, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          const StatusBadge('4 min to pickup', kind: BadgeKind.info, icon: Icons.schedule_rounded),
        ],
      ),
    );
  }
}

/// 3.1
class _NavigatingSheet extends ConsumerWidget {
  const _NavigatingSheet({required this.trip, required this.expanded, required this.busy, required this.onToggle, required this.onArrived});
  final ActiveTrip trip;
  final bool expanded;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onArrived;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = trip.request;
    return Column(
      key: const ValueKey('navigating'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _NavBar(instruction: 'Turn right onto Ozumba Mbadiwe', distance: '200 m'),
        SheetSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                child: Row(children: [
                  const RouteDot(color: AppColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r.pickup.address, style: theme.textTheme.titleSmall, maxLines: expanded ? 3 : 1, overflow: TextOverflow.ellipsis)),
                  Icon(expanded ? Icons.expand_more_rounded : Icons.expand_less_rounded, color: context.textSecondary),
                ]),
              ),
              if (expanded) ...[
                const SizedBox(height: 14),
                _RiderCard(rider: r.rider),
                const SizedBox(height: 14),
                const _Actions(),
                const SizedBox(height: 6),
                Center(child: LinkText('Cancel Trip', color: AppColors.dangerRed, onTap: () => context.push(Routes.cancelTrip))),
              ],
              const SizedBox(height: 12),
              PrimaryButton(label: "I've Arrived", icon: Icons.location_on_rounded, onPressed: busy ? null : onArrived, loading: busy),
            ],
          ),
        ),
      ],
    );
  }
}

/// 3.2 — arrived; PIN gate.
class _ArrivedSheet extends ConsumerStatefulWidget {
  const _ArrivedSheet({required this.trip, required this.busy, required this.onStarted});
  final ActiveTrip trip;
  final bool busy;
  final VoidCallback onStarted;
  @override
  ConsumerState<_ArrivedSheet> createState() => _ArrivedSheetState();
}

class _ArrivedSheetState extends ConsumerState<_ArrivedSheet> {
  bool _error = false;
  String? _message;
  bool _verifying = false;
  Timer? _clock;
  Duration _waited = Duration.zero;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _waited = DateTime.now().difference(widget.trip.arrivedAt ?? DateTime.now()));
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _verify(String pin) async {
    setState(() {
      _verifying = true;
      _error = false;
      _message = null;
    });
    try {
      await ref.read(activeTripProvider.notifier).startWithPin(pin);
      HapticFeedback.mediumImpact();
      widget.onStarted();
    } on ApiException catch (e) {
      setState(() {
        _error = true;
        _message = e.statusCode == 401 ? 'Incorrect PIN. Ask the rider to check their app.' : e.message;
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.trip.request;
    final canNoShow = _waited.inMinutes >= 5;
    return SheetSurface(
      key: const ValueKey('arrived'),
      padding: EdgeInsets.zero,
      handle: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("You've arrived at pickup", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiderCard(rider: r.rider, compact: true),
                const SizedBox(height: 6),
                Text(r.pickup.address, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
                const SizedBox(height: 16),
                Row(children: [
                  Text('Ask rider for their PIN', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  LinkText('What is this?', size: 12, onTap: () => _explain(context)),
                  const Spacer(),
                  Text('Waiting ${_waited.inMinutes}:${(_waited.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
                ]),
                const SizedBox(height: 10),
                OtpInput(length: 4, error: _error, onCompleted: _verifying ? (_) {} : _verify),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.dangerRed)),
                ],
                if (_verifying) ...[
                  const SizedBox(height: 10),
                  const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
                ],
                const SizedBox(height: 14),
                const _Actions(maps: false),
                const SizedBox(height: 4),
                Center(
                  child: LinkText(
                    canNoShow ? 'Rider is a no-show' : 'No-show available after 5 min',
                    color: canNoShow ? AppColors.dangerRed : context.textSecondary,
                    size: 13,
                    onTap: canNoShow ? () => context.push(Routes.noShow) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _explain(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Trip PIN'),
          content: const Text("The rider's PIN confirms you have the right passenger. They can see it in their app."),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
        ),
      );
}

/// 3.3 + 3.5
class _InProgressSheet extends ConsumerWidget {
  const _InProgressSheet({required this.trip, required this.expanded, required this.busy, required this.onToggle, required this.onComplete});
  final ActiveTrip trip;
  final bool expanded;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onComplete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = trip.request;
    final stops = r.stops;
    return Column(
      key: const ValueKey('inProgress'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _NavBar(instruction: 'Continue on Third Mainland Bridge', distance: '2.4 km'),
        SheetSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onToggle,
                child: Row(children: [
                  Text(naira(r.fare),
                      style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('· ${r.distanceKm} km', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                  const Spacer(),
                  Icon(expanded ? Icons.expand_more_rounded : Icons.expand_less_rounded, color: context.textSecondary),
                ]),
              ),
              if (expanded) ...[
                const SizedBox(height: 12),
                _RiderCard(rider: r.rider, compact: true),
                const SizedBox(height: 12),
                _RouteProgress(stops: stops.length, done: trip.stopsDone),
                for (var i = 0; i < stops.length; i++) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    RouteDot(color: i < trip.stopsDone ? AppColors.successTeal : context.textSecondary, square: true),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Stop ${i + 1} · ${stops[i].name}', style: theme.textTheme.bodyMedium)),
                    if (i == trip.stopsDone)
                      SizedBox(
                        width: 96,
                        child: SecondaryButton(label: 'Arrived', onPressed: () => ref.read(activeTripProvider.notifier).stopReached()),
                      )
                    else if (i < trip.stopsDone)
                      const Icon(Icons.check_rounded, color: AppColors.successTeal, size: 18),
                  ]),
                ],
                const SizedBox(height: 12),
                const _Actions(sos: true, maps: false),
                const SizedBox(height: 4),
                Center(child: LinkText('End Trip Early', color: AppColors.dangerRed, onTap: onComplete)),
              ],
              const SizedBox(height: 12),
              PrimaryButton(label: 'End Trip', icon: Icons.flag_rounded, onPressed: busy ? null : onComplete, loading: busy, color: AppColors.successTeal),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteProgress extends StatelessWidget {
  const _RouteProgress({required this.stops, required this.done});
  final int stops;
  final int done;
  @override
  Widget build(BuildContext context) {
    final points = stops + 2;
    return Row(
      children: [
        for (var i = 0; i < points; i++) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == 0
                  ? AppColors.primaryBlue
                  : i == points - 1
                      ? AppColors.dangerRed
                      : (i <= done ? AppColors.successTeal : context.border),
              shape: BoxShape.circle,
            ),
          ),
          if (i < points - 1) Expanded(child: Container(height: 2, color: i < done + 1 ? AppColors.primaryBlue : context.border)),
        ],
      ],
    );
  }
}

/// Floating SOS — 2 s press-and-hold with fill animation.
class _SosButton extends StatefulWidget {
  const _SosButton({required this.onTriggered});
  final VoidCallback onTriggered;
  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _c.reset();
        widget.onTriggered();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.dangerRed,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.dangerRed.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CircularProgressIndicator(value: _c.value, strokeWidth: 4, color: Colors.white, backgroundColor: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
