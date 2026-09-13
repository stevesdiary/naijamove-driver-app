import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/session.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/api/api_client.dart';
import '../../data/api/wire.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/driver_repository.dart';

/// 6.1 — Profile home.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = MockData.driver;
    final session = ref.watch(sessionProvider);
    final account = ref.watch(driverAccountProvider).value;
    final name = session.name ?? d.fullName;
    final rating = account?.rating ?? d.rating;
    final trips = account?.totalTrips ?? d.trips;

    Future<void> logout() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Log out?'),
          content: const Text("You'll stop receiving trip requests until you sign in again."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed), onPressed: () => Navigator.pop(ctx, true), child: const Text('Log Out')),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(sessionProvider.notifier).logout();
      if (context.mounted) context.go(Routes.phone);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(children: [
              Avatar(name: name, size: 80, showEdit: true, onEdit: () => context.push(Routes.editProfile)),
              const SizedBox(height: 10),
              Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(session.phone != null ? '+234 ${session.phone}' : d.phone, style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 18),
                Text(' ${rating.toStringAsFixed(2)} · $trips trips', style: theme.textTheme.labelLarge?.copyWith(fontFeatures: AppText.tabular)),
              ]),
              const SizedBox(height: 10),
              const Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                StatusBadge('Identity', kind: BadgeKind.completed, icon: Icons.check_rounded),
                StatusBadge('Licence', kind: BadgeKind.completed, icon: Icons.check_rounded),
                StatusBadge('Vehicle', kind: BadgeKind.completed, icon: Icons.check_rounded),
              ]),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                LinkText('Edit', onTap: () => context.push(Routes.editProfile)),
                const SizedBox(width: 24),
                LinkText('View Public Profile', onTap: () => context.push(Routes.publicProfile)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Vehicle'),
          IconRow(icon: Icons.directions_car_rounded, title: 'My Vehicle', subtitle: '${MockData.vehicle.title} · ${MockData.vehicle.plate}', onTap: () => context.push(Routes.vehicle)),
          IconRow(icon: Icons.description_rounded, title: 'My Documents', onTap: () => context.push(Routes.documentStatus)),
          const SizedBox(height: 12),
          const SectionLabel('Earnings'),
          IconRow(icon: Icons.account_balance_rounded, title: 'Bank Account', onTap: () => context.push(Routes.wallet)),
          IconRow(icon: Icons.card_giftcard_rounded, title: 'Bonuses & Incentives', onTap: () => context.push(Routes.bonuses)),
          const SizedBox(height: 12),
          const SectionLabel('Performance'),
          IconRow(icon: Icons.insights_rounded, title: 'My Performance', onTap: () => context.push(Routes.performance)),
          IconRow(icon: Icons.emoji_events_rounded, title: 'Top Driver Programme', trailing: StatusBadge(d.tier.label, kind: BadgeKind.surge), onTap: () => context.push(Routes.topDriver)),
          const SizedBox(height: 12),
          const SectionLabel('Safety & Support'),
          IconRow(icon: Icons.shield_rounded, title: 'Safety Settings', onTap: () => context.push(Routes.safety)),
          IconRow(icon: Icons.group_rounded, title: 'Emergency Contact', onTap: () => context.push(Routes.emergencyContact)),
          IconRow(icon: Icons.help_rounded, title: 'Help & Support', onTap: () => context.push(Routes.support)),
          const SizedBox(height: 12),
          const SectionLabel('App'),
          IconRow(icon: Icons.notifications_rounded, title: 'Notifications', onTap: () => context.push(Routes.notifications)),
          IconRow(icon: Icons.settings_rounded, title: 'App Settings', onTap: () => context.push(Routes.settings)),
          IconRow(icon: Icons.logout_rounded, title: 'Log Out', iconColor: AppColors.dangerRed, iconBg: AppColors.dangerTint, titleColor: AppColors.dangerRed, onTap: logout),
          const SizedBox(height: 16),
          Text('NaijaMove Driver v1.0.0', style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

(String, BadgeKind) _docBadge(DocStatus s) => switch (s) {
      DocStatus.verified => ('Verified', BadgeKind.completed),
      DocStatus.pendingReview || DocStatus.uploaded => ('Pending Review', BadgeKind.pending),
      DocStatus.rejected => ('Rejected', BadgeKind.danger),
      DocStatus.expiringSoon => ('Expiring Soon', BadgeKind.surge),
      DocStatus.expired => ('Expired', BadgeKind.danger),
      DocStatus.missing => ('Missing', BadgeKind.cancelled),
    };

/// 6.2 — My vehicle.
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = MockData.vehicle;
    final inspection = MockData.documents.firstWhere((d) => d.name.contains('Inspection'));
    final insurance = MockData.documents.firstWhere((d) => d.name.contains('Insurance'));
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Stack(children: [
              Center(child: Icon(v.category.icon, size: 96, color: AppColors.primaryBlue.withValues(alpha: 0.5))),
              Positioned(
                right: 12,
                bottom: 12,
                child: SizedBox(width: 196, child: SecondaryButton(label: 'Change Photo', icon: Icons.photo_camera_rounded, onPressed: () {})),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(v.plate, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontFeatures: AppText.tabular, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [
                StatusBadge(v.category.label, kind: BadgeKind.info),
                const Spacer(),
                LinkText('Edit Details', onTap: () => context.push(Routes.vehicleSetup)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Inspection & insurance'),
          for (final d in [inspection, insurance]) _ComplianceRow(d),
          if (inspection.status == DocStatus.expired || insurance.status == DocStatus.expired)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerTint, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text('Your vehicle is suspended until renewed', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.dangerRed)),
            ),
        ],
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow(this.d);
  final DriverDocument d;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, kind) = _docBadge(d.status);
    final days = d.expiry?.difference(MockData.now).inDays;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Icon(d.icon, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(children: [
              StatusBadge(label, kind: kind),
              if (d.expiry != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    d.status == DocStatus.expiringSoon && days != null ? 'Expires in $days days' : 'Exp. ${dayMonth(d.expiry!)} ${d.expiry!.year}',
                    style: theme.textTheme.bodySmall?.copyWith(color: d.status == DocStatus.expiringSoon ? AppColors.accentGoldText : context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ]),
          ]),
        ),
        LinkText('Update', onTap: () => context.push(Routes.documentStatus)),
      ]),
    );
  }
}

