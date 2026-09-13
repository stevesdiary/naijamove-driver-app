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
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/wallet_repository.dart';

String _bankLabel(BankAccount b) => '${b.bankName} ••• ${b.accountNumber.substring(b.accountNumber.length - 4)}';

/// Primary Dark hero card used for weekly earnings and wallet balance.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

/// 4.1 — Earnings dashboard.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = MockData.trips.where((t) => t.status == TripStatus.completed).toList();
    final today = completed.where((t) => t.date.day == MockData.now.day).toList();
    final trips = _period == 0 ? today : completed;
    final gross = _period == 0 ? today.fold(0, (s, t) => s + t.gross) : MockData.weekGross;
    final commission = _period == 0 ? today.fold(0, (s, t) => s + t.commission) : MockData.weekCommission;
    final bonuses = _period == 0 ? today.fold(0, (s, t) => s + t.bonus) : MockData.weekBonuses;
    final bonus = MockData.bonuses.firstWhere((b) => b.status == BonusStatus.active);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(icon: const Icon(Icons.account_balance_wallet_rounded), onPressed: () => context.push(Routes.wallet)),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(children: [
            Text('This week', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(naira(MockData.weekEarnings),
                style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 40, fontFeatures: AppText.tabular)),
            const SizedBox(height: 8),
            Row(children: [
              Text('${MockData.weekTrips} trips · Avg ${naira((MockData.weekEarnings / MockData.weekTrips).round())} per trip',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, fontFeatures: AppText.tabular)),
              const Spacer(),
              LinkText('View Breakdown', color: AppColors.primaryLight, size: 13, onTap: () => setState(() => _period = 1)),
            ]),
          ]),
          const SizedBox(height: 16),
          SegmentedTabs(labels: const ['Today', 'This Week', 'This Month', 'Custom'], selected: _period, onChanged: (i) => setState(() => _period = i)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              _Row('Gross earnings', naira(gross)),
              _Row('Platform commission', '− ${naira(commission)}', color: AppColors.dangerRed),
              _Row('Bonuses', '+ ${naira(bonuses)}', color: AppColors.earningsGreen),
              Divider(color: context.border, thickness: 1.5),
              _Row('Net earnings', naira(gross - commission + bonuses), bold: true, color: AppColors.earningsGreen, size: 20),
            ]),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push(Routes.bonuses),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentGold, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(bonus.name, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primaryDark))),
                  Text('+ ${naira(bonus.reward)}', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primaryDark, fontFeatures: AppText.tabular)),
                ]),
                const SizedBox(height: 4),
                Text('${bonus.progress} of ${bonus.target} trips completed', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: bonus.progress / bonus.target, minHeight: 6, backgroundColor: Colors.white54, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 6),
                Text('Ends at ${timeOf(bonus.expires!)}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primaryDark)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          if (trips.isEmpty)
            const EmptyState(icon: Icons.directions_car_rounded, title: 'No trips yet today', subtitle: 'Go online to start earning.')
          else
            for (final group in _groupByDay(trips)) ...[
              SectionLabel(dayLabel(group.$1, now: MockData.now)),
              for (final t in group.$2) _TripRow(trip: t),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  List<(DateTime, List<Trip>)> _groupByDay(List<Trip> trips) {
    final map = <DateTime, List<Trip>>{};
    for (final t in trips) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      map.putIfAbsent(key, () => []).add(t);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (k, map[k]!)];
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.color, this.bold = false, this.size});
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  final double? size;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary))),
        Text(value,
            style: theme.textTheme.titleSmall?.copyWith(color: color, fontSize: size, fontWeight: bold ? FontWeight.w600 : null, fontFeatures: AppText.tabular)),
      ]),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});
  final Trip trip;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconRow(
      icon: Icons.schedule_rounded,
      title: trip.routeLabel,
      subtitle: '${timeOf(trip.date)} · ${trip.durationMin} min · ${trip.distanceKm} km',
      trailing: Text(naira(trip.net), style: theme.textTheme.titleSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
      onTap: () => context.push(Routes.tripEarnings(trip.id)),
    );
  }
}

