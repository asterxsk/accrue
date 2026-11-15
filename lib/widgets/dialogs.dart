import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../util/share.dart';
import 'app_icon.dart';
import 'share_poster.dart';
import 'ui.dart';
import 'wheel_picker.dart';

class RoutineEdit {
  const RoutineEdit({required this.name, required this.habitIds});

  final String name;
  final List<String> habitIds;
}

// ─────────────────────────────────────────────────────────────── plumbing ──

class _DialogPanel extends StatelessWidget {
  const _DialogPanel({
    required this.title,
    required this.body,
    required this.actions,
    this.description,
    this.width = 340,
  });

  final String title;
  final String? description;
  final Widget body;
  final Widget actions;

  /// Content width. Panels that hold a short list ask for the measured width
  /// of their longest line; everything else keeps the 340pt reading width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height - padding.top - padding.bottom - 76,
        ),
        child: SizedBox(
          width: width,
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
                    title,
                    style: AppType.dialogTitle.copyWith(color: colors.text),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      style: AppType.meta.copyWith(
                        fontSize: 14,
                        height: 1.55,
                        color: colors.muted,
                      ),
                    ),
                  ],
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 14),
                      child: body,
                    ),
                  ),
                  const SizedBox(height: 14),
                  actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Width that fits [labels] on one line inside the panel's 20pt gutters.
double _fittedWidth(
  BuildContext context, {
  required String title,
  String? description,
  List<String> labels = const [],
  List<String> buttons = const [],
}) {
  double widest(Iterable<String> lines, TextStyle style) {
    var value = 0.0;
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout();
      if (painter.width > value) value = painter.width;
    }
    return value;
  }

  final titleWidth = widest([title], AppType.dialogTitle);
  // ChoiceRow adds 14pt of padding on each side.
  final labelWidth = widest(labels, AppType.button) + 28;
  final descWidth = description == null
      ? 0.0
      : widest([
          description,
        ], AppType.meta.copyWith(fontSize: 14)).clamp(0.0, 296.0);
  // Buttons sit side by side; 32pt of horizontal padding each plus 8pt gaps.
  var buttonWidth = 0.0;
  for (final label in buttons) {
    buttonWidth += widest([label], AppType.button) + 32;
  }
  if (buttons.length > 1) buttonWidth += 8.0 * (buttons.length - 1);
  final content = [
    titleWidth,
    labelWidth,
    buttonWidth,
    descWidth,
  ].reduce((a, b) => a > b ? a : b);
  return (content + 40).clamp(232.0, 340.0);
}

Future<T?> _showPanel<T>(
  BuildContext context, {
  required String title,
  String? description,
  required Widget body,
  required Widget actions,
  List<String> labels = const [],
  List<String> buttons = const [],
}) {
  return showDialog<T>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (_) => _DialogPanel(
      title: title,
      description: description,
      body: body,
      actions: actions,
      width: labels.isEmpty && buttons.isEmpty
          ? 340
          : _fittedWidth(
              context,
              title: title,
              description: description,
              labels: labels,
              buttons: buttons,
            ),
    ),
  );
}

