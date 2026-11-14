# Habit tracker — blueprint

Status: brief settled, building first direction in FigCraft.
Date: 2026-11-07

## Brief

A mobile habit-tracking app UI, designed in FigCraft as a high-fidelity screen set, styled to read
as shadcn/ui (neutral tokens, 8px radius family, Inter, restrained accent). No code deliverable.

### User decisions (confirmed)

| Question | Answer |
|---|---|
| Deliverable | FigCraft design only — no coded app in this repo |
| Platform | Mobile app, 390×844 |
| Visual character | Calm, quiet, spacious |
| Prototype count | 1 direction |

### Required capabilities

1. **Basic habits** — a habit with a simple done / not-done check.
2. **Standard tracking** — habit row with inline check and a streak.
3. **Timer tracking** — habit measured in time, running timer surface, elapsed / target.
4. **Custom tracking** — counted units, e.g. 8 glasses of water a day, increment / decrement.
5. **Routines** — ordered groups of habits, runnable as a sequence (step 1 → 2 → 3, progress).

### Non-goals

- Native code, backend, sync, auth, notifications implementation.
- Desktop layout. Phone only.
- Asset generation beyond UI glyphs available in FigCraft (vector paths, text).

## Direction (Lucent step 1)

| Dial | Value | Reason |
|---|---|---|
| Variance | 3 | A tracker is a daily tool; the layout should be learned in one use. |
| Motion | 3 | Feedback and state changes only. |
| Density | 4 | Comfortable; thumb-reachable rows, generous rhythm. |
| Mode | **Operate** | The visitor completes a task. Effect budget: none behind content. |

Feeling: calm, quiet, spacious. Paper-like white, one deep-green accent for progress, no chrome.

## Substrate (Lucent step 2)

shadcn/ui is the requested substrate. Tokens are expressed as FigCraft variables so the file is
editable as a system, not a picture of one. One kit, one token set, no second system.

## Fundamentals (Lucent step 3)

- One focal point per screen: today's completion, or the single next action inside a routine.
- Separation by spacing, not by rules, cards, or pills. Card surfaces only where a row is tappable
  as a unit and needs boundary.
- Hierarchy from size, weight, and space. No tracked capitals, no all-caps labels.
- Small labels: IBM Plex Serif **italic**, sentence case, untracked (Lucent labels rule).
- Every interactive state drawn once in the file: default, hover (light), pressed, disabled,
  empty, and the timer's running state.
- Dark mode: tokens are structured for a swap; not drawn in this pass.

### Tokens

T3 Code standard palette (read from `@t3tools/shared/themePalettes.ts`, MIT). Neutral black surfaces,
one blue accent. Dark is the default mode.

| Variable | Dark (default) | Light | Role |
|---|---|---|---|
| `bg` | `#0a0a0a` | `#fcfcfc` | app ground |
| `surface` | `#141414` | `#ffffff` | card / row |
| `ink` | `#f5f5f5` | `#27272a` | primary text |
| `muted` | `#818181` | `#71717b` | secondary text |
| `faint` | `#7c7c7c` | `#6b6b73` | tertiary / inactive |
| `border` | `#262626` | `#e4e4e7` | hairlines, tracks |
| `line-strong` | `#52525b` | `#b8b8c0` | control outlines: rings, steppers, radios, ghost buttons |
| `accent` | `#2f63e8` | `#1b4ed8` | fills: primary action, progress, selected border |
| `accent-ink` | `#7aa2ff` | `#1b4ed8` | accent used as text or icon on a surface |
| `on-accent` | `#ffffff` | `#ffffff` | text and glyphs on an accent fill |
| `accent-soft` | `#141414` | `#f4f4f5` | icon badges, selected chips |
| `bar` | `#4a4a52` | `#d4d4d8` | non-current chart bars |
| `warn` | `#fe9a00` | `#bb4d00` | broken streak only |

Two accent tokens exist because T3's blue works as a fill but not as small text on a dark ground: fills use
`accent` with white labels, text and icons use `accent-ink`.