/// 4.2 — Wallet & payouts. Balance is live when a backend is configured.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balance = ref.watch(walletBalanceProvider).value?.balanceKobo;
    final naira0 = balance != null ? balance ~/ 100 : MockData.walletBalance;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Payouts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(children: [
            Text('NaijaMove Wallet', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(naira(naira0),
                style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 36, fontFeatures: AppText.tabular)),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Withdraw', color: AppColors.accentGold, onPressed: () => context.push(Routes.withdraw)),
            const SizedBox(height: 4),
            Center(child: LinkText('Transaction History', color: AppColors.primaryLight, onTap: () => context.push(Routes.transactions))),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('Payout account'),
          AppCard(
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(_bankLabel(MockData.bank), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular))),
              LinkText('Change', onTap: () => context.push(Routes.linkBank)),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Payout history'),
          for (final p in MockData.payouts)
            IconRow(
              icon: Icons.account_balance_rounded,
              title: 'Payout to ${p.bank}',
              subtitle: dayMonthTime(p.date),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(naira(p.amount), style: theme.textTheme.titleSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
                  const SizedBox(height: 2),
                  StatusBadge(
                    switch (p.status) { PayoutStatus.completed => 'Completed', PayoutStatus.processing => 'Processing', PayoutStatus.failed => 'Failed' },
                    kind: switch (p.status) { PayoutStatus.completed => BadgeKind.completed, PayoutStatus.processing => BadgeKind.pending, PayoutStatus.failed => BadgeKind.danger },
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(label: 'Withdraw Earnings', onPressed: () => context.push(Routes.withdraw)),
        ),
      ),
    );
  }
}

/// 4.3 — Trip earnings detail.
class TripEarningsDetailScreen extends StatelessWidget {
  const TripEarningsDetailScreen({super.key, required this.tripId});
  final String tripId;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = MockData.trips.firstWhere((t) => t.id == tripId, orElse: () => MockData.trips.first);
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(height: 160, child: MapCanvas(pickup: t.pickup.at, destination: t.destination.at, showRoute: true)),
          ),
          const SizedBox(height: 14),
          Text('${fullDate(t.date)} · ${timeOf(t.date)}', style: theme.textTheme.titleSmall),
          Text('${t.durationMin} min · ${t.distanceKm} km', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 12),
          RouteSummary(pickup: t.pickup.address, destination: t.destination.address, stops: [for (final s in t.stops) s.address], dense: true),
          const SizedBox(height: 16),
          Row(children: [
            Avatar(name: t.rider.firstName, size: 40),
            const SizedBox(width: 10),
            Expanded(child: Text(t.rider.firstName, style: theme.textTheme.titleSmall)),
            if (t.ratingGiven != null) ...[
              const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
              Text('${t.ratingGiven} given', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
            ],
          ]),
          const SizedBox(height: 16),
          AppCard(
            child: Column(children: [
              _Row('Base fare', naira(t.baseFare)),
              _Row('Per km charge', naira(t.distanceCharge)),
              _Row('Booking fee', naira(t.bookingFee)),
              if (t.surge != null) _Row('Surge', '${t.surge}× applied', color: AppColors.accentGoldText),
              Divider(color: context.border),
              _Row('Gross fare', naira(t.gross), bold: true),
              _Row('Platform commission', '− ${naira(t.commission)}', color: AppColors.dangerRed),
              if (t.bonus > 0) _Row('Bonus applied', '+ ${naira(t.bonus)}', color: AppColors.earningsGreen),
              if (t.tip > 0) _Row('Tip received', '+ ${naira(t.tip)}', color: AppColors.earningsGreen),
              Divider(color: context.border, thickness: 1.5),
              _Row('Net earned', naira(t.net), bold: true, color: AppColors.earningsGreen, size: 22),
            ]),
          ),
          const SizedBox(height: 16),
          Center(child: LinkText('Report an Issue with this Trip', onTap: () => context.push(Routes.supportCategories))),
        ],
      ),
    );
  }
}

