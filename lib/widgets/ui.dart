import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import 'app_icon.dart';

/// Shared building blocks for the Accrue surfaces.
///
/// Every widget here takes its colours from [AppColors] and its rhythm from
/// [Metrics]; screens stay layout-only.

// ─────────────────────────────────────────────────────────────── headers ──

/// Eyebrow + serif title, optionally with a trailing action.
class HeaderBlock extends StatelessWidget {
  const HeaderBlock({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Eyebrow(eyebrow),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppType.title.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing!],
        ],
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.margin = EdgeInsets.zero});

  final String text;
  final Color? color;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: margin,
      child: Text(
        text.toUpperCase(),
        style: AppType.eyebrow.copyWith(color: color ?? colors.muted),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.margin = EdgeInsets.zero});

  final String text;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: margin,
      child: Text(
        text.toUpperCase(),
        style: AppType.sectionTitle.copyWith(color: colors.muted),
      ),
    );
  }
}

/// Back button, optional centre label, optional right action.
class HeadBar extends StatelessWidget {
  const HeadBar({
    super.key,
    required this.onBack,
    this.center,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final VoidCallback onBack;
  final String? center;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Metrics.headBar),
      child: Row(
        children: [
          AppIconButton(
            icon: 'back',
            size: 44,
            iconSize: 22,
            label: 'Back',
            onTap: onBack,
          ),
          if (center != null)
            Expanded(
              child: Center(
                child: Text(
                  center!,
                  textAlign: TextAlign.center,
                  style: AppType.headTitle.copyWith(color: colors.text),
                ),
              ),
            )
          else
            const Spacer(),
          if (trailing != null) ...[
            trailing!,
            if (actionLabel != null) const SizedBox(width: 4),
          ],
          if (actionLabel != null)
            HeadAction(label: actionLabel!, onTap: onAction)
          else if (trailing == null)
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Text action in a header ("Edit", "End", "Share").
class HeadAction extends StatelessWidget {
  const HeadAction({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Metrics.rSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppType.button.copyWith(color: colors.accentInk),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Circular outline button: back, more, plus, or a stepper.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 18,
    this.filled = false,
    this.label,
    this.color,
  });

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  /// Bordered + surface-filled (the prototype's mini steps and head plus).
  final bool filled;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onTap != null;
    final glyph = AppIcon(
      icon,
      size: iconSize,
      color: color ?? (enabled ? colors.text : colors.faint),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: filled
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.line),
                  )
                : null,
            alignment: Alignment.center,
            child: glyph,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── buttons ──

enum AppButtonTone { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.primary,
    this.expand = false,
    this.height = Metrics.button,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null;
    final (background, foreground, border, radius) = switch (tone) {
      AppButtonTone.primary => (
        colors.actionBg,
        colors.actionFg,
        null,
        Metrics.rMd,
      ),
      AppButtonTone.secondary => (
        colors.surface,
        colors.text,
        colors.line,
        Metrics.rSm,
      ),
      AppButtonTone.danger => (
        colors.danger,
        colors.dangerOn,
        null,
        Metrics.rSm,
      ),
      AppButtonTone.ghost => (
        Colors.transparent,
        colors.muted,
        null,
        Metrics.rSm,
      ),
    };
    final child = SizedBox(
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return foreground.withValues(alpha: 0.08);
            }
            return null;
          }),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tone == AppButtonTone.ghost ? 18 : 16),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.button.copyWith(
                  color: enabled ? foreground : foreground.withValues(alpha: 0.55),
                  fontWeight: tone == AppButtonTone.danger
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}

/// Understated text button ("Add 30 minutes", "Reset today").
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Metrics.rSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppType.metaStrong.copyWith(
                color: muted ? colors.muted : colors.accentInk,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: colors.muted,
        textStyle: AppType.meta.copyWith(fontSize: 14),
      ),
      child: Text(
        label,
        style: AppType.meta.copyWith(
          fontSize: 14,
          color: colors.muted,
          decoration: TextDecoration.underline,
          decorationColor: colors.muted,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── surfaces ──

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Metrics.rLg),
        border: Border.all(color: colors.hairline),
        boxShadow: [colors.shadow],
      ),
      child: child,
    );
  }
}

