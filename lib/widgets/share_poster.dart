import 'package:flutter/material.dart';

import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';
import 'brand_mark.dart';
import 'ui.dart';

/// The shareable summary card: 4:5, paper ground, seven bars, and a projection
/// of the pace the last two weeks set.
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
    final bio = store.profileBio.trim();
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
    final trend = store.weekTrend;
    // Two weeks of daily completion, then the same line carried forward a week
    // at the slope those days set. Regression slope is halved and the whole
    // move capped: one strong day must not claim a 100% week. A flat fortnight
    // projects flat; a rising one projects up.
    final history = List.generate(
      14,
      (i) => store.completedFractionOn(Fmt.addDays(store.today, i - 13)),
    );
    final slope = _slope(history) * 0.5;
    final projected = [
      for (var day = 1; day <= 7; day++)
        (history.last + slope * day).clamp(
          0.0,
          (history.last + 0.2).clamp(0.0, 1.0),
        ),
    ];
    final projectedPct = (projected.last * 100).round();

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
                  BrandMark(size: 11, color: colors.accent),
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
                Avatar(
                  name: name,
                  size: 24,
                  serif: true,
                  photo: store.profilePhoto,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.headTitle.copyWith(
                          fontSize: 14,
                          color: colors.text,
                        ),
                      ),
                      if (bio.isNotEmpty)
                        Text(
                          bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.micro.copyWith(
                            fontSize: 7,
                            height: 1.3,
                            color: colors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'PROJECTION',
                  style: AppType.eyebrow.copyWith(
                    fontSize: 6,
                    letterSpacing: 0.48,
                    color: colors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  'On pace for $projectedPct% in 7 days',
                  style: AppType.micro.copyWith(
                    fontSize: 7,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: colors.accentInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _PosterProjection(
                  history: history,
                  projected: projected,
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two weeks of daily completion with the next week carried on at the same
/// slope: a solid line for what happened, a dashed one for what the pace
/// implies. The only chart element that reads as a forecast rather than a
/// record, which is what makes it worth sharing.
class _PosterProjection extends StatelessWidget {
  const _PosterProjection({
    required this.history,
    required this.projected,
    required this.colors,
  });

  final List<double> history;
  final List<double> projected;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProjectionPainter(
        history: history,
        projected: projected,
        colors: colors,
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  _ProjectionPainter({
    required this.history,
    required this.projected,
    required this.colors,
  });

  final List<double> history;
  final List<double> projected;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 3.0;
    final slots = history.length + projected.length;
    if (slots < 2 || size.width <= 0) return;
    final step = (size.width - 1) / (slots - 1);
    final base = size.height - pad;
    final span = base - pad;

    Offset point(int slot, double value) =>
        Offset(slot * step, base - value.clamp(0.0, 1.0) * span);

    // Baseline
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = colors.line
        ..strokeWidth = 0.6,
    );

    // Filled area under the recorded days.
    final area = Path()..moveTo(0, base);
    for (var i = 0; i < history.length; i++) {
      final p = point(i, history[i]);
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(point(history.length - 1, history.last).dx, base)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = colors.accent.withValues(alpha: 0.14),
    );

    // Recorded days.
    final line = Path();
    for (var i = 0; i < history.length; i++) {
      final p = point(i, history[i]);
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // The day the record ends, so the dashed half is unambiguous.
    final node = point(history.length - 1, history.last);
    canvas.drawCircle(node, 1.8, Paint()..color = colors.accent);
    canvas.drawCircle(
      node,
      4.2,
      Paint()..color = colors.accent.withValues(alpha: 0.18),
    );

    // Projected days, dashed.
    final dashed = Path()
      ..moveTo(node.dx, node.dy);
    for (var k = 0; k < projected.length; k++) {
      final p = point(history.length + k, projected[k]);
      dashed.lineTo(p.dx, p.dy);
    }
    final dashPaint = Paint()
      ..color = colors.accentInk.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    for (final metric in dashed.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 3).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), dashPaint);
        distance += 5;
      }
    }
    final end = point(slots - 1, projected.last);
    canvas.drawCircle(
      end,
      1.6,
      Paint()..color = colors.accentInk.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) =>
      old.history != history ||
      old.projected != projected ||
      old.colors != colors;
}

/// Least-squares slope per day of [values], 0 when the line is flat or the
/// sample is too short to say anything.
double _slope(List<double> values) {
  final n = values.length;
  if (n < 2) return 0;
  final meanX = (n - 1) / 2;
  final meanY = values.reduce((a, b) => a + b) / n;
  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < n; i++) {
    numerator += (i - meanX) * (values[i] - meanY);
    denominator += (i - meanX) * (i - meanX);
  }
  return denominator == 0 ? 0 : numerator / denominator;
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