/// 4.4 — Withdraw. Calls POST /wallet/withdraw.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});
  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  static const _min = 500;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_ctrl.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _withdraw(int available) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm withdrawal'),
        content: Text('Withdraw ${naira(_amount)} to ${_bankLabel(MockData.bank)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(walletRepositoryProvider).withdraw(
            amountKobo: _amount * 100,
            bankCode: '058',
            accountNumber: MockData.bank.accountNumber,
            accountName: MockData.bank.holder,
          );
      await ref.read(walletBalanceProvider.notifier).refresh();
      if (!mounted) return;
      showToast(context, '${naira(_amount)} on its way — arrives within 10 minutes', kind: ToastKind.success);
      context.pop();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceKobo = ref.watch(walletBalanceProvider).value?.balanceKobo;
    final available = balanceKobo != null ? balanceKobo ~/ 100 : MockData.walletBalance;
    final valid = _amount >= _min && _amount <= available;
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available balance', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
              Text(naira(available),
                  style: theme.textTheme.headlineLarge?.copyWith(color: AppColors.earningsGreen, fontSize: 28, fontFeatures: AppText.tabular)),
              const SizedBox(height: 20),
              Text('Enter amount', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 32, fontFeatures: AppText.tabular),
                decoration: const InputDecoration(prefixText: '₦ ', border: InputBorder.none, filled: false, hintText: '0'),
                onChanged: (_) => setState(() {}),
              ),
              Wrap(spacing: 8, children: [
                for (final q in [2000, 5000, 10000])
                  SelectChip(label: naira(q), selected: _amount == q, onTap: () => setState(() => _ctrl.text = '$q')),
                SelectChip(label: 'All', selected: _amount == available, onTap: () => setState(() => _ctrl.text = '$available')),
              ]),
              const SizedBox(height: 8),
              Text(
                _amount > available ? 'Amount exceeds your balance' : 'Minimum withdrawal: ${naira(_min)}',
                style: theme.textTheme.bodySmall?.copyWith(color: _amount > available ? AppColors.dangerRed : context.textSecondary),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.account_balance_rounded, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_bankLabel(MockData.bank), style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular))),
                  LinkText('Change', onTap: () => context.push(Routes.linkBank)),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.bolt_rounded, size: 16, color: context.textSecondary),
                const SizedBox(width: 4),
                Text('Arrives within 10 minutes', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
              ]),
              const Spacer(),
              PrimaryButton(
                label: _amount > 0 ? 'Withdraw ${naira(_amount)}' : 'Withdraw',
                onPressed: valid && !_busy ? () => _withdraw(available) : null,
                loading: _busy,
              ),
              const SizedBox(height: 4),
              GhostButton(label: 'Cancel', onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4.5 — Bonuses.
class BonusesScreen extends StatelessWidget {
  const BonusesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = MockData.bonuses.where((b) => b.status == BonusStatus.active).toList();
    final upcoming = MockData.bonuses.where((b) => b.status == BonusStatus.upcoming).toList();
    final done = MockData.bonuses.where((b) => b.status == BonusStatus.completed).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bonuses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isEmpty)
            const EmptyState(icon: Icons.bolt_rounded, title: 'No active bonuses right now', subtitle: 'Check back during peak hours.')
          else ...[
            const SectionLabel('Active'),
            for (final b in active) _BonusCard(b),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionLabel('Upcoming'),
            for (final b in upcoming) _BonusCard(b),
          ],
          if (done.isNotEmpty) ...[
            const SizedBox(height: 12),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Completed (${done.length})', style: theme.textTheme.titleSmall),
                children: [
                  for (final b in done)
                    IconRow(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.successTeal,
                      title: b.name,
                      subtitle: b.paidOn != null ? 'Paid ${dayMonth(b.paidOn!)}' : null,
                      trailing: Text('+ ${naira(b.reward)}', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
                      dense: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard(this.b);
  final Bonus b;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = b.status == BonusStatus.upcoming;
    final progressLabel = b.progressIsAmount ? '${naira(b.progress)} of ${naira(b.target)}' : '${b.progress} of ${b.target} trips';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: upcoming ? context.border : AppColors.accentGold, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (upcoming) ...[Icon(Icons.lock_rounded, size: 16, color: context.textSecondary), const SizedBox(width: 6)],
          Expanded(child: Text(b.name, style: theme.textTheme.titleSmall)),
          Text('+ ${naira(b.reward)}', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
        ]),
        const SizedBox(height: 4),
        Text(b.description, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
        if (!upcoming) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: b.progress / b.target, minHeight: 6, backgroundColor: context.bg, color: AppColors.accentGold),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text(progressLabel, style: theme.textTheme.labelMedium?.copyWith(fontFeatures: AppText.tabular), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            if (b.expires != null) StatusBadge('Ends ${timeOf(b.expires!)}', kind: BadgeKind.surge),
          ]),
        ] else if (b.startsLabel != null) ...[
          const SizedBox(height: 8),
          StatusBadge(b.startsLabel!, kind: BadgeKind.pending),
        ],
      ]),
    );
  }
}

