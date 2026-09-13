import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/api/api_client.dart';
import '../../data/api/wire.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/driver_repository.dart';
import '../trip/trip_state.dart';
import 'request_sheet.dart';

/// 2.1 / 2.2 — Home dashboard. Map, the Online/Offline hero toggle, today's
/// earnings sheet, and the incoming-request modal while online.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _heatmap = true;
  bool _toggling = false;
  bool _showingRequest = false;

  Future<void> _toggle(bool online) async {
    setState(() => _toggling = true);
    try {
      await ref.read(driverAccountProvider.notifier).setOnline(online);
      final err = ref.read(driverAccountProvider).error;
      if (err is ApiException) {
        if (mounted) showToast(context, err.message, kind: ToastKind.error);
        await ref.read(driverAccountProvider.notifier).refresh();
        return;
      }
      final offers = ref.read(incomingOfferProvider.notifier);
      online ? offers.startListening() : offers.stopListening();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _presentRequest(TripRequest req) async {
    if (_showingRequest) return;
    _showingRequest = true;
    final offers = ref.read(incomingOfferProvider.notifier);
    final offerId = offers.offerId ?? req.id;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => TripRequestSheet(request: req),
    );
    _showingRequest = false;
    if (!mounted) return;
    if (accepted == true) {
      try {
        await ref.read(activeTripProvider.notifier).accept(req, offerId: offerId);
        offers.stopListening();
        if (mounted) context.push(Routes.activeTrip, extra: true);
      } on ApiException catch (e) {
        if (mounted) showToast(context, e.message, kind: ToastKind.error);
        offers.dismiss();
      }
    } else {
      unawaited(ref.read(activeTripProvider.notifier).decline(offerId).catchError((_) {}));
      offers.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = ref.watch(driverAccountProvider);
    final online = account.value?.isOnline ?? false;
    final status = account.value?.status ?? DriverAccountStatus.pending;
    final unread = MockData.notifications.where((n) => n.unread).length;
    final scheduledCount = MockData.scheduled.length;

    ref.listen(incomingOfferProvider, (_, req) {
      if (req != null && online) _presentRequest(req);
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapCanvas(
              currentLocation: const Offset(0.5, 0.55),
              pulse: online,
              heatmap: _heatmap && status.canGoOnline,
              drivers: const [],
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: _shadow),
                        child: const BrandLockup(size: 22),
                      ),
                      const Spacer(),
                      if (scheduledCount > 0) ...[
                        _TopIcon(
                          icon: Icons.calendar_month_rounded,
                          badge: '$scheduledCount',
                          onTap: () => context.push(Routes.scheduled),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _TopIcon(
                        icon: Icons.notifications_rounded,
                        dot: unread > 0,
                        onTap: () => context.push(Routes.notifications),
                      ),
                    ],
                  ),
                  if (online) ...[
                    const SizedBox(height: 12),
                    const _WaitingChip(),
                  ],
                ],
              ),
            ),
          ),
          // Sheet + toggle
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MapFab(icon: Icons.my_location_rounded, onPressed: () {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _OnlineToggle(
                    online: online,
                    enabled: status.canGoOnline && !_toggling,
                    loading: _toggling,
                    onTap: () => _toggle(!online),
                  ),
                ),
                const SizedBox(height: 12),
                SheetSurface(
                  handle: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!status.canGoOnline) ...[
                        _StatusBanner(status: status),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  naira(online ? MockData.todayEarnings : 0),
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    color: AppColors.earningsGreen,
                                    fontFeatures: AppText.tabular,
                                    fontSize: 28,
                                  ),
                                ),
                                Text('${online ? MockData.todayTrips : 0} trips',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                              ],
                            ),
                          ),
                          LinkText('View Details', onTap: () => context.go(Routes.earnings)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (online)
                        _BonusBanner(bonus: MockData.bonuses.first)
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectChip(
                            label: 'Show demand zones',
                            icon: Icons.layers_rounded,
                            selected: _heatmap,
                            onTap: () => setState(() => _heatmap = !_heatmap),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _shadow = [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))];

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.onTap, this.dot = false, this.badge});
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final String? badge;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: context.surface, shape: BoxShape.circle, boxShadow: _shadow),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: context.textPrimary, size: 22),
            if (dot)
              Positioned(
                right: 11,
                top: 11,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle)),
              ),
            if (badge != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(8)),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaitingChip extends StatefulWidget {
  const _WaitingChip();
  @override
  State<_WaitingChip> createState() => _WaitingChipState();
}

class _WaitingChipState extends State<_WaitingChip> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.7, end: 1.0).animate(_c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(20), boxShadow: _shadow),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.successTeal)),
            const SizedBox(width: 10),
            Text('Waiting for a ride request…', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

/// The hero: 64pt pill, teal when online, grey when offline, disabled while unapproved.
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.online, required this.enabled, required this.loading, required this.onTap});
  final bool online;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = !enabled && !loading ? AppColors.offlineGrey.withValues(alpha: 0.45) : online ? AppColors.successTeal : AppColors.offlineGrey;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              else ...[
                if (online) const _PulseDot() else const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(online ? "You're Online" : "You're Offline",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text(online ? 'Go Offline' : 'Go Online',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 8)]),
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final DriverAccountStatus status;
  @override
  Widget build(BuildContext context) {
    final suspended = status == DriverAccountStatus.suspended || status == DriverAccountStatus.expired || status == DriverAccountStatus.rejected;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suspended ? AppColors.dangerTint : context.tint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(suspended ? Icons.error_rounded : Icons.hourglass_top_rounded, color: suspended ? AppColors.dangerRed : AppColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suspended
                  ? 'Your account is suspended — a document has expired or is under a policy hold'
                  : "Your account is under review. We'll notify you when approved.",
              style: theme.textTheme.bodySmall?.copyWith(color: suspended ? AppColors.dangerRed : context.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          LinkText(suspended ? 'Fix Now' : 'Check Status', size: 13, onTap: () => context.push(Routes.documentStatus)),
        ],
      ),
    );
  }
}

class _BonusBanner extends StatelessWidget {
  const _BonusBanner({required this.bonus});
  final Bonus bonus;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = bonus.target - bonus.progress;
    return InkWell(
      onTap: () => context.push(Routes.bonuses),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.accentGoldTint, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.accentGoldText, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Complete $remaining more trips for ${naira(bonus.reward)} bonus',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppColors.accentGoldText)),
                ),
                Text('${bonus.progress}/${bonus.target}',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.accentGoldText, fontFeatures: AppText.tabular)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bonus.progress / bonus.target,
                minHeight: 6,
                backgroundColor: Colors.white,
                color: AppColors.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
