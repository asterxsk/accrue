# PRD — Accrue

Version 2.0 · 14 November 2026 · Source of truth for the shipped build in `lib/`
Companions: `README.md` (run/layout), `NOTES.md` (divergences),
`design/habit-tracker-prototype.html` (the design this build follows).

---

## 1. Summary

A quiet, local-only habit tracker for phone. It tracks three kinds of habit — check-off, counted,
timed — plus routines that are simply habits in order, and reports the week back as one completion
figure, seven bars and the streaks still running. A small local profile and a share poster round it
out. Data lives on the device; there is no account, no sync, no network.

Built with Flutter (Dart 3.13) for Android, styled to the Claude design system:
parchment light theme and a tuned dark theme, clay accent, serif display type, floating pill
navigation, onboarding on first launch.

---

## 2. Problem and intent

Habit apps tend to demand attention: badges, notifications, social feeds, gamified streaks that
punish a missed day. This one inverts that. It should be openable in two seconds, show one honest
number, take one tap, and get out of the way.

Design principles, in priority order:

1. **One number, one action.** Each screen leads with the single fact it exists to state.
2. **No invented data.** Every figure (percent, streak, best) is computed from recorded history.
3. **State is legible without colour.** Done, current and broken states differ in fill, ring and
   text tone together.
4. **Nothing is confirmed twice, and nothing destructive is one tap.** Destructive actions ask first.
5. **The app never pretends.** Reminders that cannot be delivered say so; sharing copies a caption
   and says so.

---

## 3. Users

| Persona | Need |
|---|---|
| The single-tracker (primary) | Three to eight daily habits, mixed kinds, checked in under 30 seconds |
| The routine keeper | A fixed sequence (morning, evening) run without thinking about order |
| The streak watcher | The current run and the best run visible, and an honest "broken" |
| The reviewer | A weekly read: completion, movement vs last week, which habits are holding |

Single-user, local-only. No roles, permissions or multi-tenant concerns.

---

## 4. Goals and non-goals

**Goals**

- Track check, count and timer habits with per-habit targets and units.
- Run routines as ordered habit sets, with per-step state, reset and editing.
- Onboard on first launch: name, which habits to start with, which routines.
- Archive each finished day and derive completion, trend, current streak and best streak from it.
- Survive day rollover, process kill, resume and unreadable stored state without losing data
  silently.
- Look deliberate and calm in dark and light, from a 320pt phone to a wide desktop, with a 430pt cap.

**Non-goals (v1)**

- Accounts, cloud sync, multi-device, social feeds.
- Delivered push notifications (intent is stored only — no notification plugin).
- Photo avatars (plugin symlinks unavailable on this build machine; initials are used).
- PNG export of the share poster (a caption is copied instead).
- Backfilling history, per-habit reminder times, tags, widgets, watch apps.
- Localisation (English strings only; `Fmt` is the single seam for a future locale layer).
- Import/export of the data file.

---

## 5. Information architecture

```
HomeShell (IndexedStack; floating 4-item pill: Today · Insights · Routines · Profile)
├── Today     (tab 1) → Counter detail · Timer · Routine run · New/Edit habit · Habit ideas
├── Insights  (tab 2) → Share poster
├── Routines  (tab 3) → Routine run · Routine editor · New routine
└── Profile   (tab 4) → Share poster · Appearance · Reminders · Data & export · About · Edit name pill

Pushed screens: Counter detail · Timer · Routine run · New/Edit habit · Mark picker
First run: OnboardingScreen (name → habits → routines), no shell until finished.
```

`HomeShell` keeps each tab's scroll position. The pill floats above content on all four tabs; every
pushed screen carries a 44pt back control instead, so "pill visible" means "you can switch tabs from
here." `AppNavScope` lets a pushed screen or dialog switch tabs (e.g. clearing data returns to Today).

---

## 6. Data model

```
Habit   id, name, kind(check|count|timer), icon, target, unit, step,
        badge, badgeText, badgeFg, badgeStart, badgeEnd,
        count(today), seconds(today), checked(today)
Routine id, name, habitIds[]           // ordered references to habits
Store   habits[], routines[], history{dateKey → habitIds}, dayKey,
        profileName, onboarded, themeMode,
        remindersOn, reminderHour, reminderMinute, weekStartsMonday
```

- `target` means: 1 for check habits, count units for count habits, **minutes** for timer habits.
- "Done" is derived, never stored per day: `checked` / `count >= target` / `seconds >= target*60`.
- `history` holds only past days, and only the ids that were done — enough for streaks and weeks.
- A routine owns no steps of its own: its steps are habits, so one habit can sit in several
  routines and deleting it removes it from all of them.
- Single storage key `accrue.state.v2` in `shared_preferences`, JSON encoded.

---

## 7. Features

### F1 — Onboarding
**What.** Three steps on a fresh install, with a dots progress indicator in the header.

