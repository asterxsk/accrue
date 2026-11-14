<p align="center">
  <img src="docs/brand/accrue-enso.svg" width="96" alt="Accrue">
</p>

<h1 align="center">Accrue</h1>

<p align="center"><em>A calm, local-first habit tracker for phone and web.</em></p>

<p align="center">
  <a href="https://github.com/asterxsk/accrue/releases/latest"><img src="https://img.shields.io/github/v/release/asterxsk/accrue?color=C96442&label=release" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/Android-7.0%2B-C96442" alt="Android 7.0+">
  <img src="https://img.shields.io/badge/Flutter-3.47.9-C96442" alt="Flutter 3.47.9">
  <img src="https://img.shields.io/badge/data-on%20device%20only-C96442" alt="Data stays on device">
</p>

---

Accrue is a quiet place to keep habits. Check things off, count them up, or run a timer — then
see the week settle into shape. There is no account, no sync and no server: every habit, routine
and streak lives in local storage on the device.

<p align="center">
  <img src="screenshots/01-today.png" width="228" alt="Today">
  <img src="screenshots/02-insights.png" width="228" alt="Insights">
  <img src="screenshots/03-routines.png" width="228" alt="Routines">
</p>

<p align="center">
  <img src="screenshots/11-profile-dark.png" width="228" alt="Profile in dark mode">
  <img src="screenshots/22-about-accrue.png" width="228" alt="About Accrue">
  <img src="screenshots/20-focus-blocked.png" width="228" alt="Focus blocking overlay">
</p>

## What it does

- **Three kinds of habit.** A check habit is done or not; a count habit takes whatever increment
  suits it; a timer habit runs a countdown that keeps the screen honest.
- **Routines.** Order habits into a sequence and work through it one step at a time.
- **Icons or badges.** Every habit carries either a Lucide icon chosen by search from the full
  1,865-icon set, or a one- or two-character text badge on a gradient of your choosing.
- **Week insights and streaks.** A week grid, per-habit history, completion share and current
  streak, in light or dark.
- **Focus blocking (Android).** While a timer habit runs, an accessibility overlay covers apps you
  have flagged as distracting, with a countdown and a way back into Accrue.
- **Share poster.** Weeks can be exported as an image, drawn locally.

## Install

Download the latest APK from [Releases](https://github.com/asterxsk/accrue/releases/latest) and
open it on an Android 7.0 or newer device. Releases are signed with a stable release key, so a
newer version installs straight over the installed one.

Accrue also builds for the web: `flutter build web --release` writes a static bundle to
`build/web`, which runs entirely in the browser.

## Build from source

```sh
flutter pub get
flutter run -d chrome      # or an attached device / emulator
```

Requires Flutter 3.47.9 (Dart 3.13). `flutter analyze` and `flutter test` should both be clean.

## Release

`.github/workflows/release.yml` builds the release APK and attaches it to a GitHub release.
Dispatch it once `pubspec.yaml` carries the version to ship:

```sh
gh workflow run release.yml
```

Pushing a tag (`git tag v2.1.2 && git push origin v2.1.2`) does the same. The workflow reads
`version:` from `pubspec.yaml`, runs analyze and tests, builds `flutter build apk --release`,
verifies the signature and publishes `accrue-<version>.apk`.

Release builds are signed with the project's release keystore so versions install over each other.
The keystore and its passwords live in repository secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, `KEY_PASSWORD`); locally, `android/key.properties` points at the keystore outside the
repo. Both are git-ignored. **Back the keystore up** — without it, no future release can update an
installed copy.

## Project layout

| Path | What lives there |
| --- | --- |
| `lib/theme` | Colour tokens, type scale, metrics, light and dark themes |
| `lib/models` | Habits, routines, starter sets, habit-idea catalogue |
| `lib/state/habit_store.dart` | State, day rollover, streaks, weeks, timer, persistence |
| `lib/screens` | Onboarding and the four tabs, plus pushed detail screens |
| `lib/widgets` | Shared control set, generated Lucide library, dialogs, share poster, brand mark |
| `lib/util/focus.dart` + `android/.../FocusAccessibilityService.kt` | Focus-blocking channel, app list, overlay |
| `tool/gen_icons.py` | Regenerates `lib/widgets/icon_library.dart` from a local `lucide-static` tree |
| `tool/export_brand.py` | Exports the in-app enso mark to `docs/brand/accrue-enso.svg` |
| `docs/` | [Product brief](docs/PRD.md) and brand assets |
| `design/` | The prototype this build follows |
| `screenshots/` | Captures of the built app at 390×844, plus the Android focus overlay at 1080×2400 |

Deliberate divergences from the prototype (no photo picking, caption-only sharing, no seeded demo
data) are recorded in [NOTES.md](NOTES.md).

## Brand

The mark is an enso: one unclosed brush ring in clay on a transparent ground, drawn from the same
1024pt geometry as the launcher icon and the About screen.

| Token | Light | Dark |
| --- | --- | --- |
| Accent (clay) | `#C96442` | `#D97757` |
| Ground | `#F5F4ED` | `#141413` |
| Ink | `#141413` | `#F5F4ED` |

Type is a serif display face over a neutral sans, with wide-tracked uppercase eyebrows.

## Credits

Built and signed by **Wrong Turn**. Typefaces ship under the SIL Open Font License; icons come from
[Lucide](https://lucide.dev). Built with Flutter.
