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

Updated 2026-09-02 (pass 2) after building + validating the mechanism in the golem-vm.

**The mechanism — REAL and proven:** `AffordanceAction { None, Spawn{argv},
HyprDispatch, OpenUrl }` + `AffordanceKind::Control` (never skill-faded) +
`Affordance.action`. `brain.rs` runs the `Mind` and streams the ranked `OptionSet`
into the daemon; the daemon surfaces the actionable offers as **dynamic OPTION pills**
on the topbar (glyph circles by affordance id, Mind-ranked, capped at 5) and dispatches
the action on click (or the `options-trigger <id>` IPC verb). A *module* is just a
provider (context matcher → offers-with-actions); adding one is a pure function. The
ranking blends multiple active modules and de-clutters by relevance/cap (unit-tested).

**SEVEN vertical slices proven end-to-end (sensed → pill → action performs), each
validated live in the golem-vm with a screenshot:**
1. **git.commit** — dirty repo while Coding → ✓ pill → **landed a real commit** (1→2),
   pills reactively cleared when clean. (Needed a collector fix: the git collector now
   walks the focused window's child shells, since foot resets its own cwd to `/`.)
2. **git.push** — surfaced alongside commit (⬆ pill); action = `git -C <root> push`.
3. **media.playpause** — MPRIS player → ⏸/▶ pill → **toggled VLC** (Playing→Paused);
   glyph flips reactively.
4. **media volume** — 🔉/🔊 pills → **moved the sink** (`wpctl`, 1.00→1.05).
5. **media seek** — ⏪/⏩ pills → **advanced VLC position** (playerctl, 17.6s→38.5s on
   2× +10s). Seek outranks track-skip so the 5-pill cluster is the video set
   (play/pause, volume, seek).
6. **audio.mic_mute** — a running capture → activity flips to Communication, media
   controls clear, 🎤̶ pill → **toggled source mute** (`wpctl`, [MUTED]↔on).
7. **selection.url / selection.search** — a copied URL → "Open copied link"; any other
   copied text → "Search the web" 🔍 → **opened Chromium to the DuckDuckGo query**
   (percent-encoded). And **system.high_cpu** — spun CPU >85% → 📊 pill → **launched
   btop** in foot. (That's the 4 original + seek + search + cpu-monitor.)

**Additional slices (grind pass), each validated in the golem-vm:**
8. **git.pull** — coding in a repo → Pull control → triggering it **fast-forwarded the
   local repo** to an ahead remote (HEAD advanced, pulled file appeared). --ff-only.
9. **selection.open_path** — a copied absolute path → "Open file" → xdg-open (dispatch
   confirmed). New signal `TextSelection.is_path`.
10. **selection.email** — a copied email address → "Compose email" → xdg-open mailto:
    (surfaced + triggered).
11. **shell.search_error** — the **first app-bridge CLIENT** (a zsh preexec/precmd hook
    over zsh's built-in socket module, shipped in `system/home/zsh.nix`): a failed
    command flows hook → bridge socket → collector → an actionable "Search the error"
    Control (web-search the command). Confirmed: running a failing command surfaced the
    control. This also makes the friction/skill signals real.
12. **coding.terminal_here** — coding in a repo → "Terminal here" opens a terminal in
    repo_root (foot --working-directory). Confirmed (trigger opened a new terminal).
13. **git.open_remote** — new `GitContext.remote_url` (collector parses origin from
    .git/config, normalizes ssh/https → https web url) → "Open remote" opens the repo's
    GitHub/GitLab page. Confirmed (opened Chromium to the GitHub page).
14. **audio.call_dnd** — a call (mic live) → "Do not disturb" mutes notifications, via
    the new `AffordanceAction::Daemon(tag)` (an internal daemon action). Engine-tested;
    the call context + NotifMute toggle are separately proven (live capture flaky this
    boot). SUSPECTED live.

15. **camera.live + privacy warning pills** — new collector signal
    `SystemMetrics.is_camera_active` (system collector scans /proc/<pid>/fd for an open
    /dev/video*). The topbar now surfaces the privacy/safety WARNINGS (camera, mic,
    screencast) as **amber, non-clickable indicator pills** (via `is_surfaced_affordance`;
    battery/deploy excluded). Confirmed: holding an fd on /dev/video10 raised an amber
    camera pill.
16. **files.open_here** — the shell bridge now also reports `cwd`; a terminal offers
    "Open files here" (xdg-open the folder → default file manager). Engine-tested; live
    end-to-end needs the shipped cwd-hook (validated on VM rebuild).

17. **window.fullscreen_dnd** — a fullscreen window (video/game/presentation) offers
    "Do not disturb". Confirmed: fullscreen → control surfaced, and triggering it flipped
    the notif-state `muted` false→true→false (proves `AffordanceAction::Daemon` end to end;
    also confirms the call-DND action).
18. **browser.find** — a browser focused → "Find in page" (Ctrl+F). The action is a
    **compositor keystroke** (`send_shortcut_active`, the same no-dep path as clipboard
    paste), so keystroke offers need NO wtype/ydotool. Confirmed (Browsing → control →
    triggered).

**Ranking/quality:** background media controls (music while coding) are damped ×0.65 so
the work controls (git) lead; when media IS the activity (watching), full weight. The
OPTION-pill hover re-hit-tests on set change so a click never fires a stale control. New
`AffordanceAction::Daemon(tag)` lets an offer drive the shell (DND, find-in-page).
Non-clickable warning pills keep the default cursor.

**Media box:** BUILT (mediabox.rs). A music-glyph pill appears when a player is active; clicking it (or `debug-media-box`) grows a transport box into the reserved dropdown region: track title, prev/play-pause/next, a seek bar showing live MPRIS position (0:22 / 1:30), and a volume bar (click-to-set). CONFIRMED rendering in the VM with VLC. Draggable sliders + hover-peek are the next refinement.

Brightness is offered only where a backlight exists (`has_backlight` from
`/sys/class/backlight`) — the VM correctly shows none; a laptop would.

**Designed, cheap next (reuse the proven mechanism):**
- system-health actions: stale-generation → Reboot, not-activated → re-run switch,
  screencast → Stop sharing (Spawn/HyprDispatch on an existing warning). Not built —
  destructive/guarded to validate autonomously (reboot; the loop must not run
  `nixos-rebuild switch`).
- a **media box** (expand a single media pill to the FULL control set — transport +
  volume + seek + brightness + next/prev) for when the 5-pill cap overflows.
- a **hover tooltip** showing each pill's title (discoverability). Deliberately not
  built: the topbar renderer (metamorphosis / clip / neumorph paths) is delicate and
  the glyphs are standard; flagged so Max can decide.
- terminal-in-repo → "Open a new terminal here" (cwd already sensed via the child walk).

**Still needed (blocked on a collector/dep):** bridge clients (shell/editor/browser
hooks) for dev-run, terminal re-run, reading-mode; a file-manager selection signal; a
key-injection tool (`wtype`/`ydotool`) for text/nav/slide offers; a camera-in-use
sensor for calls.

## 5. The mechanism & modules (where in the code)

- `options-engine` (`mind/`): `AffordanceAction` + `Control` kind + `Affordance.action`;
  modules in `decide.rs` — media-controls (playpause/volume/seek/brightness/skip),
  git-actions (commit/push), call-controls (mic mute), selection (open-url / search),
  system (high-cpu monitor). Collectors: git now walks child shells (`git.rs`);
  `has_backlight` in `system.rs`.
- `daemon`: `brain.rs` runs the Mind and streams the `OptionSet`; `options.rs` renders
  dynamic OPTION pills (`PillId::Option`, `glyph_for_option`) and dispatches actions
  (`run_affordance_action` / `action_command_line`, shell-quoted); `main.rs`
  `on_options` (signature-guarded redraw); `debug-options` / `options-trigger <id>` IPC.
- All validated in the golem-vm with screenshots (see the loop report): each of the
  seven slices in §4 was sensed by the Brain, surfaced as a pill, and its action
  actually performed.

19. **editor.diagnostics / editor.open_folder** — the SECOND app-bridge client: an nvim
    initLua autocmd (libuv socket) reports the buffer's file/language/diagnostics. Live
    CONFIRMED: an editor message with diagnostics=3 surfaced "3 problems"; "Open folder"
    (xdg-open the edited file's dir) shares that proven path while Coding.
20. **media.mute** — quick mute/unmute the sink (wpctl), in the media cluster.

## 6. File-manager selection — investigated, no clean signal (documented)

Sensing the *current selection* in a focused file manager was investigated (task
"file-manager selection collector"). Finding: **there is no standard signal to
read a file manager's live selection.**
- Nautilus (GNOME Files) exposes `org.freedesktop.FileManager1` (ShowItems /
  ShowFolders) and `org.gtk.Actions` — these *drive* the manager, they don't
  report what's selected. No "get selection" method or signal.
- Thunar exposes `org.xfce.FileManager` / `org.xfce.Thunar` — again actions
  (launch, display-folder, bulk-rename), not a selection read.
- The window process's cwd stays at launch dir (nautilus doesn't chdir), so
  "current folder" isn't derivable from `/proc` either.
The only clean path is a **file-manager extension** that pushes the selection to
the OPTIONS bridge socket — a bridge CLIENT exactly like the shipped zsh and
nvim ones (e.g. a `nautilus-python` extension on `selection-changed`). That is
the same shape as the other bridges and is the recommended next step; it is not
a "collector" that can read the signal without the manager's cooperation.
PARTIAL today: when the user *copies* files, the clipboard carries their paths,
which the selection collector already classifies (a single copied path →
"Open file"). Multi-file copies could be added there.
DECISION: documented, deferred to a file-manager bridge extension.

## 7. Grind-pass additions (continued)

21. **git.diff** — dirty repo while coding → "Show diff" (`git diff | less` in a terminal).
22. **shell.rerun** — "Re-run last" runs the shell bridge's last command in a fresh
    terminal at its cwd (dev-run). Reuses the shell bridge + foot spawn.
23. **reading.find / reading.bright** — a PDF/document reader focused (Papers/evince/
    zathura/okular/…) → Find (Ctrl+F) and, on a laptop, reading brightness.
24. **editor.run** — editor bridge deepening: editor_language → interpreter
    (python3/node/ruby/bash/lua/perl/php) → "Run this file" in a terminal. Compiled
    languages skipped (project builds, not single-file).
25. **keystroke offers via the compositor** — `find_in_page` etc. use Hyprland's
    `send_shortcut` (the same path as clipboard paste), so keystroke-based offers need
    NO wtype/ydotool dependency. This unlocks the whole "text/browser/reading" keystroke
    class the catalog had marked blocked-on-a-key-tool.

Engine providers now number ~19 (media/media-controls, git, coding-tools, dev-run/rerun,
files, editor, selection, shell-error, browser, reading, mic/call, camera, fullscreen,
cpu, battery, deploy, screencast, notifications) + the media BOX surface. ~30 distinct
offers across the desktop use-cases.

26. **window.screenshot** — fullscreen → Screenshot (grim → ~/Pictures).
27. **slides.next / slides.prev** — a fullscreen office app (impress/…) → Next/Previous
    slide via arrow keys (compositor keystroke). Gated on fullscreen (the slideshow).
28. **downloads.open / downloads.extract** — a file just finished downloading → "Open
    download" (xdg-open by type), plus "Extract here" (file-roller) when it's an archive.
    A new `downloads` collector polls `$XDG_DOWNLOAD_DIR`/`~/Downloads` on a 3 s timer,
    reports the newest regular file whose mtime is within 90 s (skipping
    `.part`/`.crdownload`/`.tmp` sidecars and hidden files), and clears it once it ages
    out — the transient "you just grabbed this" moment, not a pin. **CONFIRMED live in the
    golem-vm:** dropping `holiday-photos.zip` into ~/Downloads surfaced both controls
    (daemon log `options: 2 control(s) [downloads.extract, downloads.open]`, pills visible
    in the topbar).
29. **system.battery_dim** — on a laptop at critical battery (≤15 %, on power), the warning
    gains a one-tap "Dim screen" Control (brightnessctl set 40 %) — the backlight is the
    biggest draw, so this is the most effective runtime-stretch. Gated on `has_backlight`.
30. **system.high_mem** — sustained RAM ≥90 % → "open monitor" (foot btop), mirroring
    high-CPU. Gated above the CPU threshold so at most one monitor pill ever shows.
31. **browser.reopen_tab** — Browsing → "Reopen closed tab" (Ctrl+Shift+T, compositor
    keystroke) alongside Find. Universal across browsers, the classic "oops" recovery.
32. **shell.install_missing** — a command-not-found (shell exit 127) in a focused
    terminal → "Install <cmd>?" whose action opens the launcher's Install search
    pre-filled with the missing program (new `pkgsearch:<name>` daemon action: set query
    → Toggle open → refilter, which also kicks the lazy pkg index). Command parsed by
    first_command_token (skips sudo/VAR=val, rejects paths). Gated to Terminal/Coding.
    **CONFIRMED live in the golem-vm:** shell exit-127 `cowsay hi` surfaced the pill
    (`options: … [shell.install_missing, shell.search_error]`); triggering it opened the
    launcher with the nixpkgs search showing cowsay + neo-cowsay/xcowsay/kittysay/…. Live
    validation caught a real bug (Expand is a no-op from Hidden; fixed to Toggle, fdcd88c).
34. **reading-mode from the window title** (browser-bridge fallback) — see the
    "Browser bridge (feasibility)" note above; a docs-titled browser tab infers
    Reading → reading offers (find, brightness), no bridge.
35. **slides.present** — a presentation app (impress/powerpoint/…) focused but not
    yet fullscreen → "Present" starts the slideshow (F5, compositor keystroke),
    complementing the fullscreen slide-nav.
37. **editor.build / editor.format** — editing a file, keyed off the bridge's
    editor_language: "Build project" for compiled langs (cargo/go/zig build, in
    the file's dir) complements editor.run (single-file scripts); "Format file"
    runs the language's in-place formatter (rustfmt/gofmt -w/black/zig fmt). Both
    shell-quote the file path, gated to Coding. The editor cluster is now
    open-folder + run/build + format. **CONFIRMED live in the golem-vm:** nvim
    open on a `main.rs` in a repo surfaced `[git.commit/push/pull/diff,
    editor.build, editor.format, coding.terminal_here]` — the real nvim bridge
    sent language=rust and both offers mapped in (editor.run correctly absent for
    a compiled language). Also confirms the nvim editor bridge is healthy.
36. **git.show_commit** — a bare git commit hash (7–40 hex) on the clipboard while
    focused in a repo → "Show commit" (git show in a terminal pager). The sha + repo
    root are shell-quoted (clipboard text). Gated to Coding. **CONFIRMED live in the
    golem-vm:** with foot focused in a repo and a SHA `wl-copy`'d, the daemon surfaced
    `[…, git.pull, git.show_commit, coding.terminal_here, selection.search]`.

38. **network.down / network.settings** (catalog-expansion 1/3, from §1.15
    "reconnect wifi") — a new pure-sysfs sensor (`is_network_down`: no
    non-loopback `/sys/class/net/*/operstate` is `up`; errs toward not-down on
    unreadable sysfs) surfaces an amber "No network" warning pill plus a
    "Network settings" Control (foot nmtui — nmtui ships with NetworkManager
    itself). Provider unit-tested; the sysfs sensor is the same mechanism as the
    confirmed backlight/camera sensors. Live end-to-end SUSPECTED (inducing it
    needs root to down the interface, unavailable in the VM without passwordless
    sudo — and downing the interface kills the validation SSH anyway).
39. **reading.page_next / page_prev** (2/3, from §1.11) — a focused PDF/document
    reader gets Next/Previous page (PageDown/PageUp keystrokes, XKB
    `Next`/`Prior`). Unit-tested; CONFIRMED-by-construction — the identical
    send_shortcut tag path as the live-confirmed find_in_page and slide nav (no
    reader app installed in the VM to see it live).
40. **window.record / window.record_stop** (3/3, from §1.10 gaming "record") —
    fullscreen offers "Record screen" (timestamped MP4 → ~/Videos via
    wf-recorder, added to the Golem home packages next to grim); a new
    `is_recording` sensor (one /proc comm scan, like camera-in-use) drives the
    always-on "Stop recording" Control (pkill -INT so the file finalizes),
    which stays reachable after leaving fullscreen. **CONFIRMED live in the
    golem-vm** (comm-faked recorder): recording →
    `[window.record_stop, window.fullscreen_dnd, window.screenshot]` (stop
    ranked first, record gone); stopped → record returns, stop clears.

41. **selection.define** (micro-cases batch, §1.3/§1.11 "define/lookup") — a
    copied SINGLE WORD (2–32 letters incl. hyphen/apostrophe; skipped when the
    selection reads as a git sha) earns "Define word", ranked above the generic
    web search. New daemon tag `define:<word>`: expands the clipboard box, opens
    its offline dictionary panel, seeds the query (the DebugDict sequence).
    **CONFIRMED live in the golem-vm:** `wl-copy serendipity` surfaced
    `selection.define` above `selection.search`; `options-trigger
    selection.define` opened the dict panel pre-filled "serendipity"
    (screenshot).
42. **text.find** (§1.3 document editing) — a focused word processor
    (libreoffice/abiword/gedit/gnome-text-editor/kwrite/onlyoffice/wps) gets
    "Find" via the same universal-Ctrl+F `find_in_page` tag as the browser's
    live-confirmed Find. Unit-tested; CONFIRMED-by-construction (identical tag
    path; no word processor installed in the VM). The richer §1.3 reach-fors
    (replace, formatting, word-count) remain bridge-gated.
43. **creative.undo** (§1.8/§1.9 image & video editing) — gimp/krita/inkscape/
    darktable/kdenlive/shotcut/blender get "Undo" (Ctrl+Z), the one chord
    universal across the set. Redo deliberately NOT offered (chord diverges:
    Ctrl+Y vs Ctrl+Shift+Z — a control that's wrong in half the apps is worse
    than none). Unit-tested; CONFIRMED-by-construction (send_shortcut path).
    Everything richer in §1.8/1.9 (export, crop, brush) stays bridge-gated as
    documented.

**Discoverability:** the icon-only OPTION pills now show a hover **tooltip** with
the offer's title (a rounded label below the bar) — CONFIRMED in the golem-vm.

## 8. Coverage summary (grind mode)

Every general use-case from §1 now has real offers (sensed → pill → action), except
those documented as blocked:
- media/watching ✓ (controls + box), coding ✓ (git commit/push/pull/diff/remote,
  terminal-here, editor open-folder/run, rerun), text/selection ✓ (open url/path/email,
  search), browsing ✓ (find, reopen-tab, video-tab foregrounding), terminal ✓ (search-error,
  rerun, files-here), calls ✓ (mic-mute, DND), system ✓ (cpu/mem-monitor, battery-dim,
  privacy pills), reading ✓ (find, brightness, docs-title inference), presentations ✓ (present + slide nav),
  gaming/fullscreen ✓ (DND, screenshot), downloads ✓ (open, extract).
33. **reading-mode from the window title** (browser-bridge fallback) — a focused
    browser whose title reads like documentation (MDN, "Documentation", " docs",
    Stack Overflow, Wikipedia, "man page", "API reference", …) infers the Reading
    activity purely from the compositor-sensed title, so a docs tab gets the
    reading offers (find, brightness) with NO browser bridge. Strong markers only,
    so a false positive merely adds harmless offers.

**Browser bridge (feasibility, 2026-09-02).** A true browser bridge reporting the
active-tab URL + video-playing was assessed and is BLOCKED under the guardrails:
- A browser *extension* is the clean path but needs a store upload (nothing may
  leave the machine) and can't inject into Golem's sandboxed `--app` webapps.
- *CDP* (remote-debugging) would require launching the main browser with
  `--remote-debugging-port`, a local-security exposure (any process could then
  drive the browser); the webapps already expose it but they're single-app so the
  URL adds nothing over the window class.
- *Video-tab* detection — the one high-value signal — is ALREADY covered without a
  bridge by `media_is_foreground` (the MPRIS player being the focused browser).
So the pragmatic fallback is the title-based reading heuristic above; a real
URL/reader-mode signal waits on a packaged extension.

- Blocked (documented): file-manager selection (needs a manager extension bridge);
  a browser active-tab URL signal (needs a packaged extension — see above).

App-bridge CLIENTS shipped: zsh (shell: last_cmd/exit/cwd) and nvim (editor:
file/language/diagnostics). New sensors: camera-in-use, backlight, MPRIS position/length,
git remote-url + child-shell cwd walk, shell cwd, recent-download watcher. The action vocabulary: Spawn,
OpenUrl, HyprDispatch, Daemon(tag) (internal: toggle_dnd, find_in_page, reopen_tab,
slide_next/prev, fullscreen). Media BOX surface for the full transport. ~310 tests green.

**Memory (2026-09-02):** waverunner idle heap cut 170→97 MB anon (glibc arena cap +
lazy-loaded pkg index), validated in the golem-vm. See NOTES.md for the full RSS
breakdown — the remaining Golem-vs-GNOME gap is session daemons (easyeffects et al.),
not waverunner core.
