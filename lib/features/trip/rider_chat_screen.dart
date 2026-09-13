import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/components.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../support/chat_widgets.dart';
import 'trip_state.dart';

/// 3.8 — In-trip rider chat. Quick replies first; typing locked while moving.
class RiderChatScreen extends ConsumerStatefulWidget {
  const RiderChatScreen({super.key});
  @override
  ConsumerState<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends ConsumerState<RiderChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<ChatMessage> _messages = [...MockData.riderChat];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: t, time: DateTime.now(), sender: MessageSender.driver, read: false));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = ref.watch(activeTripProvider);
    final rider = trip?.request.rider ?? MockData.request.rider;
    final moving = trip?.phase == TripPhase.inProgress || trip?.phase == TripPhase.navigating;
    final statusLabel = switch (trip?.phase) {
      TripPhase.inProgress => 'On trip',
      TripPhase.arrived => 'At pickup',
      _ => 'Heading to pickup',
    };
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(name: rider.firstName, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rider.firstName, style: theme.textTheme.titleMedium),
                  StatusBadge(statusLabel, kind: trip?.phase == TripPhase.inProgress ? BadgeKind.inProgress : BadgeKind.info),
                ],
              ),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}), const SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: context.tint,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text('Messages are shared with NaijaMove for safety · Pull over before typing',
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primaryBlue)),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text('Trip accepted · ${timeOf(trip?.acceptedAt ?? MockData.now)}',
                          style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary, fontStyle: FontStyle.italic)),
                    ),
                  );
                }
                final m = _messages[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChatBubble(message: m, showAvatar: m.sender == MessageSender.rider, avatarName: rider.firstName),
                );
              },
            ),
          ),
          QuickReplies(options: MockData.riderQuickReplies, onPick: _send),
          if (moving)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('Pull over to type — quick replies still work',
                  style: theme.textTheme.labelSmall?.copyWith(color: context.textSecondary)),
            ),
          ChatInputBar(controller: _input, onSend: () => _send(_input.text), hint: 'Message ${rider.firstName}…', allowAttachments: false, enabled: !moving),
        ],
      ),
    );
  }
}
