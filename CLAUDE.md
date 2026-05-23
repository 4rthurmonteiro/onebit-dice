# 1-Bit Dice — CLAUDE.md

## Project

**1-Bit Dice** is a retro dice roller for board games and RPGs, built by **AM2 Studio**.
Target platforms: iOS and Android.
Visual theme: strict 1-bit pixel aesthetic — no gradients, no shadows, no anti-aliasing.

## Stack

- **Flutter** (stable channel)
- **Dart** `^3.12.0`
- No external state management packages in M1

## Folder Structure

```
lib/
├── core/           # App-wide services (analytics, audio, haptic, storage, theme)
│   ├── analytics/
│   ├── audio/
│   ├── haptic/
│   ├── models/
│   ├── storage/
│   └── theme/
├── features/       # One folder per feature slice
│   ├── dice/
│   ├── history/
│   ├── presets/
│   ├── settings/
│   └── splash/
└── shared/         # Reusable UI and utilities used by multiple features
    ├── utils/
    └── widgets/

assets/
├── fonts/          # OFL-licensed .ttf files (Silkscreen, VT323, PressStart2P)
├── sounds/
└── sprites/
```

## State Management

Use `setState` and `ChangeNotifier` only. No Bloc, Riverpod, or Provider in M1.

## Palette Rule

Every theme uses exactly **2 colors**:
- `ink` — foreground (text, icons, borders)
- `paper` — background

Zero intermediate tones. If you find yourself adding a third color, stop and reconsider.

## Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat:   new user-visible feature
fix:    bug fix
chore:  tooling, deps, CI, config
test:   adding or updating tests
docs:   documentation only
```

## Quality Gates

Before every commit:

1. `flutter analyze` — must exit 0 with **zero issues** (`very_good_analysis` rules)
2. `flutter test --coverage` — all tests must pass with **100% line coverage**

`lib/main.dart` is excluded from coverage (entry point only). Generated files (`*.g.dart`) are excluded when code generation is introduced in future epics.

## References

- Full product spec and epics: `docs/roadmap/`
- Task tracker: `docs/plan/progress.md`

## Blocked Tasks

Tasks marked `[!]` in `progress.md` require human intervention.
When you encounter one: **skip it and move to the next task**.
Do not attempt to resolve blockers autonomously.
