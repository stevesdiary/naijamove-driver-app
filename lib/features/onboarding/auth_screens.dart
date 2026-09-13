import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/state/session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/inputs.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/auth_repository.dart';

/// Shared auth page chrome: brand bar, heading, sub-copy, keyboard-aware footer.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
    this.showBack = true,
    this.step,
  });
  final String title;
  final Widget subtitle;
  final Widget body;
  final Widget footer;
  final bool showBack;
  final (int, int)? step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: showBack ? const BackButton() : null, title: const BrandLockup(size: 22)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step != null) ...[StepProgress(step: step!.$1, total: step!.$2), const SizedBox(height: 16)],
              Text(title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              subtitle,
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: body)),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// 1.3 — Phone number entry.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});
  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final local = _digits(_ctrl.text);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestOtp('+234$local');
      if (!mounted) return;
      context.push(Routes.otp, extra: local);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _digits(_ctrl.text).length == 10;
    return AuthScaffold(
      title: 'Enter your phone number',
      showBack: false,
      subtitle: Text("We'll text you a 6-digit code to verify it's you.",
          style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Phone number',
            hint: '802 555 0193',
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            autofocus: true,
            errorText: _error,
            success: valid,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (_) => setState(() {}),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇳🇬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('+234', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('By continuing you agree to the Driver Terms and Privacy Policy.',
              style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary)),
        ],
      ),
      footer: PrimaryButton(label: 'Send Code', onPressed: valid && !_sending ? _send : null, loading: _sending),
    );
  }
}

/// 1.4 — OTP verification. Routes new drivers into setup, returning drivers home.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _verifying = false;
  bool _error = false;
  String? _message;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn == 0) {
        t.cancel();
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    setState(() {
      _verifying = true;
      _error = false;
      _message = null;
    });
    try {
      final r = await ref.read(authRepositoryProvider).verifyOtp('+234${widget.phone}', code);
      if (!mounted) return;
      ref.read(sessionProvider.notifier).loginFrom(r, phone: widget.phone);
      // A brand-new account, or a rider who hasn't registered as a driver, goes through setup.
      if (r.isNewUser || r.role != 'driver') {
        context.go(Routes.profileSetup);
      } else {
        context.go(Routes.home);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = true;
        _message = e.message;
      });
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).requestOtp('+234${widget.phone}');
      if (mounted) showToast(context, 'New code sent', kind: ToastKind.success);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    }
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pretty = '+234 ${widget.phone.substring(0, 3)} ${widget.phone.substring(3, 6)} ${widget.phone.substring(6)}';
    return AuthScaffold(
      title: 'Enter the code',
      subtitle: Text.rich(TextSpan(
        style: theme.textTheme.bodyLarge?.copyWith(color: context.textSecondary),
        children: [
          const TextSpan(text: 'Sent to '),
          TextSpan(text: pretty, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
        ],
      )),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtpInput(onCompleted: _verifying ? (_) {} : _verify, error: _error),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.dangerRed)),
          ],
          const SizedBox(height: 24),
          Center(
            child: _resendIn > 0
                ? Text('Resend code in 0:${_resendIn.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.textSecondary))
                : LinkText('Resend code', onTap: _resend),
          ),
          if (_verifying) ...[
            const SizedBox(height: 24),
            const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
          ],
        ],
      ),
      footer: GhostButton(label: 'Change number', onPressed: () => context.pop()),
    );
  }
}
