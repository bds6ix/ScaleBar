# Rescale — Implementation Plan

A learning-oriented build plan for a tiny macOS menu bar app that surfaces a display's
"looks like" scaling options (`Larger Text → More Space`) as a two-click dropdown.

This file is the map. Work through it one chunk at a time so you understand every piece —
the code *and* the GitHub/CI process — instead of getting a finished app dropped on you.

---

## How to use this plan

**Two principles drive the ordering:**

1. **Walking skeleton first.** Get the *entire pipeline* (local repo → GitHub → CI) working
   with trivial code, before writing any real logic. Once the whole loop is green, every later
   chunk just grows functionality into a pipeline you already trust.

2. **One chunk = one branch = one PR.** Each chunk gets its own branch, becomes a pull request,
   CI runs against it, you read the diff, then merge. Reviewing a small diff is how you actually
   absorb what the code does — and you learn the real GitHub flow as a side effect.

**The per-chunk rhythm (especially in Claude Code):**

```
git checkout -b chunk-1.2-read-modes      # branch
# → ask Claude Code to implement THIS chunk only, and explain new APIs before committing
# → review the diff yourself
git commit / git push
# → open a PR, watch CI go green, merge
```

A good Claude Code prompt per chunk:
> "Implement chunk 1.2 only. Before we commit, walk me through the CoreGraphics calls you used
> and why. Don't touch anything outside DisplayManager.swift."

Check a box when a chunk is merged and its checkpoint passes.

---

## Phase 0 — Foundations & walking skeleton

> Goal: an end-to-end pipeline with near-zero code. By the end of this phase, code on your
> machine builds in CI on GitHub. Everything after this grows muscle onto the skeleton.

- [x] **0.1 — Local project + first commit**
  - Create `Package.swift` (executable target) and a `main.swift` that launches an
    `NSApplication` with a menu bar icon and a single "Quit" item.
  - `git init`, add `.gitignore`, first commit.
  - *Learn:* Swift Package Manager layout, executable targets, `NSStatusItem` basics,
    why `.accessory` activation policy, git init/staging/commit.
  - *Checkpoint:* `swift run` puts a quittable icon in your menu bar.

- [x] **0.2 — The `.app` bundle**
  - Add `Info.plist` (with `LSUIElement`) and `Scripts/make-app.sh` to assemble a real bundle.
  - *Learn:* why a menu bar agent needs a bundle, what `LSUIElement` does, the anatomy of a `.app`.
  - *Checkpoint:* a double-clickable `Rescale.app` that runs with no Dock icon.

- [x] **0.3 — Connect to GitHub**
  - Create the empty remote repo, `git remote add origin`, push `main`.
  - *Learn:* remotes, HTTPS vs SSH auth, local↔remote relationship, branch tracking.
  - *Checkpoint:* your code is on GitHub.

- [x] **0.4 — CI that builds**
  - A GitHub Actions workflow that compiles on every push and PR (build only — no release yet).
  - *Learn:* runners, workflow triggers, jobs/steps, YAML structure, reading the Actions log.
  - *Checkpoint:* a green check on your first PR.

---

## Phase 1 — The display engine

> The real logic, isolated in `DisplayManager.swift`. Three chunks because each is a distinct
> concept worth understanding on its own.

- [x] **1.1 — Enumerate displays**
  - List connected displays + names; show them as disabled menu items so you can see it working.
  - *Learn:* `CGGetActiveDisplayList`, matching a `CGDirectDisplayID` to an `NSScreen` for the
    human-readable name.
  - *Checkpoint:* your menu shows "DELL U3223QE" twice.

- [x] **1.2 — Read scaled modes** *(meatiest chunk)*
  - Pull the HiDPI "looks like" resolutions; filter, dedupe, sort smallest → largest width.
  - *Learn:* the `kCGDisplayShowDuplicateLowResolutionModes` flag, HiDPI vs LoDPI (framebuffer
    wider than logical width), `isUsableForDesktopGUI()`.
  - *Decision point:* compare the output against your actual Displays pane. macOS curates its
    exact 5 options internally with no public API — if you see extras, consider whitelisting your
    known displayplacer resolutions here.
  - *Checkpoint:* the menu lists the scale options (current one not yet marked).

- [x] **1.3 — Apply a resolution**
  - Wire a click to actually switch.
  - *Learn:* the `CGBeginDisplayConfiguration` → `CGConfigureDisplayWithDisplayMode` →
    `CGCompleteDisplayConfiguration` transaction, and the duplicate-mode quirk (some modes fail
    with `-1000`, so try each candidate until one sticks).
  - *Checkpoint:* clicking an option changes your resolution.

---

## Phase 2 — Menu polish

- [x] **2.1 — Live refresh**
  - Rebuild the menu when it opens via `NSMenuDelegate.menuWillOpen`; handle edge cases
    (no displays, monitor unplugged). Fixed native resolution detection for MacBook displays
    (LoDPI modes report wrong aspect ratio on non-standard panels).
  - *Learn:* `NSMenuDelegate`, native aspect ratio detection pitfalls.
  - *Checkpoint:* unplug/replug a monitor and the menu stays correct.
  - *Note:* per-display sections, checkmarks, targets/actions, and `representedObject` were
    completed during Phase 1 chunks.

