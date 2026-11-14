import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../state/habit_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_type.dart';
import '../theme/metrics.dart';
import '../util/focus.dart';
import '../util/format.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialogs.dart';
import '../widgets/habit_mark.dart';
import '../widgets/habit_menu.dart';
import '../widgets/ui.dart';

Future<void> openTimer(
  BuildContext context,
  HabitStore store,
  Habit habit,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TimerScreen(store: store, habitId: habit.id),
    ),
  );
}

/// Running a timed habit. Starting it also arms focus blocking: Android draws
/// a blocked screen over the chosen apps until the timer stops.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.store, required this.habitId});

  final HabitStore store;
  final String habitId;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _blocking = false;

  HabitStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    store.addListener(_syncBlocking);
    // A relaunch can land on a timer that is still running; re-arm blocking
    // for the rest of its span instead of leaving the apps open.
    final habit = store.habitById(widget.habitId);
    if (habit != null &&
        habit.blockDistractions &&
        store.isRunning(habit) &&
        store.blockedApps.isNotEmpty) {
      _armBlocking(habit);
    }
  }

  Future<void> _armBlocking(Habit habit) async {
    if (!habit.blockDistractions || store.blockedApps.isEmpty) return;
    final remaining = habit.target * 60 - store.liveSeconds(habit);
    // Past the goal the timer keeps running, so blocking gets the same five
    // minute floor instead of never arming.
    _blocking = true;
    final seconds = remaining > 0 ? remaining : 300;
    await FocusBlocking.start(
      habitName: habit.name,
      endsAt: DateTime.now().add(Duration(seconds: seconds)),
      packages: store.blockedApps,
    );
  }

  @override
  void dispose() {
    store.removeListener(_syncBlocking);
    super.dispose();
  }

  /// The store stops the timer from anywhere (day rollover, reset, a deleted
  /// habit), so blocking follows it rather than the buttons.
  void _syncBlocking() {
    final habit = store.habitById(widget.habitId);
    if (habit == null) {
      if (_blocking) _stopBlocking();
      return;
    }
    final wanted =
        store.isRunning(habit) &&
        habit.blockDistractions &&
        store.blockedApps.isNotEmpty;
    if (!wanted && _blocking) {
      _stopBlocking();
    } else if (wanted && !_blocking) {
      _armBlocking(habit);
    }
  }

  Future<void> _stopBlocking() async {
    if (!_blocking) return;
    _blocking = false;
    await FocusBlocking.stop();
  }

  Future<void> _toggleTimer(Habit habit) async {
    final wasRunning = store.isRunning(habit);
    store.toggleTimer(habit);
    if (wasRunning) {
      await _stopBlocking();
      return;
    }
    if (!habit.blockDistractions || store.blockedApps.isEmpty) return;
    await _armBlocking(habit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final habit = store.habitById(widget.habitId);
    if (habit == null) {
      return Scaffold(backgroundColor: colors.bg);
    }
    final gutter = Metrics.gutter;
    final accent = markAccent(habit, colors.accent);
    final width = MediaQuery.sizeOf(context).width;
    final ringSize = math.min(244.0, (math.min(width, 430) - 40) * 0.68);

    return Scaffold(
      backgroundColor: colors.bg,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final seconds = store.liveSeconds(habit);
          final running = store.isRunning(habit);
          final goalSeconds = habit.target * 60;
          final progress = goalSeconds == 0
              ? 0.0
              : (seconds / goalSeconds).clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              gutter,
              Metrics.topInset(context),
              gutter,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            child: Column(
              children: [
                HeadBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: HabitActions(store: store, habit: habit),
                ),
                const SizedBox(height: 18),
                Text(
                  habit.name,
                  textAlign: TextAlign.center,
                  style: AppType.timerName.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(ringSize),
                        painter: _TimerRingPainter(
                          track: colors.line,
                          fill: accent,
                          progress: progress,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Fmt.clock(seconds),
                            style: AppType.timerClock.copyWith(
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'of ${Fmt.minutes(habit.target)}',
                            style: AppType.meta.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _toggleTimer(habit),
                  child: Semantics(
                    button: true,
                    label: running ? 'Pause' : 'Start',
                    child: Container(
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.only(top: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AppIcon(
                        running ? 'pause' : 'play',
                        size: 26,
                        color: colors.accentOn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Today's goal",
                          style: AppType.meta.copyWith(
                            fontSize: 14,
                            color: colors.muted,
                          ),
                        ),
                      ),
                      Text(
                        '${Fmt.duration(seconds)} logged',
                        style: AppType.count.copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
                GhostButton(
                  label: 'Add time',
                  onTap: () async {
                    final seconds = await durationDialog(
                      context,
                      title: 'Add time',
                      description: 'Log time you spent away from the app.',
                    );
                    if (seconds != null) store.addSeconds(habit, seconds);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.track,
    required this.fill,
    required this.progress,
  });

  final Color track;
  final Color fill;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - 3;
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}
