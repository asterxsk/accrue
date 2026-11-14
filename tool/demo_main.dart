import 'package:flutter/material.dart';

import 'package:accrue/app.dart';
import 'package:accrue/models/habit.dart';
import 'package:accrue/state/habit_store.dart';
import 'package:accrue/util/format.dart';

/// Screenshot/dev entrypoint: a fresh store with believable sample data, dark.
///
/// Run it without touching the shipped app:
///   flutter run -t tool/demo_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HabitStore.load();
  store.resetApp();
  store.completeOnboarding(
    name: 'Alex',
    habitKeys: {'water', 'gym', 'read', 'walk', 'sleep'},
    routineKeys: {'morning', 'evening'},
  );

  final study = store.addHabit(
    name: 'Study',
    kind: HabitKind.timer,
    icon: 'book',
    target: 90,
  );
  store.updateHabit(
    study,
    name: 'Study',
    kind: HabitKind.timer,
    icon: 'book',
    target: 90,
    unit: '',
  );

  final water = store.habits.firstWhere((habit) => habit.name == 'Water');
  store.updateHabit(
    water,
    name: 'Water',
    kind: HabitKind.count,
    icon: 'water',
    target: 8,
    unit: 'bottles',
    step: 0.5,
  );

  final read = store.habits.firstWhere((habit) => habit.name == 'Read');
  final gym = store.habits.firstWhere((habit) => habit.name == 'Gym');
  final walk = store.habits.firstWhere((habit) => habit.name == 'Walk');
  final sleep = store.habits.firstWhere((habit) => habit.name == 'Sleep by 11');
  final ids = [water.id, gym.id, read.id, walk.id, sleep.id, study.id];

  // Five weeks of history: busier midweek, a little lighter on weekends.
  for (var ago = 35; ago >= 1; ago--) {
    final day = Fmt.addDays(store.today, -ago);
    final weekday = day.weekday;
    final done = switch (weekday) {
      DateTime.saturday || DateTime.sunday => [read.id, walk.id, water.id],
      DateTime.monday => [read.id, gym.id, walk.id, water.id],
      DateTime.friday => [read.id, gym.id, sleep.id, water.id],
      _ => ids.where((id) => id != (weekday.isEven ? sleep.id : walk.id)).toList(),
    };
    // Keep Study plausible: most weekdays, not every one.
    if (weekday != DateTime.sunday && !done.contains(study.id)) {
      if (weekday == DateTime.tuesday || weekday == DateTime.thursday) {
        done.add(study.id);
      }
    }
    store.history[Fmt.dateKey(day)] = done.toSet();
  }

  // Today, part-way through: nothing complete yet except one habit.
  store.setCount(water, 5.5);
  store.addSeconds(gym, 32 * 60);
  store.setCount(walk, 4300);
  store.toggleCheck(read);
  store.addSeconds(study, 45 * 60);

  store.setProfile(
    name: 'Alex',
    bio: 'Building small things, one day at a time.',
    photo: '',
  );
  store.setThemeMode(ThemeMode.dark);
  store.persistNow();

  runApp(HabitApp(store: store));
}
