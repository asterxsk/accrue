import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../util/format.dart';

/// Fill for a day at [fraction] completion: empty tile at 0, full accent at 1.
Color heatMapCellColor(AppColors colors, double fraction) {
  final value = fraction.clamp(0.0, 1.0).toDouble();
  if (value <= 0) return colors.surface2;
  return Color.alphaBlend(
    colors.accent.withValues(alpha: 0.10 + 0.90 * value),
    colors.surface2,
  );
}

/// Month view grid: one column per weekday, one row per week.
///
/// Null cells pad the first and last week. Future days stay unfilled with a
/// hairline so the month's shape is still legible, and today is outlined.
class HeatMap extends StatelessWidget {
  const HeatMap({
    super.key,
    required this.weeks,
    required this.today,
    required this.fractionFor,
    required this.mondayStart,
  });

  final List<List<DateTime?>> weeks;
  final DateTime today;
  final double Function(DateTime) fractionFor;
  final bool mondayStart;

  static const double _maxCell = 38;
  static const double _gap = 4;
  static const double _radius = 6;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final letters = mondayStart
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - _gap * 6) / 7).clamp(
          12.0,
          _maxCell,
        ).toDouble();
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: cell,
                      child: Text(
                        letters[i],
                        textAlign: TextAlign.center,
                        style: AppType.axis.copyWith(color: colors.muted),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              for (var row = 0; row < weeks.length; row++) ...[
                if (row > 0) const SizedBox(height: _gap),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var column = 0; column < 7; column++) ...[
                      if (column > 0) const SizedBox(width: _gap),
                      _cell(
                        context,
                        colors,
                        column < weeks[row].length
                            ? weeks[row][column]
                            : null,
                        cell,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    AppColors colors,
    DateTime? day,
    double size,
  ) {
    if (day == null) return SizedBox(width: size, height: size);
    final future = day.isAfter(today);
    final isToday = Fmt.sameDay(day, today);
    final fraction = fractionFor(day).clamp(0.0, 1.0).toDouble();
    final percent = (fraction * 100).round();
    return Semantics(
      label: '${Fmt.shortDate(day)}: $percent percent complete',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: future
              ? Colors.transparent
              : heatMapCellColor(colors, fraction),
          borderRadius: BorderRadius.circular(_radius),
          border: future
              ? Border.all(color: colors.line.withValues(alpha: 0.6))
              : isToday
              ? Border.all(color: colors.accent)
              : null,
        ),
      ),
    );
  }
}

/// "Less [5 swatches] More" key under the heat map.
class HeatMapLegend extends StatelessWidget {
  const HeatMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = AppType.axis.copyWith(color: colors.muted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Less', style: label),
        const SizedBox(width: 8),
        for (final fraction in const [0.0, 0.25, 0.5, 0.75, 1.0]) ...[
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: heatMapCellColor(colors, fraction),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 4),
        Text('More', style: label),
      ],
    );
  }
}
