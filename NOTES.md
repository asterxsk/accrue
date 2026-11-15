# Implementation notes — habit tracker

What the app is: an Android habit tracker, built in Flutter from a design prototype. Parchment
light theme and a tuned dark theme, clay accent, serif display type, bottom pill nav. Check / counted / timed habits,
routines as ordered habit sets, week insights, local profile, share poster. Everything is stored on
the device.

## Where things live

| Path | What |
|---|---|
| `lib/theme/` | `AppColors` token set as a `ThemeExtension`, `AppType` type scale, `Metrics`, `ThemeData` |
| `lib/models/habit.dart` | `Habit`, `HabitKind`, `Routine`, starter habits, routine presets, habit-idea catalogue |
| `lib/state/habit_store.dart` | `ChangeNotifier`: day state, history, streaks, weeks, timer, settings, persistence |
| `lib/widgets/` | Icon set (inline SVG + full Lucide library), controls, habit row, habit mark, nav pill, popup menu, dialogs, wheel picker, share poster |
| `lib/screens/` | Onboarding, Today, counter detail, timer, routine run, new habit, mark picker, Insights, Routines, Profile, `home_shell.dart` |
| `lib/app_nav.dart` | `AppNav` + `AppNavScope` so pushed screens can switch tabs |
| `lib/widgets/icon_library.dart` | Generated: 1,865 Lucide icon bodies + sorted names (`tool/gen_icons.py` regenerates it) |
| `tool/gen_icons.py` | Converts a local `lucide-static` package into `icon_library.dart` |
| `test/widget_test.dart` | 29 unit/widget tests |
| `screenshots/` | 390×867 dark Android captures (01–11), plus the Android focus overlay at 1080×2400 |

## Design facts encoded in the theme

- Light: bg `#F5F4ED`, surface `#FAF9F5`, line `#E8E6DC`, text `#141413`, muted `#5E5D59`,
  accent `#C96442`, action `#141413`/`#FAF9F5`.
- Dark: bg `#141413`, surface `#30302E`, line `#3D3D3A`, text `#FAF9F5`, muted `#B0AEA5`,
  accent `#D97757`.
- Radii 8 / 12 / 16, gutter 20 (16 under 360 wide), max content width 430.
- Titles are Source Serif 4 (variable font, `FontVariation('wght', 500)`); UI is Inter, numbers are
  rendered with tabular figures.
- Interaction state is a faint clay tint (`accentSoft`). The Material grey hover wash is turned off
  in `AppTheme`.

## Deliberate divergences from the prototype

1. **The profile photo is optional.** `image_picker` opens the system picker; the image is
   downscaled to 512px and stored as base64 in local storage. The avatar falls back to initials.
   Android builds fine without Developer Mode; Windows desktop builds still need symlink support for
   plugins.
2. **Share sends text, not a PNG.** The poster is drawn natively and previewed in the dialog. On
   Android, **Share** opens the system share sheet with the week's caption through a small
   `MethodChannel` (`accrue/share`) in `MainActivity.kt` — no plugin, so the symlink limit
   does not apply. Web and desktop have no share target, so the caption is copied to the clipboard
   there and the snackbar says so. Exporting the poster as an image still needs a plugin.
3. **Large count targets collapse the dot row.** Up to 60 units are drawn as dots; above that
   (8,000 steps) the disc becomes a proportional rail, so the target stays legible.
4. **Habit marks are a full icon library or a text badge.** `MarkPickerScreen` searches all 1,865
   Lucide icons by name, or builds a one/two character badge (auto-uppercased) with its own text
   colour and one of ten gradients. Stored per habit as `badge`, `badgeText`, `badgeFg`,
   `badgeStart`, `badgeEnd`; `HabitMark` renders it in rows, the detail disc, routines and the
   picker preview. A badge habit's progress accent is its gradient start colour
   (`markAccent` in `habit_mark.dart`), so a blue badge gets a blue ring, rail, week marker and
   timer ring; icon habits keep the theme clay. Lucide is ISC-licensed; `tool/gen_icons.py` rebuilds `icon_library.dart` from a
   local `lucide-static` tree, so no SVG assets ship.
