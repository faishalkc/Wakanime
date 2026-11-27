# GEMINI.md

Instructions for Gemini when working on **Wakanime**. Keep these rules consistent with `AGENTS.md` and `CLAUDE.md`.

## Repository Exploration

- Inspect only files needed for the task; avoid reading unrelated parts of the codebase unnecessarily.
- Verify existing implementations in `lib/` and `test/` before writing code or documentation.

## Implementation Rules

- **Minimal Scope**: Make focused, surgical edits. Do not perform unrelated refactoring or change unaffected screens.
- **Follow Project Conventions**: Write idiomatic, null-safe Dart and Material 3 Flutter widgets matching the existing codebase style.
- **Reuse Existing Components**: Build on existing `AnimeDao`, `AppDatabase`, `ImageService`, `TenraiProvider`, `SeasonImportService`, `Anime` helpers (such as `Anime.currentSeasonYear()`), and shared widgets (`AnimeCard`, `AnimeSearchField`, `EmptyState`, `SeasonSelector`).
- **Avoid Over-Engineering**: Do not introduce unnecessary repository/use-case/controller abstractions or external state-management/router packages.
- **Maintain SQLite Behavior**: Preserve local SQLite persistence (`wakanime.db`), atomic transactions for batch imports, safe schema migrations when needed, and clean local image lifecycle management.
- **Maintain Offline-First Design**: Keep the app fully functional offline; never introduce runtime API dependencies outside the manual import flow in `Seasons`.

## Verification

- Run `flutter analyze` and `flutter test` after code changes and fix any warnings, lints, or failures.
- Ensure task requirements and edge cases (such as null fields, missing local images, or empty states) are properly handled before finishing.