class DashedNewRow extends StatelessWidget {
  const DashedNewRow({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Metrics.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.rMd),
          child: CustomPaint(
            painter: DashedBorderPainter(color: colors.line),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    AppIcon('plus', size: 16, color: colors.accentInk),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: AppType.button.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(Metrics.rMd),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 4, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class Hairline extends StatelessWidget {
  const Hairline({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: color ?? AppColors.of(context).line);
}

// ───────────────────────────────────────────────────────────────── inputs ──

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLength = 60,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLength;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppType.meta.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.muted,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: controller,
          hint: hint,
          maxLength: maxLength,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength = 60,
    this.focusNode,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLength;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownedNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    if (widget.focusNode != null) widget.focusNode!.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _node.hasFocus);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocus);
      widget.focusNode?.addListener(_onFocus);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode != null) widget.focusNode!.removeListener(_onFocus);
    _node.removeListener(_onFocus);
    _ownedNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Metrics.rSm),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: colors.accentSoft,
                  spreadRadius: 3,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _node,
        autofocus: widget.autofocus,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLines: widget.maxLines,
        minLines: widget.maxLines > 1 ? 3 : null,
        style: AppType.field.copyWith(color: colors.text),
        cursorColor: colors.accent,
        cursorWidth: 1.6,
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: colors.surface,
          hintText: widget.hint,
          hintStyle: AppType.field.copyWith(color: colors.faint),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          constraints: const BoxConstraints(minHeight: 48),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Metrics.rSm),
            borderSide: BorderSide(color: colors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Metrics.rSm),
            borderSide: BorderSide(color: colors.accent),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Metrics.rSm),
            borderSide: BorderSide(color: colors.line),
          ),
        ),
      ),
    );
  }
}

/// The minus / value / plus control used on rows and the habit page.
class TargetStepper extends StatelessWidget {
  const TargetStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onTapValue,
    this.label,
    this.valueWidth = 36,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  /// When set, the number itself is tappable for direct entry — tapping a
  /// stepper up to 8,000 is not a plan anyone finishes.
  final VoidCallback? onTapValue;
  final String? label;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: 'minus',
          size: 44,
          iconSize: 16,
          filled: true,
          onTap: onMinus,
          label: label == null ? null : 'Lower $label',
        ),
        SizedBox(
          width: valueWidth,
          child: Semantics(
            button: onTapValue != null,
            label: onTapValue == null
                ? null
                : '${label ?? 'Value'} $value. Tap to type it.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapValue,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppType.count.copyWith(
                  color: colors.text,
                  decoration: onTapValue == null
                      ? null
                      : TextDecoration.underline,
                  decorationColor: colors.faint,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ),
          ),
        ),
        AppIconButton(
          icon: 'plus',
          size: 44,
          iconSize: 16,
          filled: true,
          onTap: onPlus,
          label: label == null ? null : 'Raise $label',
        ),
      ],
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? colors.accent : colors.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: value ? colors.accent : colors.line),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? colors.accentOn : colors.muted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-to-four option slider: the active option sits on a raised thumb that
/// slides between choices.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final index = options.indexOf(selected).clamp(0, options.length - 1);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = constraints.maxWidth / math.max(1, options.length);
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: index * segment,
                top: 0,
                bottom: 0,
                width: segment,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.line),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: Semantics(
                        selected: option == selected,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(option),
                          child: Center(
                            child: Text(
                              option,
                              style: AppType.metaStrong.copyWith(
                                fontSize: 13,
                                color: option == selected
                                    ? colors.text
                                    : colors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 56pt setting line with a label, optional value and chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppType.body.copyWith(color: colors.text),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Text(
              value!,
              style: AppType.meta.copyWith(
                fontSize: 14,
                color: colors.muted,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (showChevron && trailing == null) ...[
            const SizedBox(width: 4),
            AppIcon('chevron', size: 18, color: colors.faint),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Initial-based avatar, or the profile photo when one is set.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.size = 52,
    this.serif = false,
    this.photo = '',
  });

  final String name;
  final double size;
  final bool serif;

  /// Base64 image bytes. Empty falls back to the initial.
  final String photo;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bytes = _decode(photo);
    if (bytes != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _initial(context, colors),
        ),
      );
    }
    return _initial(context, colors);
  }

  static Uint8List? _decode(String value) {
    if (value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Widget _initial(BuildContext context, AppColors colors) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? null
        : trimmed.substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: initial == null
          ? AppIcon('person', size: size * 0.46, color: colors.accentInk)
          : Text(
              initial,
              style: serif
                  ? AppType.headTitle.copyWith(
                      fontSize: size * 0.46,
                      color: colors.accentInk,
                    )
                  : AppType.count.copyWith(
                      fontSize: size * 0.4,
                      color: colors.accentInk,
                    ),
            ),
    );
  }
}

class Disc extends StatelessWidget {
  const Disc({super.key, required this.icon, this.size = 44, this.iconSize});

  final String icon;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: AppIcon(
        icon,
        size: iconSize ?? size * 0.44,
        color: colors.accentInk,
      ),
    );
  }
}