/// 4.6 — Link bank account (NUBAN lookup simulated).
class LinkBankScreen extends StatefulWidget {
  const LinkBankScreen({super.key});
  @override
  State<LinkBankScreen> createState() => _LinkBankScreenState();
}

class _LinkBankScreenState extends State<LinkBankScreen> {
  String? _bank;
  final _acct = TextEditingController();
  bool _verifying = false;
  String? _holder;
  bool _mismatch = false;
  bool _consent = false;

  @override
  void dispose() {
    _acct.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BankPicker(banks: MockData.banks),
    );
    if (picked != null) setState(() => _bank = picked);
  }

  Future<void> _lookup(String v) async {
    setState(() {
      _holder = null;
      _mismatch = false;
    });
    if (v.length != 10 || _bank == null) return;
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _verifying = false;
      // Demo: numbers ending in 0000 resolve to a different holder.
      _mismatch = v.endsWith('0000');
      _holder = _mismatch ? 'ADAEZE NWOSU' : MockData.bank.holder;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _holder != null && !_mismatch && _consent;
    return Scaffold(
      appBar: AppBar(title: const Text('Add bank account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Bank',
                hint: 'Select your bank',
                readOnly: true,
                onTap: _pickBank,
                controller: TextEditingController(text: _bank ?? ''),
                suffix: Icon(Icons.expand_more_rounded, color: context.textSecondary),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Account number',
                hint: '0123454821',
                controller: _acct,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                onChanged: _lookup,
                success: _holder != null && !_mismatch,
                errorText: _mismatch ? "Account name doesn't match your profile name. Payouts can only go to an account in your name." : null,
              ),
              const SizedBox(height: 6),
              Text('10-digit NUBAN', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
              const SizedBox(height: 12),
              if (_verifying)
                Row(children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text('Verifying…', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                ])
              else if (_holder != null)
                Row(children: [
                  Icon(_mismatch ? Icons.error_rounded : Icons.check_circle_rounded, color: _mismatch ? AppColors.dangerRed : AppColors.successTeal, size: 18),
                  const SizedBox(width: 6),
                  Text(_holder!, style: theme.textTheme.titleSmall),
                  if (_mismatch) ...[const Spacer(), LinkText('Contact Support', size: 13, onTap: () => context.push(Routes.support))],
                ]),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('I confirm this account belongs to me', style: theme.textTheme.bodyMedium),
              ),
              const Spacer(),
              Row(children: [
                Icon(Icons.lock_rounded, size: 14, color: context.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text('Bank details are encrypted and used only for payouts', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary))),
              ]),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save Bank Account',
                onPressed: ready
                    ? () {
                        showToast(context, 'Bank account saved', kind: ToastKind.success);
                        context.pop();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankPicker extends StatefulWidget {
  const _BankPicker({required this.banks});
  final List<String> banks;
  @override
  State<_BankPicker> createState() => _BankPickerState();
}

class _BankPickerState extends State<_BankPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.banks.where((b) => b.toLowerCase().contains(_q.toLowerCase())).toList();
    return SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(hint: 'Search banks…', prefix: const Icon(Icons.search_rounded), autofocus: true, onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final b in list)
                  IconRow(icon: Icons.account_balance_rounded, title: b, dense: true, onTap: () => Navigator.pop(context, b)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 4.7 — Transactions.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filter = 0;
  static const _filters = ['All', 'Trips', 'Payouts', 'Bonuses', 'Adjustments'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = MockData.transactions;
    final list = switch (_filter) {
      1 => all.where((t) => t.kind == TxKind.trip),
      2 => all.where((t) => t.kind == TxKind.payout),
      3 => all.where((t) => t.kind == TxKind.bonus),
      4 => all.where((t) => t.kind == TxKind.adjustment),
      _ => all,
    }
        .toList();
    final inflow = all.where((t) => t.amount > 0).fold(0, (s, t) => s + t.amount);
    final outflow = all.where((t) => t.amount < 0).fold(0, (s, t) => s + t.amount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [TextButton(onPressed: () => showToast(context, 'Statement will be emailed to you'), child: const Text('Download')), const SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () {}),
                Text(monthYear(MockData.now), style: theme.textTheme.titleMedium),
                IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () {}),
              ]),
              Row(children: [
                Expanded(child: _Summary('In', '+ ${naira(inflow)}', AppColors.earningsGreen)),
                const SizedBox(width: 12),
                Expanded(child: _Summary('Out', '− ${naira(-outflow)}', context.textPrimary)),
              ]),
              const SizedBox(height: 12),
              FilterTabs(labels: _filters, selected: _filter, onChanged: (i) => setState(() => _filter = i)),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions this month')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final tx in list)
                        IconRow(
                          icon: switch (tx.kind) {
                            TxKind.trip => Icons.directions_car_rounded,
                            TxKind.payout => Icons.account_balance_rounded,
                            TxKind.bonus => Icons.bolt_rounded,
                            TxKind.adjustment => Icons.tune_rounded,
                          },
                          iconColor: tx.kind == TxKind.bonus ? AppColors.accentGoldText : null,
                          iconBg: tx.kind == TxKind.bonus ? AppColors.accentGoldTint : null,
                          title: tx.title,
                          subtitle: '${dayLabel(tx.date, now: MockData.now)}, ${timeOf(tx.date)} · ${tx.subtitle}',
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tx.amount >= 0 ? '+' : '−'} ${naira(tx.amount.abs())}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: tx.amount >= 0 ? AppColors.earningsGreen : context.textPrimary,
                                  fontFeatures: AppText.tabular,
                                ),
                              ),
                              if (tx.payoutStatus != null)
                                StatusBadge(
                                  tx.payoutStatus == PayoutStatus.completed ? 'Completed' : tx.payoutStatus == PayoutStatus.processing ? 'Processing' : 'Failed',
                                  kind: tx.payoutStatus == PayoutStatus.completed ? BadgeKind.completed : tx.payoutStatus == PayoutStatus.processing ? BadgeKind.pending : BadgeKind.danger,
                                ),
                            ],
                          ),
                          onTap: tx.tripId != null ? () => context.push(Routes.tripEarnings(tx.tripId!)) : null,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
        const Spacer(),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(color: color, fontFeatures: AppText.tabular)),
      ]),
    );
  }
}
