import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';

/// Labelled text field: 52pt, 12pt radius, label above in Text Secondary.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.errorText,
    this.success = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
    this.obscureText = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final bool success;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: success
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.successTeal,
                  )
                : suffix,
            errorText: errorText,
            counterText: maxLength == null ? null : '',
            enabledBorder: success
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.successTeal),
                  )
                : null,
          ),
        ),
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller ?? TextEditingController(),
                builder: (_, v, _) => Text(
                  '${v.text.length}/$maxLength',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Selectable pill chip (Primary Light fill + Primary Blue border when selected).
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.filled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// When true, selected state is Primary Blue fill with white text.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bg;
    final Color fg;
    final Color border;
    if (selected && filled) {
      bg = AppColors.primaryBlue;
      fg = Colors.white;
      border = AppColors.primaryBlue;
    } else if (selected) {
      bg = context.tint;
      fg = AppColors.primaryBlue;
      border = AppColors.primaryBlue;
    } else {
      bg = context.surface;
      fg = context.textPrimary;
      border = context.border;
    }
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(color: border, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented control (e.g. Now · Schedule · Negotiate).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.icons,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                decoration: BoxDecoration(
                  color: active ? context.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icons != null) ...[
                      Icon(
                        icons![i],
                        size: 16,
                        color: active
                            ? AppColors.primaryBlue
                            : context.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        labels[i],
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: active
                              ? AppColors.primaryBlue
                              : context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Underlined filter tabs (All · Trips · Top-ups · …).
class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.counts,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<int?>? counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.screen,
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          final count = counts?[i];
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppColors.primaryBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    labels[i],
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      color: active
                          ? AppColors.primaryBlue
                          : context.textSecondary,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primaryBlue : context.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: active ? Colors.white : context.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 6-box OTP input with auto-advance and error shake.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    this.error = false,
    this.length = 6,
  });
  final ValueChanged<String> onCompleted;
  final bool error;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput>
    with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _ctrls = List.generate(
    widget.length,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _nodes = List.generate(
    widget.length,
    (_) => FocusNode(),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(covariant OtpInput old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) {
      _shake.forward(from: 0);
      for (final c in _ctrls) {
        c.clear();
      }
      _nodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      // Pasted code
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < widget.length && k < digits.length; k++) {
        _ctrls[k].text = digits[k];
      }
      _nodes[(digits.length - 1).clamp(0, widget.length - 1)].requestFocus();
    } else if (v.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    final code = _ctrls.map((c) => c.text).join();
    if (code.length == widget.length) widget.onCompleted(code);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final dx = (_shake.value * 6.28 * 3).abs() < 0.01
            ? 0.0
            : (1 - _shake.value) *
                  10 *
                  ((_shake.value * 10).floor().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          final filled = _ctrls[i].text.isNotEmpty;
          return AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: filled ? 1.04 : 1,
            child: SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.fare(context, size: 22),
                onChanged: (v) => _onChanged(i, v),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: widget.error
                          ? AppColors.dangerRed
                          : filled
                          ? AppColors.primaryBlue
                          : context.border,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
