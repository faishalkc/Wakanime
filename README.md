# Wakanime

## Overview

Wakanime is an offline-first Android anime watchlist manager built with Flutter and Dart. It is designed primarily for personal use and published as an open-source project.

All core data—anime entries, watchlist statuses, application settings, and poster images—is stored locally on the device using SQLite and local file storage. Wakanime also includes a manual **Import from API** option powered by Tenrai so you can populate a seasonal TV series catalog when online, then continue using the entire app completely offline.

## Features

- **Offline Watchlist Management**: Add, view, edit, and remove anime entries from your personal watchlist without an internet connection.
- **Watchlist Status Tracking**: Organize anime under four statuses: `Planned`, `Watching`, `Completed`, and `Dropped`.
- **Alphabetical Watchlist & Filtering**: Filter your watchlist by status (`All`, `Planned`, `Watching`, `Completed`, `Dropped`) and search by title in real time (case-insensitive), sorted alphabetically by title.
- **Seasonal Anime Browsing**: Browse anime by season (`Winter`, `Spring`, `Summer`, `Fall`) and year with previous/next season navigation and real-time title search.
- **Weekly Release Schedule**: Automatically view a weekly (`Monday`–`Sunday`) release schedule for watchlisted anime from the current season and year, sorted chronologically by release time.
- **Manual API Season Import**: Import full seasonal TV series catalogs from Tenrai into local SQLite storage with sequential pagination and local poster caching.
- **Local Storage**: Persistent SQLite database (`wakanime.db`) for structured data and local application storage (`anime_images/`) for poster images, with graceful fallbacks if an image is missing.
- **Appearance & Data Controls**: Switch between `System Default`, `Light Theme`, and `Dark Theme`, inspect database counts, or clear all local data from Settings.

## Main Navigation

Wakanime uses a four-tab bottom navigation bar:

- **Home**: Your main watchlist view, displaying watchlisted anime sorted alphabetically by title, with status filter chips and real-time title search.
- **Seasons**: Browse anime by season and year, search within the active season, add anime manually, or trigger a manual Tenrai API import for the selected season.
- **Schedule**: Weekly release schedule (`Monday` through `Sunday`) automatically filtered to anime that are both in your watchlist (across all statuses) and belong to the current season and year based on your device date.
- **Settings**: Configure theme mode, view total anime and watchlist counts, clear all stored data, and check app version info.

## Requirements

- Flutter SDK (tested with Dart SDK `^3.13.1`)
- Android SDK / Android emulator or physical Android device

Core dependencies used by the project:

- `sqflite` — local SQLite database
- `path_provider` & `path` — local storage paths for database and poster images
- `image_picker` — selecting poster images from the device gallery

## Installation

1. Clone or download this repository and open the project root directory.
2. Fetch Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Run static analysis and tests to verify your environment:

   ```bash
   flutter analyze
   flutter test
   ```

4. Launch the app on a connected Android device or emulator:

   ```bash
   flutter run
   ```

## User Guide

### Adding an Anime Manually

1. Open the **Seasons** tab.
2. Tap **Add Anime** (or the `+` floating action button).
3. Enter the required **Title**, select the **Season** (`Winter`, `Spring`, `Summer`, `Fall`) and **Year**, and optionally select an image, **Release Day**, **Release Time**, and **Platform**.
4. Tap **Save Anime**.

### Managing Watchlist Status

1. Tap any anime card from **Home**, **Seasons**, or **Schedule** to open **Anime Details**.
2. Tap **Add to Watchlist** (or **Update Watchlist Status** if already added).
3. Choose one of the four statuses:
   - **Planned** (`planned`)
   - **Watching** (`watching`)
   - **Completed** (`completed`)
   - **Dropped** (`dropped`)
4. To remove an anime from your watchlist without deleting its catalog entry or image, select **Remove from Watchlist** in the bottom sheet.

### Browsing Seasons

1. Open the **Seasons** tab (defaults to the current season and year).
2. Use the left (`←`) and right (`→`) buttons on the season selector to navigate across seasons and years (for example, `Fall 2026` → `Winter 2027`).
3. Use the search bar below the selector to filter titles within the currently selected season.

### Importing a Season from Tenrai

1. Open the **Seasons** tab and navigate to the season and year you want to import.
2. Tap **Import from API**.
3. Wait for pagination, image staging, and local database saving to complete.
4. Once finished, the imported TV series appear in **Seasons** and remain available offline.

### Viewing the Weekly Schedule

1. Open the **Schedule** tab.
2. Watchlisted anime for the current season and year are grouped by release day (`Monday` to `Sunday`) and ordered chronologically by release time (`HH:mm`).
3. Tap any entry to open **Anime Details**.

### Editing or Deleting an Anime

1. Open **Anime Details** for any anime.
2. Tap the **Edit** icon in the top bar to update its title, poster image, season, year, release day, release time, or platform. Replacing or removing an image cleans up the old local image file automatically.
3. Tap the **Delete** icon in the top bar and confirm to permanently delete the anime, its watchlist entry (if any), and its local image file.

## API Import

Wakanime uses **Tenrai** (`https://api.tenrai.org/v1/seasons/{year}/{season}`) strictly as a manual, one-shot import mechanism—never as a runtime backend.

```text
Select season/year in Seasons
        ↓
Tap "Import from API"
        ↓
Fetch TV series pages sequentially from Tenrai (?type=tv&filter=tv)
        ↓
Stage poster images locally
        ↓
Atomic SQLite upsert (preserve platform & watchlist)
        ↓
Use Wakanime offline
```