/// 6.3 — Emergency contact (max one).
class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});
  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  EmergencyContact? _contact = MockData.emergencyContact;
  bool _editing = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _rel = 'Spouse';
  static const _rels = ['Spouse', 'Parent', 'Sibling', 'Friend', 'Other'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _startEdit() {
    _name.text = _contact?.name ?? '';
    _phone.text = _contact?.phone.replaceAll('+234 ', '').replaceAll(' ', '') ?? '';
    _rel = _contact?.relationship ?? 'Spouse';
    setState(() => _editing = true);
  }

  void _save() {
    final p = _phone.text.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _contact = EmergencyContact(name: _name.text.trim(), phone: '+234 ${p.substring(0, 3)} ${p.substring(3, 6)} ${p.substring(6)}', relationship: _rel);
      _editing = false;
    });
    showToast(context, 'Emergency contact saved', kind: ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _name.text.trim().isNotEmpty && _phone.text.replaceAll(RegExp(r'\D'), '').length == 10;
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contact')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('This person will be notified if you trigger an SOS alert', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 16),
          if (_editing) ...[
            AppTextField(label: 'Full name', controller: _name, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone number',
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              prefix: const Padding(padding: EdgeInsets.only(left: 14, right: 8), child: Text('+234', style: TextStyle(fontWeight: FontWeight.w600))),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Relationship', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final r in _rels) SelectChip(label: r, selected: _rel == r, onTap: () => setState(() => _rel = r))]),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save Contact', onPressed: valid ? _save : null),
            const SizedBox(height: 4),
            GhostButton(label: 'Cancel', onPressed: () => setState(() => _editing = false)),
          ] else if (_contact == null)
            EmptyState(icon: Icons.group_rounded, title: 'No emergency contact set', ctaLabel: 'Add Contact', onCta: _startEdit)
          else
            AppCard(
              child: Row(children: [
                Avatar(name: _contact!.name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_contact!.name, style: theme.textTheme.titleMedium),
                    Text('${_contact!.phone} · ${_contact!.relationship}', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
                  ]),
                ),
                LinkText('Edit', onTap: _startEdit),
                const SizedBox(width: 12),
                LinkText('Remove', color: AppColors.dangerRed, onTap: () => setState(() => _contact = null)),
              ]),
            ),
          const SizedBox(height: 12),
          Text('Maximum of one emergency contact for drivers', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}

