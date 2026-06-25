# CLAUDE.md — ScaleBar

## What this is

A macOS menu bar app (Swift, SPM) that lets you switch display scaling via a
dropdown — the same "Larger Text ↔ More Space" options from System Settings.

## Build commands

```bash
swift build              # debug build
swift run                # build + run
swift build -c release   # optimized build
./Scripts/make-app.sh    # assemble .app bundle
```

## Architecture

- **`main.swift`** — app lifecycle, menu bar UI, `NSStatusItem` setup.
  `AppDelegate` owns the menu and rebuilds it via `rebuildMenu()`.
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
- The `.app` bundle is just `Contents/MacOS/<binary>` + `Contents/Info.plist`.

## Development workflow

- One chunk per branch per PR. Branch naming: `chunk-X.Y-short-description`.
- Squash and merge all PRs.
- CI runs `swift build` on `macos-15` for every push and PR.
- Design decisions are recorded as ADRs in `docs/adr/`.

## Plan

Implementation follows the phased plan in the parent directory's `PLAN.md`.
Current progress: Phase 1 (display engine) in progress.
