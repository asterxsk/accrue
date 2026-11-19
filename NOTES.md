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
| `lib/widgets/` | Icon set (inline SVG + full Lucide library), controls, habit row, habit mark, nav pill, popup menu, dialogs, wheel picker, share poster, celebration (confetti) |
| `lib/screens/` | Onboarding, Today, counter detail, timer, routine run, new habit, mark picker, Insights, Routines, Profile, Updates, `home_shell.dart` |
| `lib/util/updates.dart` | `UpdateController`: GitHub release list, version compare, APK download with SHA-256 and size check, install hand-off |
| `lib/util/sfx.dart` | Two bundled sounds — `pop.wav` for a completed habit, `tick.wav` for each wheel row (`audioplayers`, low-latency, failures swallowed) |
| `assets/sounds/` | `pop.wav` (cannon report: noise crack, 150→45 Hz thump, air tail) and `tick.wav` (3.5 ms click) |
| `lib/app_nav.dart` | `AppNav` + `AppNavScope` so pushed screens can switch tabs |
| `lib/widgets/icon_library.dart` | Generated: 1,865 Lucide icon bodies + sorted names (`tool/gen_icons.py` regenerates it) |
| `tool/gen_icons.py` | Converts a local `lucide-static` package into `icon_library.dart` |
| `test/widget_test.dart` | 31 unit/widget tests |
| `screenshots/` | 390×867 dark Android captures (01–11) |

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
   does not apply. Where no share target exists the caption goes to the clipboard and the
   snackbar says so. Exporting the poster as an image still needs a plugin.
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
- **Appearance and week start are inline dropdowns.** `SettingsSelect` expands its options
  under the row (chevron flips, selected option in the accent with a check) and closes on pick or
  a second tap; only one is open at a time. Reminders and reminder time are unchanged.
- **About is a screen**, pushed from the profile row, and the version and studio strings live in
  `lib/screens/about_screen.dart` (`appVersion = '2.4'`, `studioName = 'Wrong Turn'`). The page
  credits the studio under the version and in the footer, and the Android launcher label is
  "Accrue".
- **Updates are manual.** Nothing polls. The profile's corner button spins while
  `UpdateController.check()` reads `api.github.com/repos/asterxsk/accrue/releases`, turns into an
  accent download glyph when a newer tag exists, and otherwise shows an accent check plus "No
  updates" for two seconds before settling back to the refresh glyph; it also opens the Updates
  page, which lists earlier releases and downloads on demand. The APK streams into
  `cacheDir/updates` with progress, then must match the release asset's `digest` SHA-256 and byte
  size before the install button appears — that check exists because a truncated transfer is what
  Android reports as "problem parsing the package". The native side (`installApk`) opens the
  unknown-sources settings page on first use and otherwise hands the file to `ACTION_VIEW` through
  `${applicationId}.fileprovider`.
- **A spent API quota is not an outage.** GitHub allows 60 unauthenticated calls an hour per IP, and
  a 403 used to surface as "could not reach GitHub". The API is tried first because it carries each
  asset's SHA-256; when it answers 403/429 the public `releases.atom` feed is read instead, the
  asset URL is built as `releases/download/<tag>/accrue-<version>.apk`, and the download is proven
  by its ZIP structure (local header up front, end-of-central-directory record in the tail). The
  `X-RateLimit-Reset` time is honoured, so later checks go straight to the feed until it refills.
- **Completing a habit fires two confetti cannons** from the top corners of an `OverlayEntry` above
  all routes for 1.5 s, and plays `assets/sounds/pop.wav` — a noise crack, a 150→45 Hz thump and an
  air tail, not a chime. Both hang off `HabitStore.celebration`, a `ValueNotifier<int>`
  that `_mutate` bumps only when a habit crosses from not-done to done on today, so a row tap, a
  `+`, a typed count, a finished timer and the routine runner all trigger it exactly once.
