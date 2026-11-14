import 'package:flutter/material.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';
import 'ui.dart';

/// The shareable summary card: 4:5, paper ground, seven bars, top streaks.
///
/// The prototype exported a 1080x1350 PNG. Without a file/share plugin this
/// build shows the same poster and copies its caption to the clipboard.
class SharePoster extends StatelessWidget {
  const SharePoster({super.key, required this.store});

  final HabitStore store;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = store.profileName.isEmpty ? 'You' : store.profileName;
    final week = store.weekDays;
    final bars = List.generate(7, (i) {
      final day = week[i];
      final future = day.isAfter(store.today);
      final done = future ? 0 : store.completedCountOn(day);
      final pct = store.habits.isEmpty
          ? 0
          : (done / store.habits.length * 100).round();
      return (
        letter: Fmt.weekdayLetter(day, monday: store.weekStartsMonday),
        pct: pct,
        today: Fmt.sameDay(day, store.today),
      );
    });
    final streaks = store.runningStreaks.take(3).toList();
    final trend = store.weekTrend;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand strip
            Container(
              padding: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ACCRUE',
                    style: AppType.eyebrow.copyWith(
                      fontSize: 7,
                      letterSpacing: 0.56,
                      color: colors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Fmt.weekRange(week.first, week.last),
                    style: AppType.micro.copyWith(
                      fontSize: 7,
                      height: 1.2,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Avatar(name: name, size: 24, serif: true),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.headTitle.copyWith(
                      fontSize: 14,
                      color: colors.text,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'This week',
                  style: AppType.micro.copyWith(
                    fontSize: 7,
                    height: 1.2,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${store.weekPercent}',
                  style: AppType.bigStat.copyWith(
                    fontFamily: AppType.serifFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 42,
                    height: 0.86,
                    letterSpacing: -0.84,
                    color: colors.text,
                  ),
                ),
                Text(
                  '%',
                  style: AppType.meta.copyWith(
                    fontSize: 20,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PosterTrend(trend: trend),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'of habits completed this week',
              style: AppType.micro.copyWith(
                fontSize: 8,
                height: 1.2,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _PosterTile(
                    label: 'Today',
                    value: '${store.doneCount}/${store.habits.length}',
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _PosterTile(
                    label: 'Best streak',
                    value: '${store.bestStreak}',
                    suffix: 'd',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _PosterTile(
                    label: 'Habits',
                    value: '${store.habits.length}',
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _PosterTile(
                    label: 'Routines',
                    value: '${store.routines.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < bars.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: _PosterBar(bar: bars[i], colors: colors)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (streaks.isEmpty)
              Text(
                'No streaks yet — a fresh start.',
                style: AppType.micro.copyWith(
                  fontSize: 8,
                  height: 1.2,
                  color: colors.muted,
                ),
              )
            else
              for (final row in streaks)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colors.line,
                        width: row == streaks.last ? 0 : 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.micro.copyWith(
                            fontSize: 8,
                            height: 1.2,
                            color: colors.text,
                          ),
                        ),
                      ),
                      Text(
                        '${row.days}d',
                        style: AppType.micro.copyWith(
                          fontSize: 8,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: colors.accentInk,
                        ),
                      ),
                    ],
                  ),
                ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: Text(
                'Made on this device · nothing leaves it',
                style: AppType.micro.copyWith(
                  fontSize: 6,
                  height: 1.2,
                  color: colors.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  const _PosterTile({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppType.eyebrow.copyWith(
              fontSize: 6,
              letterSpacing: 0.48,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppType.headTitle.copyWith(
                  fontSize: 14,
                  color: colors.text,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: AppType.micro.copyWith(
                    fontSize: 9,
                    color: colors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PosterBar extends StatelessWidget {
  const _PosterBar({required this.bar, required this.colors});

  final ({String letter, int pct, bool today}) bar;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    // The bar column sits in a stretched Row, so it must fit whatever height
    // is left after the stat grid — fixed 26pt bars used to overflow it.
    return LayoutBuilder(
      builder: (context, box) {
        const labelSlot = 10.0;
        const gap = 3.0;
        final maxBar = (box.maxHeight - labelSlot - gap).clamp(2.0, 26.0);
        final height = bar.pct == 0
            ? 2.0
            : (bar.pct / 100 * maxBar).clamp(2.0, maxBar);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: bar.today ? colors.accent : colors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: labelSlot,
              child: Text(
                bar.letter,
                maxLines: 1,
                softWrap: false,
                style: AppType.labelSmall.copyWith(
                  fontSize: 7,
                  height: 1,
                  color: bar.today ? colors.text : colors.muted,
                  fontWeight: bar.today ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PosterTrend extends StatelessWidget {
  const _PosterTrend({required this.trend});

  final int trend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = trend == 0
        ? colors.surface2
        : trend > 0
        ? colors.accentSoft
        : colors.danger.withValues(alpha: 0.12);
    final foreground = trend == 0
        ? colors.muted
        : trend > 0
        ? colors.accentInk
        : colors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${trend > 0 ? '+' : ''}$trend%',
        style: AppType.metaStrong.copyWith(fontSize: 8, color: foreground),
      ),
    );
  }
}

String shareCaption(HabitStore store) {
  final name = store.profileName.isEmpty ? 'You' : store.profileName;
  final best = store.bestStreak;
  return '$name on Accrue — ${store.doneCount} of '
      '${store.habits.length} habits today, ${store.weekPercent}% this week, '
      'best streak $best ${best == 1 ? 'day' : 'days'}.';
}