1. **Name.** Welcome title, "A name makes this app personal", initials avatar preview, name field.
   Continue is disabled until the name has a non-space character.
2. **Habits.** "Start with a few" — five starter cards (Water 8 glasses, Gym 45 minutes, Read once,
   Walk 8,000 steps, Sleep by 11), each toggled on by default, plus "Add your own habit" (opens the
   habit form) and "Browse habit ideas".
3. **Routines.** "Then a routine" — Morning (Water, Read) and Evening (Walk, Sleep by 11), each
   optional. Finish setup.

**Rules.** Finishing writes the selected habits and routines, marks the app onboarded and lands on
Today with an empty day. Back moves one step; nothing is written until Finish. A fresh install has
no sample data.

### F2 — Today
**What.** Eyebrow date ("Sat, 14 November"), title "Today". Then the day's number: **"N of M done"**
with a percentage on the right and a progress track. Then **Habits** — one row per habit — a dashed
**New habit** row, and a **Routines** section of compact cards (only when routines exist).

**Rules.**
- Completion = habits done ÷ habits total; 0 when there are no habits.
- Rows render in creation order; nothing reorders by state.
- With no habits the empty state renders: "A clean start", a short explanation, a primary
  **Create a habit** button and a **Browse habit ideas** link.
- A compact routine card shows done/total, the steps in one line and a chevron into the runner.

### F3 — Habit kinds and rows
| Kind | Subtitle | Leading | Trailing | Row tap |
|---|---|---|---|---|
| Check | `N-day streak` / `Done today` / `Once a day` / broken-streak warning | 44pt ring + mark | — | toggles the tick |
| Count | `6 of 8 glasses` | 44pt ring + mark | inline − / value / + (44pt, logs `step`) | opens Counter detail |
| Timer | `20m of 45m` | 44pt ring + mark | — | opens Timer |

**Rules.**
- "Mark" is the habit's icon from the Lucide library, or its text badge on a gradient.
- Inline − is disabled at 0, + at target; the store guards the same bounds and moves by `step`.
- The ring arc is the habit's progress; the icon turns clay when the habit is done.
- Rows expose a toggle semantic for check habits and a button semantic for all.
- A broken streak is only reported when the habit has history and missed both today and yesterday.
- Each row's "more" button opens an anchored menu: Edit habit, Delete habit.

### F4 — Counter detail
**What.** A clay-tinted disc with the icon, the name in serif, the target line ("8 glasses a day"),
the count as a 56pt numeral over the unit, a **unit dot row** (one dot per unit, filled as counted),
64pt − / + controls, and two cards: **Current streak** with best, and **This week**.

**Rules.**
- Up to 60 units draw as dots that shrink to fit; above 60 the disc becomes a proportional rail with
  the count and target, so an 8,000-step habit stays legible.
- Best streak walks all history, not just the current run.
- The week row of seven dots fills from history; today is an accent ring until done.
- The "more" menu edits or deletes the habit.

### F5 — Timer
**What.** A timer surface: the habit name, a 244pt ring showing elapsed over goal, the clock
(`0:20:00`), a 72pt accent start/pause control, a goal card (target on the left, logged on the
right) and a ghost **Add 30 minutes** action.

**Rules.**
- Elapsed time is read from the wall clock against a base count, not accumulated from ticks, so
  backgrounding or a sleeping tab never drifts.
- One timer runs at a time, app-wide; starting another rebases cleanly.
- The running state is in memory only. Logged seconds persist; time since the last save is not
  recovered after a kill, and a rollover stops the timer and credits what was logged.
- Seconds are capped at 24h.
- While running, a 1-second ticker exists (created only when a timer runs) and state is written every
  10 seconds.

- *Add time* opens the hour/minute/second picker (see F15) rather than adding a fixed 30 minutes.

### F6 — Routines
**What.**
- **Routines tab:** each routine as a large card — done/total disc, name, step count, a state line,
  and the ordered steps with done / current / upcoming state. Dashed **New routine**, and a menu per
  card to edit or delete.
- **Routine run:** a segments bar (one segment per step), then rows for every habit in order with a
  tap-to-complete affordance, then a completion card when everything is done, and a ghost **Reset
  today** (with confirmation) once there is progress.
- **Routine editor** (`routineEditorDialog`): name plus a habit picker, returning name and ordered
  habit ids.

**Rules.**
- A routine with no habits shows an empty card with **Add habits** rather than a dead action.
- Reset today clears the day's habits in that routine and confirms first.
- Deleting a routine leaves its habits alone; deleting a habit removes it from every routine.
- Routine progress is derived from the habits' today state, so it clears on rollover with them.