5. **Counted habits can log in steps.** A habit carries `step` (default 1): each tap of `+`/`−`
   adds or removes that many, clamped to the target. The form's increment and target steppers widen
   their stride as the number grows (1 → 10 → 100), and tapping the number opens a typed entry, so
   an 8,000 target or a 250 increment is a few digits rather than hundreds of taps.
6. **The nav pill runs to the screen edges** minus a 12pt side gutter, 78pt tall with 64pt buttons,
   and sits 6pt above the real safe-area bottom rather than the prototype's taller inset.
7. **Edit name is a pill on the profile card**, not a row under About; About now holds only the
   version row.
8. **Onboarding is the first run.** There is no sample data. A fresh install goes name → habits →
   routines, then lands on Today. The prototype's seeded demo screens are not shipped.
9. **"New habit" lives at the bottom of Today** as the dashed row the prototype uses on Routines.
   It sits below the fold at 844pt, so first paint matches the prototype.
10. **Reminders are stored intent.** No notification plugin, so the switch and time persist and are
    read back; nothing is scheduled.
11. **Theme order** cycles System → Light → Dark, and the label always states the current mode.
12. **Routine steps are habits**, keyed by habit id, exactly as the prototype models them. Deleting a
    habit removes it from every routine and from history.
13. **The mock OS status bar is not drawn.** Content uses `max(real safe-area top, 44)`.

## Behaviour worth knowing

- **Rollover.** On load, on resume and before every day-scoped write the store archives the finished
  day's done habit ids into history, then resets counts, seconds and ticks. Date maths is
  calendar-based (`Fmt.addDays`), so a DST change cannot shift a day.
- **Streaks** count today when done, otherwise from yesterday, so a habit done yesterday keeps its
  run until today ends. A missed day breaks it; `bestStreakOf` walks all of history.
- **Week percentage** divides by elapsed days only (`elapsedWeekDays`), so a Monday morning does not
  read as failure. `previousWeekPercent` uses the same number of days of the prior week.
- **Timer.** It reads elapsed time from the wall clock against a base count, so the display cannot
  drift, and a running timer is stopped (and credited) at rollover. The running state is in memory
  only: a killed process loses the unlogged part, the logged seconds persist.
- **Persistence.** `shared_preferences` key `accrue.state.v2` holds habits, routines, history
  and settings. An unreadable blob is copied to `accrue.state.unreadable` and never
  overwritten; a single unreadable habit or routine row is dropped and the rest still load.
- **Data & export** offers *Clear all* (habits, routines and history; profile and settings stay) and
  *Reset app* (everything, back to onboarding). Both confirm first.
- English-only strings; no locale layer in this build.
- **Pop-ups fit their content.** Action menus (`showActionMenu`) measure the longest label
  (icon + gap + row padding + panel padding) and clamp to 168–300pt, so a two-item menu is a small
  anchored card instead of a full-width sheet. Dialogs keep a 340pt reading width, except the
  short ones (choice lists, confirms, info) which measure their title, longest label and button
  row with a `TextPainter` in `_fittedWidth` and clamp to 232–340pt; their buttons are intrinsic
  and right-aligned. IntrinsicWidth was tried first and rejected: bodies containing a
  `LayoutBuilder` (the share poster) throw when intrinsics are queried.
- **Dialogs own their text controllers.** `nameDialog` and `numberDialog` are built on a stateful
  `_EntryDialog`, so a controller is disposed with its widget, never while the route is still
  animating out. (The earlier `whenComplete(controller.dispose)` crashed the app with
  `A TextEditingController was used after being disposed` plus a framework `_dependents.isEmpty`
  assertion.)

- **Add time is a picker.** The timer's *Add time* opens `durationDialog` (hour/minute/second
  columns); the confirmed total goes to the store's logged seconds. Zero is refused.
