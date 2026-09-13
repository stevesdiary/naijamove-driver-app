import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/components.dart';
import '../data/repositories/driver_repository.dart';
import 'state/session.dart';
import 'theme/app_colors.dart';

/// Bottom-nav shell: Home · Trips · Earnings · Profile.
/// The Home icon carries a teal dot while the driver is online.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    (Icons.map_outlined, Icons.map_rounded, 'Home'),
    (Icons.schedule_outlined, Icons.schedule_rounded, 'Trips'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Earnings'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(sessionProvider.select((s) => s.offline));
    final online = ref.watch(driverAccountProvider).value?.isOnline ?? false;
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          if (offline) SafeArea(bottom: false, child: OfflineBanner(visible: offline)),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(top: BorderSide(color: context.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final (icon, activeIcon, label) = _items[i];
                final active = navigationShell.currentIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(i, initialLocation: active),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 30,
                          decoration: BoxDecoration(
                            color: active ? context.tint : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(active ? activeIcon : icon,
                                  size: 22, color: active ? AppColors.primaryBlue : context.textSecondary),
                              if (i == 0)
                                Positioned(
                                  right: 12,
                                  top: 4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: online ? AppColors.successTeal : context.textSecondary.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.surface, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: active ? AppColors.primaryBlue : context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