- [x] **2.2 — Orientation icons**
  - SF Symbol filled rectangles next to display names showing landscape vs portrait orientation.
  - *Learn:* `NSMenuItem.image`, SF Symbols as vectors with custom sizing.
  - *Deferred:* friendly "Larger Text / More Space" labels — may revisit with a custom
    `NSPopover` UI.

- [x] **2.3 — Favorites**
  - Option-click a resolution to toggle it as a favorite (★/☆). Favorites stored in
    `UserDefaults` for persistence across launches. "Favorites Only" toggle filters the menu
    to just starred resolutions. Dim `⌥-click to favorite` hint at the bottom for
    discoverability.
  - *Learn:* `NSEvent.modifierFlags` for detecting Option-click, `UserDefaults` for
    lightweight persistence, `NSMenuItem.alternate` considerations.
  - *Checkpoint:* Option-click stars a resolution, "Favorites Only" shows only starred items.

---

## Phase 3 — Release & distribute

> Goal: get Rescale into people's hands. No Apple Developer Program needed —
> distribute via GitHub Releases, a landing page, and community channels.

- [x] **3.1 — Release on tags**
  - A second GitHub Actions workflow: on a `v*` tag, build the `.app` bundle →
    zip → attach to a GitHub Release. Include Gatekeeper instructions in the
    release notes.
  - *Learn:* tag-triggered workflows, `permissions: contents: write`, release
    actions, semantic version tags, the `make-app.sh` → zip → upload pipeline.
  - *Checkpoint:* `git tag v0.1.0 && git push --tags` produces a downloadable
    release on GitHub with a zip of `Rescale.app`.

- [x] **3.2 — App icon & menu bar icon**
  - Added Rr brand mark as the app icon (1024×1024 `.icns` in the bundle) and
    replaced the SF Symbol menu bar icon with a custom scale-arrows template
    image. Source assets kept in `Design/` folder.
  - *Learn:* `.icns` format, `iconutil`, `CFBundleIconFile` in `Info.plist`,
    SPM resource bundling, `NSImage.isTemplate` for menu bar icons.
  - *Checkpoint:* `Rescale.app` shows the Rr icon in Finder and the scale
    arrows in the menu bar.

- [ ] **3.3 — Landing page**
  - A single-page site on GitHub Pages: screenshot, what it does, download link
    (pointing to the latest GitHub Release), and a Buy Me a Coffee / Ko-fi tip
    jar button.
  - *Learn:* GitHub Pages, static HTML, linking to release assets.
  - *Checkpoint:* a live URL like `bds6ix.github.io/Rescale` with a working
    download link.

- [ ] **3.4 — README polish & Gatekeeper instructions**
  - Update README with: screenshot, installation instructions (including the
    unsigned app Gatekeeper workaround), link to the landing page, tip jar
    badge.
  - *Learn:* README as marketing, badges, screenshot best practices.
  - *Checkpoint:* a visitor to the GitHub repo can figure out what this is,
    download it, and run it within 60 seconds.

- [ ] **3.5 — Share it**
  - Post to r/macapps, r/mac, and any other relevant communities. Optionally
    list on Product Hunt.
  - *Learn:* the art of the launch post — what to say, where to post, how to
    present a side project.
  - *Checkpoint:* at least one download from someone who isn't you.

---

## Future phases *(parked — revisit when motivated)*

### Scriptability

- [ ] **The `rescale://` URL scheme**
  - Register and handle it so external tools (Stream Deck, Shortcuts, etc.) can
    drive the app.
  - *Learn:* `CFBundleURLTypes`, `NSAppleEventManager`, `kAEGetURL`.

### Stream Deck plugin *(separate sub-project)*

- [ ] **Scaffold** — `streamdeck create` to generate the Node/TypeScript plugin.
- [ ] **One action** — a single button whose `onKeyDown` runs
  `open "rescale://set?..."`. Requires the URL scheme above.
- [ ] **Scale picker** — property inspector to choose display + scale per button.

### Quality of life

- [ ] **Launch at login** — add a "Launch at Login" toggle to the menu using
  `SMAppService.mainApp.register()` (macOS 13+). One menu item, no helper app
  needed.
  - *Learn:* `ServiceManagement` framework, `SMAppService` API.

### Advanced UI

- [ ] **Custom `NSPopover` / `NSPanel`** — replace the `NSMenu` dropdown with a
  custom UI. Enables horizontal layout (like System Settings), richer controls.
- [ ] **Friendly labels** — "Larger Text" / "More Space" endpoint labels, possibly
  a scale slider.

### Signing & notarization *(requires $99/yr Apple Developer Program)*

- [ ] **Code signing + notarization** — eliminates the Gatekeeper warning for
  downloaded apps. Only worth it if you're building more macOS/iOS apps or
  distributing commercially.

### Distribution extras

- [ ] **Homebrew Cask** — `brew install --cask rescale` for developer-friendly
  installs.
- [ ] **Sparkle auto-updates** — notify users when a new version is available.

---

## Scope summary

- **Core path:** Phases 0–3. A working app, released on GitHub, with a landing
  page and community launch.
- **Future:** scriptability, Stream Deck plugin, custom UI, signing — revisit
  based on interest and traction.

## Placeholders to replace before publishing

- `YOUR NAME` → your name in `LICENSE`
- Bundle ID `com.github.bds6ix.rescale` is already set in `Info.plist`
