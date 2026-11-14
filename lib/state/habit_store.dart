import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../util/format.dart';

/// Single source of truth for habits, routines, history and preferences.
///
/// Day-scoped values (count, seconds, checked) live on the habit itself and are
/// archived into [history] when a new day starts, so Insights and streaks only
/// ever read facts the user actually produced.
class HabitStore extends ChangeNotifier {
  HabitStore._(this._prefs);

  /// v2: the app rebuilt to the Claude-design prototype. v1 data belongs to the
  /// previous design and is left untouched in its own key.
  static const String _storageKey = 'habit_tracker.state.v2';
  static const String _backupKey = 'habit_tracker.state.unreadable';

  final SharedPreferences _prefs;

  List<Habit> habits = [];
  List<Routine> routines = [];

  /// date key -> habit ids completed that day (past days only).
  Map<String, Set<String>> history = {};

  ThemeMode themeMode = ThemeMode.system;
  bool remindersOn = true;
  int reminderHour = 8;
  int reminderMinute = 0;
  bool weekStartsMonday = true;

  /// App packages drawn over while a focus timer runs.
  Set<String> blockedApps = {};

  String profileName = '';
  bool onboarded = false;

  /// Habit whose timer is currently running, if any.
  String? runningHabitId;

  /// Wall-clock base for the running timer: the count when it started, and
  /// when that was. Ticks only repaint; they never drive the total.
  DateTime? _timerStartedAt;
  int _timerBaseSeconds = 0;

  String _dayKey = '';

