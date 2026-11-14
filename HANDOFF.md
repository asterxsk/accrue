# Handoff — habit tracker (Flutter app)

## Context

- Working dir: `D:\Apps\projects\habit_tracker` (not a git repo).
- The app was rebuilt to a new design prototype: `design/habit-tracker-prototype.html` (kept
  verbatim). The previous design (`design/archive/habit-tracker.figcraft` + its renders) is
  discarded and archived, not deleted.
- Flutter 3.47.9 / Dart 3.13.7 at `D:\Apps\tools\flutter\bin\flutter.bat` (not on PATH).
- Adding a plugin (e.g. `image_picker`) fails on this machine with "Building with plugins requires
  symlink support" — Developer Mode is off. `flutter pub get` (0), analyze, tests and
  `flutter build web` all work.

## User messages

1. "Make a Flutter application with this design." (earlier thread; previous design, now replaced).
2. `/handoff` (previous session).
3. "[HANDOFF.md](HANDOFF.md) continue" (previous session: finished and reviewed the previous design).
4. `[index.html] Apply this design to the app. Discard previous design.` — this session: rebuilt the
   app to the new prototype.

## What exists

- **Theme** (`lib/theme/`): `AppColors` light/dark token sets as a `ThemeExtension`, `AppType`
  (Source Serif 4 titles, Inter UI, tabular figures), `Metrics` (gutter 20, max width 430, radii
  8/12/16, pill 78 with 64pt buttons and a 12pt side gutter), `AppTheme` with dialogs, snackbars,
  fade-page transitions and no grey Material hover wash.
- **Models** (`lib/models/habit.dart`): mutable `Habit` (check/count/timer), `Routine` (habit ids),
  `starterHabits`, `starterRoutines`, `habitIdeas`.
- **Store** (`lib/state/habit_store.dart`): day state, history, streaks/best, week percent/trend/series,
  running streak list, timer on a wall clock, settings, `shared_preferences` key
  `accrue.state.v2`. Rollover archives the finished day before resetting; restore is
  row-tolerant and backs up an unreadable blob.
- **Widgets** (`lib/widgets/`): inline SVG icon set plus the generated 1,865-icon Lucide library
  (`icon_library.dart`), header/nav/buttons/cards/fields/steppers/switch, habit row with progress
  ring, `HabitMark` (icon or gradient text badge), routine cards, nav pill, anchored popup menu,
  all dialogs, share poster.
- **Screens** (`lib/screens/`): onboarding (name → habits → routines), Today, counter detail, timer,
  routine run, new habit, mark picker (`icon_picker_screen.dart`), Insights, Routines, Profile;
  `home_shell.dart` owns the `IndexedStack` and
  the pill. `lib/app.dart` owns theme resolution and the ticker; `lib/app_nav.dart` lets pushed
  screens switch tabs.
- **Tests**: `test/widget_test.dart`, 23 tests (store + widgets, including 320pt layout).

## This session

- Rebuilt theme, widgets and every screen to the prototype; onboarding-first flow replaces the old
  settings screen and seeded demo data.
- Fixed two visual defects found in the browser: Material grey hover wash (now transparent hover,
  clay highlight/splash) and a clipped "3,000" count value (count cell widened to 48).
- Archived the previous design and screenshots; copied the prototype into `design/`.
- Rewrote `NOTES.md` and `README.md` for the new design.

## Emulator pass and bugs fixed

- **Share did not use Android.** The dialog only copied a caption. Added `lib/util/share.dart` plus a
  `accrue/share` `MethodChannel` in `MainActivity.kt` that fires `ACTION_SEND` through a
  chooser; the dialog's primary is now **Share**. Verified on the Android 15 emulator: the system
  sheet opens with the week's caption. Web/desktop still fall back to copying and say so.
- **Huge count targets drew a wrapped dot grid.** An 8,000-step habit rendered 40 dots in two rows,
  contradicting the documented rail. `_UnitDots` now draws one proportional rail above 60 units.
- **Buttons exposed as plain groups to accessibility.** `AppButton`, `HeadAction` and tappable
  `SettingsRow`s now carry button semantics (Share, Cancel, settings rows read as buttons on Android).
- **A host that never answers the share channel** could leave the dialog stuck; `NativeShare.text`
  now times out after 4s and falls back to the clipboard.
- Added a widget test for the share dialog's copy fallback.

## Feature pass after the emulator run

- **Full icon library.** Lucide 0.544.0 (ISC) converted into `lib/widgets/icon_library.dart`
  (1,865 icons, inner SVG markup + sorted names) by `tool/gen_icons.py`; no asset files ship.
- **Mark picker** (`MarkPickerScreen`): Icon/Text badge switch, live icon search with counts and an
  empty-state line, and a 1-2 character badge with auto-uppercase, ten text colours and ten
  gradients. Rendering goes through `HabitMark` in rows, counter detail and the form preview.
- **Custom increment.** `Habit.step` (1..target) drives the row and detail steppers; the form's
  TargetStepper has an `onTapValue` typed entry and strides 1 -> 10 -> 100, so 8,000/250 is a few
  digits. Target clamp raised to 100,000.
- **Nav pill** is edge-to-edge minus a 12pt gutter, 78pt tall, 6pt above the safe-area bottom.
- **Edit name** moved into an Edit pill on the profile card; About keeps only the version row.
- **Crash fixed.** `nameDialog`/`numberDialog` disposed their controller with
  `whenComplete(controller.dispose)`, so tapping Set target threw `A TextEditingController was used
  after being disposed` and then the framework `_dependents.isEmpty` assertion (red screen). Both
  now build a stateful `_EntryDialog` that owns the controller.
