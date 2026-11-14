import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/habit_row.dart';
import '../widgets/ui.dart';
import 'check_detail_screen.dart';
import 'counter_detail_screen.dart';
import 'new_habit_screen.dart';
import 'timer_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: screenPadding(context, topLevel: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderBlock(
                eyebrow: Fmt.eyebrowDate(store.today),
                title: 'Today',
              ),
              if (store.habits.isEmpty)
                _EmptyToday(store: store, colors: colors)
              else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _StatBlock(store: store, colors: colors),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: SectionTitle('Habits'),
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: colors.line),
                for (final habit in store.habits)
                  HabitRow(
                    store: store,
                    habit: habit,
                    onOpen: () {
                      switch (habit.kind) {
                        case HabitKind.check:
                          openCheckDetail(context, store, habit);
                        case HabitKind.count:
                          openCounter(context, store, habit);
                        case HabitKind.timer:
                          openTimer(context, store, habit);
                      }
                    },
                  ),
                DashedNewRow(
                  label: 'New habit',
                  onTap: () => openHabitForm(context, store),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.store, required this.colors});

  final HabitStore store;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: '${store.doneCount} ',
                    style: AppType.statLine.copyWith(color: colors.text),
                    children: [
                      TextSpan(
                        text: 'of ${store.habits.length} done',
                        style: AppType.statLine.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${store.completionPercent}%',
              style: AppType.statPct.copyWith(color: colors.accentInk),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProgressTrack(value: store.completionPercent / 100),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.store, required this.colors});

  final HabitStore store;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 64, 8, 24),
      child: Column(
        children: [
          Eyebrow('A clean start'),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              'Add your first habit',
              textAlign: TextAlign.center,
              style: AppType.emptyTitle.copyWith(color: colors.text),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              "Pick one thing worth repeating. Check it off, count it, or time "
              "it — the day's number starts with a single habit.",
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: colors.muted),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            child: AppButton(
              label: 'Create a habit',
              expand: true,
              onPressed: () => openHabitForm(context, store),
            ),
          ),
          const SizedBox(height: 10),
          LinkButton(
            label: 'Browse habit ideas',
            onTap: () => ideasDialog(context, store),
          ),
        ],
      ),
    );
  }
}
