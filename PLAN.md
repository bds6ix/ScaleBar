# ScaleBar — Implementation Plan

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

- [ ] **0.1 — Local project + first commit**
  - Create `Package.swift` (executable target) and a `main.swift` that launches an
    `NSApplication` with a menu bar icon and a single "Quit" item.
  - `git init`, add `.gitignore`, first commit.
  - *Learn:* Swift Package Manager layout, executable targets, `NSStatusItem` basics,
    why `.accessory` activation policy, git init/staging/commit.
  - *Checkpoint:* `swift run` puts a quittable icon in your menu bar.

- [ ] **0.2 — The `.app` bundle**
  - Add `Info.plist` (with `LSUIElement`) and `Scripts/make-app.sh` to assemble a real bundle.
  - *Learn:* why a menu bar agent needs a bundle, what `LSUIElement` does, the anatomy of a `.app`.
  - *Checkpoint:* a double-clickable `ScaleBar.app` that runs with no Dock icon.

- [ ] **0.3 — Connect to GitHub**
  - Create the empty remote repo, `git remote add origin`, push `main`.
  - *Learn:* remotes, HTTPS vs SSH auth, local↔remote relationship, branch tracking.
  - *Checkpoint:* your code is on GitHub.

- [ ] **0.4 — CI that builds**
  - A GitHub Actions workflow that compiles on every push and PR (build only — no release yet).
  - *Learn:* runners, workflow triggers, jobs/steps, YAML structure, reading the Actions log.
  - *Checkpoint:* a green check on your first PR.

---

## Phase 1 — The display engine

> The real logic, isolated in `DisplayManager.swift`. Three chunks because each is a distinct
> concept worth understanding on its own.

- [ ] **1.1 — Enumerate displays**
  - List connected displays + names; show them as disabled menu items so you can see it working.
  - *Learn:* `CGGetActiveDisplayList`, matching a `CGDirectDisplayID` to an `NSScreen` for the
    human-readable name.
  - *Checkpoint:* your menu shows "DELL U3223QE" twice.

- [ ] **1.2 — Read scaled modes** *(meatiest chunk)*
  - Pull the HiDPI "looks like" resolutions; filter, dedupe, sort smallest → largest width.
  - *Learn:* the `kCGDisplayShowDuplicateLowResolutionModes` flag, HiDPI vs LoDPI (framebuffer
    wider than logical width), `isUsableForDesktopGUI()`.
  - *Decision point:* compare the output against your actual Displays pane. macOS curates its
    exact 5 options internally with no public API — if you see extras, consider whitelisting your
    known displayplacer resolutions here.
  - *Checkpoint:* the menu lists the scale options (current one not yet marked).

- [ ] **1.3 — Apply a resolution**
  - Wire a click to actually switch.
  - *Learn:* the `CGBeginDisplayConfiguration` → `CGConfigureDisplayWithDisplayMode` →
    `CGCompleteDisplayConfiguration` transaction, and the duplicate-mode quirk (some modes fail
    with `-1000`, so try each candidate until one sticks).
  - *Checkpoint:* clicking an option changes your resolution.

---

## Phase 2 — Menu polish

- [ ] **2.1 — Real menu structure**
  - Per-display sections, checkmark the active scale, friendly "Larger Text / More Space" labels.
  - *Learn:* `NSMenuItem` targets/actions, `representedObject` for attaching data, `state` for
    checkmarks.

- [ ] **2.2 — Live refresh**
  - Rebuild the menu when it opens; handle edge cases (no displays, monitor unplugged).
  - *Learn:* `NSMenuDelegate.menuWillOpen` for always-fresh state.
  - *Checkpoint:* unplug/replug a monitor and the menu stays correct.

---

## Phase 3 — Scriptability

- [ ] **3.1 — The `scalebar://` URL scheme**
  - Register and handle it so external tools can drive the app.
  - *Learn:* `CFBundleURLTypes`, `NSAppleEventManager`, `kAEGetURL`, parsing query params.
  - *Checkpoint:* `open "scalebar://set?display=0&scale=3"` from Terminal switches the resolution.
  - *Note:* this is the exact hook the Stream Deck plugin (Phase 5) uses — building it here makes
    Phase 5 self-contained.

---

## Phase 4 — Release pipeline

- [ ] **4.1 — Release on tags**
  - A second workflow: on a `v*` tag, build → zip → attach to a GitHub Release.
  - *Learn:* tag-triggered workflows, `permissions: contents: write`, release actions, semantic
    version tags.
  - *Checkpoint:* `git tag v0.1.0 && git push --tags` produces a downloadable release.

- [ ] **4.2 — Signing & notarization** *(stretch — only once the app is proven)*
  - *Learn:* Developer ID identities, repository secrets, `notarytool`, Gatekeeper.
  - *Cost:* requires the $99/yr Apple Developer account. Park it until you're sure.

---

## Phase 5 — Stream Deck plugin *(separate sub-project)*

- [ ] **5.1 — Scaffold** — `streamdeck create` to generate the Node/TypeScript plugin.
  - *Learn:* plugin architecture (Node backend ↔ Stream Deck over WebSocket), `manifest.json`.
  - *Requires:* Node.js 24+, Stream Deck 7.1+.

- [ ] **5.2 — One action** — a single button whose `onKeyDown` runs `open "scalebar://set?..."`.
  - *Learn:* actions, the SDK event model, shelling out from Node.

- [ ] **5.3 — Scale picker** — multiple actions or a property inspector to choose display + scale.
  - *Learn:* property inspectors, persisting per-button settings.

- [ ] **5.4 — Package & distribute** *(optional)* — bundle the `.streamDeckPlugin`, optionally
  submit to Marketplace.

---

## Scope summary

- **Core path:** Phases 0–4. You'll have a working, releasable app before touching Stream Deck.
- **Polish extras:** Phase 4.2 (notarization) and Phase 5 (Stream Deck plugin).
- **Rough effort:** Phase 0 is one focused session; Phases 1–3 are a session or two each at a
  careful review pace.

## Placeholders to replace before publishing

- `com.example.scalebar` → a real bundle ID (e.g. `com.yourname.scalebar`) in `Info.plist`
- `YOUR_USERNAME` → your GitHub handle in the README clone URL
- `YOUR NAME` → your name in `LICENSE`
- Project name `ScaleBar` itself, if you pick a different one
