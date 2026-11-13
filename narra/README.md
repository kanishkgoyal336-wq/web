# Narra

A Flutter app (macOS and Android) for listening to documents: upload PDFs or
text, read them in a reader with synchronized read-along highlighting, and
create documents, podcasts, quizzes and summaries with AI.

Narra follows the layout, spacing and interaction patterns of Speechify's web
app, measured from reference screenshots. It uses its own name, logo, font
(Inter, SIL OFL) and icons (Lucide, ISC). It does not use Speechify's
branding, assets or private APIs.

## Status: milestone 1 of 7

| Area | State |
| --- | --- |
| Design system (colours, type scale, sizes) | Done, measured from the references |
| App shell: sidebar on wide windows, drawer on phones | Done |
| Home: Continue, Listen, Create | Done |
| Library: date groups, sort, grid and list, search, multi-select delete | Done |
| Upload File (PDF, .txt) with rendered covers | Done |
| Paste Text | Done |
| Reader | Basic: title bar and pages. Menus, outline, tools and player come in milestones 2–3 |
| Paste Link, Upload From | Not built. The buttons open a dialog explaining this (milestone 4) |
| Create (Document, Podcast, Quiz, Summary) | Not built. Needs the AI backend (milestone 5) |
| Accounts, sync, subscription | Not built (milestone 6). The profile shows a local guest |

### Milestones

1. Design system, shell, Home, Library ← this
2. Reader: menu bar, outline, search, share
3. Player: cloud TTS with word timings, read-along highlighting, voices, speed
4. Import: Paste Link (backend fetch), Upload From (Google Drive, Dropbox)
5. Create tools and AI chat (Firebase Cloud Functions → Claude API)
6. Firebase Auth, library sync, subscription, settings, all error/empty states
7. Android phone layout from reference recordings, testing on both platforms

## Run it

Requires Flutter 3.50+ (Dart 3.14).

```bash
flutter pub get
```

```bash
flutter run -d macos
```

```bash
flutter run -d android
```

macOS builds need a Mac with Xcode; Android builds need the Android SDK.

## Test it

```bash
flutter test
```

Golden images of Home and Library are rendered at the reference capture size
(2000×1133 device pixels at 1.357 px per logical pixel). After a visual change,
regenerate them and compare with a reference screenshot:

```bash
flutter test test/golden --update-goldens
```

```bash
python3 -I tool/compare_reference.py reference.webp test/golden/goldens/home.png /tmp/home
```

This writes a side-by-side image and an overlay (reference in red, Narra in
cyan) and prints the mean pixel difference. The reference screenshots are not
committed because they contain personal account details.

## How closely it matches

Measured against the Home and Library references:

- Element positions: within 1 device pixel vertically for headings, pills,
  cards, nav items and the profile row.
- Text widths: within 1–4%. Inter is wider than the reference font, so each
  text style carries a calibrated negative letter spacing (`lib/core/theme/tokens.dart`).
- Mean pixel difference: Home 3.5/255, Library 5.1/255. Most of what remains is
  thumbnail contents (test fixtures, not your PDFs), the logo and the icons.

Known visual differences:

- Logo, font and icons are Narra's own, by design.
- Create tiles use Lucide line icons; the reference uses filled illustrations.
- Thumbnail shadows are blurred in the app, but Flutter's test renderer does
  not draw blur, so goldens show a hard-edged shadow.

## Not yet verified against a reference

The reference screenshots show only Home, Library and the Reader. These parts
are designed in the same style and should be checked against recordings:

- The Add menu (currently lists the four Listen actions)
- The Recents dropdown (currently has only "Recents")
- Library list view, search field, selection bar
- Date groups after "Previous 7 Days" ("Previous 30 Days", then months)
- Paste Text dialog, empty and error states
- The whole phone layout

## Structure

```
lib/
  app/            app widget and GoRouter routes
  core/theme/     measured design tokens and Material theme
  core/widgets/   logo, thumbnails, pill buttons
  features/
    shell/        sidebar and responsive frame
    home/         Home screen
    library/      domain model, repository (SQLite), Riverpod state, Library screen
    import/       file and text import, PDF cover rendering (pdfrx)
    reader/       reader screen
test/
  golden/         reference-size golden images
  fixtures/       synthetic thumbnails for tests
tool/
  compare_reference.py
```

State is managed with Riverpod, navigation with GoRouter, local storage with
SQLite (sqflite), and PDF rendering with pdfrx. Documents are copied into the
app's support directory; deleting them from the library removes the copies.
