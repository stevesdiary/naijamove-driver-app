import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/session.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../data/repositories/driver_repository.dart';
import '../trip/trip_state.dart';

/// 10.1 — No internet connection.
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offline = ref.watch(sessionProvider.select((s) => s.offline));
    final trip = ref.watch(activeTripProvider);
    final wasOnline = ref.watch(driverAccountProvider).value?.isOnline ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Center(child: BrandMark(size: 96, tileColor: AppColors.primaryDark)),
          const SafeArea(child: OfflineBanner(visible: true)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SheetSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: trip != null
                    ? [
                        Text('Connection lost — your trip is still active', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Your route is saved. Trip data will sync when you reconnect.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                        const SizedBox(height: 14),
                        Row(children: [
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Reconnecting…', style: theme.textTheme.labelLarge),
                        ]),
                      ]
                    : [
                        Text(wasOnline ? 'You went offline due to a lost connection' : 'No internet connection', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Check your mobile data or Wi-Fi.', style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary)),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: wasOnline ? 'Go Online Again' : 'Try Again',
                          color: wasOnline ? AppColors.successTeal : null,
                          onPressed: offline
                              ? null
                              : () {
                                  ref.read(sessionProvider.notifier).setOffline(false);
                                  context.go(Routes.home);
                                },
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
