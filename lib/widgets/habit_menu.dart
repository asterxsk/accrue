import 'package:flutter/material.dart';

import '../app_nav.dart';
import '../models/habit.dart';
import '../screens/new_habit_screen.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import 'dialogs.dart';
import 'ui.dart';

/// Edit and delete, side by side in the top-right of a habit's full page.
class HabitActions extends StatelessWidget {
  const HabitActions({super.key, required this.store, required this.habit});

  final HabitStore store;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: 'pencil',
          size: 44,
          iconSize: 18,
          label: 'Edit ${habit.name}',
          onTap: () =>
              openHabitForm(context, store, habit: habit, fromDetail: true),
        ),
        AppIconButton(
          icon: 'trash',
          size: 44,
          iconSize: 18,
          label: 'Delete ${habit.name}',
          color: colors.danger,
          onTap: () => deleteHabit(context, store, habit),
        ),
      ],
    );
  }
}

/// Confirms, then removes the habit and every day it was recorded, and lands
/// back on Today.
Future<void> deleteHabit(
  BuildContext context,
  HabitStore store,
  Habit habit,
) async {
  final confirmed = await confirmDialog(
    context,
    title: 'Delete the habit "${habit.name}"?',
    body:
        'The habit and every day it was recorded are removed from this '
        'device. Streaks and Insights recalculate. This cannot be undone.',
    confirmLabel: 'Delete habit',
    danger: true,
  );
  if (!confirmed || !context.mounted) return;
  final nav = AppNavScope.of(context);
  store.deleteHabit(habit);
  Navigator.of(context).popUntil((route) => route.isFirst);
  nav.select(0);
}