### F7 — New / Edit habit
**What.** Name field (autofocused), "Browse habit ideas", a **Mark** row (preview, label, and a
**Choose** button into the mark picker), three kind options (Check off / Count / Timer, each with a
description), a target stepper, an **Each tap adds** increment stepper for counted habits, a unit
field for counted habits, and a sticky footer (**Create habit** / **Save changes**). Editing adds
**Delete habit**.

**Rules.**
- Kind decides the row affordance, so it is chosen up front; switching kind resets the target to
  that kind's default (check 1, count 8, timer 30).
- Target range 1–100,000. Steppers widen their stride as the number grows (1 → 10 → 100), and
  tapping the number opens a typed entry, so 8,000 steps is four digits rather than 7,992 taps.
- **Increment** (`step`, default 1) is how much one tap of − / + logs for a counted habit; it is
  clamped to 1…target, and the row subtitle reads "N of M steps" the same either way.
- **Mark picker** (`MarkPickerScreen`): an Icon / Text badge switch.
  - *Icon*: search across 1,865 Lucide icons with a live result count and a selection grid.
  - *Text badge*: 1–2 characters, forced uppercase and filtered to letters and digits, a live
    preview disc, ten text colours, ten background gradients, and the hint "Two letters read best".
  - The choice applies to the habit's row ring, counter detail disc and routine steps.
- Unit is free text for counted habits ("glasses", "pages"); a timer uses minutes and a check habit
  has no unit.
- Name is trimmed and inner whitespace collapsed; Create is disabled while empty.
- Delete asks first, then removes the habit, its history references and its routine memberships.
- The page states that reminders are stored as intent only.

### F8 — Insights
**What.** Eyebrow week range, title "Insights", a **Share** action. A hero card: **week completion
percent**, a trend pill (`+23%` up, `−5%` down, `0%` flat), and "completion this week". Then **Daily
completion**: a 150pt bar chart with a 100/50/0 axis, a baseline, one bar per weekday, today's bar in
accent, and weekday letters under the bars. Then **Streaks**: habits with a running streak, highest
first, as "N days".

**Rules.**
- Week completion = done ÷ (habits × elapsed days in the week), not a projection of the full week.
- Trend compares the same elapsed span against the matching span of the previous week.
- Future days draw nothing; a day with nothing done draws no bar.
- Streaks lists only non-zero runs.
- With no habits the screen renders an empty state instead of a zeroed chart.

### F9 — Routines tab
Covered by F6. New routine opens the same editor as editing, starting empty.

### F10 — Profile

Settings rows that hold a short list (Appearance, Start week on) are inline dropdowns: tapping the
row expands the options beneath it, the open row flips its chevron, the current value carries the
accent and a check, and choosing closes the list. Only one dropdown is open at a time. The About
row pushes a full screen that shows the version (read from the installed package), the studio
(Wrong Turn), what the app does and the licences.
**What.** A profile card (initials avatar, name, "Local profile · nothing syncs, nothing leaves.",
and an **Edit** pill that opens the name dialog), a **Share stats** button, then grouped rows:

| Row | Behaviour |
|---|---|
| Appearance | Cycles System → Light → Dark; the value states the current mode |
| Reminders | Toggle; stores intent only |
| Reminder time | Opens the app's own hour/minute picker; default 08:00 |
| Start week on | Two-option dialog (Monday / Sunday), selected state marked |
| Data & export | Dialog: **Clear all** (habits, routines, history; profile and settings stay) and **Reset app** (everything, back to onboarding) — both confirm first |
| About | Dialog: v1.0, local-only, no account, no sync |

**Rules.** Week start affects every week-derived view: the trend maths, chart, range and week labels.
Nothing destructive happens without the app's own dialog and a destructive confirm label.

### F11 — Share
**What.** **Share stats** opens a dialog with a 4:5 poster: the week range, name, completion percent
with trend, four stat tiles (today, best streak, habits, routines), the week's bars and the top
streaks. **Share** opens the system share sheet (Android, via a method channel) carrying the week's
caption as text. Where no share target exists it copies the caption and the snackbar
says so. **Cancel** closes.

**Rules.** The poster is drawn natively, not a screenshot. No image file is produced (a PNG export
needs a plugin this build cannot add). Share never fails silently: if the sheet cannot open, the
caption is copied instead.

### F12 — Persistence, restore and rollover
**What.** Every mutation writes the whole store to `accrue.state.v2`.

**Rules.**
- **Rollover:** on load, on resume and before **every** day-scoped write. The finished day's done
  habit ids are archived to `history`, then ticks, counts and seconds reset and a running timer
  stops. Mutators roll first, so a first tap after midnight lands on the new day.
- **Calendar date maths** (`Fmt.addDays`): a DST change cannot shift a day.
- **Restore is defensive.** An unreadable blob is copied to `accrue.state.unreadable`, and
  nothing is overwritten. Rows are parsed individually: one unreadable habit or routine is dropped;
  the rest still load.
