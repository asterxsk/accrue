# Accrue 2.2 — implementation plan

Scope: the profile/data/habit/insights rework requested for the next release. Everything stays
local-first. Release stays signed with the existing key (workflow unchanged).

## Decisions

- **Per-habit reminders deliver real notifications.** Global reminders are removed. Each habit gets
  an optional daily time. Implemented with `flutter_local_notifications` + `timezone` +
  `flutter_timezone`; plain no-op on web/desktop. Android gets `POST_NOTIFICATIONS`; scheduling uses
  inexact daily repeats so no `SCHEDULE_EXACT_ALARM` permission is added.
- **Counted habits accept halves.** `Habit.count` and `Habit.step` become `double` (target stays
  `int`). Old JSON (ints) loads unchanged. Increment presets allow `0.5`.
- **Habit row**: body tap is the primary action (check toggles, count increments by its step, timer
  opens the timer). The old +/- and the middle number leave the row. The trailing three-dot becomes a
  pencil button that opens the habit's full-screen page.
- **Full-screen habit page** carries the three-dot menu (Edit habit / Delete habit):
  counter → existing counter detail (keeps +/-), timer → timer page, check → new check detail page
  with today's status, streak and week.
- **Profile edit is a full page**: name, bio, photo (`image_picker`, downscaled to 512px, stored as
  base64 in prefs).
- **Appearance / Start week on** open anchored popup menus (same component as the habit menu) instead
  of inline expansion.
- **Data & export is a full page** with explanatory copy and full-width buttons: Export, Import,
  Clear habits & history, Reset app. Export/import are JSON files via `file_picker`
  (save/open). Import replaces all state after a confirmation.
- **Insights** gets two controls under the header: a **filter** pill (All habits / one habit, anchored
  popup) and a **sliding Week | Month toggle**. Week view keeps the detailed bar graph (plus
  per-day numbers); Month view is a GitHub-style heat map whose saturation is the completed fraction
  of habits for that day (2 of 4 = 50 %, 4 of 4 = full accent). A habit filter makes a day 0 or 100 %.
- **Swipe navigation.** The four top-level tabs live in a `PageView`; swiping left/right moves between
  Today, Insights, Routines and Profile with the same animation the pill uses. Tabs keep their state.
- **Timer page** drops the End action; the three-dot menu sits top right. Each timer habit gains a
  "Block distracting apps" switch so focus blocking is opt-in per habit.
- Screenshots are captured from the Android emulator in **dark mode** with seeded demo data via a
  new `tool/demo_main.dart` entrypoint (seeding code lives only in `tool/`, never in the app).

## Phase 0 — shared foundation (no UI ownership)

Files: `pubspec.yaml`, `lib/models/habit.dart`, `lib/state/habit_store.dart`, `lib/util/format.dart`,
`lib/util/reminders.dart` (new), `lib/widgets/popup_menu.dart`, `lib/widgets/ui.dart`,
`lib/widgets/avatar` usage, `android/app/src/main/AndroidManifest.xml`.

- Add deps: `file_picker`, `image_picker`, `flutter_local_notifications`, `timezone`,
  `flutter_timezone`.
- `Habit`: `double count`, `double step`, `int? reminderMinutes` (minute of day), json round-trip,
  defaults.
- Store:
  - decimal increment/decrement/setCount, ratio/done math untouched otherwise.
  - monthly helpers: `monthDays` (week-aligned rows), `completedFractionOn(day, {habitId})`,
    `monthPercent({habitId})`, `daySeries` retained.
  - remove `remindersOn/reminderHour/reminderMinute` (+ setters, json; old keys ignored).
  - `profileBio`, `profilePhoto` (base64), `setProfile(...)`.
  - `String exportJson()` and `ImportResult importJson(String)` (validate, replace, reschedule,
    notify); `clearAll`/`resetApp` also cancel notifications.
  - `reminderMinutes` change hooks call the reminder scheduler.
- `Fmt`: decimal count (`2.5`), minute-of-day time label reuse.
- `AppMenuItem` gains `selected` → check mark. `SegmentedToggle` (animated sliding thumb) added.
  `Avatar` accepts optional base64 photo. `HeadBar` may show both `trailing` and `actionLabel`.
