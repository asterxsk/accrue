import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import 'app_icon.dart';
import 'habit_mark.dart';
import 'ui.dart';

String _routineMeta(HabitStore store, Routine routine) {
  final habits = store.routineHabits(routine);
  final minutes = store.routineMinutes(routine);
  if (habits.isEmpty) return 'No habits yet';
  final count = habits.length == 1 ? '1 habit' : '${habits.length} habits';
  return minutes > 0 ? '$count · $minutes min' : count;
}

String _routineState(HabitStore store, Routine routine) {
  final total = store.routineHabits(routine).length;
  final done = store.routineDoneCount(routine);
  if (total == 0) return 'Add habits to this routine';
  if (done == total) return 'Done today';
  if (done == 0) return 'Not started';
  return '$done of $total done';
}

class _RoutineDisc extends StatelessWidget {
  const _RoutineDisc({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        total == 0 ? '0' : '$done/$total',
        style: AppType.count.copyWith(
          fontSize: 15,
          color: colors.accentInk,
        ),
      ),
    );
  }
}

/// Compact routine card on Today.
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.store,
    required this.routine,
    required this.onOpen,
    required this.onMenu,
  });

  final HabitStore store;
  final Routine routine;
  final VoidCallback onOpen;

  /// Called with the more button's context for menu anchoring.
  final void Function(BuildContext) onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Metrics.rLg),
        border: Border.all(color: colors.hairline),
        boxShadow: [colors.shadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(Metrics.rMd),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                child: Row(
                  children: [
                    _RoutineDisc(
                      done: store.routineDoneCount(routine),
                      total: store.routineHabits(routine).length,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            routine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodyStrong.copyWith(
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _routineMeta(store, routine),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(color: colors.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _routineState(store, routine),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.meta.copyWith(color: colors.muted),
                          ),
                        ],
                      ),
                    ),
                    AppIcon('chevron', size: 18, color: colors.faint),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          Builder(
            builder: (menuContext) => AppIconButton(
              icon: 'more',
              size: 44,
              iconSize: 18,
              label: 'Options for ${routine.name}',
              color: colors.faint,
              onTap: () => onMenu(menuContext),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full routine card with its step list on the Routines tab.
class RoutineLargeCard extends StatelessWidget {
  const RoutineLargeCard({
    super.key,
    required this.store,
    required this.routine,
    required this.onOpen,
    required this.onMenu,
  });

  final HabitStore store;
  final Routine routine;
  final VoidCallback onOpen;

  /// Called with the more button's context for menu anchoring.
  final void Function(BuildContext) onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final habits = store.routineHabits(routine);
    final currentId = store.currentRoutineHabitId(routine);
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(Metrics.rSm),
                  child: Row(
                    children: [
                      _RoutineDisc(
                        done: store.routineDoneCount(routine),
                        total: habits.length,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              routine.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.bodyStrong.copyWith(
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _routineMeta(store, routine),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.meta.copyWith(
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _routineState(store, routine),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.meta.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIcon('chevron', size: 18, color: colors.faint),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (menuContext) => AppIconButton(
                  icon: 'more',
                  size: 44,
                  iconSize: 18,
                  label: 'Options for ${routine.name}',
                  color: colors.faint,
                  onTap: () => onMenu(menuContext),
                ),
              ),
            ],
          ),
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final habit in habits)
              _StepRow(
                store: store,
                habit: habit,
                done: store.isDone(habit),
                current: habit.id == currentId,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
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
    final accent = markAccent(habit, colors.accent);
    final upcoming = !done && !current;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? accent : Colors.transparent,
              border: Border.all(
                color: done || current ? accent : colors.line,
                width: 1.5,
              ),
            ),
            child: done
                ? AppIcon('check', size: 10, color: colors.accentOn)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.meta.copyWith(
                fontSize: 14,
                color: done || upcoming ? colors.muted : colors.text,
                fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            store.shortValue(habit),
            style: AppType.meta.copyWith(
              fontSize: 13,
              color: colors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
