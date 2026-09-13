import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';

/// 1.2 — Three-slide carousel: earnings, flexibility, safety.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    (Icons.payments_rounded, AppColors.earningsGreen, 'Earn on your schedule',
        'Keep more of every fare with a flat 20% commission and weekly payouts straight to your bank.'),
    (Icons.schedule_rounded, AppColors.primaryBlue, 'Drive when you want',
        'Go online with one tap, take the trips that suit you, and go offline any time — no minimums.'),
    (Icons.shield_rounded, AppColors.successTeal, 'Safety built in',
        'Verified riders, pickup PINs, in-app SOS and 24/7 support — you are never on your own.'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      context.go(Routes.phone);
    } else {
      _ctrl.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GhostButton(label: 'Skip', onPressed: () => context.go(Routes.phone)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final (icon, color, title, body) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: Icon(icon, size: 72, color: color),
                        ),
                        const SizedBox(height: 40),
                        Text(title, style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(body,
                            style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  StepProgress(step: _page + 1, total: _slides.length),
                  const SizedBox(height: 20),
                  PrimaryButton(label: last ? 'Get Started' : 'Next', onPressed: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