Widget dialogActions(List<Widget> buttons) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        buttons[i],
      ],
    ],
  );
}

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final String? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: selected ? colors.accentSoft : colors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.rSm),
        side: BorderSide(color: selected ? colors.accent : colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Metrics.rSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppType.button.copyWith(
                    color: danger ? colors.danger : colors.text,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 10),
                  AppIcon('check', size: 16, color: colors.accentInk),
                ] else if (icon != null) ...[
                  const SizedBox(width: 10),
                  AppIcon(
                    icon!,
                    size: 16,
                    color: danger ? colors.danger : colors.accentInk,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── dialogs ──

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await _showPanel<bool>(
    context,
    title: title,
    description: body,
    body: const SizedBox.shrink(),
    labels: ['Cancel', confirmLabel],
    buttons: ['Cancel', confirmLabel],
    actions: dialogActions([
      AppButton(
        label: 'Cancel',
        tone: AppButtonTone.secondary,
        expand: false,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      AppButton(
        label: confirmLabel,
        tone: danger ? AppButtonTone.danger : AppButtonTone.primary,
        expand: false,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ]),
  );
  return result ?? false;
}

Future<void> infoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return _showPanel<void>(
    context,
    title: title,
    description: body,
    body: const SizedBox.shrink(),
    labels: const ['Close'],
    buttons: const ['Close'],
    actions: dialogActions([
      AppButton(
        label: 'Close',
        tone: AppButtonTone.secondary,
        expand: false,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ]),
  );
}

Future<String?> choiceDialog(
  BuildContext context, {
  required String title,
  String? description,
  required List<String> options,
  required String selected,
}) {
  return _showPanel<String>(
    context,
    title: title,
    description: description,
    labels: [...options, 'Cancel'],
    buttons: const ['Cancel'],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          ChoiceRow(
            label: options[i],
            selected: options[i] == selected,
            onTap: () => Navigator.of(context).pop(options[i]),
          ),
        ],
      ],
    ),
    actions: dialogActions([
      AppButton(
        label: 'Cancel',
        tone: AppButtonTone.secondary,
        expand: false,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ]),
  );
}

/// A one-field dialog. It owns its controller so nothing is disposed while
/// the route is still animating out — the old `whenComplete(dispose)` pattern
/// killed the controller under a live TextField and crashed the app.
class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    required this.title,
    this.description,
    required this.initial,
    required this.buttonLabel,
    this.fieldLabel,
    this.hint,
    this.maxLength = 60,
    this.number,
  });

  final String title;
  final String? description;
  final String initial;
  final String buttonLabel;
  final String? fieldLabel;
  final String? hint;
  final int maxLength;

  /// Non-null turns this into a numeric entry clamped to the range.
  final ({int min, int max})? number;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  int? get _numberValue {
    final range = widget.number;
    final parsed = int.tryParse(_text);
    if (range == null || parsed == null) return null;
    return parsed.clamp(range.min, range.max);
  }

  bool get _canSubmit =>
      widget.number == null ? _text.isNotEmpty : _numberValue != null;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(widget.number == null ? _text : _numberValue);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final numeric = widget.number != null;
    return _DialogPanel(
      title: widget.title,
      description: widget.description,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fieldLabel != null) ...[
            Text(
              widget.fieldLabel!,
              style: AppType.meta.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 6),
          ],
          AppTextField(
            controller: _controller,
            maxLength: widget.maxLength,
            autofocus: true,
            keyboardType: numeric ? TextInputType.number : null,
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.hint!,
              style: AppType.micro.copyWith(color: colors.faint),
            ),
          ],
        ],
      ),
      actions: dialogActions([
        AppButton(
          label: 'Cancel',
          tone: AppButtonTone.secondary,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: widget.buttonLabel,
          expand: false,
          onPressed: _canSubmit ? _submit : null,
        ),
      ]),
    );
  }
}

Future<String?> nameDialog(
  BuildContext context, {
  required String title,
  String? description,
  required String initial,
  required String buttonLabel,
  String? hint,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (_) => _EntryDialog(
      title: title,
      description: description,
      initial: initial,
      buttonLabel: buttonLabel,
      fieldLabel: 'Name',
      hint: hint,
      maxLength: 40,
    ),
  );
}

/// Type a number instead of tapping a stepper up to it. Returns the clamped
/// value, or null when cancelled.
Future<int?> numberDialog(
  BuildContext context, {
  required String title,
  String? description,
  required int initial,
  required String buttonLabel,
  int min = 1,
  int max = 100000,
  String? hint,
}) {
  return showDialog<int>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (_) => _EntryDialog(
      title: title,
      description: description,
      initial: '$initial',
      buttonLabel: buttonLabel,
      hint: hint,
      maxLength: 6,
      number: (min: min, max: max),
    ),
  );
}

