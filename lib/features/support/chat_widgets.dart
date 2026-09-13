import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/components.dart';
import '../../data/models.dart';

/// Chat bubble per the spec: driver = Primary Blue right; rider/agent = surface left; system = centred italic.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.showAvatar = false,
    this.senderName,
    this.avatarName,
  });
  final ChatMessage message;
  final bool showAvatar;
  final String? senderName;
  final String? avatarName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = message;
    if (m.sender == MessageSender.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            '${m.text} · ${timeOf(m.time)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    final mine = m.sender == MessageSender.driver;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(mine ? 16 : 4),
      bottomRight: Radius.circular(mine ? 4 : 16),
    );
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: m.imageAttachment
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.primaryBlue : context.surface,
        borderRadius: radius,
        border: mine ? null : Border.all(color: context.border),
      ),
      child: m.imageAttachment
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 220,
                height: 160,
                color: mine ? AppColors.primaryDark : context.bg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: mine ? Colors.white70 : context.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.text,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: mine ? Colors.white70 : null,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Text(
              m.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mine ? Colors.white : context.textPrimary,
                height: 1.35,
              ),
            ),
    );

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeOf(m.time), style: theme.textTheme.labelSmall),
        if (mine) ...[
          const SizedBox(width: 4),
          Icon(
            m.read ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: m.read ? AppColors.primaryBlue : context.textSecondary,
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine)
            SizedBox(
              width: 36,
              child: showAvatar
                  ? Avatar(name: avatarName ?? 'NaijaMove Support', size: 28)
                  : null,
            ),
          Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!mine && showAvatar && senderName != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    senderName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              bubble,
              const SizedBox(height: 3),
              meta,
            ],
          ),
        ],
      ),
    );
  }
}

/// Three animated dots in an agent-style bubble.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: context.border),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = ((_c.value * 3) - i).clamp(0.0, 1.0);
                  final bump = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                  return Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    transform: Matrix4.translationValues(0, -4 * bump, 0),
                    decoration: BoxDecoration(
                      color: context.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned message input bar.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Type a message…',
    this.allowAttachments = true,
    this.enabled = true,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;
  final bool allowAttachments;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (allowAttachments)
              IconButton(
                onPressed: enabled ? () => _attachSheet(context) : null,
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: context.textSecondary,
                ),
              ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, v, _) => TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, _) {
                final active = enabled && v.text.trim().isNotEmpty;
                return Material(
                  color: active ? AppColors.primaryBlue : context.border,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: active ? onSend : null,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _attachSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconRow(
              icon: Icons.photo_camera_rounded,
              title: 'Camera',
              onTap: () => Navigator.pop(ctx),
            ),
            IconRow(
              icon: Icons.photo_library_rounded,
              title: 'Photo Library',
              onTap: () => Navigator.pop(ctx),
            ),
            IconRow(
              icon: Icons.insert_drive_file_rounded,
              title: 'File',
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Horizontal quick-reply chips.
class QuickReplies extends StatelessWidget {
  const QuickReplies({
    super.key,
    required this.options,
    required this.onPick,
    this.filled = false,
  });
  final List<String> options;
  final ValueChanged<String> onPick;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Material(
          color: filled ? context.tint : context.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: filled ? Colors.transparent : context.border,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onPick(options[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                options[i],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

StatusBadge caseBadge(CaseStatus s) => switch (s) {
  CaseStatus.open => const StatusBadge('Open', kind: BadgeKind.open),
  CaseStatus.pendingUser || CaseStatus.pendingAgent => const StatusBadge(
    'Pending',
    kind: BadgeKind.pending,
  ),
  CaseStatus.escalated => const StatusBadge(
    'Escalated',
    kind: BadgeKind.danger,
  ),
  CaseStatus.resolved => const StatusBadge(
    'Resolved',
    kind: BadgeKind.resolved,
  ),
  CaseStatus.closed => const StatusBadge('Closed', kind: BadgeKind.closed),
};