- **Wheels tick.** `WheelPicker` plays `assets/sounds/tick.wav` on every selected-row change, so the
  reminder clock and the *Add time* columns click their way past each value. `Sfx` keeps one
  low-latency player per asset and drops ticks closer than 45 ms apart, which is what a fast flick
  produces; without that the clicks blur and the player falls behind.

## Verification

- `flutter analyze` — no issues.
- `flutter test` — 31/31 pass, including the Atom feed fallback and version comparison.
- Debug APK installed on the Android 15 emulator and walked end to end: onboarding, check/count/timer,
  counter detail, routine runner, rename/create/delete, reminder time, week start, appearance, the
  Android share sheet, and state after a force-stop and relaunch.
- Re-walked on the emulator after the mark picker, increment and nav changes: icon search
  ("footprints" → 1 icon), badge typed as `wa` → `WA` on the Ocean gradient, target typed as 8,000,
  increment typed as 250 (one `+` logs 250), badge rendered in Today and in counter detail, Edit
  pill renames the profile, pill sits flush to the edges.
- Release APK (2.3.0) signed with the stable key installed over the previous build and walked on the
  emulator after the wheel picker, share poster, updater and celebration changes: hour wheel wraps
  both ways, 12-hour mapping matches the label, *Add time* opens at 00:00:00 on three wheels,
  checking from the profile corner spins → accent check + "No updates. You are on the latest build."
  for two seconds → back to the refresh glyph, and ticking a habit fires confetti and the pop.
  With the host IP's API quota spent (403), a check still resolved through the Atom feed,
  listed 2.3.0 back to 2.1.0, and downloaded 2.2.1 to an Install button.

## Repository and releases

- The repo is `github.com/asterxsk/accrue`; the Android package is `com.wrongturn.accrue` and the
  display name is **Accrue** (launcher label, About, share subject).
- Icons come from `C:/Users/p/Downloads/accrue-enso-icon` (clay enso, transparent): Android mipmaps and the adaptive
  icon; the in-app mark is `lib/widgets/brand_mark.dart`.
- `.github/workflows/release.yml` builds a release APK on tag `v*` or `workflow_dispatch` and
  attaches it as `accrue-<version>.apk`, with `accrue-<version>.apk.sha256` beside it.
- **Both signature schemes.** AGP drops the v1 (JAR) signature once `minSdk` reaches 24, and that
  v2-only APK is what a real phone can answer with "There was a problem parsing the package" even
  though the build is intact. `enableV1Signing` and `enableV2Signing` are both on, and the workflow
  refuses an APK where either scheme fails to verify, where the certificate is not the release key,
  where the package, versionName or versionCode disagree with `pubspec.yaml`, where the manifest's
  `minSdkVersion` is not 24, or where `zipalign -c -p 4` fails.
- **Stable signing.** `android/app/build.gradle.kts` reads `android/key.properties` (git-ignored)
  and signs with the release keystore when it exists, else falls back to the debug key. CI writes
  that file from secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`)
  before building; the workflow fails when the keystore secret is missing so an unsigned debug-key
  build cannot slip out. Certificate: `CN=Wrong Turn, OU=Accrue`, SHA-256
  `53dfdd44b0377a07746e4c3ed8540bcd95038670d13aaeb0a3a8b8622d78182c`, alias `accrue-v2`,
  RSA-4096, valid to 2054-04-05. Local keystore: `C:/Users/p/.accrue/accrue-release-v2.jks`, with
  both passwords in `accrue-release-v2.credentials.dpapi` (Windows DPAPI, bound to this user and
  machine — export it with `ConvertFrom-SecureString` on this account only). Back both up — losing
  them ends update-over-install for everyone.
- The key was rotated on 2026-11-18 after the previous keystore and its passwords were exposed.
  The old key (`accrue`, SHA-256 `09fb…80dc`) is retired and its local copies are deleted.
- v2.1.1 is the first build on the old key; v2.5.0 is the first on the current one. Both are
  install breaks: uninstall the previous build once, then updates are stable again.
- Data key stays `habit_tracker.state.v2` so installs from before the rename keep their habits.
