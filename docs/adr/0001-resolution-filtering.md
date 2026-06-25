# ADR 0001: Resolution Filtering Strategy

**Date:** 2026-06-24
**Status:** Accepted

## Context

macOS System Settings shows exactly 5 curated "looks like" resolution options per
display (Larger Text → More Space), but there is no public API to retrieve that
specific set. CoreGraphics' `CGDisplayCopyAllDisplayModes` (with the
`kCGDisplayShowDuplicateLowResolutionModes` flag) returns all available modes —
typically 16+ unique HiDPI resolutions plus dozens of LoDPI and non-GUI modes.

We need a monitor-agnostic filtering strategy that produces a useful subset on
any display, without hardcoding resolutions for specific monitor models.

### What we learned

We dumped every mode from two displays (a Gigabyte M27U horizontal and a Dell
U2718Q in portrait) and compared against System Settings:

- **No consistent percentage** between macOS's 5 steps. The jumps vary:
  33%, 17%, 12%, 14% on the M27U.
- **Different monitors at the same native resolution get different sets.**
  The M27U shows {1920, 2560, 3008, 3360, 3840} while the Dell U3223QE
  (also 3840×2160) shows {1680, 1920, 2560, 3008, 3200}. The selection
  appears to be curated per-model via EDID/firmware.
- **Structural pattern holds across all displays:**
  - First option = half native width (2× retina, "Larger Text")
  - Last option = 1:1 native ("More Space")
  - macOS picks 3 intermediate steps from available modes

### Options considered

1. **Hardcode known resolutions per monitor model** — fragile, requires
   maintenance for every new display.
2. **Show all HiDPI modes** — 16+ items per display, cluttered menu.
3. **Filter by aspect ratio + half-native floor** — monitor-agnostic, gets
   ~8 modes, always includes every mode macOS would show.
4. **Attempt to reverse-engineer macOS's exact 5** — no public API, would
   break across OS versions.

### Native resolution detection pitfall

`CGDisplayCopyDisplayMode(displayID).pixelWidth` returns the pixel backing of
the *current* mode, not the panel's native resolution. In a HiDPI mode, the
pixel backing can exceed the physical panel resolution (e.g., 2880×5120 for a
2160×3840 native panel at a 1440×2560 logical mode). Using this value to
calculate "half native" incorrectly excluded the Larger Text option on the
portrait Dell.

**Fix:** find the largest LoDPI mode where `pixelWidth == width` — that's the
true 1:1 native resolution.

## Decision

**Option 3: filter by aspect ratio + half-native floor, with a toggle for all
modes.**

Filter rules:
- HiDPI only (`pixelWidth > width`)
- `isUsableForDesktopGUI()` must be true
- Must match the native display aspect ratio (within 0.01 tolerance)
- Logical width must be ≥ half the native width
- Include the 1:1 native mode (which is LoDPI)
- Deduplicate by logical resolution

A "Show All Resolutions" toggle in the menu bypasses the aspect ratio and
half-native filters for debugging and power users.

## Consequences

- **Pro:** Works on any display without configuration. Every resolution macOS
  shows in System Settings is guaranteed to appear.
- **Pro:** ~8 items per display instead of 16+ keeps the menu usable.
- **Pro:** The toggle provides an escape hatch for edge cases.
- **Con:** Shows ~3 more options than System Settings' curated 5. Acceptable
  tradeoff for monitor-agnostic operation.
- **Future:** A "favorites" or "pin" feature could let users reduce to exactly
  the modes they care about.