Future<({int hour, int minute})?> timeDialog(
  BuildContext context, {
  required int hour,
  required int minute,
  bool clock24 = true,
}) {
  var nextHour = hour;
  var nextMinute = minute;
  final hours = [
    for (var h = 0; h < (clock24 ? 24 : 12); h++)
      clock24 ? h.toString().padLeft(2, '0') : '${h == 0 ? 12 : h}',
  ];
  return showDialog<({int hour, int minute})>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final colors = AppColors.of(context);
          final pm = nextHour >= 12;
          return _DialogPanel(
            title: 'Reminder time',
            description: 'Every day',
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WheelPicker(
                      values: hours,
                      selected: clock24 ? nextHour : nextHour % 12,
                      semanticLabel: 'Hour',
                      onChanged: (index) => setState(() {
                        nextHour = clock24
                            ? index
                            : index + (pm ? 12 : 0);
                      }),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ':',
                      style: AppType.count.copyWith(
                        fontSize: 20,
                        color: colors.faint,
                      ),
                    ),
                    const SizedBox(width: 4),
                    WheelPicker(
                      values: [
                        for (var m = 0; m < 60; m++)
                          m.toString().padLeft(2, '0'),
                      ],
                      selected: nextMinute,
                      semanticLabel: 'Minute',
                      onChanged: (index) => setState(() => nextMinute = index),
                    ),
                    if (!clock24) ...[
                      const SizedBox(width: 12),
                      MeridiemToggle(
                        pm: pm,
                        onChanged: (isPm) => setState(
                          () => nextHour = (nextHour % 12) + (isPm ? 12 : 0),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Delivered every day at '
                  '${Fmt.clockLabel(nextHour * 60 + nextMinute, clock24: clock24)}'
                  ' while the habit is active.',
                  style: AppType.micro.copyWith(color: colors.faint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: dialogActions([
              AppButton(
                label: 'Cancel',
                tone: AppButtonTone.secondary,
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
              AppButton(
                label: 'Save',
                expand: false,
                onPressed: () =>
                    Navigator.of(context)
                        .pop((hour: nextHour, minute: nextMinute)),
              ),
            ]),
          );
        },
      );
    },
  );
}

/// Hours / minutes / seconds picker for logging time by hand. Returns the
/// number of seconds, or null when cancelled.
Future<int?> durationDialog(
  BuildContext context, {
  required String title,
  String? description,
  int hour = 0,
  int minute = 0,
  int second = 0,
}) {
  var nextHour = hour;
  var nextMinute = minute;
  var nextSecond = second;
  return showDialog<int>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final colors = AppColors.of(context);
          final total = nextHour * 3600 + nextMinute * 60 + nextSecond;
          return _DialogPanel(
            title: title,
            description: description,
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WheelPicker(
                      values: _twoDigits(24),
                      selected: nextHour,
                      semanticLabel: 'Hours',
                      onChanged: (index) => setState(() => nextHour = index),
                    ),
                    _TimeColon(colors: colors),
                    WheelPicker(
                      values: _twoDigits(60),
                      selected: nextMinute,
                      semanticLabel: 'Minutes',
                      onChanged: (index) => setState(() => nextMinute = index),
                    ),
                    _TimeColon(colors: colors),
                    WheelPicker(
                      values: _twoDigits(60),
                      selected: nextSecond,
                      semanticLabel: 'Seconds',
                      onChanged: (index) => setState(() => nextSecond = index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WheelLabel('HOURS'),
                    SizedBox(width: 24),
                    _WheelLabel('MINUTES'),
                    SizedBox(width: 24),
                    _WheelLabel('SECONDS'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  total == 0
                      ? 'Pick at least a second.'
                      : 'Adds ${_durationLabel(total)} to today.',
                  style: AppType.micro.copyWith(color: colors.faint),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: dialogActions([
              AppButton(
                label: 'Cancel',
                tone: AppButtonTone.secondary,
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
              AppButton(
                label: 'Add time',
                expand: false,
                onPressed: total == 0
                    ? null
                    : () => Navigator.of(context).pop(total),
              ),
            ]),
          );
        },
      );
    },
  );
}

/// "00"…"23" or "00"…"59" — the rows of a wheel column.
List<String> _twoDigits(int count) => [
  for (var i = 0; i < count; i++) i.toString().padLeft(2, '0'),
];

/// "1h 5m 30s" — seconds included, unlike [Fmt.duration], which rounds to
/// whole minutes for a habit's logged total.
String _durationLabel(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return [
    if (h > 0) '${h}h',
    if (m > 0) '${m}m',
    if (s > 0) '${s}s',
  ].join(' ');
}

class _TimeColon extends StatelessWidget {
  const _TimeColon({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          ':',
          style: AppType.count.copyWith(fontSize: 20, color: colors.faint),
        ),
      ),
    );
  }
}

class _WheelLabel extends StatelessWidget {
  const _WheelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 68,
      child: Center(
        child: Text(
          label,
          style: AppType.eyebrow.copyWith(
            fontSize: 11,
            letterSpacing: 0.88,
            color: colors.muted,
          ),
        ),
      ),
    );
  }
}

Future<String?> editProfileDialog(
  BuildContext context, {
  required String name,
}) {
  return nameDialog(
    context,
    title: 'Edit profile',
    description: 'Your name appears on the profile and the share card.',
    initial: name,
    buttonLabel: 'Save',
  );
}

