import 'package:flutter/material.dart';

import '../app_nav.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
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
  late int _step;
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
    _target = habit?.target ?? 1;
    _step = habit?.step ?? 1;
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
      if (_step > _target) _step = _target;
    });
  }

  /// Same idea for the per-tap increment: step by 1, then 10, then 100 so a
  /// 250-step increment is a few taps away rather than 250.
  int get _stepStride {
    if (_step >= 100) return 100;
    if (_step >= 10) return 10;
    return 1;
  }

  void _bumpStep(int direction) {
    final next = _step + direction * _stepStride;
    setState(() => _step = next.clamp(1, _target));
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
      if (_step > _target) _step = _target;
    });
  }

  Future<void> _typeStep() async {
    final value = await numberDialog(
      context,
      title: 'Each tap adds',
      description: 'How much one tap logs.',
      initial: _step,
      buttonLabel: 'Set increment',
      min: 1,
      max: _target,
      hint: 'Up to $_target — it cannot add more than the whole target.',
    );
    if (value == null || !mounted) return;
    setState(() => _step = value);
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
    );
    if (!mounted) return;
    if (widget.fromDetail && kindChanged) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      AppNavScope.of(context).select(0);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final habit = widget.habit;
    if (habit == null) return;
    final confirmed = await confirmDialog(
      context,
      title: 'Delete ${habit.name}?',
      body:
          'The habit and every day it was recorded are removed from this '
          'device. Streaks and Insights recalculate. This cannot be undone.',
      confirmLabel: 'Delete habit',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    widget.store.deleteHabit(habit);
    Navigator.of(context).popUntil((route) => route.isFirst);
    AppNavScope.of(context).select(0);
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
                            border: Border(
                              top: BorderSide(color: colors.line),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
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
                                      _step > 1
                                          ? 'One + logs $_step ${_unit.text.trim().isEmpty ? 'times' : _unit.text.trim()} — handy for steps.'
                                          : 'One tap, one unit.',
                                      style: AppType.meta.copyWith(
                                        color: colors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              TargetStepper(
                                value: _step,
                                label: 'increment',
                                onTapValue: _typeStep,
                                onMinus: _step <= 1
                                    ? null
                                    : () => _bumpStep(-1),
                                onPlus: _step >= _target
                                    ? null
                                    : () => _bumpStep(1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 26),
                    Text(
                      'Reminders are stored as intent only — this build does '
                      'not deliver notifications.',
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
