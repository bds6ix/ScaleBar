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

### Native resolution detection pitfalls

Two bugs were discovered during testing across three displays (Gigabyte M27U
horizontal, Dell U2718Q portrait, MacBook Pro built-in):

**Pitfall 1 — current mode pixel backing ≠ native resolution.**
`CGDisplayCopyDisplayMode(displayID).pixelWidth` returns the pixel backing of
the *current* mode, not the panel's native resolution. In a HiDPI mode, the
pixel backing can exceed the physical panel resolution (e.g., 2880×5120 for a
2160×3840 native panel at a 1440×2560 logical mode). Using this value to
calculate "half native" incorrectly excluded the Larger Text option on the
portrait Dell.

**Pitfall 2 — LoDPI modes can have a different aspect ratio than the panel.**
MacBook displays expose LoDPI (1:1) modes at 16:10 (e.g., 3456×2160) even
though the actual panel is ~1.547 (3456×2234). Using the LoDPI aspect ratio
to filter HiDPI modes rejected every mode that System Settings actually shows.
Similarly, using the LoDPI width to compute half-native set the floor at 1728,
cutting out the three smallest options (1168, 1312, 1496).

**Fix:** use two separate sources of truth:
- **Aspect ratio** from `currentMode.width / currentMode.height` — macOS
  always runs at the native panel aspect ratio, so this is reliable.
- **Half-native floor** from the largest HiDPI mode matching the native aspect
  ratio — not from LoDPI modes, which may have a different aspect ratio on
  non-standard panels.

## Decision

**Option 3: filter by aspect ratio + half-native floor, with a toggle for all
modes.**

Filter rules:
- HiDPI only (`pixelWidth > width`)
- `isUsableForDesktopGUI()` must be true
- Must match the native display aspect ratio (within 0.01 tolerance), derived
  from the current mode's logical dimensions
- Logical width must be ≥ half the largest HiDPI width at the native aspect ratio
- Include the 1:1 native mode (LoDPI) if one exists at the native aspect ratio
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
