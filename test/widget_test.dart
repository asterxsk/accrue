import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accrue/app.dart';
import 'package:accrue/models/habit.dart';
import 'package:accrue/widgets/habit_mark.dart';
import 'package:accrue/widgets/icon_library.dart';
import 'package:accrue/state/habit_store.dart';
import 'package:accrue/util/format.dart';
import 'package:accrue/util/updates.dart';
import 'package:accrue/widgets/nav_pill.dart';
import 'package:accrue/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<HabitStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return HabitStore.load();
}

Future<HabitStore> seededStore() async {
  final store = await freshStore();
  store.completeOnboarding(
    name: 'Alex',
    habitKeys: {'water', 'read', 'gym'},
    routineKeys: {'morning'},
  );
  return store;
}

Habit habitNamed(HabitStore store, String name) =>
    store.habits.firstWhere((habit) => habit.name == name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store', () {
    test('a fresh install has no data and is not onboarded', () async {
      final store = await freshStore();
      expect(store.habits, isEmpty);
      expect(store.routines, isEmpty);
      expect(store.onboarded, isFalse);
      expect(store.themeMode, ThemeMode.system);
    });

    test('onboarding creates selected habits and routines', () async {
      final store = await seededStore();
      expect(store.onboarded, isTrue);
      expect(store.profileName, 'Alex');
      expect(store.habits.map((habit) => habit.name), ['Water', 'Gym', 'Read']);
      expect(store.routines, hasLength(1));
      expect(store.routines.first.name, 'Morning');
      expect(store.routines.first.habitIds, [
        habitNamed(store, 'Water').id,
        habitNamed(store, 'Read').id,
      ]);
    });

    test('a check habit toggles and counts toward completion', () async {
      final store = await seededStore();
      final read = habitNamed(store, 'Read');
      expect(store.isDone(read), isFalse);
      store.toggleCheck(read);
      expect(store.isDone(read), isTrue);
      expect(store.doneCount, 1);
      expect(store.completionPercent, 33);
      store.toggleCheck(read);
      expect(store.doneCount, 0);
    });

    test('a count habit stops at its target', () async {
      final store = await seededStore();
      final water = habitNamed(store, 'Water');
      for (var i = 0; i < 12; i++) {
        store.increment(water);
      }
      expect(water.count, 8);
      expect(store.isDone(water), isTrue);
      store.decrement(water);
      expect(water.count, 7);
      expect(store.ratio(water), closeTo(7 / 8, 0.001));
    });

    test('a counted habit can step by a custom increment', () async {
      final store = await seededStore();
      final habit = store.addHabit(
        name: 'Steps',
        kind: HabitKind.count,
        icon: 'footprints',
        target: 8000,
        unit: 'steps',
        step: 250,
      );
      expect(habit.step, 250);
      store.increment(habit);
      expect(habit.count, 250);
      store.increment(habit);
      expect(habit.count, 500);
      store.decrement(habit);
      expect(habit.count, 250);
      for (var i = 0; i < 40; i++) {
        store.increment(habit);
      }
      expect(habit.count, 8000);
      expect(store.isDone(habit), isTrue);
    });

    test('a text badge survives a save and restore', () async {
      final store = await seededStore();
      final habit = store.addHabit(
        name: 'Water',
        kind: HabitKind.count,
        icon: 'check',
        target: 8,
        unit: 'glasses',
        badge: true,
        badgeText: 'WA',
        badgeFg: '#141413',
        badgeStart: '#0EA5E9',
        badgeEnd: '#2563EB',
      );
      store.persistNow();
      expect(habit.badge, isTrue);
      expect(habit.badgeText, 'WA');

      final restored = await HabitStore.load();
      final again = restored.habits.firstWhere((row) => row.id == habit.id);
      expect(again.badge, isTrue);
      expect(again.badgeText, 'WA');
      expect(again.badgeFg, '#141413');
      expect(again.badgeStart, '#0EA5E9');
      expect(again.badgeEnd, '#2563EB');
    });

    test('a badge habit takes its progress accent from its gradient', () async {
      final store = await seededStore();
      const clay = Color(0xFFC96442);
      final plain = store.addHabit(
        name: 'Run',
        kind: HabitKind.count,
        icon: 'footprints',
        target: 5,
        unit: 'km',
      );
      final badged = store.addHabit(
        name: 'Water',
        kind: HabitKind.count,
        icon: 'droplet',
        target: 8,
        unit: 'glasses',
        badge: true,
        badgeText: 'WA',
        badgeStart: '#0EA5E9',
        badgeEnd: '#2563EB',
      );
      expect(markAccent(plain, clay), clay);
      expect(markAccent(badged, clay), const Color(0xFF0EA5E9));
    });

    test('the icon library is searchable and covers common habits', () {
      expect(lucideIconNames.length, greaterThan(1000));
      for (final name in [
        'droplet',
        'footprints',
        'book-open',
        'moon',
        'dumbbell',
      ]) {
        expect(lucideIcons.containsKey(name), isTrue, reason: name);
      }
      expect(
        lucideIconNames.where((name) => name.contains('water')).toList(),
        isNotEmpty,
      );
    });

    test('a timed habit logs seconds and completes at target', () async {
      final store = await seededStore();
      final gym = habitNamed(store, 'Gym');
      expect(gym.target, 45);
      store.addSeconds(gym, 45 * 60);
      expect(store.isDone(gym), isTrue);
      expect(store.liveSeconds(gym), 45 * 60);
    });

    test('streaks count today plus consecutive past days', () async {
      final store = await seededStore();
      final read = habitNamed(store, 'Read');
      final now = store.today;
      store.history[Fmt.dateKey(Fmt.addDays(now, -1))] = {read.id};
      store.history[Fmt.dateKey(Fmt.addDays(now, -2))] = {read.id};
      store.toggleCheck(read);
      expect(store.streakOf(read), 3);
      expect(store.bestStreakOf(read), 3);
      expect(store.runningStreaks.first.habit.id, read.id);
    });

    test('the week percentage uses only elapsed days', () async {
      final store = await seededStore();
      final water = habitNamed(store, 'Water');
      for (final habit in store.habits) {
        store.setHabitDone(habit, true);
      }
      final expected =
          (store.doneCount /
                  (store.habits.length * store.elapsedWeekDays) *
                  100)
              .round();
      expect(store.weekPercent, expected);
      store.setHabitDone(water, false);
      expect(store.weekPercent, lessThan(expected));
      expect(store.weekSeries.length, 7);
    });

    test('deleting a habit clears it from routines and history', () async {
      final store = await seededStore();
      final water = habitNamed(store, 'Water');
      final yesterday = Fmt.dateKey(Fmt.addDays(store.today, -1));
      store.history[yesterday] = {water.id};
      store.deleteHabit(water);
      expect(store.habits.map((habit) => habit.name), isNot(contains('Water')));
      expect(store.routines.first.habitIds, isNot(contains(water.id)));
      expect(store.history.containsKey(yesterday), isFalse);
    });

    test('a day left open rolls over and archives the finished day', () async {
      final past = Fmt.dateKey(Fmt.addDays(DateTime.now(), -1));
      SharedPreferences.setMockInitialValues({
        'habit_tracker.state.v2': jsonEncode({
          'habits': [
            {
              'id': 'h1',
              'name': 'Read',
              'kind': 'check',
              'icon': 'book',
              'target': 1,
              'unit': '',
              'count': 0,
              'seconds': 0,
              'checked': true,
            },
          ],
          'routines': <Object>[],
          'history': <String, Object>{},
          'dayKey': past,
          'profileName': 'Sam',
          'onboarded': true,
        }),
      });
      final store = await HabitStore.load();
      expect(store.history[past], {'h1'});
      expect(store.habits.first.checked, isFalse);
      expect(store.onboarded, isTrue);
    });

    test('an unreadable blob is set aside, not overwritten', () async {
      SharedPreferences.setMockInitialValues({
        'habit_tracker.state.v2': 'not json',
      });
      final store = await HabitStore.load();
      expect(store.habits, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('habit_tracker.state.unreadable'), 'not json');
    });

    test('reset app clears the profile and returns to onboarding', () async {
      final store = await seededStore();
      store.resetApp();
      expect(store.habits, isEmpty);
      expect(store.onboarded, isFalse);
      expect(store.profileName, '');
    });

    test('a counted habit can step in halves', () async {
      final store = await seededStore();
      final habit = store.addHabit(
        name: 'Water',
        kind: HabitKind.count,
        icon: 'water',
        target: 4,
        unit: 'bottles',
        step: 0.5,
      );
      for (var i = 0; i < 5; i++) {
        store.increment(habit);
      }
      expect(habit.count, 2.5);
      expect(Fmt.count(habit.count), '2.5');
      store.decrement(habit);
      expect(habit.count, 2.0);
      expect(Fmt.count(habit.count), '2');
    });

    test('month heat fractions follow the completed share', () async {
      final store = await seededStore();
      final now = store.today;
      final twoDaysAgo = Fmt.addDays(now, -2);
      store.history[Fmt.dateKey(twoDaysAgo)] = {
        store.habits[0].id,
        store.habits[1].id,
      };
      expect(
        store.completedFractionOn(twoDaysAgo),
        closeTo(2 / store.habits.length, 0.001),
      );
      expect(
        store.completedFractionOn(twoDaysAgo, habitId: store.habits[0].id),
        1,
      );
      expect(
        store.completedFractionOn(twoDaysAgo, habitId: store.habits[2].id),
        0,
      );
      expect(
        store.monthGrid.expand((row) => row).whereType<DateTime>(),
        isNotEmpty,
      );
    });

    test('a backup round-trips through import', () async {
      final store = await seededStore();
      final water = habitNamed(store, 'Water');
      final habit = store.addHabit(
        name: 'Study',
        kind: HabitKind.timer,
        icon: 'book',
        target: 60,
        reminderMinutes: 16 * 60,
      );
      store.setCount(water, 2.5);
      store.setProfile(name: 'Sam', bio: 'One line', photo: '');
      final backup = store.exportJson();

      final restored = await freshStore();
      final result = restored.importJson(backup);
      expect(result.ok, isTrue);
      expect(restored.habits.map((row) => row.name), contains('Study'));
      final restoredWater = habitNamed(restored, 'Water');
      expect(restoredWater.count, 2.5);
      expect(habitNamed(restored, 'Study').reminderMinutes, 16 * 60);
      expect(restored.profileName, 'Sam');
      expect(restored.profileBio, 'One line');
      expect(habit.reminderMinutes, 16 * 60);
    });

    test('a broken import leaves the store untouched', () async {
      final store = await seededStore();
      final before = store.habits.length;
      final result = store.importJson('{"nope": true}');
      expect(result.ok, isFalse);
      expect(store.habits.length, before);
      expect(store.importJson('not json').ok, isFalse);
    });

    test('the clock setting reads times in 12 or 24 hours', () async {
      final store = await seededStore();
      expect(store.clock24, isTrue);
      expect(store.formatTime(16 * 60 + 30), '16:30');
      store.setClock24(false);
      expect(store.clockLabel, '12-hour');
      expect(store.formatTime(16 * 60 + 30), '4:30 PM');
      expect(store.formatTime(0), '12:00 AM');
      expect(store.formatTime(12 * 60 + 5), '12:05 PM');

      final restored = await HabitStore.load();
      expect(restored.clock24, isFalse);
      expect(restored.formatTime(9 * 60), '9:00 AM');
    });
  });

  group('updates', () {
    const feed = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>tag:github.com,2008:Repository/1/v2.3.0</id>
    <updated>2026-11-15T14:24:24Z</updated>
    <link rel="alternate" type="text/html" href="https://github.com/a/b/releases/tag/v2.3.0"/>
    <title>Accrue v2.3.0</title>
    <content type="html">&lt;p&gt;Accrue 2.3.0.&lt;br&gt;Signed with the release key.&lt;/p&gt;</content>
  </entry>
  <entry>
    <id>tag:github.com,2008:Repository/1/v2.2.1</id>
    <updated>2026-11-14T20:00:57Z</updated>
    <link rel="alternate" type="text/html" href="https://github.com/a/b/releases/tag/v2.2.1"/>
    <title>Accrue v2.2.1</title>
    <content type="html">&lt;p&gt;Accrue 2.2.1.&lt;/p&gt;</content>
  </entry>
</feed>
''';

    test('the Atom feed stands in for the rate-limited API', () {
      final rows = parseAtomReleases(feed, repo: 'a/b');
      expect(rows.map((r) => r.version), ['2.3.0', '2.2.1']);
      expect(
        rows.first.apkUrl,
        'https://github.com/a/b/releases/download/v2.3.0/accrue-2.3.0.apk',
      );
      expect(rows.first.notes, 'Accrue 2.3.0.\nSigned with the release key.');
      expect(rows.first.apkBytes, 0);
      expect(rows.first.sha256, isNull);
      expect(rows.first.publishedAt, isNotNull);
    });

    test('versions compare numerically', () {
      expect(isNewer('2.10.0', '2.9.2'), isTrue);
      expect(isNewer('2.3.0', '2.3.0'), isFalse);
      expect(isNewer('2.2.9', '2.3.0'), isFalse);
    });
  });

  group('widgets', () {
    Future<void> pumpStore(WidgetTester tester, HabitStore store) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(HabitApp(store: store));
      await tester.pumpAndSettle();
    }

    testWidgets('onboarding walks from name to habits to routines', (
      tester,
    ) async {
      final store = await freshStore();
      await pumpStore(tester, store);

      expect(find.text('Let’s make this yours.'), findsOneWidget);
      final continueButton = find.widgetWithText(AppButton, 'Continue');
      expect(continueButton, findsOneWidget);
      final button = tester.widget<AppButton>(continueButton);
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Alex');
      await tester.pump();
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
            .onPressed,
        isNotNull,
      );

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Continue'));
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Start with a few'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Continue'));
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Then a routine'), findsOneWidget);

      await tester.ensureVisible(
        find.widgetWithText(AppButton, 'Finish setup'),
      );
      await tester.tap(find.widgetWithText(AppButton, 'Finish setup'));
      await tester.pumpAndSettle();
      expect(store.onboarded, isTrue);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('Today shows the stat line and a check habit toggles', (
      tester,
    ) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      expect(find.textContaining('of 3 done'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      expect(store.isDone(habitNamed(store, 'Read')), isTrue);
      expect(find.textContaining('of 3 done'), findsOneWidget);
    });

    testWidgets(
      'a count row increments on tap and opens detail from the dots',
      (tester) async {
        final store = await seededStore();
        await pumpStore(tester, store);

        await tester.tap(find.text('Water'));
        await tester.pumpAndSettle();
        expect(habitNamed(store, 'Water').count, 1);
        expect(find.text('8 glasses a day'), findsNothing);

        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is AppIconButton && widget.label == 'Open Water',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('8 glasses a day'), findsOneWidget);
        expect(find.text('CURRENT STREAK'), findsOneWidget);

        final plus = find.byWidgetPredicate(
          (widget) => widget is AppIconButton && widget.label == '1 more',
        );
        await tester.tap(plus);
        await tester.pumpAndSettle();
        expect(habitNamed(store, 'Water').count, 2);
      },
    );

    testWidgets('swiping moves between tabs', (tester) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      await tester.fling(find.byType(PageView), const Offset(-320, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('completion this week'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.textContaining('of 3 done'), findsOneWidget);
    });

    testWidgets('a routine card opens the runner and marks a habit done', (
      tester,
    ) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      await tester.tap(
        find.descendant(
          of: find.byType(NavPill),
          matching: find.text('Routines'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 2 done · next: Water'), findsOneWidget);

      await tester.tap(find.text('Water'));
      await tester.pumpAndSettle();
      expect(store.doneCount, 1);
      expect(find.text('1 of 2 done · next: Read'), findsOneWidget);
    });

    testWidgets('the pill switches to Insights and Profile', (tester) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      await tester.tap(
        find.descendant(
          of: find.byType(NavPill),
          matching: find.text('Insights'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('completion this week'), findsOneWidget);
      expect(find.text('STREAKS'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavPill),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alex'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);

      await tester.tap(find.text('Appearance').last);
      await tester.pumpAndSettle();
      expect(find.text('System'), findsWidgets);
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(store.themeMode, ThemeMode.light);
    });

    testWidgets('a habit can be created from Today', (tester) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      await tester.ensureVisible(find.text('New habit'));
      await tester.tap(find.text('New habit'));
      await tester.pumpAndSettle();
      expect(find.text('New habit'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Journal');
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, 'Create habit'));
      await tester.pumpAndSettle();

      expect(store.habits.map((habit) => habit.name), contains('Journal'));
      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets('Share stats copies the caption where no share sheet exists', (
      tester,
    ) async {
      final store = await seededStore();
      await pumpStore(tester, store);

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('habit_tracker/share'),
        (call) async => false,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('habit_tracker/share'),
          null,
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(NavPill),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share stats'));
      await tester.pumpAndSettle();
      expect(find.text('Share your stats'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Share'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Share'));
      await tester.pumpAndSettle();

      expect(copied, contains('Alex on Accrue'));
      expect(find.text('Share your stats'), findsNothing);
      expect(find.text('Caption copied'), findsOneWidget);
    });

    testWidgets('the layout holds at 320 wide', (tester) async {
      final store = await seededStore();
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(HabitApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsWidgets);
    });
  });
}
