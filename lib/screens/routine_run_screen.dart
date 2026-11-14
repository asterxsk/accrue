import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';

Future<void> openRoutineRun(
  BuildContext context,
  HabitStore store,
  Routine routine,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RoutineRunScreen(store: store, routineId: routine.id),
    ),
  );
}

/// Running one routine, step by step.
class RoutineRunScreen extends StatelessWidget {
  const RoutineRunScreen({
    super.key,
    required this.store,
    required this.routineId,
  });

  final HabitStore store;
  final String routineId;

  Future<void> _edit(BuildContext context) async {
    final routine = store.routineById(routineId);
    if (routine == null) return;
    final edit = await routineEditorDialog(
      context,
      store,
      routine: routine,
    );
    if (edit == null) return;
    store.updateRoutine(routine, edit.name, edit.habitIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final routine = store.routineById(routineId);
    if (routine == null) {
      return Scaffold(backgroundColor: colors.bg);
    }
    final gutter = Metrics.gutter;

    return Scaffold(
      backgroundColor: colors.bg,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final habits = store.routineHabits(routine);
          final total = habits.length;
          final done = store.routineDoneCount(routine);
          final currentId = store.currentRoutineHabitId(routine);
          Habit? next;
          for (final habit in habits) {
            if (!store.isDone(habit)) {
              next = habit;
              break;
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              Metrics.topInset(context),
              gutter,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeadBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  actionLabel: 'Edit',
                  onAction: () => _edit(context),
                  trailing: null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: Eyebrow(routine.name),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: store.isDone(habits[i])
                                ? colors.accent
                                : habits[i].id == currentId
                                ? colors.accentInk.withValues(alpha: 0.55)
                                : colors.track,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                if (total == 0)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('Empty routine'),
                        const SizedBox(height: 6),
                        Text(
                          'Made of habits',
                          style: AppType.stepName.copyWith(color: colors.text),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A routine is a set of your habits in order. Add a '
                          'few and they will line up here.',
                          style: AppType.meta.copyWith(
                            fontSize: 14,
                            color: colors.muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppButton(
                          label: 'Add habits',
                          expand: true,
                          onPressed: () => _edit(context),
                        ),
                      ],
                    ),
                  )
                else if (done >= total)
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                    child: Column(
                      children: [
                        Text(
                          'Routine complete',
                          textAlign: TextAlign.center,
                          style: AppType.stepName.copyWith(color: colors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${routine.name} is done for today.',
                          textAlign: TextAlign.center,
                          style: AppType.meta.copyWith(
                            fontSize: 14,
                            color: colors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      '$done of $total done · next: ${(next ?? habits.first).name}',
                      style: AppType.eyebrow.copyWith(color: colors.muted),
                    ),
                  ),
                  for (final habit in habits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RunRow(
                        store: store,
                        habit: habit,
                        done: store.isDone(habit),
                        current: habit.id == currentId,
                      ),
                    ),
                ],
                if (done > 0 && total > 0)
                  Center(
                    child: GhostButton(
                      label: 'Reset today',
                      muted: true,
                      onTap: () async {
                        final confirmed = await confirmDialog(
                          context,
                          title: 'Reset this routine?',
                          body:
                              "Today's habits in ${routine.name} will be marked "
                              'not done. This cannot be undone.',
                          confirmLabel: 'Reset',
                          danger: true,
                        );
                        if (confirmed) store.resetRoutine(routine);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.store,
    required this.habit,
    required this.done,
    required this.current,
  });

  final HabitStore store;
  final Habit habit;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: !done && !current ? 0.78 : 1,
      child: Semantics(
        toggled: done,
        button: true,
        label: habit.name,
        child: Material(
          color: current ? colors.accentSoft : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Metrics.rMd),
            side: BorderSide(
              color: current ? colors.accent : colors.hairline,
            ),
          ),
          child: InkWell(
            onTap: () => store.setHabitDone(habit, !done),
            borderRadius: BorderRadius.circular(Metrics.rMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? colors.accent : Colors.transparent,
                        border: Border.all(
                          color: done || current ? colors.accent : colors.line,
                        ),
                      ),
                      child: done
                          ? const _CheckGlyph()
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodyStrong.copyWith(
                              color: done ? colors.muted : colors.text,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.faint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store.typeLine(habit),
                            style: AppType.meta.copyWith(
                              fontSize: 12,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      store.shortValue(habit),
                      style: AppType.meta.copyWith(color: colors.muted),
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

class _CheckGlyph extends StatelessWidget {
  const _CheckGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 15,
      child: CustomPaint(painter: _CheckPainter(AppColors.of(context).accentOn)),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.9, size.height * 0.16);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) => oldDelegate.color != color;
}