/// 6.4 — Safety settings.
class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({super.key});
  @override
  State<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  bool _audio = false;
  bool _share = true;
  bool _fatigue = true;
  int _hours = 6;
  bool _sos112 = false;
  bool _sosContact = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget toggle(String title, bool v, ValueChanged<bool> on, {String? sub}) => SwitchListTile(
          value: v,
          onChanged: on,
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: theme.textTheme.bodyLarge),
          subtitle: sub != null ? Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)) : null,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Trip recording'),
          toggle('Audio trip recording', _audio, (v) => setState(() => _audio = v), sub: 'Recordings are encrypted and only accessed if a safety incident is reported'),
          const SizedBox(height: 8),
          const SectionLabel('Location'),
          toggle('Share live location with emergency contact during trips', _share, (v) => setState(() => _share = v)),
          const SizedBox(height: 8),
          const SectionLabel('Fatigue alerts'),
          toggle('Driving hours reminder', _fatigue, (v) => setState(() => _fatigue = v)),
          if (_fatigue)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(spacing: 8, children: [for (final h in [4, 6, 8]) SelectChip(label: 'After ${h}h', selected: _hours == h, onTap: () => setState(() => _hours = h))]),
            ),
          const SizedBox(height: 8),
          const SectionLabel('SOS'),
          toggle('SOS also calls 112 automatically', _sos112, (v) => setState(() => _sos112 = v)),
          toggle('SOS notifies emergency contact', _sosContact, (v) => setState(() => _sosContact = v)),
        ],
      ),
    );
  }
}

/// 6.5 — Document status. Live list when a backend is configured.
class DocumentStatusScreen extends ConsumerWidget {
  const DocumentStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final docs = MockData.documents;
    final allVerified = docs.every((d) => d.status == DocStatus.verified);
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (allVerified)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(children: [
                const Icon(Icons.verified_rounded, color: AppColors.successTeal),
                const SizedBox(width: 8),
                Text('Your account is fully verified', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.successTeal)),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Keep your documents up to date to stay active on the platform', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
            ),
          for (final d in docs) _DocRow(d, onUpload: () => _upload(context, ref, d)),
        ],
      ),
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref, DriverDocument d) async {
    final type = switch (d.name) {
      "Driver's Licence" => DriverDocumentType.driversLicence,
      'Vehicle Licence' => DriverDocumentType.vehicleRegistration,
      'Proof of Insurance' => DriverDocumentType.insurance,
      'Vehicle Inspection Certificate' => DriverDocumentType.inspection,
      _ => DriverDocumentType.profilePhoto,
    };
    try {
      await ref.read(driverRepositoryProvider).submitDocument(type: type, referenceNumber: 'pending-upload');
      if (context.mounted) showToast(context, '${d.name} submitted for review', kind: ToastKind.success);
    } on ApiException catch (e) {
      if (context.mounted) showToast(context, e.message, kind: ToastKind.error);
    }
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(this.d, {required this.onUpload});
  final DriverDocument d;
  final VoidCallback onUpload;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, kind) = _docBadge(d.status);
    final rejected = d.status == DocStatus.rejected;
    final needsAction = rejected || d.status == DocStatus.missing || d.status == DocStatus.expired || d.status == DocStatus.expiringSoon;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: rejected ? const Border(left: BorderSide(color: AppColors.dangerRed, width: 4)) : Border.all(color: context.border),
      ),
      child: Row(children: [
        Icon(d.icon, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: theme.textTheme.titleSmall),
            if (d.rejectionReason != null) ...[
              const SizedBox(height: 2),
              Text(d.rejectionReason!, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              StatusBadge(label, kind: kind),
              if (d.expiry != null) ...[
                const SizedBox(width: 8),
                Text('Exp. ${dayMonth(d.expiry!)} ${d.expiry!.year}', style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
              ],
            ]),
          ]),
        ),
        LinkText(rejected ? 'Re-upload' : needsAction ? 'Upload' : 'Update', size: 13, onTap: onUpload),
      ]),
    );
  }
}

