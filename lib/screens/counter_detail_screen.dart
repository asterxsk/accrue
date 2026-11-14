import 'dart:math' as math;

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

Future<void> openCounter(
  BuildContext context,
  HabitStore store,
  Habit habit,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CounterDetailScreen(store: store, habitId: habit.id),
    ),
  );
}

/// Counted habit detail: big number, unit dots, streaks, this week.
class CounterDetailScreen extends StatelessWidget {
  const CounterDetailScreen({
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
    final current = store.streakOf(habit);
    final best = store.bestStreakOf(habit);
    final accent = markAccent(habit, colors.accent);

    return Scaffold(
      backgroundColor: colors.bg,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
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
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      Fmt.count(habit.count),
                      style: AppType.bigCount.copyWith(color: colors.text),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${Fmt.count(habit.target)}',
                      style: AppType.bigCountDenom.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _UnitDots(habit: habit, accent: accent),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIconButton(
                      icon: 'minus',
                      size: 64,
                      iconSize: 24,
                      filled: true,
                      label: '${Fmt.count(habit.step)} less',
                      onTap: habit.count <= 0
                          ? null
                          : () => store.decrement(habit),
                    ),
                    const SizedBox(width: 16),
                    AppIconButton(
                      icon: 'plus',
                      size: 64,
                      iconSize: 24,
                      filled: true,
                      label: '${Fmt.count(habit.step)} more',
                      onTap: habit.count >= habit.target
                          ? null
                          : () => store.increment(habit),
                    ),
                  ],
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

/// One dot per unit; very large targets get a proportional rail of 40 dots
/// rather than thousands of 10pt circles that would never fit.
class _UnitDots extends StatelessWidget {
  const _UnitDots({required this.habit, required this.accent});

  final Habit habit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = math.min(constraints.maxWidth, 340.0);
        final large = habit.target > 60;
        if (large) {
          // Thousands of units cannot be dots: show one honest rail instead.
          return Semantics(
            label: '${Fmt.count(habit.count)} of ${Fmt.count(habit.target)} marked',
            child: SizedBox(
              width: inner,
              height: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: colors.surface2),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: inner * (habit.count / habit.target).clamp(0.0, 1.0),
                      child: ColoredBox(color: accent),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final count = habit.target;
        final filled = habit.count;
        var gap = 6.0;
        while (gap > 4 && (inner - (count - 1) * gap) / count < 16) {
          gap -= 1;
        }
        final size = ((inner - (count - 1) * gap) / count)
            .floorToDouble()
            .clamp(10.0, 26.0);
        return Semantics(
          label: '${Fmt.count(habit.count)} of ${Fmt.count(habit.target)} marked',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: 6,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? accent : colors.surface2,
                    border: Border.all(
                      color: i < filled ? accent : colors.line,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
