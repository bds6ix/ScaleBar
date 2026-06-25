# CLAUDE.md — Rescale

## What this is

A macOS menu bar app (Swift, SPM) that lets you switch display scaling via a
dropdown — the same "Larger Text ↔ More Space" options from System Settings.

- Tagline: "The missing menu for display scaling."
- Short description: "Quick-switch display scaling from the macOS menu bar."
- URL scheme (future): `rescale://`
- Bundle ID: `com.github.bds6ix.rescale`

## Build commands

```bash
swift build              # debug build
swift run                # build + run
swift build -c release   # optimized build
./Scripts/make-app.sh    # assemble .app bundle
```

## Architecture

- **`main.swift`** — app lifecycle, menu bar UI, `NSStatusItem` setup.
  `AppDelegate` owns the menu and rebuilds it via `rebuildMenu()`. Implements
  `NSMenuDelegate` for live refresh on every menu open. Handles resolution
  switching, Option-click favorites, and Show All / Favorites Only toggles.
- **`DisplayManager.swift`** — all display/resolution logic. Uses CoreGraphics
  (`CGGetActiveDisplayList`, `CGDisplayCopyAllDisplayModes`) to enumerate
  displays and their HiDPI modes. Filtering rules are documented in
  `docs/adr/0001-resolution-filtering.md`.

## Key technical notes

- The `kCGDisplayShowDuplicateLowResolutionModes` flag is required to get HiDPI
  modes from `CGDisplayCopyAllDisplayModes`. Without it, only LoDPI modes are
  returned.
- Native aspect ratio comes from `currentMode.width / height` (always correct).
  Native width for the half-native floor comes from the largest HiDPI mode at
  that aspect ratio — NOT from LoDPI modes (MacBooks expose LoDPI at 16:10 even
  when the panel is ~1.547). See `docs/adr/0001-resolution-filtering.md`.
- `LSUIElement = true` in `Info.plist` makes it a menu bar agent (no Dock icon).
  The code also sets `.accessory` activation policy as a belt-and-suspenders
  measure.
- The `.app` bundle contains `Contents/MacOS/<binary>`, `Contents/MacOS/Rescale_Rescale.bundle`
  (SPM resource bundle with menu bar icon), `Contents/Resources/AppIcon.icns`,
  and `Contents/Info.plist`.
- Favorites stored in `UserDefaults` keyed by `"favorites"`, each entry is
  `"displayID:widthxheight"`.

## Features implemented

- Display enumeration with human-readable names via NSScreen
- HiDPI mode filtering: aspect ratio match + half-native floor (monitor-agnostic)
- Resolution switching via CGDisplayConfiguration transaction
- Checkmark on active resolution
- Live menu refresh via NSMenuDelegate.menuWillOpen
- Custom scale-arrows menu bar icon (template image, adapts to light/dark)
- Rr brand app icon (.icns) for Finder/Activity Monitor
- Orientation icons (filled SF Symbol rectangles) on display names
- Show All Resolutions toggle (bypasses filtering)
- Favorites: Option-click to star, Favorites Only toggle, UserDefaults persistence
- "No displays found" empty state

## Development workflow

- One chunk per branch per PR. Branch naming: `chunk-X.Y-short-description`
  or `fix/short-description` for bug fixes.
- Squash and merge all PRs.
- CI runs `swift build` on `macos-15` for every push and PR.
- Design decisions are recorded as ADRs in `docs/adr/`.
- Brian runs all git/gh commands himself (learning the workflow).

## Plan

See `PLAN.md` in this directory. Phases 0–2 complete. Phase 3 in progress
(3.1 release workflow and 3.2 icons done; 3.3 landing page and 3.4 README
remaining). Future phases (launch at login, scriptability, Stream Deck,
advanced UI) are parked.
