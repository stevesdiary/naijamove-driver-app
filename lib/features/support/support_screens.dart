import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/map_canvas.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import 'chat_widgets.dart';

(String, BadgeKind) _caseBadge(CaseStatus s) => switch (s) {
      CaseStatus.open => ('Open', BadgeKind.open),
      CaseStatus.pendingUser || CaseStatus.pendingAgent => ('Pending', BadgeKind.pending),
      CaseStatus.escalated => ('Escalated', BadgeKind.danger),
      CaseStatus.resolved => ('Resolved', BadgeKind.resolved),
      CaseStatus.closed => ('Closed', BadgeKind.closed),
    };

/// 9.1 — Help & Support home.
class SupportHomeScreen extends StatelessWidget {
  const SupportHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = MockData.cases.where((c) => c.status != CaseStatus.resolved && c.status != CaseStatus.closed).firstOrNull;
    final recent = MockData.trips.take(3).toList();
    const quick = [
      (Icons.credit_card_rounded, 'Payment issue'),
      (Icons.directions_car_rounded, 'Trip problem'),
      (Icons.description_rounded, 'Document help'),
      (Icons.person_rounded, 'Account issue'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppTextField(hint: 'Search help topics', prefix: const Icon(Icons.search_rounded), onTap: () => context.push(Routes.faq), readOnly: true),
          if (open != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(children: [
                Expanded(child: Text(open.ref, style: theme.textTheme.titleSmall?.copyWith(fontFeatures: AppText.tabular))),
                StatusBadge(_caseBadge(open.status).$1, kind: _caseBadge(open.status).$2),
                const SizedBox(width: 10),
                LinkText('View Case', size: 13, onTap: () => context.push(Routes.caseDetail(open.ref))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              for (final (icon, label) in quick)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onTap: () => context.push(Routes.supportCategories),
                  child: Row(children: [
                    Icon(icon, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
                    Icon(Icons.chevron_right_rounded, size: 18, color: context.textSecondary),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Get help for a recent trip'),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = recent[i];
                return SizedBox(
                  width: 200,
                  child: AppCard(
                    padding: const EdgeInsets.all(10),
                    onTap: () => context.push(Routes.supportCategories, extra: t.id),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 56, height: 56, child: MapCanvas(pickup: t.pickup.at, destination: t.destination.at, showRoute: true))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(t.destination.area ?? t.destination.name, style: theme.textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(dayLabel(t.date, now: MockData.now), style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
                          Text(naira(t.net), style: theme.textTheme.labelLarge?.copyWith(color: AppColors.earningsGreen, fontFeatures: AppText.tabular)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Chat with Support', icon: Icons.chat_bubble_rounded, onPressed: () => context.push(Routes.supportCategories)),
          const SizedBox(height: 8),
          SecondaryButton(label: 'Call Support', icon: Icons.call_rounded, onPressed: () {}),
          const SizedBox(height: 20),
          SectionLabel('FAQs', trailing: LinkText('View all', size: 13, onTap: () => context.push(Routes.faq))),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: Column(children: [
              for (final q in MockData.faqQuestions)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(q, style: theme.textTheme.bodyLarge),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        Expanded(child: Text(MockData.faq.intro, style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary))),
                        LinkText('Read', size: 13, onTap: () => context.push(Routes.faq)),
                      ]),
                    ),
                  ],
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// 9.2 — Select issue category.
class IssueCategoryScreen extends StatelessWidget {
  const IssueCategoryScreen({super.key, this.tripId});
  final String? tripId;
  @override
  Widget build(BuildContext context) {
    final trip = tripId == null ? null : MockData.trips.where((t) => t.id == tripId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('What do you need help with?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (trip != null) ...[_TripContext(trip), const SizedBox(height: 12)],
          for (final (icon, label) in MockData.issueCategories)
            IconRow(icon: icon, title: label, onTap: () => context.push(Routes.supportForm, extra: (category: label, tripId: tripId))),
        ],
      ),
    );
  }
}

class _TripContext extends StatelessWidget {
  const _TripContext(this.t);
  final Trip t;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 56, height: 56, child: MapCanvas(pickup: t.pickup.at, destination: t.destination.at, showRoute: true))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.routeLabel, style: theme.textTheme.labelLarge),
          Text('${dayMonthTime(t.date)} · ${naira(t.net)} earned', style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
        ])),
      ]),
    );
  }
}

/// 9.3 — Issue detail form.
class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key, required this.category, this.tripId});
  final String category;
  final String? tripId;
  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _desc = TextEditingController();
  final _expected = TextEditingController();
  final _actual = TextEditingController();
  String? _resolution;
  int _severity = 1;
  int _attachments = 0;
  static const _resolutions = ['Refund', 'Correction', 'Explanation', 'I just want to report this', 'Other'];

  @override
  void dispose() {
    for (final c in [_desc, _expected, _actual]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _payment => widget.category.contains('payment');
  bool get _safety => widget.category.contains('safety');
  bool get _document => widget.category.contains('document');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.tripId == null ? null : MockData.trips.where((t) => t.id == widget.tripId).firstOrNull;
    final valid = _desc.text.trim().length >= 10 && _resolution != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.split(' — ').first, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (trip != null) ...[_TripContext(trip), const SizedBox(height: 16)],
          if (_payment) ...[
            Row(children: [
              Expanded(child: AppTextField(label: 'Expected amount', hint: '₦ 1,850', controller: _expected, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Actual amount', hint: '₦ 1,480', controller: _actual, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
          ],
          if (_document) ...[
            SecondaryButton(label: 'Re-upload Document', icon: Icons.upload_rounded, onPressed: () => context.push(Routes.documentStatus)),
            const SizedBox(height: 16),
          ],
          if (_safety) ...[
            Text('Severity', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
            const SizedBox(height: 8),
            SegmentedTabs(labels: const ['Low', 'Medium', 'Urgent'], selected: _severity, onChanged: (i) => setState(() => _severity = i)),
            const SizedBox(height: 16),
          ],
          AppTextField(
            label: 'Tell us what happened',
            hint: 'The more detail you give, the faster we can help',
            controller: _desc,
            maxLines: 5,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text('Attach evidence (optional)', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 0; i < _attachments; i++)
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.image_rounded, color: AppColors.primaryBlue),
              ),
            if (_attachments < 4)
              InkWell(
                onTap: () => setState(() => _attachments++),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(border: Border.all(color: context.border), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.add_a_photo_rounded, color: context.textSecondary),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Preferred resolution', style: theme.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final r in _resolutions) SelectChip(label: r, selected: _resolution == r, onTap: () => setState(() => _resolution = r))]),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Submit', onPressed: valid ? () => context.pushReplacement(Routes.supportSubmitted, extra: widget.category) : null),
          const SizedBox(height: 4),
          GhostButton(label: 'Cancel', onPressed: () => context.pop()),
        ],
      ),
    );
  }
}

/// 9.4 — Case submitted.
class CaseSubmittedScreen extends StatelessWidget {
  const CaseSubmittedScreen({super.key, this.category});
  final String? category;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = (category ?? '').contains('safety') ? '15 minutes' : (category ?? '').contains('payment') ? '2 hours' : '24 hours';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const SuccessCheck(),
            const SizedBox(height: 20),
            Text('We have received your report', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: MockData.caseRef));
                showToast(context, 'Reference copied', kind: ToastKind.success);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(MockData.caseRef, style: theme.textTheme.headlineSmall?.copyWith(fontFeatures: AppText.tabular)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryBlue),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Text('Expected response: within $eta', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
            const Spacer(),
            PrimaryButton(label: 'Track this case', onPressed: () => context.pushReplacement(Routes.cases)),
            const SizedBox(height: 4),
            GhostButton(label: 'Go Home', onPressed: () => context.go(Routes.home)),
          ]),
        ),
      ),
    );
  }
}