  static Future<HabitStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = HabitStore._(prefs);
    store._restore();
    return store;
  }

  DateTime get today => Fmt.startOfDay(DateTime.now());

  String get todayKey => Fmt.dateKey(today);

  // ---------------------------------------------------------------- reading

  bool isDone(Habit? habit) {
    if (habit == null) return false;
    return switch (habit.kind) {
      HabitKind.check => habit.checked,
      HabitKind.count => habit.target > 0 && habit.count >= habit.target,
      HabitKind.timer => habit.target > 0 && habit.seconds >= habit.target * 60,
    };
  }

  double ratio(Habit? habit) {
    if (habit == null) return 0;
    return switch (habit.kind) {
      HabitKind.check => habit.checked ? 1 : 0,
      HabitKind.count => habit.target <= 0
          ? 0
          : (habit.count / habit.target).clamp(0.0, 1.0),
      HabitKind.timer => habit.target <= 0
          ? 0
          : (habit.seconds / (habit.target * 60)).clamp(0.0, 1.0),
    };
  }

  int get doneCount => habits.where(isDone).length;

  int get completionPercent =>
      habits.isEmpty ? 0 : (doneCount / habits.length * 100).round();

  Habit? habitById(String id) {
    for (final habit in habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Routine? routineById(String id) {
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  List<Habit> routineHabits(Routine routine) =>
      routine.habitIds.map(habitById).whereType<Habit>().toList();

  int routineDoneCount(Routine routine) =>
      routineHabits(routine).where(isDone).length;

  int routineMinutes(Routine routine) => routineHabits(routine)
      .where((habit) => habit.kind == HabitKind.timer)
      .fold(0, (sum, habit) => sum + habit.target);

  String? currentRoutineHabitId(Routine routine) {
    for (final habit in routineHabits(routine)) {
      if (!isDone(habit)) return habit.id;
    }
    return null;
  }

  bool doneOn(DateTime day, String habitId) {
    if (Fmt.sameDay(day, today)) return isDone(habitById(habitId));
    return history[Fmt.dateKey(day)]?.contains(habitId) ?? false;
  }

  /// Streak length in days. A finished today counts; otherwise the run may
  /// still be alive from yesterday.
  int streakOf(Habit habit) {
    var cursor = isDone(habit) ? today : Fmt.addDays(today, -1);
    var streak = 0;
    while (streak < 4000) {
      if (!doneOn(cursor, habit.id)) break;
      streak += 1;
      cursor = Fmt.addDays(cursor, -1);
    }
    return streak;
  }

  /// Longest run the habit has ever had, not just the current one.
  int bestStreakOf(Habit habit) {
    final keys =
        history.keys.map(Fmt.parseDateKey).whereType<DateTime>().toList()
          ..sort();
    if (keys.isEmpty) return isDone(habit) ? 1 : 0;

    var best = 0;
    var run = 0;
    var cursor = Fmt.startOfDay(keys.first);
    var guard = 0;
    while (!cursor.isAfter(today) && guard < 5000) {
      run = doneOn(cursor, habit.id) ? run + 1 : 0;
      if (run > best) best = run;
      cursor = Fmt.addDays(cursor, 1);
      guard += 1;
    }
    return best;
  }

  bool get hasHistory => history.values.any((ids) => ids.isNotEmpty);

  bool hasRecorded(Habit habit) =>
      history.values.any((ids) => ids.contains(habit.id));

  /// True when the habit has run before and missed both yesterday and the day
  /// before.
  bool isBroken(Habit habit) {
    if (doneOn(today, habit.id)) return false;
    if (!hasRecorded(habit)) return false;
    return !doneOn(Fmt.addDays(today, -1), habit.id) &&
        !doneOn(Fmt.addDays(today, -2), habit.id);
  }

  // -------------------------------------------------------------- the week

  DateTime get weekStart {
    final offset = weekStartsMonday
        ? (today.weekday - 1) % 7
        : today.weekday % 7;
    return Fmt.addDays(today, -offset);
  }

  List<DateTime> get weekDays =>
      List.generate(7, (i) => Fmt.addDays(weekStart, i));

  int get elapsedWeekDays =>
      min(7, (Fmt.diffDays(weekStart, today) + 1).clamp(0, 7));

  int completedCountOn(DateTime day) =>
      habits.where((habit) => doneOn(day, habit.id)).length;

  int get weekPercent {
    if (habits.isEmpty) return 0;
    final done = weekDays
        .take(elapsedWeekDays)
        .fold<int>(0, (sum, day) => sum + completedCountOn(day));
    return (done / (habits.length * elapsedWeekDays) * 100).round();
  }

  int get previousWeekPercent {
    if (habits.isEmpty) return 0;
    final start = Fmt.addDays(weekStart, -7);
    final done = List.generate(elapsedWeekDays, (i) {
      return completedCountOn(Fmt.addDays(start, i));
    }).fold<int>(0, (sum, n) => sum + n);
    return (done / (habits.length * elapsedWeekDays) * 100).round();
  }

  int get weekTrend => weekPercent - previousWeekPercent;

  /// Percentage per day of the current week, 0 for future days.
  List<int> get weekSeries => weekDays.map((day) {
    if (day.isAfter(today) || habits.isEmpty) return 0;
    return (completedCountOn(day) / habits.length * 100).round();
  }).toList();

  /// Habits with a running streak, highest first.
  List<({Habit habit, int days})> get runningStreaks {
    final rows = habits
        .map((habit) => (habit: habit, days: streakOf(habit)))
        .where((row) => row.days > 0)
        .toList()
      ..sort((a, b) => b.days.compareTo(a.days));
    return rows;
  }

  int get bestStreak =>
      habits.isEmpty ? 0 : habits.map(streakOf).reduce(max);

  // ---------------------------------------------------------------- copy

  /// The unit under a count: "glasses", "steps", else "times".
  String unitWord(Habit habit) {
    if (habit.kind != HabitKind.count) return 'time';
    final unit = habit.unit.trim();
    if (unit.isNotEmpty && unit != 'times') return unit;
    return habit.target == 1 ? 'time' : 'times';
  }

  /// Second line in a habit row.
  ({String text, bool warn}) subline(Habit habit) {
    switch (habit.kind) {
      case HabitKind.count:
        return (
          text: '${Fmt.count(habit.count)} of ${Fmt.count(habit.target)} '
              '${unitWord(habit)}',
          warn: false,
        );
      case HabitKind.timer:
        return (
          text: '${Fmt.duration(liveSeconds(habit))} of '
              '${Fmt.minutes(habit.target)}',
          warn: false,
        );
      case HabitKind.check:
        if (isDone(habit)) return (text: 'Done today', warn: false);
        final streak = streakOf(habit);
        if (streak > 0) {
          return (
            text: '$streak-day streak',
            warn: false,
          );
        }
        if (isBroken(habit)) {
          return (text: 'Streak broken yesterday', warn: true);
        }
        return (text: 'Once a day', warn: false);
    }
  }

  /// "3/8", "1h 20m", "Done" or "Tap" on routine step rows.
  String shortValue(Habit habit) => switch (habit.kind) {
    HabitKind.count => '${habit.count}/${habit.target}',
    HabitKind.timer => Fmt.duration(liveSeconds(habit)),
    HabitKind.check => isDone(habit) ? 'Done' : 'Tap',
  };

  /// "Count · 8 glasses", "Timer · 45 min", "Check off · once a day".
  String typeLine(Habit habit) => switch (habit.kind) {
    HabitKind.count => 'Count · ${Fmt.count(habit.target)} ${unitWord(habit)}',
    HabitKind.timer => 'Timer · ${habit.target} min',
    HabitKind.check => 'Check off · once a day',
  };

  /// "8 glasses a day" / "45 minutes a day".
  String targetLine(Habit habit) => switch (habit.kind) {
    HabitKind.count =>
      '${Fmt.count(habit.target)} ${unitWord(habit)} a day',
    HabitKind.timer => '${habit.target} minutes a day',
    HabitKind.check => 'Once a day',
  };

  // ---------------------------------------------------------------- timer

  bool isRunning(Habit habit) => runningHabitId == habit.id;

  /// Seconds shown for [habit], including the live part of a running timer.
  int liveSeconds(Habit habit) {
    if (runningHabitId == habit.id) {
      final startedAt = _timerStartedAt;
      if (startedAt != null) {
        final elapsed = DateTime.now().difference(startedAt).inSeconds;
        return min(86400, _timerBaseSeconds + max(0, elapsed)).toInt();
      }
    }
    return habit.seconds;
  }

  // --------------------------------------------------------------- mutation

  void _ensureDay() {
    if (_dayKey.isEmpty || _dayKey == todayKey) return;
    _rollover();
  }

  void _commit() {
    _ensureDay();
    _save();
    notifyListeners();
  }

  void toggleCheck(Habit habit) {
    if (habit.kind != HabitKind.check) return;
    _ensureDay();
    habit.checked = !habit.checked;
    _commit();
  }

  void increment(Habit habit) {
    if (habit.kind != HabitKind.count) return;
    _ensureDay();
    habit.count = min(habit.target, habit.count + habit.step);
    _commit();
  }

  void decrement(Habit habit) {
    if (habit.kind != HabitKind.count) return;
    _ensureDay();
    habit.count = max(0, habit.count - habit.step);
    _commit();
  }

  void setCount(Habit habit, int next) {
    if (habit.kind != HabitKind.count) return;
    _ensureDay();
    habit.count = next.clamp(0, habit.target);
    _commit();
  }

  /// Marks a habit done/not done from the routine runner, which has to work
  /// for every kind.
  void setHabitDone(Habit habit, bool done) {
    _ensureDay();
    switch (habit.kind) {
      case HabitKind.check:
        habit.checked = done;
      case HabitKind.count:
        habit.count = done ? habit.target : 0;
      case HabitKind.timer:
        habit.seconds = done ? max(habit.seconds, habit.target * 60) : 0;
        if (runningHabitId == habit.id) {
          runningHabitId = null;
          _timerStartedAt = null;
          _timerBaseSeconds = 0;
        }
    }
    _commit();
  }

  void toggleTimer(Habit habit) {
    _ensureDay();
    if (runningHabitId == habit.id) {
      stopTimer();
      return;
    }
    _applyElapsed();
    runningHabitId = habit.id;
    _timerBaseSeconds = habit.seconds;
    _timerStartedAt = DateTime.now();
    _commit();
  }

  void stopTimer() {
    if (runningHabitId == null) return;
    _ensureDay();
    _applyElapsed();
    runningHabitId = null;
    _timerStartedAt = null;
    _timerBaseSeconds = 0;
    _commit();
  }

  void addSeconds(Habit habit, int delta) {
    _ensureDay();
    final base = isRunning(habit) ? liveSeconds(habit) : habit.seconds;
    final next = (base + delta).clamp(0, 86400).toInt();
    if (isRunning(habit)) {
      _timerBaseSeconds = next;
      _timerStartedAt = DateTime.now();
    }
    habit.seconds = next;
    _commit();
  }

  /// Called once a second while a timer runs.
  void tickTimer() {
    _ensureDay();
    final id = runningHabitId;
    if (id == null) return;
    final habit = habitById(id);
    if (habit == null) {
      runningHabitId = null;
      _timerStartedAt = null;
      notifyListeners();
      return;
    }
    _applyElapsed();
    if (habit.seconds % 10 == 0) _save();
    notifyListeners();
  }

  /// Elapsed time is read from the clock, not counted in ticks, so a timer
  /// keeps the right total while the app is backgrounded or the tab is asleep.
  void _applyElapsed() {
    final id = runningHabitId;
    final startedAt = _timerStartedAt;
    if (id == null || startedAt == null) return;
    final habit = habitById(id);
    if (habit == null) return;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    habit.seconds = (_timerBaseSeconds + max(0, elapsed)).clamp(0, 86400).toInt();
  }

  void resetRoutine(Routine routine) {
    _ensureDay();
    for (final habit in routineHabits(routine)) {
      switch (habit.kind) {
        case HabitKind.check:
          habit.checked = false;
        case HabitKind.count:
          habit.count = 0;
        case HabitKind.timer:
          habit.seconds = 0;
          if (runningHabitId == habit.id) {
            runningHabitId = null;
            _timerStartedAt = null;
            _timerBaseSeconds = 0;
          }
      }
    }
    _commit();
  }

  // ---------------------------------------------------------------- habits

  String _habitId() =>
      'h-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${Random().nextInt(9999).toRadixString(36)}';

  String _routineId() =>
      'r-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${Random().nextInt(9999).toRadixString(36)}';

  Habit addHabit({
    required String name,
    required HabitKind kind,
    required String icon,
    required int target,
    String unit = '',
    bool badge = false,
    String badgeText = '',
    String badgeFg = '#FAF9F5',
    String badgeStart = '#C96442',
    String badgeEnd = '#A94E2E',
    int step = 1,
  }) {
    _ensureDay();
    final habit = Habit(
      id: _habitId(),
      name: name.trim(),
      kind: kind,
      icon: icon,
      target: kind == HabitKind.check ? 1 : target.clamp(1, 100000),
      unit: kind == HabitKind.count
          ? (unit.trim().isEmpty ? 'times' : unit.trim())
          : kind == HabitKind.timer
          ? 'min'
          : '',
      badge: badge,
      badgeText: badgeText,
      badgeFg: badgeFg,
      badgeStart: badgeStart,
      badgeEnd: badgeEnd,
      step: step.clamp(1, 100000),
    );
    habits = [...habits, habit];
    _commit();
    return habit;
  }

  Habit? addIdeaHabit(HabitIdea idea) {
    final exists = habits.any(
      (habit) => habit.name.toLowerCase() == idea.name.toLowerCase(),
    );
    if (exists) return null;
    return addHabit(
      name: idea.name,
      kind: idea.kind,
      icon: idea.icon,
      target: idea.target,
      unit: idea.unit,
    );
  }

  /// Applies edits from the habit page. Changing kind clears the day's
  /// progress, because a count target and a stopwatch are not comparable.
  void updateHabit(
    Habit habit, {
    required String name,
    required HabitKind kind,
    required String icon,
    required int target,
    required String unit,
    bool? badge,
    String? badgeText,
    String? badgeFg,
    String? badgeStart,
    String? badgeEnd,
    int? step,
  }) {
    _ensureDay();
    final kindChanged = habit.kind != kind;
    habit
      ..name = name.trim()
      ..kind = kind
      ..icon = icon
      ..target = kind == HabitKind.check ? 1 : target.clamp(1, 100000)
      ..unit = kind == HabitKind.count
          ? (unit.trim().isEmpty ? 'times' : unit.trim())
          : kind == HabitKind.timer
          ? 'min'
          : '';
    if (badge != null) habit.badge = badge;
    if (badgeText != null) habit.badgeText = badgeText;
    if (badgeFg != null) habit.badgeFg = badgeFg;
    if (badgeStart != null) habit.badgeStart = badgeStart;
    if (badgeEnd != null) habit.badgeEnd = badgeEnd;
    if (step != null) habit.step = step.clamp(1, 100000);
    if (kindChanged) {
      habit
        ..checked = false
        ..count = 0
        ..seconds = 0;
      if (runningHabitId == habit.id) {
        runningHabitId = null;
        _timerStartedAt = null;
        _timerBaseSeconds = 0;
      }
    }
    if (habit.count > habit.target) habit.count = habit.target;
    _commit();
  }

  void deleteHabit(Habit habit) {
    _ensureDay();
    habits = habits.where((h) => h.id != habit.id).toList();
    history = {
      for (final entry in history.entries)
        if (entry.value.any((id) => id != habit.id))
          entry.key: entry.value.where((id) => id != habit.id).toSet(),
    };
    for (final routine in routines) {
      routine.habitIds = routine.habitIds.where((id) => id != habit.id).toList();
    }
    if (runningHabitId == habit.id) {
      runningHabitId = null;
      _timerStartedAt = null;
      _timerBaseSeconds = 0;
    }
    _commit();
  }

  // -------------------------------------------------------------- routines

  Routine addRoutine(String name, List<String> habitIds) {
    _ensureDay();
    final routine = Routine(
      id: _routineId(),
      name: name.trim(),
      habitIds: [...habitIds],
    );
    routines = [...routines, routine];
    _commit();
    return routine;
  }

  void updateRoutine(Routine routine, String name, List<String> habitIds) {
    _ensureDay();
    routine
      ..name = name.trim()
      ..habitIds = [...habitIds];
    _commit();
  }

  void deleteRoutine(Routine routine) {
    _ensureDay();
    routines = routines.where((r) => r.id != routine.id).toList();
    _commit();
  }

  // ------------------------------------------------------------- onboarding

  /// Creates the selected starter habits and routines, then opens the app.
  void completeOnboarding({
    required String name,
    required Set<String> habitKeys,
    required Set<String> routineKeys,
  }) {
    final created = <String, String>{};
    for (final idea in starterHabits) {
      if (!habitKeys.contains(idea.key)) continue;
      final exists = habits.any(
        (habit) => habit.name.toLowerCase() == idea.name.toLowerCase(),
      );
      if (exists) {
        created[idea.key] = habits.firstWhere(
          (habit) => habit.name.toLowerCase() == idea.name.toLowerCase(),
        ).id;
        continue;
      }
      final habit = Habit(
        id: _habitId(),
        name: idea.name,
        kind: idea.kind,
        icon: idea.icon,
        target: idea.target,
        unit: idea.unit,
      );
      habits = [...habits, habit];
      created[idea.key] = habit.id;
    }
    for (final entry in starterRoutines.entries) {
      if (!routineKeys.contains(entry.key)) continue;
      final ids = entry.value
          .map((key) => created[key])
          .whereType<String>()
          .toList();
      if (ids.isEmpty) continue;
      routines = [
        ...routines,
        Routine(
          id: _routineId(),
          name: entry.key[0].toUpperCase() + entry.key.substring(1),
          habitIds: ids,
        ),
      ];
    }
    profileName = name.trim();
    onboarded = true;
    _dayKey = todayKey;
    _save();
    notifyListeners();
  }

  void setProfileName(String name) {
    profileName = name.trim();
    _commit();
  }

  // -------------------------------------------------------------- settings

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _commit();
  }

  void cycleThemeMode() {
    themeMode = switch (themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    _commit();
  }

  String get themeLabel => switch (themeMode) {
    ThemeMode.dark => 'Dark',
    ThemeMode.light => 'Light',
    ThemeMode.system => 'System',
  };

  void setReminders(bool value) {
    remindersOn = value;
    _commit();
  }

  void setReminderTime(int hour, int minute) {
    reminderHour = hour % 24;
    reminderMinute = minute % 60;
    _commit();
  }

  void setWeekStartsMonday(bool value) {
    weekStartsMonday = value;
    _commit();
  }

  void toggleBlockedApp(String packageName) {
    if (!blockedApps.remove(packageName)) blockedApps.add(packageName);
    _commit();
  }

  void clearBlockedApps() {
    blockedApps = {};
    _commit();
  }

  /// Removes habits, routines and their history; profile and settings stay.
  void clearAll() {
    habits = [];
    routines = [];
    history = {};
    runningHabitId = null;
    _timerStartedAt = null;
    _timerBaseSeconds = 0;
    _dayKey = todayKey;
    _save();
    notifyListeners();
  }

  /// Wipes everything, including the profile, and starts setup again.
  void resetApp() {
    habits = [];
    routines = [];
    history = {};
    themeMode = ThemeMode.system;
    remindersOn = true;
    reminderHour = 8;
    reminderMinute = 0;
    weekStartsMonday = true;
    blockedApps = {};
    profileName = '';
    onboarded = false;
    runningHabitId = null;
    _timerStartedAt = null;
    _timerBaseSeconds = 0;
    _dayKey = todayKey;
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------------ persistence

  void _save() {
    unawaited(_prefs.setString(_storageKey, jsonEncode(_toJson())));
  }

  /// Called when the app leaves the foreground: no tick will run, so the
  /// seconds logged so far have to reach disk now.
  void persistNow() {
    _applyElapsed();
    _save();
  }

  Map<String, Object?> _toJson() => {
    'habits': habits.map((habit) => habit.toJson()).toList(),
    'routines': routines.map((routine) => routine.toJson()).toList(),
    'history': history.map((key, ids) => MapEntry(key, ids.toList())),
    'themeMode': themeMode.name,
    'remindersOn': remindersOn,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'weekStartsMonday': weekStartsMonday,
    'blockedApps': blockedApps.toList(),
    'runningHabitId': runningHabitId,
    'timerBaseSeconds': _timerBaseSeconds,
    'timerStartedAt': _timerStartedAt?.toIso8601String(),
    'dayKey': _dayKey,
    'profileName': profileName,
    'onboarded': onboarded,
  };

  void _restore() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) {
      _dayKey = todayKey;
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map) {
      // Unreadable state is set aside, never overwritten silently.
      unawaited(_prefs.setString(_backupKey, raw));
      _dayKey = todayKey;
      return;
    }

    final json = Map<String, Object?>.from(decoded);
    _dayKey = (json['dayKey'] as String?) ?? todayKey;
    habits = _parseList(json['habits'], Habit.fromJson);
    routines = _parseList(json['routines'], Routine.fromJson);
    history = _parseHistory(json['history']);

    // A routine may only point at habits that still exist.
    final known = habits.map((habit) => habit.id).toSet();
    for (final routine in routines) {
      routine.habitIds = routine.habitIds.where(known.contains).toList();
    }
    routines = routines.where((routine) => routine.habitIds.isNotEmpty).toList();

    themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    );
    remindersOn = (json['remindersOn'] as bool?) ?? true;
    reminderHour = (json['reminderHour'] as num?)?.toInt() ?? 8;
    reminderMinute = (json['reminderMinute'] as num?)?.toInt() ?? 0;
    weekStartsMonday = (json['weekStartsMonday'] as bool?) ?? true;
    final blocked = json['blockedApps'];
    if (blocked is List) {
      blockedApps = blocked.whereType<String>().toSet();
    }
    profileName = (json['profileName'] as String?) ?? '';
    onboarded = (json['onboarded'] as bool?) ?? false;

    final runningId = json['runningHabitId'] as String?;
    final startedAt = DateTime.tryParse(
      (json['timerStartedAt'] as String?) ?? '',
    );
    if (runningId != null && habitById(runningId) != null && startedAt != null) {
      runningHabitId = runningId;
      _timerStartedAt = startedAt;
      _timerBaseSeconds = (json['timerBaseSeconds'] as num?)?.toInt() ?? 0;
    }

    if (_dayKey != todayKey) _rollover();
    _applyElapsed();
  }

  /// One unreadable row must not cost the rest of the store, so rows are
  /// parsed individually and dropped only when they cannot be understood.
  List<T> _parseList<T>(
    Object? value,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (value is! List) return <T>[];
    final rows = <T>[];
    for (final row in value) {
      if (row is! Map) continue;
      try {
        rows.add(fromJson(Map<String, Object?>.from(row)));
      } catch (_) {
        // Skipped: the other rows still load.
      }
    }
    return rows;
  }

  Map<String, Set<String>> _parseHistory(Object? value) {
    if (value is! Map) return {};
    final result = <String, Set<String>>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final ids = entry.value;
      if (key is! String || Fmt.parseDateKey(key) == null || ids is! List) {
        continue;
      }
      result[key] = ids.whereType<String>().toSet();
    }
    return result;
  }

  /// Archives the finished day and starts a clean one.
  void _rollover() {
    // A timer that ran past midnight is credited to the day it ran in before
    // the counts are archived and cleared.
    _applyElapsed();
    if (_dayKey.isNotEmpty && _dayKey != todayKey) {
      final archived = habits.where(isDone).map((habit) => habit.id).toSet();
      if (archived.isNotEmpty) history[_dayKey] = archived;
    }
    for (final habit in habits) {
      habit
        ..checked = false
        ..count = 0
        ..seconds = 0;
    }
    runningHabitId = null;
    _timerStartedAt = null;
    _timerBaseSeconds = 0;
    _dayKey = todayKey;
    _save();
  }

  /// Called when the app comes back to the foreground, and by every write.
  void ensureToday() {
    if (_dayKey.isEmpty || _dayKey == todayKey) return;
    _rollover();
    notifyListeners();
  }
}
