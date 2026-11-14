import 'package:flutter/material.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';
import '../util/share.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'new_habit_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.store});

  final HabitStore store;

  Future<void> _share(BuildContext context) async {
    final outcome = await shareDialog(context, store);
    if (outcome != ShareOutcome.copied || !context.mounted) return;
    // Only reached where no native share target exists.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Caption copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final week = store.weekDays;
        return SingleChildScrollView(
          padding: screenPadding(context, topLevel: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderBlock(
                eyebrow: Fmt.weekRange(week.first, week.last),
                title: 'Insights',
                trailing: store.habits.isEmpty
                    ? null
                    : HeadAction(
                        label: 'Share',
                        onTap: () => _share(context),
                      ),
              ),
              if (store.habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 64, 8, 24),
                  child: Column(
                    children: [
                      Eyebrow('No data yet'),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          'Nothing to chart yet',
                          textAlign: TextAlign.center,
                          style: AppType.emptyTitle.copyWith(
                            color: colors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          'Once you record a few days, this page will show the '
                          'week back as a percentage, seven bars and the '
                          'streaks still running.',
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
                    ],
                  ),
                )
              else ...[
                const SizedBox(height: 26),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: '${store.weekPercent}',
                                style: AppType.bigStat.copyWith(
                                  color: colors.text,
                                ),
                                children: [
                                  TextSpan(
                                    text: '%',
                                    style: AppType.bigStatSuffix.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TrendPill(trend: store.weekTrend),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'completion this week',
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
                      const SectionTitle(
                        'Daily completion',
                        margin: EdgeInsets.only(bottom: 14),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final label in ['100', '50', '0'])
                                  Text(
                                    label,
                                    style: AppType.axis.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: colors.line),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (var i = 0; i < week.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: _Bar(
                                        percent: store.weekSeries[i],
                                        today: Fmt.sameDay(
                                          week[i],
                                          store.today,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 38, top: 6),
                        child: Row(
                          children: [
                            for (var i = 0; i < week.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  Fmt.weekdayLetter(
                                    week[i],
                                    monday: store.weekStartsMonday,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: AppType.labelSmall.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 0.55,
                                    color: Fmt.sameDay(week[i], store.today)
                                        ? colors.text
                                        : colors.muted,
                                    fontWeight:
                                        Fmt.sameDay(week[i], store.today)
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        'Streaks',
                        margin: EdgeInsets.only(bottom: 6),
                      ),
                      if (store.runningStreaks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'No running streaks right now. A streak starts the '
                            'first day you complete a habit.',
                            style: AppType.micro.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < store.runningStreaks.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: i == store.runningStreaks.length - 1
                                      ? Colors.transparent
                                      : colors.line,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    store.runningStreaks[i].habit.name,
                                    style: AppType.body.copyWith(
                                      color: colors.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  '${store.runningStreaks[i].days} '
                                  '${store.runningStreaks[i].days == 1 ? 'day' : 'days'}',
                                  style: AppType.body.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.percent, required this.today});

  final int percent;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final height = percent == 0
        ? 0.0
        : (percent / 100 * 150).clamp(4.0, 150.0);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: percent == 0
              ? Colors.transparent
              : today
              ? colors.accent
              : colors.faint.withValues(alpha: 0.45),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
        ),
      ),
    );
  }
}
