# AGENTS.md

Instructions for AI coding agents working on **Wakanime**.

## Project Overview

Wakanime is an offline-first Android anime watchlist manager built with Flutter, Dart, Material 3 UI, SQLite (`sqflite`), and local image storage. It is a personal open-source project designed to stay simple, maintainable, and fully usable offline.

## Project Understanding

- Inspect only the files relevant to the current task; avoid exhaustive repository-wide reads when targeted inspection is sufficient.
- Understand how existing models, `AnimeDao`, `AppDatabase`, `ImageService`, screens, and widgets work before introducing new code.
- Treat the repository source code as the source of truth. Do not assume features or behaviors that are not implemented.

## Scope & Minimal Changes

- Keep changes as small and focused on the requested task as possible.
- Do not perform unrelated refactoring, formatting sweeps, or code cleanup outside the task scope.
- Do not redesign UI or change existing behavior unless explicitly requested.
- Preserve the existing four-tab navigation structure (`Home`, `Seasons`, `Schedule`, `Settings`) and all existing features.

## Code Reuse

- Reuse existing implementations wherever appropriate:
  - `Anime`, `Watchlist`, `WatchlistItem`, and `AnimeImportData` in `lib/models/`
  - `AppDatabase` and `AnimeDao` in `lib/database/`
  - `ImageService`, `TenraiProvider`, and `SeasonImportService` in `lib/services/`
  - `AnimeCard`, `AnimeSearchField`, `EmptyState`, and `SeasonSelector` in `lib/widgets/`
  - Shared helpers such as `Anime.currentSeasonYear()` and `Anime.seasonFromMonth()`
- Avoid duplicating SQL queries, UI components, or business logic across screens.

## Architecture & Dependencies

- Follow the existing straightforward modular structure (`app/`, `database/`, `models/`, `screens/`, `services/`, `widgets/`).
- Do not introduce enterprise architecture layers (repositories, controllers, use-cases, factories, or unnecessary interfaces) or state-management/routing packages.
- Do not add new dependencies to `pubspec.yaml` unless there is a clear, unavoidable technical need.

## Database & Data Integrity

- Keep SQLite (`wakanime.db`) as the primary runtime data store.
- Do not modify the database schema without a clear requirement; when schema changes are required, write safe, non-destructive `onUpgrade` migrations that preserve existing `anime`, `watchlist`, `settings`, timestamps, and `image_path` references.
- Preserve the invariants around `anime` and `watchlist`:
  - `watchlist.anime_id` is unique (one watchlist record per anime, statuses: `planned`, `watching`, `completed`, `dropped`).
  - Manual entries (`source = null`, `external_id = null`) must coexist cleanly alongside API-imported entries (`(source, external_id)` unique when non-null).
  - API re-imports must preserve local `platform`, `watchlist` status, and existing images if new image downloads fail.

## Offline-First Rule

- Keep Wakanime strictly offline-first.
- Never make the Tenrai API (or any network call) a runtime dependency for `Home`, `Seasons`, `Schedule`, `Settings`, `AnimeDetailScreen`, or displaying poster images.
- API integration exists solely as an explicit manual import mechanism on `Seasons`.

## UI/UX Guidelines

- Keep Material 3 UI patterns consistent with the existing screens.
- Handle loading, empty, and error states cleanly without crashing on missing files or null fields (such as null `release_day` or `release_time`).
- Do not redesign unrelated screens.

## Validation

After making changes:

1. Review all modified files for correctness and minimal diff.
2. Run `flutter analyze` and ensure zero issues.
3. Run `flutter test` (and add/update targeted tests when changing logic).
4. Verify task-specific behavior accurately, and only report checks that were actually executed and observed passing.
