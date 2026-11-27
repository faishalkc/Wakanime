<div align="center">
  <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEhbaBm-O5hk3eZqPA_J9oVosFHloaQVhFSVPY4BdMcPSAT9V3eH35SiKr365BnCxqVco7QWpO7ZTNYmbKW3IOus5aW2WvO1UJq68kO_Ger68pzweuIyef712d4EMxSt5PvsGrHhJqmtgxefCCZ9BPf_yP4hwet5Xdq8Y9HL3QbUfGXcyv7-CuCRW5PegYc/s512/155465.png" alt="Wakanime App Icon" width="160" height="160">
</div>

<h1 align="center">Wakanime</h1>

<p align="center">
  An offline-first anime watchlist manager for Android, built with Flutter &amp; SQLite.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white" alt="SQLite">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

---

## 📱 Overview

Wakanime is a personal, open-source Android application for organizing your anime watchlist without relying on an internet connection or external user accounts.

All anime entries, watchlist statuses, preferences, and poster images live locally on your device using SQLite and local file storage. When you want to populate a seasonal TV catalog quickly, Wakanime provides an optional manual **Import from API** workflow via Tenrai—and once imported, everything continues working completely offline.

## ✨ Features

- 📋 **Personal Watchlist (Home)** — Manage watchlisted anime with four statuses (`Planned`, `Watching`, `Completed`, `Dropped`), status filter chips, alphabetical sorting, and real-time title search.
- 🌸 **Seasonal Browsing (Seasons)** — Browse anime by season (`Winter`, `Spring`, `Summer`, `Fall`) and year using left/right navigation, with real-time title search within the active season.
- 📅 **Weekly Schedule (Schedule)** — View a chronological `Monday`–`Sunday` release schedule for watchlisted anime belonging to the current season and year.
- 📥 **Manual API Import** — Import a full season of TV series from Tenrai with sequential pagination and automatic local poster caching.
- 💾 **Offline-First Local Storage** — Persistent SQLite database (`wakanime.db`) and local image storage (`anime_images/`), with safe placeholders if an image is unavailable.
- 🎨 **Clean Material 3 UI** — Supports `System Default`, `Light Theme`, and `Dark Theme`, plus database statistics and data reset in Settings.

### Main Navigation

| Tab | Purpose |
|---|---|
| **Home** | Watchlist hub sorted alphabetically by title, with status filters and title search. |
| **Seasons** | Seasonal catalog browser (`Winter` / `Spring` / `Summer` / `Fall` + year), manual entry, and Tenrai API import. |
| **Schedule** | Weekly release schedule (`Monday`–`Sunday`) for watchlisted anime in the current season and year. |
| **Settings** | Theme selection, stored anime/watchlist counts, data management, and app info. |

## 📸 Screenshots

<table align="center">
  <tr>
    <td align="center">
      <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEiD93isCyngxkZtj2RnDu2jo6doWiDplAsBA3BMdaBnicXFeeqA2xVrB1n71nCrANmjWJknWxn_XtOSEtEaFE1C7UOaTSOshP7ZFzcndlrU9GzfdyL0vgKdr-zLZXzWRaZoHFLnnYjB9_hkLUWUdwOeMOMgCJhEQ7I6ouETWiEdiX4JhHEv-XrAfkxCi2s/s1024/158195.png" alt="Home Screen" width="200">
    </td>
    <td align="center">
      <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEip9aZyiRXdqEebtafKrtrQcGWjfw4tLUBiz-qCIYk33d286cdgcj521UHou6_0mV3qa6pcCRlivzWGPPWp5QB3qu4ysBGHK6yvTTuVdYtRGdKzPreFga83RpNIUve_3QlhsoaVPpPDWBSOAQzn-OJh_A7BcYVdDQT1mdJIOF_2kJ2R-yGQAw0Bt4-6tn4/s1024/158196.png" alt="Seasons Screen" width="200">
    </td>
    <td align="center">
      <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEhWE9QIKedZ1ap0RPbpAL1HY9uHA9w_tSvQsf6_rITrHS6_333ci5M3xdZEN3fWNHRZqEXKMvX_MvNR83Z17UAvHWoNfNeBSrP4DgzpcSd0n7F1FP-QTWiYgrV6qg8GDbIlxoa9p2LUrn-gpSNJTnOkdP-EXuWDH_YhORRz1vOMgMECIccgmUH1TIiHwnk/s1024/158197.jpg" alt="Schedule Screen" width="200">
    </td>
    <td align="center">
      <img src="https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgrbRRBC3IgdDmwaYnBJNavxCS7FJrmx7xYpH_HF44PbqZvmPq6YaihdU7NRtPtOOVVgEDjsXAfVIuRzxlC6Z1Q-hHZpDvjULMAgn25YVdV3Q1rSxP58yopUcl0adPOR_qnp6xncERlJwRv3HvZBCjndWwt3fHTDYn-7xsRMZbP2DKAIv0HeFDIDp1eQ9M/s1024/158198.png" alt="Settings Screen" width="200">
    </td>
  </tr>
  <tr>
    <td align="center"><b>Home</b></td>
    <td align="center"><b>Seasons</b></td>
    <td align="center"><b>Schedule</b></td>
    <td align="center"><b>Settings</b></td>
  </tr>
