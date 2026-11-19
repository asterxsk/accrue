import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_nav.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/habit_mark.dart';
import '../widgets/ui.dart';
import 'icon_picker_screen.dart';

Future<void> openHabitForm(
  BuildContext context,
  HabitStore store, {
  Habit? habit,
  bool fromDetail = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          NewHabitScreen(store: store, habit: habit, fromDetail: fromDetail),
    ),
  );
}

/// The new/edit habit page.
class NewHabitScreen extends StatefulWidget {
  const NewHabitScreen({
    super.key,
    required this.store,
    this.habit,
    this.fromDetail = false,
  });

  final HabitStore store;
  final Habit? habit;
  final bool fromDetail;

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late HabitKind _kind;
  late String _icon;
  late int _target;
  late double _step;
  late int? _reminderMinutes;
  late TimerMode _timerMode;
  late bool _badge;
  late String _badgeText;
  late String _badgeFg;
  late String _badgeStart;
  late String _badgeEnd;
  bool _iconTouched = false;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _unit = TextEditingController(
      text: habit != null && habit.unit != 'times' ? habit.unit : '',
    );
    _kind = habit?.kind ?? HabitKind.check;
    _icon = habit?.icon ?? _kind.defaultIcon;
    _target = habit != null && habit.target > 0 ? habit.target : 1;
    _step = habit?.step ?? 1;
    _reminderMinutes = habit?.reminderMinutes;
    _timerMode = habit?.timerMode ?? TimerMode.timer;
    _badge = habit?.badge ?? false;
    _badgeText = habit?.badgeText ?? '';
    _badgeFg = habit?.badgeFg ?? '#FAF9F5';
    _badgeStart = habit?.badgeStart ?? '#C96442';
    _badgeEnd = habit?.badgeEnd ?? '#A94E2E';
    _iconTouched = habit != null;
    _name.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _selectKind(HabitKind kind) {
    setState(() {
      _kind = kind;
      if (!_iconTouched || _icon == _kind.defaultIcon) {
        _icon = kind.defaultIcon;
      }
      _target = switch (kind) {
        HabitKind.check => 1,
        HabitKind.timer => 30,
        HabitKind.count => 8,
      };
      if (_step > _target) _step = _target.toDouble();
    });
  }

  /// Big targets (8,000 steps) are unreachable one at a time, so the stepper
  /// widens its stride as the number grows.
  int get _targetStride {
    if (_target >= 1000) return 100;
    if (_target >= 100) return 10;
    return 1;
  }

  void _bumpTarget(int direction) {
    final next = _target + direction * _targetStride;
    setState(() {
      _target = next.clamp(1, 100000);
      if (_step > _target) _step = _target.toDouble();
    });
  }

  /// Presets cover the common cases; anything else is a typed "Custom" value.
  static const List<String> _stepPresets = ['0.5', '1', '5', '10'];

  String get _stepLabel {
    for (final preset in _stepPresets) {
      if (double.parse(preset) == _step) return preset;
    }
    return 'Custom';
  }

  void _selectStep(String label) {
    if (label == 'Custom') {
      unawaited(_typeStep());
      return;
    }
    final next = double.parse(label);
    setState(() => _step = next.clamp(0.05, _target.toDouble()).toDouble());
  }

  String get _stepCopy {
    final unit = _unit.text.trim().isEmpty ? 'times' : _unit.text.trim();
    if (_step < 1) return 'One tap logs ${Fmt.count(_step)} $unit.';
    if (_step > 1) {
      return 'One + logs ${Fmt.count(_step)} $unit — handy for steps.';
    }
    return 'One tap, one unit.';
  }

  Future<void> _typeTarget() async {
    final value = await numberDialog(
      context,
      title: 'Daily target',
      description: 'How much counts as a full day.',
      initial: _target,
      buttonLabel: 'Set target',
      min: 1,
      max: 100000,
      hint: 'Type it instead of tapping — 8,000 steps is a few digits.',
    );
    if (value == null || !mounted) return;
    setState(() {
      _target = value;
      if (_step > _target) _step = _target.toDouble();
    });
  }

  Future<void> _typeStep() async {
    final value = await _decimalStepDialog(
      context,
      initial: _step,
      max: _target,
    );
    if (value == null || !mounted) return;
    setState(() => _step = value.clamp(0.05, _target.toDouble()).toDouble());
  }

  Future<void> _pickMark() async {
    final choice = await openMarkPicker(
      context,
      initial: MarkChoice(
        badge: _badge,
        icon: _icon,
        text: _badgeText,
        fg: _badgeFg,
        start: _badgeStart,
        end: _badgeEnd,
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _badge = choice.badge;
      _icon = choice.icon;
      _badgeText = choice.text;
      _badgeFg = choice.fg;
      _badgeStart = choice.start;
      _badgeEnd = choice.end;
      _iconTouched = true;
    });
  }

