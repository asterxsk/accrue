import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/format.dart';
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
    required this.onOpenCounter,
    required this.onOpenTimer,
    required this.onMenu,
  });

  final HabitStore store;
  final Habit habit;
  final VoidCallback onOpenCounter;
  final VoidCallback onOpenTimer;

  /// Called with the more button's context for menu anchoring.
  final void Function(BuildContext) onMenu;

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
          onOpenCounter();
        case HabitKind.timer:
          onOpenTimer();
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
            if (habit.kind == HabitKind.count) ...[
              AppIconButton(
                icon: 'minus',
                size: 44,
                iconSize: 16,
                filled: true,
                label: habit.step > 1
                    ? '${habit.step} less ${habit.name}'
                    : 'One less ${habit.name}',
                onTap: habit.count <= 0 ? null : () => store.decrement(habit),
              ),
              SizedBox(
                width: 56,
                // Scaled, not clipped: "1,000" must not run over the buttons.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Fmt.count(habit.count),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: AppType.count.copyWith(color: colors.text),
                  ),
                ),
              ),
              AppIconButton(
                icon: 'plus',
                size: 44,
                iconSize: 16,
                filled: true,
                label: habit.step > 1
                    ? '${habit.step} more ${habit.name}'
                    : 'One more ${habit.name}',
                onTap: habit.count >= habit.target
                    ? null
                    : () => store.increment(habit),
              ),
            ],
            Builder(
              builder: (menuContext) => AppIconButton(
                icon: 'more',
                size: 44,
                iconSize: 18,
                label: 'Options for ${habit.name}',
                color: colors.faint,
                onTap: () => onMenu(menuContext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