- Unknown or missing optional fields fall back to defaults (target 1, unit "", system theme, 08:00,
  Monday start).

### F13 — Theme, type and system chrome
- Two token sets (`AppColors.light`, `AppColors.dark`) exposed as a `ThemeExtension`; a type scale
  (`AppType`); layout metrics (`Metrics`); `AppTheme` builds both `ThemeData`s.
- Type: Source Serif 4 (variable, weight 500) for titles; Inter 400/500/600 for UI; tabular figures
  for numbers.
- Radii: 8 controls, 12 cards and rows, 16 dialogs and large surfaces.
- Colour carries meaning: clay for action and progress, warn for a broken streak, faint for absent.
- The Material grey hover/press wash is off; interaction shows as a faint clay tint.
- Page pushes fade with a 12pt rise — the same surface with a back control, not an effect.

### F14 — Accessibility and layout robustness
- Every interactive element meets a 44pt minimum (back, menu, steppers, dialog actions, option rows).
- Semantics: check rows expose toggled state; buttons expose labels; the nav item exposes selected.
- Text scales: rows ellipsize rather than overflow; the count value never clips; the pill scales down
  under cramped text instead of overflowing.
- Layout verified at 390×844 and at 320pt wide; content is capped at 430pt on wide surfaces.

---

### F15 — Add time picker (timed habits)

"Add time" on the timer opens a picker instead of adding a fixed 30 minutes. It is the same
three-column control used for the reminder time: hour, minute and second each with up and down
targets, clamped at 0..23 / 0..59 / 0..59, and a live summary ("Adds 1h 25m to today."). The
confirmed duration is added to the habit's logged seconds for the day; zero is refused so the
button cannot log nothing.

### F16 — Stopwatch and countdown timers

The *Track it as* list names the timed kind **Time**. Choosing it reveals a **Timer type** row
above the daily target: a Stopwatch / Timer segmented control, the same in-row toggle the
Insights page uses for Week / Month / Year.

**Stopwatch** counts up from zero, has no daily target (the target row is hidden and the habit
stores `target: 0`), shows the time logged, and marks the day done once any time is logged.
**Timer** counts the daily target down and shows what is left ("17:56 left of 30 min"), completing
at zero. The mode is stored with the habit as `timerMode` and survives export, import and restore;
habits saved before the field existed load as `timer`.

## 8. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | Idle app runs no ticker. A running timer costs one 1s tick. Store writes are async and non-blocking. |
| Reliability | No day is lost across midnight, resume, kill or corrupt storage. Unreadable data is preserved. |
| Storage | Single `shared_preferences` string; full snapshot per mutation. |
| Platforms | Android 7.0+ (API 24). `flutter build apk --release` shipped from CI. |
| Quality gate | `flutter analyze` clean; `flutter test` 19/19. |
| Privacy | No network calls, no analytics, no account. Dependencies: `flutter_svg`, `shared_preferences`. Android share uses a `MethodChannel` intent, not a plugin. |
| Localisation | English only; all user-facing strings route through widgets/`Fmt`. |

---

## 9. Known limitations (as shipped)

1. **No notification delivery.** Reminders persist intent only (F10).
2. **No photo avatar.** Initials only, because `image_picker` cannot be added on the build machine.
3. **No image export.** Share sends or copies a caption; the poster is displayed, not saved as a
   file.
4. **`createdAt` is not stored.** Adding a habit retroactively changes past days' completion
   percentages.
5. **The running timer is not restored** after a process kill; logged seconds are.
6. **No backfill.** History only accrues forward from real use.
7. **No import/export** despite the "Data & export" label.
8. **One timer at a time**, app-wide.
9. **Adding a plugin fails on the build machine** ("Building with plugins requires symlink support" —
   Developer Mode is off). `flutter pub get`, analysis, tests and Android builds still work.
10. Not a git repository as of this document.

---

## 10. Roadmap candidates

Ordered by what unblocks the most truth:

1. **Real reminders** — `flutter_local_notifications`, per-habit times, a permission flow that states
   failure honestly.
2. **Habit lifecycle** — `createdAt`, archive/soft-delete, and a repair of the retro-completion
   inflation.
3. **Poster export** — rasterise the poster to a PNG and share it through `share_plus`.
4. **Photo avatars** — `image_picker`, cropped to the disc.
5. **Export/import** — a JSON file, so the data is portable without a server.
6. **Backfill** — mark a past day done from a day sheet.

---

## 11. Open questions

- Should a missed day break a streak immediately, or keep a one-day grace? (Currently: the streak
  survives until today ends, then breaks.)
- Should routines count toward the day's completion number? (Currently: no — habits only.)
- Is a habit's weekly target (e.g. 5 of 7 days) in scope, or is daily-only the product boundary?
- Should "Data & export" be renamed until export exists, or should export ship first?