Key import behaviors:

- **TV Series Only**: Requests filter for TV series (`type=tv` and `filter=tv`), and non-TV entries are excluded.
- **Full Sequential Pagination**: Automatically fetches all pages (`has_next_page`, `current_page`, `last_visible_page`) with rate-limit (`HTTP 429` / `Retry-After`) handling.
- **Atomic Database Transaction**: All pages are fetched before any SQLite transaction runs. If a critical API or pagination error occurs, the import aborts and existing local data remains untouched.
- **Upsert by External Identity**: Imported records use `source = "tenrai"` and `external_id = mal_id`. Re-importing updates metadata (`title`, `season`, `season_year`, `release_day`, `release_time`, and poster image) without creating duplicates.
- **Preserves Local Data**:
  - `platform` is left empty on new imports and never overwritten on re-import.
  - Existing `watchlist` records and statuses are never modified or created automatically by an import.
  - Anime that disappear from later API responses are not deleted from SQLite.
  - Manually created anime (`source = null`, `external_id = null`) remain separate and do not collide with imported entries.
- **Resilient Image Handling**: Individual poster download failures do not abort a season import. New entries fall back to a placeholder if the image fails, and existing entries retain their previous local image if the new download fails.

## Offline Behavior & Data & Privacy

- **100% Local Storage**: All structured data resides in a local SQLite database (`wakanime.db`), and poster images are stored locally inside the app's documents directory (`anime_images/`).
- **No Accounts or Cloud**: Wakanime has no user account system, no backend server, no cloud synchronization, and no telemetry or analytics.
- **Network Usage**: The app only accesses the internet when you explicitly tap **Import from API** on the **Seasons** screen (to fetch Tenrai season data and download poster images). Normal browsing across **Home**, **Seasons**, **Schedule**, **Settings**, and **Anime Details** works entirely offline.

## Project Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── database/
│   ├── anime_dao.dart
│   └── database.dart
├── models/
│   ├── anime.dart
│   ├── anime_import_data.dart
│   └── watchlist.dart
├── screens/
│   ├── anime/
│   │   ├── add_anime_screen.dart
│   │   ├── anime_detail_screen.dart
│   │   └── edit_anime_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── schedule/
│   │   └── schedule_screen.dart
│   ├── seasons/
│   │   └── seasons_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── services/
│   ├── image_service.dart
│   ├── season_import_service.dart
│   └── tenrai_provider.dart
└── widgets/
    ├── anime_card.dart
    ├── anime_search_field.dart
    ├── empty_state.dart
    └── season_selector.dart

test/
├── schedule_test.dart
├── search_test.dart
├── season_import_test.dart
├── season_selector_test.dart
└── widget_test.dart
```

## FAQ

### What is Wakanime?
Wakanime is an offline-first Android application built with Flutter and SQLite for managing a personal anime watchlist, browsing seasonal catalogs, and viewing weekly release schedules.

### Does Wakanime require an internet connection?
No. All normal features—viewing your watchlist, browsing saved seasons, checking the weekly schedule, and adding/editing/deleting anime—work completely offline. An internet connection is only needed when you manually tap **Import from API**.

### What is the difference between Home and Seasons?
**Home** displays only the anime you have added to your personal watchlist (sorted alphabetically, with status filters and title search). **Seasons** is your seasonal catalog browser, allowing you to switch between seasons/years, search within a season, add anime manually, or import a season from Tenrai.

### How does Schedule decide which anime to display?
**Schedule** queries your local SQLite database for anime that meet two conditions:
1. They have an entry in the `watchlist` table.
2. Their `season` and `season_year` match the current season and year based on your device date (`Jan–Mar` = Winter, `Apr–Jun` = Spring, `Jul–Sep` = Summer, `Oct–Dec` = Fall).

It then groups matching entries by `release_day` (`Monday`–`Sunday`) and sorts them chronologically by `release_time`.

### Does Schedule include all watchlist statuses?
Yes. Any anime with a `watchlist` record in the current season and year appears in **Schedule**, regardless of whether its status is `Planned`, `Watching`, `Completed`, or `Dropped`.

### What does API Import do?
It fetches TV series for the currently selected season and year from the Tenrai API across all pagination pages, downloads available poster images to local storage, and performs an atomic upsert into your local SQLite database.

### Does importing anime automatically add it to the watchlist?
No. Imported anime are saved only to the `anime` catalog table so they appear in **Seasons**. You choose which titles to add to your watchlist.

### Does importing data change the watchlist status?
No. Re-importing a season updates anime metadata from Tenrai while preserving your existing `watchlist` entries, statuses, and manually entered `platform` values.

### Why is an anime not appearing in Schedule?
An anime will not appear in **Schedule** if any of the following apply:
- It has not been added to your watchlist.
- Its `season` and `season_year` do not match the current season and year.
- It does not have a valid `release_day` (`Monday`–`Sunday`) set (for example, movies or series without broadcast day metadata).

### Can Wakanime be used without API import?
Yes. You can add, edit, and manage all anime and poster images completely manually through the **Add Anime** form without ever using API import.

### Where is anime data stored?
Structured data (anime metadata, watchlist statuses, and settings) is stored locally in `wakanime.db` via SQLite, and poster images are stored locally inside the application's `anime_images` directory.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before opening an issue or pull request.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