/// 9.5 — My cases.
class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  int _filter = 0;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = switch (_filter) {
      1 => MockData.cases.where((c) => c.status != CaseStatus.resolved && c.status != CaseStatus.closed),
      2 => MockData.cases.where((c) => c.status == CaseStatus.resolved || c.status == CaseStatus.closed),
      _ => MockData.cases,
    }
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      floatingActionButton: FloatingActionButton(onPressed: () => context.push(Routes.supportCategories), child: const Icon(Icons.add_rounded)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilterTabs(labels: const ['All', 'Open', 'Resolved'], selected: _filter, onChanged: (i) => setState(() => _filter = i)),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(icon: Icons.assignment_rounded, title: 'No support cases yet')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: [
                    for (final c in list)
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => context.push(Routes.caseDetail(c.ref)),
                        child: Row(children: [
                          Icon(c.icon, color: AppColors.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.ref, style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
                            Text(c.title, style: theme.textTheme.titleSmall),
                            Text(c.preview, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          const SizedBox(width: 8),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            StatusBadge(_caseBadge(c.status).$1, kind: _caseBadge(c.status).$2),
                            const SizedBox(height: 4),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              if (c.unread) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle)),
                              Text(relative(c.updated, now: MockData.now), style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
                            ]),
                          ]),
                        ]),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }
}