- **Focus blocking is native.** `FocusAccessibilityService` (Kotlin) draws a
  `TYPE_ACCESSIBILITY_OVERLAY` window over the packages listed in the `habit_focus` prefs, which
  the Flutter side writes through `accrue/focus` when a timed habit starts, when time is
  added and when it pauses or ends. The service only handles `TYPE_WINDOW_STATE_CHANGED`, ignores
  systemui and IME windows, and hides on our own activity — the overlay's own window reports this
  package as a `FrameLayout`, so only a class name containing `Activity` counts as "the user came
  back". The grant is per-install: force-stopping the app or reinstalling drops it, and the
  profile row says so.
- **The overlay is not focusable** (`FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL`), so blocked apps
  keep their own input state; the pill is the only interactive target.
- **UiAutomation steals the overlay.** Any `uiautomator`/agent-device snapshot registers
  UiTestAutomationService, which removes accessibility overlay windows; screenshots taken after a
  snapshot therefore look unblocked. Capture with a plain screencap instead.
- **Appearance and week start are inline dropdowns.** `SettingsSelect` expands its options
  under the row (chevron flips, selected option in the accent with a check) and closes on pick or
  a second tap; only one is open at a time. Reminders and reminder time are unchanged.
- **About is a screen**, pushed from the profile row, and the version and studio strings live in
  `lib/screens/about_screen.dart` (`appVersion = '2.1'`, `studioName = 'Wrong Turn'`). The page
  credits the studio under the version and in the footer, and the Android launcher label is
  "Accrue".
- **Distracting apps rows toggle on tap** anywhere in the row, not only on the switch.

## Verification

- `flutter analyze` — no issues.
- `flutter test` — 29/29 pass (the profile test now walks the Appearance pop-up).
- Debug APK installed on the Android 15 emulator and walked end to end: onboarding, check/count/timer,
  counter detail, routine runner, rename/create/delete, reminder time, week start, appearance, the
  Android share sheet, and state after a force-stop and relaunch.
- Re-walked on the emulator after the mark picker, increment and nav changes: icon search
  ("footprints" → 1 icon), badge typed as `wa` → `WA` on the Ocean gradient, target typed as 8,000,
  increment typed as 250 (one `+` logs 250), badge rendered in Today and in counter detail, Edit
  pill renames the profile, pill sits flush to the edges.
- Re-walked on the Android 15 emulator after focus blocking: accessibility granted, Clock
  selected in Distracting apps, timer started → overlay over Clock ("FOCUS MODE / Gym / 5 min
  left"), countdown ticking (4 → 3 min), pill opening the app and lifting the overlay, overlay
  returning when Clock came back, and cleared when the timer paused. `Add time` picker confirmed
  1h 37m + 1h 25m = 3h 2m. About shows Version 2.1. Screenshot: `screenshots/20-focus-blocked.png`.

## Repository and releases

- The repo is `github.com/asterxsk/accrue`; the Android package is `com.wrongturn.accrue` and the
  display name is **Accrue** (launcher label, About, share subject).
- Icons come from `C:/Users/p/Downloads/accrue-enso-icon` (clay enso, transparent): Android mipmaps and the adaptive
  icon; the in-app mark is `lib/widgets/brand_mark.dart`.
- `.github/workflows/release.yml` builds a release APK on tag `v*` or `workflow_dispatch` and
  attaches it as `accrue-<version>.apk`.
- **Stable signing.** `android/app/build.gradle.kts` reads `android/key.properties` (git-ignored)
  and signs with the release keystore when it exists, else falls back to the debug key. CI writes
  that file from secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`)
  before building; the workflow fails when the keystore secret is missing so an unsigned debug-key
  build cannot slip out. Certificate: `CN=Wrong Turn, OU=Accrue`, SHA-256
  `09fbb2aff8aa99cb7633bfe08180dea1f8364119e556b50252b127c7a11b80dc`. Local keystore:
  `C:/Users/p/.accrue/accrue-release.jks` (password in `keystore-password.txt` beside it). Back it
  up — losing it ends update-over-install for everyone.
- v2.1.1 is the first build on that key: installs of 2.1.0 (debug-key signed) must be uninstalled
  once.
- Data key stays `habit_tracker.state.v2` so installs from before the rename keep their habits.
