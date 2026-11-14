import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';
import '../util/share.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialogs.dart';
import '../widgets/heat_map.dart';
import '../widgets/popup_menu.dart';
import '../widgets/ui.dart';
import 'new_habit_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const List<String> _ranges = ['Week', 'Month'];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Null means every habit.
  String? _habitId;
  String _range = 'Week';

  HabitStore get store => widget.store;

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
        final monthStart = store.monthStart;
        final selectedHabit = _habitId == null
            ? null
            : store.habitById(_habitId!);
        if (_habitId != null && selectedHabit == null) _habitId = null;
        return SingleChildScrollView(
          padding: screenPadding(context, topLevel: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderBlock(
                eyebrow: _range == 'Week'
                    ? Fmt.weekRange(week.first, week.last)
                    : Fmt.weekRange(monthStart, store.monthEnd),
                title: 'Insights',
                trailing: store.habits.isEmpty
                    ? null
                    : HeadAction(
                        label: 'Share',
                        onTap: () => _share(context),
                      ),
              ),
              if (store.habits.isEmpty)
                _emptyState(context, colors)
              else ...[
                const SizedBox(height: 18),
                _controls(context, selectedHabit),
                const SizedBox(height: 16),
                if (_range == 'Week')
                  ..._weekContent(context, colors, selectedHabit)
                else
                  ..._monthContent(context, colors, selectedHabit),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, AppColors colors) {
    return Padding(
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
              style: AppType.emptyTitle.copyWith(color: colors.text),
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
    );
  }

  Widget _controls(BuildContext context, Habit? selectedHabit) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Builder(
            builder: (anchorContext) => _FilterPill(
              label: selectedHabit?.name ?? 'All habits',
              onTap: () => _openFilter(context, anchorContext),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: SegmentedToggle(
            options: _ranges,
            selected: _range,
            onChanged: (value) => setState(() => _range = value),
          ),
        ),
      ],
    );
  }

  void _openFilter(BuildContext context, BuildContext anchorContext) {
    showActionMenu(context, anchorContext, [
      AppMenuItem(
        label: 'All habits',
        icon: 'layers',
        selected: _habitId == null,
        onSelected: () => setState(() => _habitId = null),
      ),
      for (final habit in store.habits)
        AppMenuItem(
          label: habit.name,
          icon: habit.icon,
          selected: _habitId == habit.id,
          onSelected: () => setState(() => _habitId = habit.id),
        ),
    ]);
  }

  List<Widget> _weekContent(
    BuildContext context,
    AppColors colors,
    Habit? habit,
  ) {
    final habitId = habit?.id;
    final percent = store.weekPercentFor(habitId: habitId);
    final trend = habitId == null
        ? store.weekTrend
        : store.percentBetween(
                store.weekStart,
                store.today,
                habitId: habitId,
              ) -
              store.percentBetween(
                Fmt.addDays(store.weekStart, -7),
                Fmt.addDays(store.today, -7),
                habitId: habitId,
              );
    final series = store.weekSeriesFor(habitId: habitId);
    final week = store.weekDays;
    final hasCompletions = habitId == null || _hasCompletions(habitId);
    return [
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _heroPercent(colors, percent)),
                const SizedBox(width: 12),
                TrendPill(trend: trend),
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
            if (!hasCompletions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No completions yet for this habit.',
                  style: AppType.micro.copyWith(color: colors.muted),
                ),
              )
            else ...[
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
                            style: AppType.axis.copyWith(color: colors.muted),
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
                                percent: series[i],
                                today: Fmt.sameDay(week[i], store.today),
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
                            fontWeight: Fmt.sameDay(week[i], store.today)
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 3),
                child: Row(
                  children: [
                    for (var i = 0; i < week.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          week[i].isAfter(store.today)
                              ? '–'
                              : '${series[i]}',
                          textAlign: TextAlign.center,
                          style: AppType.axis.copyWith(
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
            if (habit != null)
              _streakRow(
                colors,
                habit.name,
                store.streakOf(habit),
                last: true,
              )
            else if (store.runningStreaks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No running streaks right now. A streak starts the '
                  'first day you complete a habit.',
                  style: AppType.micro.copyWith(color: colors.muted),
                ),
              )
            else
              for (var i = 0; i < store.runningStreaks.length; i++)
                _streakRow(
                  colors,
                  store.runningStreaks[i].habit.name,
                  store.runningStreaks[i].days,
                  last: i == store.runningStreaks.length - 1,
                ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _monthContent(
    BuildContext context,
    AppColors colors,
    Habit? habit,
  ) {
    final habitId = habit?.id;
    final percent = store.monthPercentFor(habitId: habitId);
    final hasCompletions = habitId == null || _hasCompletions(habitId);
    final monthStart = store.monthStart;
    final monthLabel = '${_monthNames[monthStart.month - 1]} ${monthStart.year}';
    return [
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroPercent(colors, percent),
            const SizedBox(height: 8),
            Text(
              'completion this month',
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
            SectionTitle(
              monthLabel,
              margin: const EdgeInsets.only(bottom: 14),
            ),
            if (!hasCompletions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'No completions yet for this habit.',
                  style: AppType.micro.copyWith(color: colors.muted),
                ),
              )
            else ...[
              HeatMap(
                weeks: store.monthGrid,
                today: store.today,
                fractionFor: (day) =>
                    store.completedFractionOn(day, habitId: habitId),
                mondayStart: store.weekStartsMonday,
              ),
              const SizedBox(height: 14),
              const HeatMapLegend(),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _heroPercent(AppColors colors, int percent) {
    return Text.rich(
      TextSpan(
        text: '$percent',
        style: AppType.bigStat.copyWith(color: colors.text),
        children: [
          TextSpan(
            text: '%',
            style: AppType.bigStatSuffix.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }

  Widget _streakRow(
    AppColors colors,
    String name,
    int days, {
    required bool last,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : colors.line,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppType.body.copyWith(color: colors.text),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$days ${days == 1 ? 'day' : 'days'}',
            style: AppType.body.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }

  bool _hasCompletions(String habitId) {
    final habit = store.habitById(habitId);
    if (habit == null) return false;
    if (store.isDone(habit)) return true;
    return store.hasRecorded(habit);
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Filter: $label',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  AppIcon('filter', size: 16, color: colors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.button.copyWith(color: colors.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
              : heatMapCellColor(colors, percent / 100),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
        ),
      ),
    );
  }
}