- `reminders.dart`: init/permission/schedule/cancel; no-op off Android/iOS.
- Manifest: notification permission + plugin receivers.

## Phase 1 — four parallel workstreams

### A. Data & export page

Files: `lib/screens/data_export_screen.dart` (new), `lib/widgets/dialogs.dart`, `lib/screens/profile_screen.dart` (row only).

- Full page with HeadBar, intro copy, sections Export / Import / Clear.
- Full-width buttons (`AppButton(expand: true)`), inline status text; confirmations for import,
  clear, reset. Import shows result count and errors.
- Remove `DataChoice` + `dataDialog`; Profile's Data row pushes the page.

### B. Profile page, edit page, settings popups

Files: `lib/screens/edit_profile_screen.dart` (new), `lib/screens/profile_screen.dart`,
`lib/widgets/share_poster.dart`.

- `EditProfileScreen`: photo preview + Change/Remove, name field, bio field (multiline, 160 max),
  Save. Uses `image_picker`; decodes failures gracefully.
- Profile card shows photo and bio; Edit pill pushes the page.
- Appearance and Start week on use anchored popup menus with a check on the selected option.
- Delete the entire Reminders group (switch + time). Update copy mentioning reminders where stale.

### C. Habit rows, detail pages, counter halves, per-habit reminder form

Files: `lib/widgets/habit_row.dart`, `lib/screens/today_screen.dart`,
`lib/screens/counter_detail_screen.dart`, `lib/screens/timer_screen.dart`,
`lib/screens/check_detail_screen.dart` (new), `lib/widgets/habit_menu.dart` (new),
`lib/screens/new_habit_screen.dart`, `lib/screens/routine_run_screen.dart` if it uses row controls.

- Row: body action per kind; count body increments; no +/- or number; trailing pencil opens detail.
- Shared `habitActionMenu` (Edit / Delete) used by Today and all detail pages; delete pops to Today.
- Counter detail: three-dot menu, decimal display/step, keeps +/-.
- Timer page: three-dot menu while keeping End.
- Check detail: mark, today status + big toggle, streak, week grid, three-dot menu.
- Habit form: Reminder section (switch + time dialog) shown for every kind; `0.5 / 1 / 5 / 10 /
  custom` increment choices for counts; update the intent-only footnote to the real behaviour.
- Routine runner keeps working with decimal counts.

### D. Insights rework

Files: `lib/screens/insights_screen.dart`, `lib/widgets/heat_map.dart` (new).

- Stateful screen: `_range` (week/month), `_filterHabitId`.
- Controls row: filter pill (anchored popup, All habits + habits, selected check) and sliding
  Week | Month `SegmentedToggle`.
- Week: hero stat for the range selection, existing seven-bar graph plus per-day values, streaks
  (filtered).
- Month: month hero, heat map (weekday-aligned, month label, legend Less→More), today outlined,
  future days empty; per-habit filter switches cells to 0/100 %.
- Empty and filtered-empty states.

## Phase 2 — verification (me)

- `flutter analyze`, `flutter test`; extend `test/widget_test.dart` (decimal step, reminder
  round-trip, export/import round-trip, heat-map fraction, filters, new row behaviour).
- Emulator: boot, `flutter run -t tool/demo_main.dart`, exercise every changed screen, screenshot.
- Capture dark screenshots of Today / Insights / Routines, resize to 390 × 844, replace
  `screenshots/01-today.png`, `02-insights.png`, `03-routines.png`; update README screenshot note.
- Check in with the user before any git push.

## Phase 3 — release (only after explicit green light)

- Bump `pubspec.yaml` to `2.2.0+24`, About version to 2.2.
- Update README feature list / release notes as needed.
- Commit, push `main`, tag `v2.2.0`, let `.github/workflows/release.yml` build and publish the APK
  with the existing keystore secrets. Verify the release APK signature matches the previous release.

## Risks

- Plugin versions resolving against Flutter 3.47.9 (pub reachable; verify `flutter pub get` first).
- Concurrent agents editing disjoint files; shared widgets are finalised in Phase 0.
- Emulator notification permission prompt during screenshot run — seed without reminders enabled.
