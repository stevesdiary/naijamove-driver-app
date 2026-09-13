import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/api/api_client.dart';
import '../../data/api/wire.dart';
import '../../data/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/driver_repository.dart';
import 'auth_screens.dart';

/// 1.5 — Profile setup. Creates the driver profile server-side on Continue.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  bool _photo = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final session = ref.read(sessionProvider);
      ref.read(sessionProvider.notifier).setName(_name.text.trim());
      // A rider becomes a driver here; drivers who already registered skip the call.
      if (session.stage == SessionStage.needsDriverProfile) {
        final account = await ref.read(authRepositoryProvider).registerAsDriver();
        ref.read(sessionProvider.notifier).applyAccount(account);
      }
      if (mounted) context.push(Routes.vehicleSetup);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _name.text.trim().split(' ').where((p) => p.isNotEmpty).length >= 2 && _photo;
    return AuthScaffold(
      title: "Let's set up your profile",
      step: (1, 3),
      subtitle: Text('This is what riders will see', style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary)),
      body: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _photo = true),
              child: Stack(
                children: [
                  _photo
                      ? Avatar(name: _name.text.isEmpty ? 'Driver' : _name.text, size: 96)
                      : Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(color: context.tint, shape: BoxShape.circle, border: Border.all(color: context.border)),
                          child: Icon(Icons.person_rounded, size: 44, color: context.textSecondary),
                        ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: _photo ? AppColors.successTeal : AppColors.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.surface, width: 2)),
                      child: Icon(_photo ? Icons.check_rounded : Icons.photo_camera_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_photo ? 'Photo added' : 'Add a clear photo of your face',
              style: theme.textTheme.bodySmall?.copyWith(color: _photo ? AppColors.successTeal : context.textSecondary)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Full name',
            hint: 'Emeka Okafor',
            controller: _name,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      footer: PrimaryButton(label: 'Continue', onPressed: valid && !_busy ? _continue : null, loading: _busy),
    );
  }
}

/// 1.6 — Vehicle details.
class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});
  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _colour = TextEditingController();
  final _plate = TextEditingController();
  int _year = 2019;
  VehicleCategory _category = VehicleCategory.economy;

  @override
  void dispose() {
    for (final c in [_make, _model, _colour, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = List.generate(20, (i) => now - i);
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SheetSurface(
        child: SizedBox(
          height: 260,
          child: ListWheelScrollView.useDelegate(
            controller: FixedExtentScrollController(initialItem: years.indexOf(_year).clamp(0, years.length - 1)),
            itemExtent: 44,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => _year = years[i],
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: years.length,
              builder: (ctx, i) => Center(child: Text('${years[i]}', style: Theme.of(ctx).textTheme.titleLarge)),
            ),
          ),
        ),
      ),
    );
    setState(() => _year = picked ?? _year);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = [_make, _model, _colour].every((c) => c.text.trim().isNotEmpty) && _plate.text.replaceAll(' ', '').length >= 6;
    return AuthScaffold(
      title: 'Tell us about your vehicle',
      step: (2, 3),
      subtitle: Text('Riders see the make, colour and plate before you arrive',
          style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: AppTextField(label: 'Make', hint: 'Toyota', controller: _make, onChanged: (_) => setState(() {}))),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Model', hint: 'Corolla', controller: _model, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: AppTextField(
                label: 'Year',
                readOnly: true,
                onTap: _pickYear,
                controller: TextEditingController(text: '$_year'),
                suffix: Icon(Icons.expand_more_rounded, color: context.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Colour', hint: 'White', controller: _colour, onChanged: (_) => setState(() {}))),
          ]),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Plate number',
            hint: 'LND 482 KJ',
            controller: _plate,
            inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('Category', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in VehicleCategory.values)
                SelectChip(label: '${c.label} · ${c.seats} seats', icon: c.icon, selected: _category == c, onTap: () => setState(() => _category = c)),
            ],
          ),
        ],
      ),
      footer: PrimaryButton(label: 'Continue', onPressed: valid ? () => context.push(Routes.documents) : null),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

