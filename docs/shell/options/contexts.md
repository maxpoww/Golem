# LIST 1 — CONTEXTS

*The curated list of situations a person is actually in. Max's file: cut,
rename, merge, add. Proposed 2026-09-12; nothing here is settled until he
has been through it.*

**APPROVED by Max 2026-09-12 and BUILT the same day.** `Activity` in
`options-engine/src/mind/activity.rs` is now these seventeen plus `Idle`
and `Unknown` — it was eight coarse values (`Idle, Communication,
Reading, Browsing, Coding, Terminal, Media, Unknown`) with no drawing, no
video editing, no gaming and no music production. The classifier
recognises each from its window class, keeping the two rules that were
argued out on live hardware: a terminal must show **dev work** to count
as Coding (a repo cwd is not an intention), and a browser title that
reads like documentation flips Browsing → Reading without a bridge.

Every OPTION in [options-list.md](options-list.md) names one of these on
its `Shows in:` line. A context with no OPTIONS is a context we have not
earned yet; an OPTION with no context does not exist.

---

## Primary contexts

What you *are* doing. One at a time.

| # | Context | What it is | Sensed by |
|---|---|---|---|
| 1 | **Coding** | writing software | editor focused, or a terminal where dev work is actually happening |
| 2 | **Writing** | prose — documents, notes, long-form | word processor, notes app, prose editor |
| 3 | **Drawing** | raster and vector art, and layout | Krita, GIMP, Inkscape, Aseprite, Scribus |
| 4 | **Photo editing** | developing and correcting photographs | darktable, RawTherapee |
| 5 | **Video editing** | cutting and grading video | kdenlive, Shotcut, DaVinci |
| 6 | **Music production** | composing, recording, mixing | a DAW — Ardour, Reaper, Bitwig, LMMS |
| 7 | **3D / CAD** | modelling, sculpting, parametric design | Blender, FreeCAD |
| 8 | **Reading** | documents, books, documentation | PDF/ebook reader, or docs in a browser |
| 9 | **Browsing** | general web, not clearly reading | browser focused |
| 10 | **Watching** | video with your attention on it | fullscreen video, or the focused browser is the MPRIS player |
| 11 | **Gaming** | playing | a game focused — fullscreen + gamepad + known launchers |
| 12 | **On a call** | a live conversation | mic captured, meeting app focused |
| 13 | **Messaging** | chat, asynchronous | chat app focused |
| 14 | **Terminal** | shell work that is not clearly coding | a terminal focused |
| 15 | **Files** | moving, sorting, organizing | file manager focused |
| 16 | **Presenting** | showing something to an audience | slides fullscreen, or screencasting |
| 17 | **Configuring** | settings, packages, Modules | **the bar should go quiet here** — the user is already somewhere deliberate |
| — | **Idle** | nothing focused | empty workspace |
| — | **Unknown** | an app we do not classify | the honest fallback — never guess |

## Shell arrangement — the second axis

*Added by Max 2026-09-12, approving the seventeen: "we also need normal
tile, stage, overview, empty workspace, second monitor — all of those
will condition the options too."*

These are **not more contexts.** You can be *coding on the stage*,
*coding in the overview*, or *coding with a second screen*, and each
wants something different on the bar while what you are doing has not
changed at all. Folding them into the list above would force a choice
between two facts that are both true.

| State | What it is | Sensed by |
|---|---|---|
| **normal tile** | the ordinary tiled session | the default |
| **stage** | one task alone at the stage rect, the deck beneath (`stage.rs`, Super+Enter) | `stage.is_on()` |
| **overview** | waveview owns the screen | `overview_active` |
| **empty workspace** | **no windows — a NEW one** | counted from the compositor (`activeworkspace.windows == 0`), never inferred from "nothing focused": an unfocused floating window leaves the workspace occupied, and a new workspace is an invitation while an unfocused one is just a pause |
| **second monitor** | two or more displays | the Wayland output count |

### What each arrangement SHOWS — the rule

*Max, 2026-09-12: "stage will show the context options + a couple of
stage-specific options; overview will show overview options, because
overview is not meant to show per-context options — it's meant to show
window-management options."*

So the arrangement does not merely *add* to the context axis — **the
overview replaces it.**

| Arrangement | Shows |
|---|---|
| **normal tile** | context OPTIONS |
| **stage** | context OPTIONS **+** stage-specific |
| **overview** | overview OPTIONS **only** — window management. What you were doing is not the question while you are looking at your windows |

Every OPTION therefore declares a `ShowsIn` — `Context`, `Stage` or
`Overview` — and the filter runs inside the **decision**, not in the
surface: the Mind must never rank a context OPTION in the overview, or it
could win a slot and displace a window-management one.

**Who owns it:** the collectors *cannot* sense this. STAGE and the
overview are waverunner's own modes — invisible to the compositor — so
this axis travels **surface → mind**, the opposite direction from every
other signal. `Mind::set_shell()` is the door, and the daemon calls it
whenever a mode, the workspace's emptiness or the screen count changes.

**Known and deliberately not modelled yet:** `Estructure.md` also lists
**Stage 2** and **zoomout**. A mode earns a variant when an OPTION needs
to tell it apart — the same growth rule the module census uses.

**Built 2026-09-12:** `options-engine/src/mind/shell.rs` — `ShellMode`
(normal tile / stage / overview) + `ShellState { mode, workspace_empty,
monitors }`, threaded through `decide_with` beside the activity, with
`fits_shell` as the suppression seam alongside `fits_activity`.

## Ambient states

True *alongside* a context, never instead of one. A lot of OPTIONS key off
these rather than off what you are doing, which is why they are listed
separately — the `Shows in:` line may name one.

| State | True when |
|---|---|
| **media playing** | something is playing and it is not what you are looking at |
| **a call is live** | the mic is captured |
| **screen shared / recording** | a screencast or a recording is running |
| **camera live** | something holds `/dev/video*` |
| **on battery / running low** | unplugged, and the threshold crossed |
| **a device arrived** | display, audio device, tablet, USB storage |
| **a file just appeared** | export folder, downloads, a screenshot |
| **the clipboard has something** | a selection was copied |
| **the system needs attention** | disk nearly full, network down, update waiting |

---

## Decisions taken in this cut — argue with any of them

- **Design / layout folded into Drawing.** Separate tools, but the moments
  the shell can serve are the same (reference on top, colour pick, tablet,
  export). Split it back out the moment an OPTION wants one and not the
  other.
- **Listening demoted from a context to an ambient state.** It is almost
  never what you are *doing*; it is what is also true while you do
  something else. The engine already models this (`media_is_foreground`).
- **Searching is not a context.** The launcher being open is a mode of the
  shell, not a situation you are in.
- **"Configuring" earns its place by being where the bar shuts up.** A
  context can be valuable for what it suppresses. The user is already
  somewhere deliberate; an offer here is an interruption.
- **Coding is not split by language.** Rust vs Python changes parameters,
  not what should be on the bar. A split is warranted only when the
  OPTIONS differ.
- **Unknown is kept and stays honest.** Guessing a context to have
  something to offer is how a shell starts lying.