</table>

## ⚙️ Requirements & Installation

### Requirements

- Flutter SDK (tested with Dart SDK `^3.13.1`)
- Android SDK with a connected Android device or emulator

### Setup

1. Clone or download this repository and navigate to the project root.
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Verify with static analysis and tests:

   ```bash
   flutter analyze
   flutter test
   ```

4. Run on your Android device or emulator:

   ```bash
   flutter run
   ```

## 📖 User Guide

### 🏠 Home

- View every anime you have added to your watchlist, sorted alphabetically by title.
- Filter entries using the status chips (`All`, `Planned`, `Watching`, `Completed`, `Dropped`).
- Use the search bar to filter watchlisted titles in real time alongside your active status filter.
- Tap any card to open **Anime Details** and update or remove its watchlist status.

### 🌸 Seasons

- Opens to the current season and year by default.
- Use `←` and `→` on the season selector to move across seasons and years (for example, `Fall 2026` → `Winter 2027`).
- Search titles within the currently selected season using the search bar.
- Tap **Add Anime** (or `+`) to enter an anime manually (`Title`, optional poster image, `Season`, `Year`, `Release Day`, `Release Time`, `Platform`).

### 📥 Importing Anime

1. Open **Seasons** and select the season and year you want to import.
2. Tap **Import from API**.
3. Wait while Wakanime fetches all TV series pages, stages poster images, and saves them to SQLite.
4. Imported anime appear in **Seasons** immediately and remain available offline.

### 📅 Schedule

- Automatically displays watchlisted anime for the **current season and year** (determined from your device date).
- Includes all watchlist statuses (`Planned`, `Watching`, `Completed`, `Dropped`).
- Groups anime by release day (`Monday` to `Sunday`) and sorts each day chronologically by release time (`HH:mm`).
- Entries without a release day are omitted safely without errors.

### ✏️ Editing & Deleting Anime

- Open **Anime Details** from **Home**, **Seasons**, or **Schedule**.
- Tap the **Edit** icon to update metadata or replace/remove the poster image (old local image files are cleaned up automatically).
- Tap the **Delete** icon and confirm to remove the anime, its linked watchlist entry, and its local poster image.

## 🌐 API Import

Wakanime integrates **Tenrai** (`https://api.tenrai.org/v1/seasons/{year}/{season}`) strictly as a manual import tool—not a runtime backend.

```text
Select season/year in Seasons
        ↓
Tap "Import from API"
        ↓
Fetch TV series pages sequentially (?type=tv&filter=tv)
        ↓
Stage poster images locally
        ↓
Atomic SQLite upsert
        ↓
Use Wakanime completely offline
```

Key guarantees:

