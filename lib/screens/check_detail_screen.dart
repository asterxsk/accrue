import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
import '../widgets/habit_mark.dart';
import '../widgets/habit_menu.dart';
import '../widgets/ui.dart';

Future<void> openCheckDetail(
  BuildContext context,
  HabitStore store,
  Habit habit,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CheckDetailScreen(store: store, habitId: habit.id),
    ),
  );
}

/// Checked habit detail: today's state, streaks, this week.
class CheckDetailScreen extends StatelessWidget {
  const CheckDetailScreen({
    super.key,
    required this.store,
    required this.habitId,
  });

  final HabitStore store;
  final String habitId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final habit = store.habitById(habitId);
    if (habit == null) {
      return Scaffold(backgroundColor: colors.bg);
    }
    final gutter = Metrics.gutter;
    final week = store.weekDays;
    final accent = markAccent(habit, colors.accent);

    return Scaffold(
      backgroundColor: colors.bg,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final done = store.isDone(habit);
          final current = store.streakOf(habit);
          final best = store.bestStreakOf(habit);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              Metrics.topInset(context),
              gutter,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            child: Column(
              children: [
                HeadBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: HabitActions(store: store, habit: habit),
                ),
                if (habit.badge)
                  HabitMark(habit: habit, size: 64)
                else
                  Disc(icon: habit.icon, size: 64, iconSize: 28),
                const SizedBox(height: 14),
                Text(
                  habit.name,
                  textAlign: TextAlign.center,
                  style: AppType.displayName.copyWith(color: colors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  store.targetLine(habit),
                  style: AppType.meta.copyWith(
                    fontSize: 14,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  done ? 'Done today' : 'Not yet',
                  textAlign: TextAlign.center,
                  style: AppType.stepName.copyWith(
                    color: done ? colors.accentInk : colors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: done ? 'Mark as not done' : 'Mark done',
                  expand: true,
                  onPressed: () => store.toggleCheck(habit),
                ),
                const SizedBox(height: 28),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Eyebrow('Current streak'),
                            const SizedBox(height: 2),
                            Text(
                              '$current ${current == 1 ? 'day' : 'days'}',
                              style: AppType.streakNumber.copyWith(
                                color: colors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Best $best ${best == 1 ? 'day' : 'days'}',
                        style: AppType.meta.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('This week'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0; i < week.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: _WeekDot(
                                done: store.doneOn(week[i], habit.id),
                                today: Fmt.sameDay(week[i], store.today),
                                accent: accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var i = 0; i < week.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                Fmt.weekdayLetter(
                                  week[i],
                                  monday: store.weekStartsMonday,
                                ),
                                textAlign: TextAlign.center,
                                style: AppType.axis.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                  color: colors.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.done,
    required this.today,
    required this.accent,
  });

  final bool done;
  final bool today;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: done ? accent : colors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? accent : today ? accent : colors.line,
        ),
      ),
    );
  }
}
