import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import 'app_icon.dart';
import 'habit_mark.dart';
import 'ui.dart';

/// A 44pt progress ring with the habit's icon inside it.
class HabitRing extends StatelessWidget {
  const HabitRing({
    super.key,
    required this.progress,
    required this.habit,
    required this.done,
    this.size = 44,
    this.iconSize = 17,
  });

  final double progress;
  final Habit habit;
  final bool done;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              track: colors.line,
              fill: markAccent(habit, colors.accent),
              progress: progress,
            ),
          ),
          if (habit.badge)
            HabitMark(
              habit: habit,
              size: size - 12,
              iconSize: iconSize,
            )
          else
            AppIcon(
              habit.icon,
              size: iconSize,
              color: done ? colors.accentInk : colors.muted,
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.track,
    required this.fill,
    required this.progress,
  });

  final Color track;
  final Color fill;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - 1;
    final center = size.center(Offset.zero);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress <= 0) return;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}

/// One line in Today's habit list.
class HabitRow extends StatelessWidget {
  const HabitRow({
    super.key,
    required this.store,
    required this.habit,
    required this.onOpen,
  });

  final HabitStore store;
  final Habit habit;

  /// Opens the habit's full-screen page: counter, timer or check detail.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final done = store.isDone(habit);
    final sub = store.subline(habit);

    void onMainTap() {
      switch (habit.kind) {
        case HabitKind.check:
          store.toggleCheck(habit);
        case HabitKind.count:
          store.increment(habit);
        case HabitKind.timer:
          onOpen();
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Metrics.habitRow),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                toggled: habit.kind == HabitKind.check ? done : null,
                button: true,
                label: '${habit.name}. ${sub.text}',
                child: InkWell(
                  onTap: onMainTap,
                  borderRadius: BorderRadius.circular(Metrics.rSm),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 4, 10),
                    child: Row(
                      children: [
                        HabitRing(
                          progress: store.ratio(habit),
                          habit: habit,
                          done: done,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                habit.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.habitName.copyWith(
                                  color: colors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Scaled rather than truncated: an 8,000-step
                              // habit still reads "3,000 of 8,000 steps".
                              LayoutBuilder(
                                builder: (context, box) => SizedBox(
                                  width: box.maxWidth,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      sub.text,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: AppType.habitSub.copyWith(
                                        color: sub.warn
                                            ? colors.warnInk
                                            : colors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AppIconButton(
              icon: 'ellipsis-vertical',
              size: 44,
              iconSize: 18,
              label: 'Open ${habit.name}',
              color: colors.muted,
              onTap: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