/// 6.6 — Public profile preview.
class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = MockData.driver;
    final v = MockData.vehicle;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Public Profile'), actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Center(child: StatusBadge('Preview', kind: BadgeKind.info)))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Avatar(name: d.fullName, size: 96)),
          const SizedBox(height: 10),
          Text(d.preferredName, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          Text('Member since ${d.memberSince}', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          const Wrap(spacing: 6, alignment: WrapAlignment.center, children: [
            StatusBadge('Identity', kind: BadgeKind.completed, icon: Icons.check_rounded),
            StatusBadge('Licence', kind: BadgeKind.completed, icon: Icons.check_rounded),
            StatusBadge('Vehicle', kind: BadgeKind.completed, icon: Icons.check_rounded),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _Stat(Icons.star_rounded, d.rating.toStringAsFixed(2), 'rating', AppColors.accentGold),
            _Stat(Icons.directions_car_rounded, '${d.trips}', 'trips', AppColors.primaryBlue),
            _Stat(Icons.emoji_events_rounded, d.tier.label, 'Top Driver', AppColors.accentGoldText),
          ]),
          const SizedBox(height: 16),
          SectionLabel('About', trailing: LinkText('Edit', size: 13, onTap: () => context.push(Routes.editProfile))),
          Text(d.bio, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          const SectionLabel('Ratings'),
          AppCard(child: StarDistribution(percentages: MockData.starDistribution)),
          const SizedBox(height: 16),
          const SectionLabel('Top compliments'),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final (label, n) in MockData.compliments) SelectChip(label: '$label · $n', filled: true)]),
          const SizedBox(height: 16),
          const SectionLabel('Vehicle'),
          AppCard(
            child: Row(children: [
              Icon(v.category.icon, size: 32, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.title, style: theme.textTheme.titleSmall),
                Text(v.plate, style: theme.textTheme.bodyMedium?.copyWith(fontFeatures: AppText.tabular)),
              ])),
              StatusBadge(v.category.label, kind: BadgeKind.info),
            ]),
          ),
          const SizedBox(height: 16),
          Text('This is what riders see', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontFeatures: AppText.tabular)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
        ]),
      ),
    );
  }
}

