# Habit tracker

A quiet, local-only habit tracker for phone: check-off, counted and timed habits, ordered routines,
week insights and streaks, a small profile and a share poster. Each habit carries either an icon
picked from the full 1,865-icon Lucide set by search, or a one/two character text badge on a
gradient of your choosing; counted habits log in whatever increment suits them. Timed habits can
cover distracting apps while the timer runs, using an Android accessibility overlay. Built with
Flutter to the Claude design prototype kept at `design/habit-tracker-prototype.html` — parchment
light theme, tuned dark theme, clay accent, serif display type, floating pill navigation.

Signed **Wrong Turn**.

## Run

```sh
flutter pub get
flutter run -d chrome      # or an attached device / emulator
```

`flutter build web --release` outputs to `build/web`.

## Release

`.github/workflows/release.yml` builds the release APK and attaches it to a GitHub release. Dispatch
it from the CLI once `pubspec.yaml` carries the version you want to ship:

```sh
gh workflow run release.yml
```

or push a tag (`git tag v2.1.1 && git push origin v2.1.1`). The workflow reads `version:` from
`pubspec.yaml`, builds `flutter build apk --release` and publishes `accrue-<version>.apk`.

Release builds are signed with the project's release keystore so versions install over each
other. The keystore and its passwords live in repository secrets (`KEYSTORE_BASE64`,
`KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`); the local copy is at
`C:/Users/p/.accrue/accrue-release.jks` with `android/key.properties` pointing at it. Both are
git-ignored. **Back the keystore up**: without it you cannot ship an update to an installed
release.

## Test

```sh
flutter analyze
flutter test
```

## Layout

- `lib/theme` — colour tokens, type scale, metrics, themes
- `lib/models` — habits, routines, starter sets and the habit-idea catalogue
- `lib/state/habit_store.dart` — state, day rollover, streaks, weeks, timer, persistence
- `lib/widgets` — the shared control set, the generated Lucide library, dialogs and the share poster
- `tool/gen_icons.py` — regenerates `lib/widgets/icon_library.dart` from a local `lucide-static` tree
- `lib/screens` — onboarding and the four tabs, plus the pushed detail screens
- `lib/util/focus.dart` + `android/.../FocusAccessibilityService.kt` — focus blocking channel,
  app list and the blocked overlay
- `design/` — the prototype this build follows (previous design in `design/archive/`)
- `screenshots/` — captures of the built app at 390×844, plus `20-focus-blocked.png` (1080×2400)
  from the emulator

Deliberate divergences (no photo picking, caption-only sharing, no seeded demo data, and others)
are listed in [NOTES.md](NOTES.md).
