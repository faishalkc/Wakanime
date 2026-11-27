# CLAUDE.md

Guidance for Claude when working on the **Wakanime** repository. Keep these instructions aligned with `AGENTS.md`.

## Context & Inspection

- Read only the files relevant to your task (`pubspec.yaml`, target screens, `lib/database/`, `lib/models/`, `lib/services/`, `lib/widgets/`, or `test/`).
- Understand the actual implementation in the repository before proposing or writing changes.

## Working Principles

- **Minimal, Scoped Changes**: Modify only what is required to complete the task. Avoid unrelated refactoring, stylistic rewrites, or unrequested feature additions.
- **Reuse Existing Code**: Use existing models (`Anime`, `Watchlist`, `AnimeImportData`), `AnimeDao`, `ImageService`, `SeasonImportService`, `TenraiProvider`, and reusable widgets (`AnimeCard`, `AnimeSearchField`, `SeasonSelector`, `EmptyState`). Reuse `Anime.currentSeasonYear()` rather than duplicating month-to-season logic.
- **Simple Architecture**: Keep the current Flutter `StatefulWidget` + `ValueNotifier` + `Navigator` approach. Do not introduce external state-management/router packages or unnecessary abstraction layers.
- **Minimal Dependencies**: Do not add new packages to `pubspec.yaml` unless strictly necessary.

## Core Invariants to Preserve

- **Offline-First Behavior**: All runtime screens (`Home`, `Seasons`, `Schedule`, `Settings`, `AnimeDetailScreen`) read strictly from local SQLite (`wakanime.db`) and local image storage (`anime_images/`). Tenrai API calls happen only during manual **Import from API** on `Seasons`.
- **SQLite & Data Integrity**: Do not alter database schema needlessly. Any schema change must include a safe non-destructive migration (`onUpgrade`). Keep `watchlist.anime_id` unique, preserve `platform` and `watchlist` data during API re-imports, and keep manual anime entries (`source = null`, `external_id = null`) distinct from API entries.
- **Existing Navigation & Behavior**: Keep the four main tabs (`Home`, `Seasons`, `Schedule`, `Settings`) and all existing behaviors intact unless explicitly asked to change them.

## Validation

- After editing, inspect affected files and run:
  - `flutter analyze`
  - `flutter test`
- Report only results directly observed from running commands and reading files.