/// 6.7 — App settings.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _nav = 0;
  bool _trips = true;
  bool _earnings = true;
  bool _bonus = true;
  int _lang = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = ref.watch(sessionProvider.select((s) => s.themeMode));
    Widget toggle(String t, bool v, ValueChanged<bool>? on) =>
        SwitchListTile(value: v, onChanged: on, contentPadding: EdgeInsets.zero, title: Text(t, style: theme.textTheme.bodyLarge));
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('Navigation'),
          SegmentedTabs(labels: const ['Built-in', 'Google Maps', 'Waze', 'Apple Maps'], selected: _nav, onChanged: (i) => setState(() => _nav = i)),
          const SizedBox(height: 16),
          const SectionLabel('Notifications'),
          toggle('Trip requests', _trips, (v) => setState(() => _trips = v)),
          toggle('Earnings updates', _earnings, (v) => setState(() => _earnings = v)),
          toggle('Bonus alerts', _bonus, (v) => setState(() => _bonus = v)),
          toggle('Safety alerts (always on)', true, null),
          const SizedBox(height: 16),
          const SectionLabel('Language'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (i, l) in ['English', 'Yoruba', 'Igbo', 'Hausa'].indexed) SelectChip(label: l, selected: _lang == i, onTap: () => setState(() => _lang = i)),
            const SelectChip(label: 'Pidgin · coming soon'),
          ]),
          const SizedBox(height: 16),
          const SectionLabel('Display'),
          SegmentedTabs(
            labels: const ['System', 'Light', 'Dark'],
            selected: ThemeMode.values.indexOf(mode),
            onChanged: (i) => ref.read(sessionProvider.notifier).setThemeMode(ThemeMode.values[i]),
          ),
          const SizedBox(height: 32),
          Center(child: LinkText('Delete Account', color: AppColors.dangerRed, onTap: () => _deleteAccount(context))),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text('Your trip history, earnings statements and documents will be permanently removed after 30 days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Account')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue', style: TextStyle(color: AppColors.dangerRed))),
        ],
      ),
    );
    if (first != true || !context.mounted) return;
    final ctrl = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'DELETE')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == 'DELETE'), child: const Text('Delete', style: TextStyle(color: AppColors.dangerRed))),
        ],
      ),
    );
    if (second == true && context.mounted) showToast(context, 'Deletion requested — support will confirm by SMS', kind: ToastKind.error);
  }
}

/// 6.8 — Edit profile.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _d = MockData.driver;
  late final _preferred = TextEditingController(text: _d.preferredName);
  late final _email = TextEditingController(text: _d.email);
  late final _bio = TextEditingController(text: _d.bio);
  late final Set<String> _langs = {..._d.languages};
  bool _dirty = false;

  @override
  void dispose() {
    _preferred.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _touch() => setState(() => _dirty = true);

  void _save() {
    ref.read(sessionProvider.notifier).setName(_preferred.text.trim());
    showToast(context, 'Profile updated', kind: ToastKind.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile'), actions: [TextButton(onPressed: _dirty ? _save : null, child: const Text('Save')), const SizedBox(width: 4)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Avatar(name: _d.fullName, size: 96)),
          const SizedBox(height: 8),
          Center(child: LinkText('Change Photo', onTap: _touch)),
          Text('Riders must be able to recognise you — clear face, no sunglasses',
              style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: AppTextField(label: 'First name', readOnly: true, controller: TextEditingController(text: _d.firstName), suffix: Icon(Icons.lock_rounded, size: 16, color: context.textSecondary))),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Last name', readOnly: true, controller: TextEditingController(text: _d.lastName), suffix: Icon(Icons.lock_rounded, size: 16, color: context.textSecondary))),
          ]),
          const SizedBox(height: 4),
          Text('Contact support to change your legal name', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 16),
          AppTextField(label: 'Preferred name (shown to riders)', controller: _preferred, onChanged: (_) => _touch()),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone number',
            readOnly: true,
            controller: TextEditingController(text: _d.phone),
            success: true,
            suffix: Padding(padding: const EdgeInsets.only(right: 8), child: LinkText('Change', size: 13, onTap: () => context.push(Routes.phone))),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Email (optional)', controller: _email, keyboardType: TextInputType.emailAddress, onChanged: (_) => _touch()),
          const SizedBox(height: 16),
          Text('Languages spoken', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin'])
              SelectChip(label: l, selected: _langs.contains(l), onTap: () {
                _langs.contains(l) ? _langs.remove(l) : _langs.add(l);
                _touch();
              }),
          ]),
          const SizedBox(height: 16),
          AppTextField(label: 'Short bio', controller: _bio, maxLength: 150, maxLines: 3, onChanged: (_) => _touch()),
        ],
      ),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: PrimaryButton(label: 'Save Changes', onPressed: _dirty ? _save : null))),
    );
  }
}
