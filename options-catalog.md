# OPTIONS catalog — use-cases → signals → offers → modules

> The foundation doc for making OPTIONS real. OPTIONS is Golem's core idea: the
> shell (waverunner) senses your context via the Brain (`options-engine`) and
> surfaces exactly the right actions at the right moment, then gets out of the
> way. This catalogs the general computer use-cases, the actions users reach for
> in each, the real signals the engine can sense to trigger them, and how each
> maps to an OPTIONS **module**.
>
> Status legend for each signal: **[live]** sensed by a shipping collector today ·
> **[cheap]** a small addition to an existing collector · **[bridge]** needs an
> app to talk to the bridge socket (`$XDG_RUNTIME_DIR/options/bridge.sock`) ·
> **[new]** needs a new collector.
>
> Grounded against the real engine at `/home/max/launcher/crates/options-engine`
> (2026-09-02): collectors = hyprland, system, git, media, bridge, selection,
> audio, deploy, notifications; Mind = `infer_activity` + `decide` providers.

---

## 0. What the engine senses TODAY (the ground truth)

From `ContextState` (`state.rs`) and the nine collectors:

| Field | Source collector | Meaning | Status |
|---|---|---|---|
| `window.{class,title,pid,address,workspace_id,is_fullscreen,is_floating}` | hyprland | focused window identity + geometry state | live |
| `behavior.focus_switch_velocity` | hyprland (derived) | window switches/sec (churn) | live |
| `git.{repo_root,branch,is_dirty}` | git (derives from focused pid's cwd) | repo of the focused window | live |
| `media.{player_name,title,artist,is_playing}` | media (MPRIS) | what's playing | live |
| `audio.{is_mic_active,default_sink_volume,is_muted}` | audio (pw-dump/wpctl) | mic live, sink volume/mute | live |
| `metrics.{cpu_usage_pct,ram_usage_pct,battery_pct,is_charging}` | system (/proc,/sys) | load + power | live |
| `deploy.{not_activated,stale_generation}` | deploy (nix profiles) | generation drift | live |
| `notifications.{active_count,has_critical,latest_app,latest_summary}` | notifications (dbus) | unread summary | live |
| `selection.{highlighted_text,char_count,is_code,contains_url}` | selection (wl-paste) | classified clipboard | live |
| `app_internal.{shell_last_cmd,shell_exit_code,editor_file,editor_language,editor_diagnostics_count,browser_url,is_reading_docs}` | bridge (unix socket) | in-app truth | bridge (no clients installed yet) |
| `is_screencasting`, `hypr_submap`, `active_layout` | (spec'd; not all fed) | share state, keymap | partial |

**The two big gaps to actionability:**
1. `Affordance` has no **action** — offers describe, they don't *do*. (Fixed by this line of work: an `AffordanceAction` the daemon executes.)
2. The daemon runs the raw `Engine` but not the **Mind**, and there is no dynamic surface for Mind offers. (Fixed: run `Mind`, surface actionable affordances as topbar OPTION pills.)

---

## 1. The use-case catalog

For each: the actions users reach for, the detectable trigger, the offers OPTIONS
should surface, and feasibility. Ordered roughly by **value × feasibility**.

### 1.1 Watching / listening to media  — Activity::Media (also ambient under Coding/Browsing)
**Reach-for:** play/pause, next, previous, seek ±, volume up/down/mute, fullscreen,
"cast to…", subtitle/caption toggle, playback speed.
**Signals:** `media.is_playing` **[live]**, `media.title/artist` **[live]**,
`audio.default_sink_volume`/`is_muted` **[live]**, `window.is_fullscreen` **[live]**.
Seek/position: MPRIS `Position`/`Seek` **[cheap]** (media collector already has the
MPRIS proxy). Brightness (for video): read `/sys/class/backlight` **[cheap/new]**.
**Offers → actions:**
- Play/Pause → `playerctl play-pause` (or MPRIS `PlayPause`)
- Next / Previous → `playerctl next` / `previous`
- Volume −/+ / Mute → `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-|5%+` / `set-mute … toggle`
- Seek −10s/+10s → `playerctl position 10-` / `10+`
- Brightness −/+ → `brightnessctl set 10%-|+10%` (ships system-wide)
**Module:** `media-controls`. **Priority: HIGHEST** (universal, all signals live, all
actions are one-shot CLIs already on the system). *This is the first vertical slice.*

### 1.2 Programming / coding  — Activity::Coding
**Reach-for:** commit, push, pull, stage, diff, run/build/test, format, jump-to-error,
open terminal in repo, branch switch, blame, resolve conflicts.
**Signals:** editor/terminal `window.class` **[live]**, `git.repo_root/branch/is_dirty`
**[live]**, `app_internal.editor_file/language/diagnostics` **[bridge]**,
`app_internal.shell_last_cmd/exit_code` **[bridge]**.
**Offers → actions:**
- Commit all → `git -C <root> commit -am …` (needs a message → opens an input, or
  a quick "commit all (wip)")
- Push → `git -C <root> push`
- Pull → `git -C <root> pull --ff-only`
- Open terminal here → spawn `foot` with cwd = repo_root
- Show diff → `foot -e git -C <root> diff`
- (bridge) Run last build/test → re-run `shell_last_cmd`; Jump to first diagnostic
**Module:** `git-actions` (dirty→commit/push) + `dev-run` (bridge-fed). **Priority:
HIGH** for git-actions (all signals live), MED for dev-run (needs bridge clients).
*Second candidate vertical slice: dirty repo → Commit/Push.*

### 1.3 Text / document editing  — (editor or office app focused)
**Reach-for:** copy, cut, paste, find, replace, undo/redo, bold/italic, save,
word-count, spellcheck.
**Signals:** `window.class` in an editor/office set **[live]**; `selection.char_count`
**[live]** for "you have a selection". Rich in-app edit state **[bridge/new]**.
**Offers → actions:** the clipboard OPTION already covers paste/copy-link. Find/replace,
bold/italic map to **synthetic keystrokes** (`wtype`/`ydotool`) **[new dep]** — feasible
but needs a key-injection tool; marked designed-not-built. Paste is live today.
**Module:** `text-edit` (mostly bridge/keystroke). **Priority: MED** (paste live; the
rest needs key injection).

### 1.4 Web browsing  — Activity::Browsing / Reading
**Reach-for:** copy page link, new tab, back/forward, find in page, bookmark, reader
mode, open link in app, share, download.
**Signals:** browser `window.class` **[live]**, `app_internal.browser_url` **[bridge]**,
`app_internal.is_reading_docs` **[bridge]**, `selection.contains_url` **[live]**.
**Offers → actions:**
- Copy page link → already the `ClipCopyLink` pill (browser focused) **[live]**
- Open copied link → `xdg-open <url>` (from `selection.url`) **[live]**
- New tab / back / forward / find → keystrokes to the browser **[new]**
**Module:** `browser-actions`. **Priority: MED** (copy-link + open-copied-url live; nav
needs keystrokes).

### 1.5 Terminal work  — Activity::Terminal
**Reach-for:** re-run last, copy output, cd to repo, clear, kill job, open a second pane.
**Signals:** terminal `window.class` **[live]**; `shell_last_cmd/exit_code` **[bridge]**;
`git` context **[live]**.
**Offers → actions:** Re-run last command / Explain failure (on nonzero exit) — the
`shell.last_failed` provider exists (Info today); make it an Action that re-runs or
opens help **[bridge]**. **Priority: MED** (needs the shell bridge hook).

### 1.6 File management  — (file manager focused)
**Reach-for:** new folder, rename, copy/move, compress, extract, open terminal here,
properties, trash.
**Signals:** file-manager `window.class` (nautilus/thunar/dolphin) **[live]**; the
selected file path **[new — needs a file-manager bridge]**.
**Offers → actions:** "Open terminal here" (spawn terminal) is doable once cwd is known
**[bridge/new]**. **Priority: LOW-MED** (needs a file-manager signal).

### 1.7 Video calls / meetings  — Activity::Communication (mic live)
**Reach-for:** mute/unmute mic, camera on/off, share screen, leave, raise hand.
**Signals:** `audio.is_mic_active` **[live]** (already the dominant activity),
`is_screencasting` **[partial]**, camera in use `/dev/video*` open **[new]**.
**Offers → actions:**
- Mute/unmute mic → `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` **[live signal +
  one-shot action]** — HIGH value the moment the mic goes live.
- Stop sharing → surfaced today as a Warning (screencast) — make it an action.
**Module:** `call-controls`. **Priority: HIGH** (mic-mute: live signal + trivial action).

### 1.8 Image / photo editing  — (gimp/krita/inkscape/darktable focused)
**Reach-for:** undo/redo, export, crop, brush size, zoom-fit, colour pick.
**Signals:** `window.class` in an image-app set **[live]**; internal state **[new]**.
**Offers → actions:** mostly keystrokes/in-app **[new]**. **Priority: LOW** (little
sensable beyond "an image editor is focused").

### 1.9 Video editing  — (kdenlive/davinci/shotcut)
Similar to 1.8: `window.class` **[live]**, rest **[new]**. **Priority: LOW.**

### 1.10 Gaming  — (a game is fullscreen/foregrounded)
**Reach-for:** do-not-disturb, performance mode, screenshot, record, brightness.
**Signals:** `window.is_fullscreen` + non-standard class **[live]**; high GPU/CPU
**[live cpu]**. **Offers:** DND toggle (mute notifications — already have NotifMute),
screenshot (`grim`), record (`wf-recorder`) **[cheap: spawn]**. **Priority: MED**
(DND + screenshot are trivial spawns; "is gaming" detection is heuristic).

### 1.11 Reading / PDF  — Activity::Reading (docs) or a PDF viewer focused
**Reach-for:** next/prev page, zoom, search, night mode, TOC.
**Signals:** `is_reading_docs` **[bridge]**; PDF-viewer `window.class` (papers/evince)
**[live]**. **Offers:** page nav via keystrokes **[new]**; brightness/night **[cheap]**.
**Priority: LOW-MED.**

### 1.12 Downloading / transfers
**Signals:** a download in progress **[new — browser bridge or watching ~/Downloads]**.
**Offers:** open Downloads, open file when done. **Priority: LOW.**

### 1.13 Email / chat  — Activity::Communication (no mic) / an app class
**Signals:** `window.class` in a mail/chat set **[live]**; unread via notifications
**[live]**. **Offers:** reply (open app), mark read (notification action) — the
notifications OPTION owns this. **Priority: MED** (largely covered by notifications).

### 1.14 Presentations  — (impress/a slideshow fullscreen)
**Signals:** fullscreen + office class **[live]**. **Offers:** next/prev slide
(keystrokes), DND, laser pointer. **Priority: LOW** (needs keystrokes).

### 1.15 System / power situations  — always-on background module
**Reach-for:** plug in (low battery), reboot (stale generation), re-deploy (not
activated), free RAM (pressure), reconnect wifi/bluetooth.
**Signals:** `metrics.battery_pct/is_charging` **[live]**, `deploy.*` **[live]**,
`metrics.cpu/ram` **[live]**, mic/screencast **[live]**.
**Offers → actions:**
- Battery critical → Warning (live today); action: nothing to *do* but plug in.
- Stale generation → **Reboot** (`systemctl reboot`) / not-activated → **re-run switch**
  (`rebuild-golem`) **[cheap: spawn, gated to Golem]**.
- Screen sharing live → Warning (live); action: stop share.
**Module:** `system-health` (already half-built as providers; add actions).
**Priority: HIGH** (signals all live; a couple of safe spawns turn warnings into fixes).

---

## 2. Priority ranking (value × feasibility)

| Rank | Module | Why now |
|---|---|---|
| 1 | **media-controls** | universal; every signal live; actions are one-shot CLIs on the system |
| 2 | **call-controls (mic mute)** | live signal (`is_mic_active`), trivial `wpctl` action, high value the instant a call starts |
| 3 | **git-actions (commit/push)** | repo/dirty all live; actions are `git -C <root> …`; the canonical "coding" demo |
| 4 | **system-health actions** | battery/deploy/screencast all live; adds safe spawns to existing warnings |
| 5 | **browser-actions (open copied url / copy link)** | partly live already (ClipCopyLink); `xdg-open` for copied url |
| 6 | dev-run, text-edit, terminal, file-mgmt, gaming, reading | need bridge clients or a key-injection tool — designed, staged behind a collector/dep |

---

## 3. The module mechanism (what an OPTIONS "module" IS)

A **module** = **a context matcher + a set of offers + the action each performs.**
Concretely, in this engine a module is expressed as a **provider** —
`fn(&ContextState) -> Vec<Affordance>` — where each `Affordance` now carries an
`AffordanceAction` describing what triggering it does. The Mind already ranks,
gates by source liveness, de-clutters by activity, and caps; modules just add
offers with actions.

```
module = provider(ctx) -> [ Affordance { id, kind, title, detail, relevance,
                                          source, action } ]
```

**Action vocabulary** (`AffordanceAction`, executed by the daemon):
- `None` — pure information (today's affordances).
- `Spawn { argv }` — run a program, fire-and-forget (playerctl, wpctl, brightnessctl,
  git, grim, rebuild-golem, xdg-open). Covers the overwhelming majority of offers.
- `HyprDispatch(cmd)` — a compositor dispatch (fullscreen, close) via the existing
  `hypr::` helpers.
- `OpenUrl(url)` — `xdg-open` a URL (from the selection module).
- *(future)* `Keys(chord)` — synthetic keystrokes (needs `wtype`/`ydotool`); unlocks
  find/replace, tab nav, slide nav, page nav.

**Surface:** the actionable affordances (kind `Action` with a non-`None` action) are
rendered as **OPTION pills** on the topbar (reusing the existing pill machinery), in
the free left-centre band. Clicking a pill runs its action. Pure `Info`/`Warning`
affordances continue to inform (and can grow actions over time). The whole set is
Mind-ranked and capped, so the bar never clutters — "surface the right thing, then
get out of the way."

**Why the topbar, not a new box:** pills already exist, animate, hit-test and dispatch;
the design note at `options.rs:249` explicitly reserves this seam for the Brain. A box
(like clipboard/notifications) remains the right home for *rich* modules later (a media
scrubber, a diff view), but the atomic "right action, right moment" is a pill.

---

## 4. What's real vs designed vs still-needed (honest status)

Updated 2026-09-02 after building + validating the mechanism in the golem-vm.

**REAL and proven end-to-end (sensed → surfaced → action performs), validated in
the golem-vm with screenshots:**
- The **action vocabulary** — `AffordanceAction { None, Spawn{argv}, HyprDispatch,
  OpenUrl }` and the `AffordanceKind::Control` (never skill-faded). Affordances now
  carry a real `action` (options-engine).
- The **Mind wired into the daemon**: `brain.rs` runs `Mind`, streams the ranked
  `OptionSet`; the daemon surfaces the actionable offers as **dynamic OPTION pills**
  on the topbar (glyph circles, ranked, capped at 5) and dispatches the action on
  click (or the `options-trigger <id>` IPC verb). This is the general mechanism:
  a *module* = a provider (context matcher → offers) whose offers carry actions.
- **git-actions** (Commit all / Push): dirty repo while Coding → the two Control
  pills; triggering **git.commit landed a real commit** (1→2), then the pills
  reactively cleared when the tree went clean. Required a collector fix — the git
  collector now walks the focused window's child shells (foot resets its own cwd to
  `/`), so "a terminal in a repo → Coding" is finally sensed.
- **media-controls** (Play/Pause, Volume ±, Next/Prev, Brightness ±): an MPRIS
  player present → the control cluster; triggering **play/pause toggled VLC**
  (Playing→Paused) and **vol_up moved the sink** (1.00→1.05). The play/pause glyph
  flips Play↔Pause reactively. Brightness is offered only where a backlight exists
  (`has_backlight`, sensed from `/sys/class/backlight`) — the VM correctly shows no
  brightness pills; a laptop would.
- **selection / open-copied-url**: a copied URL → an "Open copied link" Control that
  `xdg-open`s it (dispatch confirmed).

**REAL in the engine, mechanism proven, live collector unconfirmed in the VM:**
- **call-controls (mic mute)**: the engine emits the mute Control when `is_mic_active`
  (unit-tested), and the surfacing/dispatch path is the same one proven three times
  above — but a *running* capture stream couldn't be conjured in the headless VM (no
  real mic), so the audio collector firing wasn't observed here. Expected to work on
  real hardware / a real call. SUSPECTED.

**Designed here, cheap to add next (reuse the proven mechanism):**
- system-health actions: stale-generation → Reboot, not-activated → re-run switch,
  screencast → Stop sharing (each a Spawn/HyprDispatch on an existing warning). Not
  built because they're destructive/guarded to validate autonomously (reboot; and the
  loop must not run `nixos-rebuild switch`).
- true seek (playerctl position ±10s) alongside next/prev; a hover tooltip showing
  each pill's title for discoverability.

**Still needed (blocked on a collector/dep):** bridge clients (shell/editor/browser
hooks) for dev-run, terminal re-run, reading-mode; a file-manager selection signal; a
key-injection tool (`wtype`/`ydotool`) for text/nav/slide offers; a camera-in-use
sensor for calls.

## 5. The proven vertical slices (commits)

- `options-engine`: actions + Control kind + the four modules; git child-shell walk;
  backlight sensing + gating.
- `daemon`: Mind streamed into the loop; dynamic OPTION pills (`PillId::Option`);
  action dispatch (`run_affordance_action`); `debug-options` / `options-trigger` IPC.
- Validated in the golem-vm (see the loop's report for screenshots): git commit &
  push, media transport & volume, open-copied-url — each sensed by the Brain,
  surfaced as a pill, and its action actually performed.
