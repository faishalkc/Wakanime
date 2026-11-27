# Contributing to Wakanime

Thank you for your interest in contributing to Wakanime. Because this is primarily a personal open-source project built around a focused offline-first scope, small and well-scoped contributions work best.

## Before Contributing

- Read [README.md](README.md) to understand Wakanime's purpose, features, and offline-first design.
- Check existing issues and pull requests to avoid duplicate work.
- Keep changes focused on a single bug fix or clear improvement.
- Avoid submitting large architectural rewrites or unrelated changes.

## Development

1. Ensure you have the Flutter SDK (Dart SDK `^3.13.1`) and Android tooling configured.
2. Fetch dependencies from the repository root:

   ```bash
   flutter pub get
   ```

3. Run the app on an Android device or emulator:

   ```bash
   flutter run
   ```

## Code Changes

- Follow the existing project structure (`lib/app/`, `lib/database/`, `lib/models/`, `lib/screens/`, `lib/services/`, `lib/widgets/`).
- Reuse existing models, `AnimeDao`, `ImageService`, and reusable widgets instead of duplicating logic.
- Avoid unrelated refactoring or formatting changes in files you do not need to modify.
- Do not add new packages to `pubspec.yaml` without a clear, necessary reason.
- Preserve existing behavior, SQLite data integrity, and offline-first operation (do not turn API import into a runtime dependency).

## Testing and Validation

Before submitting your changes, verify them with the project's standard Flutter checks:

```bash
flutter analyze
flutter test
```

If you modify logic or fix a bug, add or update unit/widget tests under `test/` where appropriate.

## Pull Requests

When opening a pull request, please include:

- A clear summary of what was changed.
- The reason for the change.
- Which checks you ran (such as `flutter analyze` and `flutter test`).
- Screenshots, if your change affects the UI and screenshots are helpful.
- Only changes directly related to the pull request.