- **TV Series Only**: Queries Tenrai for TV series (`type=tv` and `filter=tv`) and skips non-TV entries.
- **Full Pagination & Rate-Limit Handling**: Fetches every page (`has_next_page`, `current_page`, `last_visible_page`) sequentially and respects `HTTP 429` `Retry-After` headers.
- **Atomic Import**: Fetches all pages before opening a single SQLite transaction. If a critical API or pagination failure occurs, existing data is left untouched.
- **Safe Re-Import (Upsert)**: Matches API records by `(source, external_id)` (`"tenrai"` + `mal_id`), updating metadata and posters without creating duplicates or removing titles absent from later responses.
- **Preserves Local Data**: Never overwrites user-entered `platform`, never modifies or auto-creates `watchlist` records, keeps existing images if a new download fails, and keeps manual entries (`source = null`, `external_id = null`) independent.

## 🔒 Data & Privacy

- 💾 **Local Database**: Structured data (`anime`, `watchlist`, `settings`) is stored locally in `wakanime.db` via SQLite.
- 🖼️ **Local Images**: Poster images are stored locally inside the app's `anime_images` directory.
- 🚫 **No Accounts or Cloud**: No login, no backend server, no cloud sync, and no tracking or analytics.
- 📡 **Offline by Default**: Internet access is used only when you explicitly tap **Import from API** on the **Seasons** screen.

## 📁 Project Structure

```text
lib/
├── main.dart                  # App entry point and initial theme loading
├── app/                       # MaterialApp shell, theme config, and routes
├── database/                  # SQLite initialization, migrations, and AnimeDao
├── models/                    # Anime, Watchlist, and AnimeImportData models
├── screens/                   # Home, Seasons, Schedule, Settings, and Anime CRUD screens
├── services/                  # Local image lifecycle, Tenrai provider, and season importer
└── widgets/                   # Reusable AnimeCard, search field, season selector, empty state

test/                          # Unit and widget tests
```

## ❓ FAQ

### What is Wakanime?
Wakanime is an offline-first Android anime watchlist manager built with Flutter and SQLite for personal use.

### Does Wakanime require an internet connection?
No. Browsing your watchlist, seasons, schedule, and managing anime details all work offline. Internet is only required when you manually tap **Import from API**.

### What is the difference between Home and Seasons?
**Home** shows only anime in your watchlist (sorted alphabetically, with status filters and title search). **Seasons** shows the seasonal anime catalog where you can switch seasons/years, add anime manually, or import TV series from Tenrai.

### How does Schedule decide which anime to display?
**Schedule** queries local SQLite for anime that both have a `watchlist` record and match the current season and year based on your device date (`Jan–Mar` = Winter, `Apr–Jun` = Spring, `Jul–Sep` = Summer, `Oct–Dec` = Fall), then groups them by `release_day` (`Monday`–`Sunday`) and sorts by `release_time`.

### Does Schedule include all watchlist statuses?
Yes. Watchlisted anime in the current season and year appear in **Schedule** regardless of whether their status is `Planned`, `Watching`, `Completed`, or `Dropped`.

### What does API Import do?
It fetches TV series for the currently selected season and year across all Tenrai pagination pages, downloads available poster images locally, and upserts them into SQLite inside an atomic transaction.

### Does importing anime automatically add it to the watchlist?
No. Imported anime are added only to the local `anime` catalog in **Seasons** so you can decide which titles to add to your watchlist.

### Does importing data change the watchlist status?
No. Re-importing updates anime metadata while preserving your existing `watchlist` entries, statuses, and manually set `platform` values.

### Why is an anime not appearing in Schedule?
An anime will not appear in **Schedule** if it is not in your watchlist, belongs to a different season or year, or does not have a valid `release_day` (`Monday`–`Sunday`).

### Can Wakanime be used without API import?
Yes. You can add, edit, and manage all anime and poster images manually via **Add Anime**.

### Where is anime data stored?
Metadata, watchlist entries, and settings are stored in `wakanime.db` (SQLite), and poster images are stored locally in the app's `anime_images` directory.

## 🤝 Contributing

Contributions are welcome! Please review [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before opening an issue or pull request.

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.<br>
Made with Flutter and a love for anime. 🌸