  Future<void> _save() async {
    final name = _name.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) return;
    final habit = widget.habit;
    if (habit == null) {
      widget.store.addHabit(
        name: name,
        kind: _kind,
        icon: _icon,
        target: _target,
        unit: _unit.text,
        badge: _badge,
        badgeText: _badgeText,
        badgeFg: _badgeFg,
        badgeStart: _badgeStart,
        badgeEnd: _badgeEnd,
        step: _step,
        reminderMinutes: _reminderMinutes,
        timerMode: _timerMode,
      );
      Navigator.of(context).pop();
      return;
    }
    final kindChanged = habit.kind != _kind;
    widget.store.updateHabit(
      habit,
      name: name,
      kind: _kind,
      icon: _icon,
      target: _target,
      unit: _unit.text,
      badge: _badge,
      badgeText: _badgeText,
      badgeFg: _badgeFg,
      badgeStart: _badgeStart,
      badgeEnd: _badgeEnd,
      step: _step,
      reminderMinutes: _reminderMinutes,
      updateReminder: true,
      timerMode: _timerMode,
    );
    if (!mounted) return;
    if (widget.fromDetail && kindChanged) {
      final nav = AppNavScope.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      nav.select(0);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final habit = widget.habit;
    if (habit == null) return;
    final confirmed = await confirmDialog(
      context,
      title: 'Delete the habit "${habit.name}"?',
      body:
          'The habit and every day it was recorded are removed from this '
          'device. Streaks and Insights recalculate. This cannot be undone.',
      confirmLabel: 'Delete habit',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    final nav = AppNavScope.of(context);
    widget.store.deleteHabit(habit);
    Navigator.of(context).popUntil((route) => route.isFirst);
    nav.select(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gutter = Metrics.gutter;
    final canSave = _name.text.trim().isNotEmpty;
    final unitLabel = _kind == HabitKind.timer
        ? 'minutes'
        : (_unit.text.trim().isEmpty
              ? (_target == 1 ? 'time' : 'times')
              : _unit.text.trim());

    return Scaffold(
      backgroundColor: colors.bg,
      body: Padding(
        padding: EdgeInsets.only(top: Metrics.topInset(context)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: HeadBar(
                onBack: () => Navigator.of(context).maybePop(),
                center: _editing ? 'Edit habit' : 'New habit',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(gutter, 2, gutter, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledField(
                      label: 'Name',
                      controller: _name,
                      hint: 'Drink water',
                      autofocus: !_editing,
                    ),
                    if (!_editing)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => ideasDialog(context, widget.store),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(44, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Browse habit ideas',
                            style: AppType.metaStrong.copyWith(
                              fontSize: 14,
                              color: colors.accentInk,
                            ),
                          ),
                        ),
                      ),
                    SectionTitle(
                      'Mark',
                      margin: const EdgeInsets.only(top: 26),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _badge ? null : colors.accentSoft,
                          ),
                          child: HabitMark(
                            badge: _badge,
                            icon: _icon,
                            badgeText: _badgeText,
                            badgeFg: _badgeFg,
                            badgeStart: _badgeStart,
                            badgeEnd: _badgeEnd,
                            size: 44,
                            iconSize: 22,
                            iconColor: colors.accentInk,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _badge ? 'Text badge' : 'Icon',
                                style: AppType.bodyStrong.copyWith(
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _badge
                                    ? (_badgeText.isEmpty
                                          ? 'Pick one or two letters'
                                          : _badgeText.toUpperCase())
                                    : _icon.replaceAll('-', ' '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.meta.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppButton(
                          label: 'Choose',
                          tone: AppButtonTone.secondary,
                          height: 40,
                          onPressed: _pickMark,
                        ),
                      ],
                    ),
                    SectionTitle(
                      'Track it as',
                      margin: const EdgeInsets.only(top: 26),
                    ),
                    const SizedBox(height: 10),
                    for (final kind in HabitKind.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: KindOption(
                          kind: kind,
                          selected: _kind == kind,
                          onTap: () => _selectKind(kind),
                        ),
                      ),
                    if (_kind != HabitKind.check) ...[
                      const SizedBox(height: 18),
                      if (_kind == HabitKind.timer) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Timer type',
                                style: AppType.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 190,
                              child: SegmentedToggle(
                                options: const ['Stopwatch', 'Timer'],
                                selected: _timerMode.label,
                                onChanged: (value) => setState(
                                  () => _timerMode = value == 'Timer'
                                      ? TimerMode.timer
                                      : TimerMode.stopwatch,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_kind != HabitKind.timer ||
                          _timerMode == TimerMode.timer)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: colors.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Daily target',
                                      style: AppType.body.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: colors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$unitLabel per day',
                                      style: AppType.meta.copyWith(
                                        color: colors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              TargetStepper(
                                value: _target,
                                label: 'target',
                                onTapValue: _typeTarget,
                                onMinus: _target <= 1
                                    ? null
                                    : () => _bumpTarget(-1),
                                onPlus: _target >= 100000
                                    ? null
                                    : () => _bumpTarget(1),
                              ),
                            ],
                          ),
                        ),
                      if (_kind == HabitKind.count) ...[
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Unit (optional)',
                          controller: _unit,
                          hint: 'glasses, bottles, litres',
                          maxLength: 16,
                          onChanged: (_) => _rebuild(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Whatever you count in — bottles, glasses, litres, '
                          'pages.',
                          style: AppType.micro.copyWith(color: colors.faint),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: colors.line)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Each tap adds',
                                style: AppType.bodyStrong.copyWith(
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _stepCopy,
                                style: AppType.meta.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SegmentedToggle(
                                options: [
                                  for (final preset in _stepPresets) preset,
                                  if (_stepLabel == 'Custom') 'Custom',
                                ],
                                selected: _stepLabel,
                                onChanged: _selectStep,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    SectionTitle(
                      'Reminder',
                      margin: const EdgeInsets.only(top: 26),
                    ),
                    const SizedBox(height: 4),
                    SettingsRow(
                      label: 'Remind me',
                      showChevron: false,
                      trailing: AppSwitch(
                        value: _reminderMinutes != null,
                        onChanged: (on) => setState(
                          () => _reminderMinutes = on
                              ? (_reminderMinutes ?? 8 * 60)
                              : null,
                        ),
                      ),
                    ),
                    if (_reminderMinutes != null)
                      SettingsRow(
                        label: 'Time',
                        value: widget.store.formatTime(_reminderMinutes!),
                        onTap: () async {
                          final picked = await timeDialog(
                            context,
                            hour: _reminderMinutes! ~/ 60,
                            minute: _reminderMinutes! % 60,
                            clock24: widget.store.clock24,
                          );
                          if (picked == null || !mounted) return;
                          setState(
                            () => _reminderMinutes =
                                picked.hour * 60 + picked.minute,
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'A daily notification at this time. On Android, allow '
                      'notifications when asked; the reminder is saved even if '
                      'notifications are off.',
                      style: AppType.micro.copyWith(color: colors.faint),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 22),
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(44, 44),
                        ),
                        child: Text(
                          'Delete habit',
                          style: AppType.metaStrong.copyWith(
                            fontSize: 14,
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                gutter,
                12,
                gutter,
                Metrics.bottomInset(context) + 4,
              ),
              decoration: BoxDecoration(
                color: colors.bg,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: AppButton(
                label: _editing ? 'Save changes' : 'Create habit',
                expand: true,
                onPressed: canSave ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decimal entry for an increment the presets do not cover.
Future<double?> _decimalStepDialog(
  BuildContext context, {
  required double initial,
  required int max,
}) {
  return showDialog<double>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (_) => _DecimalStepDialog(initial: initial, max: max),
  );
}

class _DecimalStepDialog extends StatefulWidget {
  const _DecimalStepDialog({required this.initial, required this.max});

  final double initial;
  final int max;

  @override
  State<_DecimalStepDialog> createState() => _DecimalStepDialogState();
}

class _DecimalStepDialogState extends State<_DecimalStepDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _plainNumber(widget.initial),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) return null;
    return parsed.clamp(0.05, widget.max.toDouble()).toDouble();
  }

  void _submit() {
    final value = _value;
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        width: 340,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Metrics.rLg),
            side: BorderSide(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Each tap adds',
                  style: AppType.dialogTitle.copyWith(color: colors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'How much one tap logs. Halves are fine — 0.5 for half a '
                  'glass.',
                  style: AppType.meta.copyWith(
                    fontSize: 14,
                    height: 1.55,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _controller,
                  maxLength: 8,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Between 0.05 and ${Fmt.count(widget.max)}.',
                  style: AppType.micro.copyWith(color: colors.faint),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      tone: AppButtonTone.secondary,
                      expand: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Set increment',
                      expand: false,
                      onPressed: _value == null ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "2.5" for halves, "250" for whole numbers — a TextField should not get
/// thousands separators it cannot parse back.
String _plainNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