- **Badge colour drives progress.** `markAccent(habit, fallback)` returns the badge's gradient
  start colour, used by the row ring, the counter-detail rail/dots/week marker, the routine step
  dots and the timer ring, so a blue "WA" badge gets a blue progress line. Icon habits stay clay.
- The share poster's bar column overflowed by 2.9pt ("BOTTOM OVERFLOWED BY 2.9 PIXELS" over the
  preview): the bars were fixed 26pt inside a stretched `Row`. `_PosterBar` now measures the space
  it is given and sizes the bar and the weekday label slot to fit.
- The counter-detail rail never painted its fill (`FractionallySizedBox` under a tinted
  `Container`); it is now a two-layer `Stack`. The row's count cell also scales itself instead of
  letting "1,000" run over the minus button.
- Text-colour swatches and icon tiles carry semantics labels; "1 icons" now reads "1 icon"; an
  empty icon search explains itself.

## Focus blocking and settings pass

- **Add time picker.** The timer's fixed "Add 30 minutes" button is now *Add time*, opening the
  hour/minute/second picker from the reminder dialog family (`durationDialog`), with live
  "Adds X to today." copy.
- **Focus blocking.** New `FocusAccessibilityService` (Kotlin, accessibility overlay) plus
  `lib/util/focus.dart` (channel `accrue/focus`) and
  `lib/screens/distracting_apps_screen.dart` (search, per-app switches, permission card, consent
  dialog, grant adopted on resume). `HabitStore.blockedApps` persists with the state; the timer
  starts, re-arms and stops blocking. Overlay: FOCUS MODE / habit / minutes left / "Blocked while
  your focus timer runs." / *Open Accrue* pill. It is non-focusable and hides on our own
  activity; a 1s tick notices a torn-down overlay and re-arms it.
- **Settings are inline dropdowns.** `SettingsSelect` expands Appearance (System/Light/Dark) and
  Start week on (Monday/Sunday) under the row instead of opening a dialog; Reminders and Reminder
  time are unchanged.
- **About is a full screen** (`lib/screens/about_screen.dart`) with Local only / What is inside /
  Focus blocking / Reminders / Licences, the version **2.1**, and the studio credit
  **Wrong Turn** under the title and in the footer. The Android launcher label is now
  "Accrue" instead of `habit_tracker`.
- **Distracting apps rows** toggle from anywhere in the row.
- **Pop-ups sized to content.** The habit/routine action menu measures its labels instead of
  filling the screen, and short dialogs (choice lists, confirms, info) measure title/labels/buttons
  and clamp to 232–340pt with intrinsic, right-aligned buttons. Long dialogs keep the 340pt reading
  width.
- **Test updated**: the profile test opens the Appearance dropdown and picks Light.

## Verification

- `flutter analyze` — no issues.
- `flutter test` — 23/23 pass.
- `flutter build web --release` — succeeds; served locally and captured at 390×844 in Chrome:
  onboarding steps 1–3, Today, Insights, Routines, Profile, counter detail, timer, routine run, new
  habit, habit ideas, share poster, dark Profile and dark Insights. Fresh captures are in
  `screenshots/`; captures of the replaced design are in `screenshots/archive-old-design/`.
- Debug APK (`flutter build apk --debug`) installed on the Android 15 emulator
  `stock_phone_play` (emulator-5554), walked end to end: onboarding, check/count/timer habits,
  counter detail, routine runner, rename/create/delete, reminder time, week start, appearance, the
  native share sheet, and state after force-stop + relaunch.
- Focus blocking verified on the emulator: grant → Clock blocked → overlay persists and counts
  down → pill opens the app → overlay returns over Clock → pause clears it. `Add time` picker,
  Appearance pop-up, About (Version 2.1) and the row-tap toggle all checked on device. Note:
  agent-device/uiautomator snapshots unregister accessibility overlays, so the overlay must be
  captured with `adb exec-out screencap` and not after a snapshot.

## Rename, icon and release pipeline

- App renamed **Accrue**; Android package `com.wrongturn.accrue`; launcher label, About title and
  share copy updated; the About header shows the enso mark from `assets/branding/enso.png`.
- New icon set wired from the `accrue-enso-icon` folder: Android legacy + adaptive mipmaps, web
  icons/favicon, Windows ICO.
- `.github/workflows/release.yml` builds the release APK and attaches it to a GitHub release on
  tag `v*` or `workflow_dispatch`; `gh workflow run release.yml` is the release command.
- Release APKs are debug-key signed by the runner's generated keystore (installable, not
  store-ready).

## Open items

- No git repo; ask before initialising one.
- Native mobile builds were not produced (web + tests only).
- Reminders persist intent only — no notification plugin yet.
- Focus blocking depends on a user-granted accessibility service; the grant is dropped by a
  reinstall or "force stop", and nothing re-prompts from inside the app yet beyond the profile row
  state.
- The overlay copies a fixed in-app palette (clay on ink) rather than following the in-app theme.
- Photo picking and PNG export of the share poster are absent for the same plugin reason
  (documented in `NOTES.md`); the avatar is initials and sharing copies a caption.
- Habit `createdAt` is not stored, so a habit added today counts in earlier weeks' percentages.