/// A row with a rounded recommendation card look: onboarding, ideas, routine
/// habit picking.
class RecCard extends StatelessWidget {
  const RecCard({
    super.key,
    required this.icon,
    required this.name,
    required this.meta,
    required this.selected,
    this.onTap,
    this.disabled = false,
    this.trailingIcon = 'check',
  });

  final String icon;
  final String name;
  final String meta;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;
  final String trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? colors.accentSoft : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Metrics.rMd),
            side: BorderSide(color: selected ? colors.accent : colors.line),
          ),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(Metrics.rMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : colors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(
                      icon,
                      size: 18,
                      color: selected ? colors.accentOn : colors.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: AppType.bodyStrong.copyWith(
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: AppType.meta.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? colors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colors.accent : colors.line,
                      ),
                    ),
                    child: AppIcon(
                      trailingIcon,
                      size: 14,
                      color: selected ? colors.accentOn : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 64pt choice in the "Track it as" list.
class KindOption extends StatelessWidget {
  const KindOption({
    super.key,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final HabitKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.accentSoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.rMd),
          side: BorderSide(color: selected ? colors.accent : colors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.rMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? colors.surface : colors.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    kind.defaultIcon,
                    size: 18,
                    color: selected ? colors.accentInk : colors.muted,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kind.label,
                        style: AppType.bodyStrong.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kind.description,
                        style: AppType.meta.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconOption extends StatelessWidget {
  const IconOption({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: '$icon icon',
      child: Material(
        color: selected ? colors.accentSoft : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.rMd),
          side: BorderSide(color: selected ? colors.accent : colors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.rMd),
          child: AspectRatio(
            aspectRatio: 1,
            child: Center(
              child: AppIcon(
                icon,
                size: 20,
                color: selected ? colors.accentInk : colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 6pt progress track.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: colors.track,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => FractionallySizedBox(
            widthFactor: animated,
            child: Container(
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "↑ +12%" pill on the insights hero.
class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.trend});

  final int trend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final zero = trend == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 30,
      decoration: BoxDecoration(
        color: zero ? colors.surface2 : colors.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            trend > 0 ? 'up' : trend < 0 ? 'down' : 'flat',
            size: 12,
            color: zero ? colors.muted : colors.accentInk,
          ),
          const SizedBox(width: 4),
          Text(
            '${trend > 0 ? '+' : ''}$trend%',
            style: AppType.metaStrong.copyWith(
              color: zero ? colors.muted : colors.accentInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard screen content padding. Top-level screens keep room for the pill.
EdgeInsets screenPadding(BuildContext context, {bool topLevel = false}) {
  final width = MediaQuery.sizeOf(context).width;
  final gutter = Metrics.gutterFor(math.min(width, Metrics.maxAppWidth));
  return EdgeInsets.fromLTRB(
    gutter,
    Metrics.topInset(context) + Metrics.headerTop,
    gutter,
    topLevel
        ? Metrics.pillClearance + MediaQuery.paddingOf(context).bottom
        : MediaQuery.paddingOf(context).bottom + 40,
  );
}

/// Pushed screens start right under the status bar with the head bar's own
/// 52pt height supplying the rhythm.
EdgeInsets pushedPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final gutter = Metrics.gutterFor(math.min(width, Metrics.maxAppWidth));
  return EdgeInsets.fromLTRB(
    gutter,
    Metrics.topInset(context),
    gutter,
    MediaQuery.paddingOf(context).bottom + 40,
  );
}