### Icons

Tabler Icons (MIT, free, 24px grid, 2px stroke), fetched from the Iconify API. Every icon in the app comes from
that one grid, which is what fixes the earlier misalignment: the previous set was hand-authored paths with
different boxes. Each icon is placed by its layer's left edge, never by raw path coordinates.

Icons used: home, chart-bar, list-details, user, check, book-2, glass-full, clock-hour-4, chevron-left,
chevron-right, plus, minus, player-pause, notebook, stretching.

Type: Inter 400/500/600. Display 28/32, title 20/26, body 15/22, meta 13/18, serif label 12/16.

## Screens (one direction)

| # | Screen | Contains |
|---|---|---|
| 1 | Today | Date, day's completion, habit rows (check, counter, timer states), routines section |
| 2 | Counter detail | Water habit — 8/8 unit row, tap targets, streak, history strip |
| 3 | Timer running | Focus surface — large elapsed time, ring, pause / finish |
| 4 | Routine run | Ordered steps, current step, progress, skip / next |
| 5 | New habit | Tracking-type chooser (check, timer, count) with the fields each needs |
| 6 | Insights | Week grid, per-habit streak, best day |
| 7 | Empty state | No habits yet, one CTA |
| 8 | Routines | Routines as ordered step lists, per-routine progress, new routine |
| 9 | You | Settings, pushed from the profile avatar: preferences, account |

## Build plan

1. Create the `tokens` colour variable collection.
2. Build page frames 390×844 with a status bar and tab bar component.
3. Build each screen with auto layout; rows as reusable components where repeated.
4. Verify by rendering every frame (`screenshot`) at 2×, at full frame height.
5. Audit once (Lucent step 5): contrast, touch targets ≥ 44px, state coverage, type scale.

## Acceptance criteria

- All six frames render with no overlapping or clipped text at 390×844.
- Every habit row is ≥ 56px tall and its check target ≥ 44px.
- Colour use is limited to the token set above.
- Small labels are serif italic, sentence case, untracked.
- The file saves as `.figcraft` under `design/`.

## Build status

- Built in FigCraft: 9 frames on one page — Today, Counter detail, Timer running, Routine run,
  New habit, Insights, Empty state, Routines, You (settings). Each has a light-mode duplicate on the second row
  (18 frames).
- Tokens live as the `tokens` colour variable collection (bg, surface, ink, muted, faint, border,
  accent, accent-soft, warn); every layer is bound to them, so a dark mode is a variable swap.
- Native file: `design/habit-tracker.figcraft`. 2× PNG renders: `design/renders/`.
- Tap targets raised to 44px on the stepper and 36px on the inline counter control.

## Poise finishing pass

Ran as a subagent over the 2× renders. Applied:

1. Habit rows lost their card chrome — one list on the page ground, separation by spacing.
2. Leading slot unified: filled check = done, partial ring = in progress (Water 6/8, Deep work 1h20 of 2h), hollow ring = not done.
3. Duplicate actions removed: no "End session" under the timer pause, no "Create" top-right beside the primary button, no full-width CTA beside the Water stepper.
4. Insights: zero baseline, 0 / 50 / 100% scale, corrected day labels, "86%" moved to ink so green keeps meaning.
5. Buttons moved from pill radius to 16px; routine segments now agree with "Step 3 of 4"; back buttons 40 → 44.
6. Weekday letters raised to the muted token; streak mini-dots replaced with "Best 21 days".
7. Timer digits set to tabular figures; Routines tab glyph changed from a hamburger to a list.

Kept deliberately: the 8-glass dot row in the Water detail (it answers "today" at a glance, which the week row does
not), the two routine cards on Today, and the warm orange only for a broken streak.

Not built: disabled / error / paused states, dark mode, pressed states.


## Open items

- No git repo here; design deliverable needs none. Ask before initialising git if code follows.
- Dark mode, loading, error and pressed states are not drawn in this pass.
- Pressed / focus rings for the shadcn implementation are specified per row, not drawn.

## Dark mode (added 2026-11-07)