Future<void> ideasDialog(BuildContext context, HabitStore store) {
  const groups = ['Health', 'Movement', 'Mind', 'Home'];
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final colors = AppColors.of(context);
          return _DialogPanel(
            title: 'Habit ideas',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready-made habits. Tap one to add it — you can rename it or '
                  'change its target later.',
                  style: AppType.meta.copyWith(
                    fontSize: 14,
                    height: 1.55,
                    color: colors.muted,
                  ),
                ),
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      group.toUpperCase(),
                      style: AppType.eyebrow.copyWith(color: colors.muted),
                    ),
                  ),
                  for (final idea in habitIdeas.where(
                    (idea) => idea.group == group,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Builder(
                        builder: (context) {
                          final added = store.habits.any(
                            (habit) =>
                                habit.name.toLowerCase() ==
                                idea.name.toLowerCase(),
                          );
                          final meta = switch (idea.kind) {
                            HabitKind.count =>
                              'Count · ${Fmt.count(idea.target)} '
                                  '${Fmt.unit(idea.target, idea.unit)} a day',
                            HabitKind.timer =>
                              'Timer · ${idea.target} min a day',
                            HabitKind.check => 'Check off · once a day',
                          };
                          return RecCard(
                            icon: idea.icon,
                            name: idea.name,
                            meta: added ? 'Added' : meta,
                            selected: added,
                            disabled: added,
                            onTap: () {
                              store.addIdeaHabit(idea);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
            actions: dialogActions([
              AppButton(
                label: 'Done',
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          );
        },
      );
    },
  );
}

/// Returns null when the dialog was dismissed without sharing.
Future<ShareOutcome?> shareDialog(
  BuildContext context,
  HabitStore store,
) async {
  return _showPanel<ShareOutcome>(
    context,
    title: 'Share your stats',
    body: Column(
      children: [
        SharePoster(store: store),
        const SizedBox(height: 10),
        Text(
          "Opens the system share sheet with this week's numbers as text. "
          'Without a share target the caption goes to the clipboard instead. '
          'The poster is previewed here, not exported as an image.',
          style: AppType.micro.copyWith(color: AppColors.of(context).faint),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    actions: dialogActions([
      AppButton(
        label: 'Cancel',
        tone: AppButtonTone.secondary,
        expand: false,
        onPressed: () => Navigator.of(context).pop(),
      ),
      AppButton(
        label: 'Share',
        expand: false,
        onPressed: () async {
          final caption = shareCaption(store);
          final shared = await NativeShare.text(
            caption,
            subject: 'Accrue — this week',
          );
          // No native share target (web or desktop): copy instead of failing.
          if (!shared) {
            await Clipboard.setData(ClipboardData(text: caption));
          }
          if (context.mounted) {
            Navigator.of(context)
                .pop(shared ? ShareOutcome.shared : ShareOutcome.copied);
          }
        },
      ),
    ]),
  );
}

Future<RoutineEdit?> routineEditorDialog(
  BuildContext context,
  HabitStore store, {
  Routine? routine,
}) {
  final controller = TextEditingController(text: routine?.name ?? '');
  final selected = <String>[...?routine?.habitIds];
  final editing = routine != null;

  return showDialog<RoutineEdit>(
    context: context,
    barrierColor: AppColors.of(context).scrim,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final colors = AppColors.of(context);
          final canSave =
              controller.text.trim().isNotEmpty && selected.isNotEmpty;
          return _DialogPanel(
            title: editing ? 'Edit routine' : 'New routine',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField(
                  label: 'Name',
                  controller: controller,
                  hint: 'Morning',
                  maxLength: 60,
                  autofocus: !editing,
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 2),
                  child: SectionTitle('Habits in this routine'),
                ),
                Text(
                  'Pick them in the order you want to run them.',
                  style: AppType.micro.copyWith(color: colors.faint),
                ),
                const SizedBox(height: 10),
                if (store.habits.isEmpty)
                  Text(
                    'No habits yet. Create a habit first — a routine is made '
                    'of habits.',
                    style: AppType.micro.copyWith(color: colors.faint),
                  )
                else
                  for (final habit in store.habits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RecCard(
                        icon: habit.icon,
                        name: habit.name,
                        meta: store.typeLine(habit),
                        selected: selected.contains(habit.id),
                        onTap: () {
                          setState(() {
                            if (selected.contains(habit.id)) {
                              selected.remove(habit.id);
                            } else {
                              selected.add(habit.id);
                            }
                          });
                        },
                      ),
                    ),
              ],
            ),
            actions: dialogActions([
              AppButton(
                label: 'Cancel',
                tone: AppButtonTone.secondary,
                expand: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
              AppButton(
                label: editing ? 'Save routine' : 'Create routine',
                expand: false,
                onPressed: canSave
                    ? () => Navigator.of(context).pop(
                        RoutineEdit(
                          name: controller.text.trim(),
                          habitIds: [...selected],
                        ),
                      )
                    : null,
              ),
            ]),
          );
        },
      );
    },
  ).whenComplete(controller.dispose);
}