/// 9.6 — Case detail & chat.
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseRef});
  final String caseRef;
  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final _input = TextEditingController();
  late final SupportCase _case = MockData.cases.firstWhere((c) => c.ref == widget.caseRef, orElse: () => MockData.cases.first);
  late final List<ChatMessage> _messages = [..._case.messages];
  bool _typing = false;
  bool? _helpful;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: t, time: DateTime.now(), sender: MessageSender.driver, read: false));
      _input.clear();
      _typing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(ChatMessage(text: 'Thanks — an agent is looking into this now.', time: DateTime.now(), sender: MessageSender.agent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = _case.status == CaseStatus.resolved || _case.status == CaseStatus.closed;
    final (label, kind) = _caseBadge(_case.status);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_case.ref, style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary, fontFeatures: AppText.tabular)),
          Text(_case.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 4), child: Center(child: StatusBadge(label, kind: kind))),
          PopupMenuButton<String>(
            onSelected: (v) => showToast(context, v == 'trip' ? 'Opening trip…' : 'Request sent'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'close', child: Text('Close case')),
              PopupMenuItem(value: 'escalate', child: Text('Escalate')),
              PopupMenuItem(value: 'trip', child: Text('View trip')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text('Case summary', style: theme.textTheme.titleSmall),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('${_case.title}\n${_case.tripLabel ?? 'Submitted ${dayMonthTime(_case.updated)}'}', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
              ),
            ],
          ),
        ),
        if (resolved && _case.resolution != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_case.resolution!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.successTeal)),
              const SizedBox(height: 6),
              Row(children: [
                Text('Was this helpful?', style: theme.textTheme.labelMedium),
                const SizedBox(width: 8),
                LinkText('Yes', size: 13, onTap: () => setState(() => _helpful = true)),
                const SizedBox(width: 12),
                LinkText('No', size: 13, onTap: () => setState(() => _helpful = false)),
                const Spacer(),
                if (_helpful == false) LinkText('Reopen Case', size: 13, onTap: () {}),
              ]),
            ]),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final m in _messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChatBubble(message: m, showAvatar: m.sender == MessageSender.agent, senderName: m.sender == MessageSender.agent ? 'NaijaMove Support' : null, avatarName: 'NaijaMove'),
                ),
              if (_typing) const Padding(padding: EdgeInsets.only(bottom: 8), child: TypingIndicator()),
            ],
          ),
        ),
        if (!resolved) ...[
          QuickReplies(options: MockData.supportQuickReplies, onPick: _send),
          ChatInputBar(controller: _input, onSend: () => _send(_input.text)),
        ],
      ]),
    );
  }
}

/// 9.7 — FAQ article.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool? _helpful;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = MockData.faq;
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(a.breadcrumb, style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
          const SizedBox(height: 6),
          Text(a.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(a.intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 14),
          for (final (i, s) in a.steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s, style: theme.textTheme.bodyLarge)),
              ]),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.tint, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(a.highlight, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: AppColors.accentGold, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(a.tip, style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Text('Was this helpful?', style: theme.textTheme.titleSmall),
            const SizedBox(width: 12),
            IconButton(icon: Icon(Icons.thumb_up_rounded, color: _helpful == true ? AppColors.successTeal : context.textSecondary), onPressed: () => setState(() => _helpful = true)),
            IconButton(icon: Icon(Icons.thumb_down_rounded, color: _helpful == false ? AppColors.dangerRed : context.textSecondary), onPressed: () => setState(() => _helpful = false)),
          ]),
          if (_helpful == false) SecondaryButton(label: 'Contact Support', onPressed: () => context.push(Routes.supportCategories)),
          const SizedBox(height: 20),
          const SectionLabel('Related'),
          for (final r in a.related) IconRow(icon: Icons.article_rounded, title: r, dense: true, onTap: () {}),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(label: 'Still need help? Chat with us', onPressed: () => context.push(Routes.supportCategories)),
        ),
      ),
    );
  }
}