Dark is the default, at the owner's request. It is a mode of the same `tokens` collection, not a second file:
the collection has `dark` (default) and `light`. Every layer is bound, so switching mode repaints all seven
screens. Palette is neutral black and white, no hue: bg `#0A0A0A`, surface `#171717`, ink `#FAFAFA`, muted `#A1A1A1`,
faint `#8A8A8A`, border `#262626`, accent `#FAFAFA`, accent-soft `#262626`, warn `#A1A1A1`. Button labels use
the `surface` token, so on the white primary they read near-black.

Light mode is kept as seven duplicated frames on the second row of the page, switched to the `light` mode.
Renders export as `01-today.png` (dark) and `01-today-light.png`.

Anti-slop audit of this pass: `anti-slop/audit-001-2026-11-07.md`.

## Navigation and row controls (2026-11-07)

- Bottom navigation is a floating pill: 358x68, radius 34, inset 16 from each side, sitting 24px above the
  home indicator. No hairline, the surface and its 1px border do the work.
- Duplicate tab icons removed. The old hand-authored vectors (`icon-today`, `icon-insights`, `icon-routines`,
  `icon-you`) were still under the new Tabler frames; only the library icons remain.
- Habit leading control rebuilt on one geometry: 26px box at x16 y21, 2.5px stroke, icon centred at 14px.
  Row 3 and 4 keep a full track ring plus a dashed progress arc drawn from 12 o'clock, so the arc, track and
  habit glyph share one centre. Rotation was dropped from the arc path, which is what had been shifting it.
- Nav reduced to three tabs, Today / Insights / You. Routines no longer has its own tab.

## You page (2026-11-07)

Routines management moved onto the You page, which now also holds every setting — one destination instead of
two. Screen 8, dark default plus a light duplicate.

- Header: serif italic date, "You" display, initial avatar. No card around it.
- Routines: serif italic label, then one card per routine (14px radius, surface, hairline). The left disc
  carries the completed-step count, the right edge the state ("2 of 4", "Not started"), so the two readings
  that matter sit at opposite ends of one row. "+ New routine" is a text action, not a full-width button.
- Settings: one card, 16px radius, five 52px rows, inset hairline dividers at x48. Icon left, label, then the
  current value and a chevron; Reminders is a switch, not a chevron row, because it has no detail screen.
- Values are stated rather than implied: "Dark", "8:00 AM", "1.0". A settings row with no visible current
  state is a row you have to open to read.

Routine cards use the 14px radius that remains from the earlier set; the settings card uses 16. Consolidated
radii remain an open item (audit #5).

## Three tabs, Routines page, settings behind the avatar (2026-11-07)

Replaces the four-tab layout. Nav is now Today / Insights / Routines, and the account page moved behind the
profile avatar in the header.

- **Nav** is three tabs in the same floating pill. It appears only on the three top-level screens and the empty
  state. Pushed screens (counter detail, timer running, routine run, new habit, settings) carry a back button
  and no pill, so the pill means "you can switch tabs from here".
- **Profile avatar** sits top-right on Today and Insights at 326,60, 40px, `accent-soft` with an `accent-ink`
  initial. It opens the settings page. It is not a fourth tab, so it never competes with the pill.
- **Routines page** (screen 8) is now a real page, not two summary rows. Each routine is a card that shows its
  steps in order, because order is the thing a routine is: 22px numbered disc, step name, duration. States are
  done (filled `accent` disc, white numeral), current (accent ring, `accent-ink` numeral), upcoming
  (`line-strong` ring, muted numeral and name) — three levels that survive a colour-blind reader because the
  fill, the ring, and the text tone all change together. The header carries a 40px circular plus button; the
  list ends in a dashed ghost "New routine".
- **Settings page** (screen 9) is pushed: 40px back button, "You" title, two groups. Preferences holds
  Appearance, Reminders, Reminder time, Start week on. Account holds Data & export, About, Sign out. Two groups
  instead of one five-row card because the file has no routines above it any more, and one long card there
  would read as a wall.