/// 1.7 — Document upload. Each row records a document via /drivers/documents.
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});
  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _done = <DriverDocumentType>{DriverDocumentType.profilePhoto};
  DriverDocumentType? _uploading;
  bool _submitting = false;

  static const _rows = [
    (DriverDocumentType.driversLicence, "Driver's Licence", Icons.badge_rounded),
    (DriverDocumentType.vehicleRegistration, 'Vehicle Licence', Icons.directions_car_rounded),
    (DriverDocumentType.insurance, 'Proof of Insurance', Icons.verified_user_rounded),
    (DriverDocumentType.inspection, 'Vehicle Inspection Certificate', Icons.fact_check_rounded),
    (DriverDocumentType.profilePhoto, 'Profile Photo', Icons.account_circle_rounded),
  ];

  Future<void> _upload(DriverDocumentType type) async {
    setState(() => _uploading = type);
    try {
      // File picking/upload to storage is a later step; the record is what the review queue needs.
      await ref.read(driverRepositoryProvider).submitDocument(type: type, referenceNumber: 'pending-upload');
      setState(() => _done.add(type));
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go(Routes.underReview);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _rows.every((r) => _done.contains(r.$1));
    return AuthScaffold(
      title: 'Upload your documents',
      step: (3, 3),
      subtitle: Text("We'll verify these within 24 hours", style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary)),
      body: Column(
        children: [
          for (final (type, label, icon) in _rows) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        _done.contains(type)
                            ? const StatusBadge('Uploaded', kind: BadgeKind.completed, icon: Icons.check_rounded)
                            : const StatusBadge('Pending', kind: BadgeKind.pending),
                      ],
                    ),
                  ),
                  if (_uploading == type)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else if (_done.contains(type))
                    LinkText('Change', onTap: () => _upload(type))
                  else
                    AppIconButton(icon: Icons.upload_rounded, size: 40, onPressed: () => _upload(type)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      footer: Column(
        children: [
          PrimaryButton(label: 'Submit for Review', onPressed: all && !_submitting ? _submit : null, loading: _submitting),
          const SizedBox(height: 4),
          GhostButton(label: 'Save and Continue Later', onPressed: () => context.go(Routes.underReview)),
        ],
      ),
    );
  }
}

/// 1.8 — Application under review.
class UnderReviewScreen extends StatelessWidget {
  const UnderReviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: AppColors.accentGoldTint, shape: BoxShape.circle),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.description_rounded, size: 64, color: AppColors.accentGoldText),
                    Positioned(right: 26, bottom: 30, child: Icon(Icons.schedule_rounded, size: 30, color: AppColors.accentGold)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Application submitted!', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                "We're reviewing your documents. This usually takes up to 24 hours. We'll notify you by SMS when you're approved.",
                style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(label: 'Got it', onPressed: () => context.go(Routes.permissions)),
              const SizedBox(height: 4),
              GhostButton(label: 'Check Status', onPressed: () => context.push(Routes.documentStatus)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1.9 — Permissions. Location + notifications required; camera optional.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});
  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _granted = <String>{};

  static const _perms = [
    ('location', Icons.location_on_rounded, 'Location — "Always"', 'So riders can find you and we can route your trips', true),
    ('notifications', Icons.notifications_rounded, 'Notifications', 'So you never miss a trip request', true),
    ('camera', Icons.photo_camera_rounded, 'Camera', 'For document uploads and vehicle photos', false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _granted.contains('location') && _granted.contains('notifications');
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A few permissions to get you on the road', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 24),
              for (final (key, icon, title, reason, required) in _perms) ...[
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(reason, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
                            const SizedBox(height: 6),
                            StatusBadge(required ? 'Required' : 'Optional', kind: required ? BadgeKind.info : BadgeKind.pending),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _granted.contains(key)
                          ? const StatusBadge('Allowed', kind: BadgeKind.completed, icon: Icons.check_rounded)
                          : SizedBox(
                              width: 96,
                              child: SecondaryButton(label: 'Allow', onPressed: () => setState(() => _granted.add(key))),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              Text('NaijaMove only tracks your location while you are online or on a trip',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
              const Spacer(),
              PrimaryButton(label: 'Continue', onPressed: ready ? () => context.go(Routes.home) : null),
            ],
          ),
        ),
      ),
    );
  }
}
