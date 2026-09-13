import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand.dart';
import '../../data/repositories/repository_providers.dart';

/// 1.1 — Splash. Primary Dark background, brand mark, tagline; decides where to go.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    unawaited(_route());
  }

  Future<void> _route() async {
    final tokens = ref.read(tokenStoreProvider);
    final hasSession = (await tokens.refreshToken) != null;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    if (hasSession) {
      ref.read(sessionProvider.notifier).demoLogin();
      context.go(Routes.home);
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 88, tileColor: AppColors.primaryBlue),
                const SizedBox(height: 20),
                const BrandWordmark(size: 28, color: Colors.white),
                const SizedBox(height: 6),
                Text('DRIVER',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accentGold, letterSpacing: 4, fontWeight: FontWeight.w700)),
                const SizedBox(height: 32),
                Text('Drive. Earn. Thrive.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
