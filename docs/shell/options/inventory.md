# Inventory — the record of what was DELETED

> **None of population B exists any more.** Max's call, 2026-09-12: these
> 76 offers were grown by an autonomous build queue that chose its own
> targets, never curated, so they went. `decide.rs` lost 3,912 lines; the
> machine stayed. The curated replacements are [contexts.md](contexts.md)
> and [options-list.md](options-list.md).
>
> This file is kept as the record of what was removed — the evidence
> behind finding #82, and the map for anyone who wants the *plumbing* of a
> deleted offer back (recoverable from git at `9ed17b1`). The plumbing may
> be worth reusing; the offer was not.
>
> **Population A is untouched EXCEPT the media box**, which was the one
> hand-made surface the loop had built (2026-09-02, in GRIND's queue) and
> which went on the same rule, 2026-09-12. The provenance test used was
> the date the autonomous loop started: everything created before
> 2026-09-02 came out of a Max-directed session and stays.

*Census taken 2026-09-12 from the tree at `~/launcher` `3d9c364`, before
the deletion.*

**The count at deletion: 33 sources producing 76 offers, plus 8 hand-made
surfaces.**

---

## Population B — the Mind providers

32 providers in `PROVIDERS` (`options-engine/src/mind/decide.rs`) plus
`temporal_affordances`, each a pure `fn(&ContextState) -> Vec<Affordance>`.
Kinds: **C** = Control (never fades with skill) · **I** = Info (fades
gently) · **W** = Warning (never suppressed) · **A** = Action, scaffolding
(fades most).

| Module | Offers | Provider(s) |
|---|---|---|
| **media** (11) | `now_playing`ᴵ · `playpause`ᶜ · `prev`ᶜ · `next`ᶜ · `seek_back`ᶜ · `seek_fwd`ᶜ · `vol_up`ᶜ · `vol_down`ᶜ · `mute`ᶜ · `bright_up`ᶜ · `bright_down`ᶜ | `media_provider`, `media_controls_provider` |
| **git** (8) | `branch`ᴵ · `dirty`ᵂ · `commit`ᶜ · `push`ᶜ · `pull`ᶜ · `diff`ᶜ · `open_remote`ᶜ · `show_commit`ᶜ | `git_provider`, `git_sha_provider` |
| **system** (7) | `battery_low`ᴵ · `battery_critical`ᵂ · `battery_dim`ᶜ · `disk_full`ᵂ · `empty_trash`ᶜ · `high_cpu`ᶜ · `high_mem`ᶜ | `battery_provider`, `cpu_provider`, `memory_provider`, `disk_provider` |
| **selection** (6) | `url`ᶜ · `search`ᶜ · `open_path`ᶜ · `email`ᶜ · `define`ᶜ · `multi_path`ᶜ | `selection_provider` |
| **reading** (5) | `find`ᶜ · `bright_up`ᶜ · `bright_down`ᶜ · `page_next`ᶜ · `page_prev`ᶜ | `reading_provider` |
| **editor** (5) | `diagnostics`ᴵ · `build`ᶜ · `format`ᶜ · `run`ᶜ · `open_folder`ᶜ | `editor_provider`, `diagnostics_provider` |
| **window** (4) | `screenshot`ᶜ · `fullscreen_dnd`ᶜ · `record`ᶜ · `record_stop`ᶜ | `fullscreen_provider`, `recording_provider` |
| **shell** (4) | `last_failed`ᴵ · `search_error`ᶜ · `rerun`ᶜ · `install_missing`ᶜ | `shell_error_provider`, `rerun_provider`, `install_missing_provider` |
| **slides** (3) | `present`ᶜ · `next`ᶜ · `prev`ᶜ | `presentation_provider` |
| **audio** (3) | `mic_live`ᵂ · `mic_mute`ᶜ · `call_dnd`ᶜ | `mic_provider` |
| **session** (2) | `long_coding`ᴵ · `failure_streak`ᴬ | `temporal_affordances` |
| **notifications** (2) | `unread`ᴵ · `critical`ᵂ | `notifications_provider` |
| **network** (2) | `down`ᵂ · `settings`ᶜ | `network_provider` |
| **downloads** (2) | `open`ᶜ · `extract`ᶜ | `downloads_provider` |
| **deploy** (2) | `not_activated`ᵂ · `stale_generation`ᵂ | `deploy_provider` |
| **browser** (2) | `find`ᶜ · `reopen_tab`ᶜ | `browser_provider` |
| **text** (1) | `find`ᶜ | `doc_editor_provider` |
| **sunset** (1) | `eye_protection`ᶜ | `sunset_provider` |
| **files** (1) | `open_here`ᶜ | `files_here_provider` |
| **creative** (1) | `undo`ᶜ | `creative_provider` |
| **compositor** (1) | `screencasting`ᵂ | `screencast_provider` |
| **coding** (1) | `terminal_here`ᶜ | `coding_tools_provider` |
| **camera** (1) | `live`ᵂ | `camera_provider` |
| **behavior** (1) | `focus_churn`ᴬ | `focus_churn_provider` |

### What the Mind does with them

Pillar 3's machinery, in the order `decide_with` runs it: freshness gate
(never surface from a dead sensor) → activity de-clutter (`fits_activity`)
→ **skill calibration** (`calibrate`, pillar 4) → contextual relevance
(background media damped ×0.65) → drop below `min_relevance` → rank →
**bystander cap** (a module that is not what you are doing may place at
most 2 controls) → truncate to `max_items`. Then `settle.rs` holds each
offer off the bar until it has been on the decision for 1200ms unbroken —
except Warnings, which skip the wait.

---

## Population A — the hand-made surfaces (`crates/daemon/src`)

Built before the Brain or beside it; these are surfaces, not providers.

| Surface | File(s) | Note |
|---|---|---|
| **the OPTIONS bar** | `options.rs` | pills, the window cluster, the clock, hit-testing, dispatch — and the dynamic Mind pills |
| **clipboard** | `clipboard.rs`, `clip_source.rs` | box with rows; **the dictionary is a *panel inside it*** ("define a word"), not a separate module — the roster in modules.md reads otherwise |
| **dictionary** | `dict.rs` | fully offline word→definition maps (Webster's 1913 EN, a Spanish synonyms list), in-memory hash lookup |
| **notifications** | `notif.rs`, `notifications/`, `notif_icons.rs` | the box, the bell, DND |
| **battery** | `battery.rs` | the v2 ladder (≤10% red bell · ≤7% beat · ≤5% suspend · woken-still-low hibernate) |
| ~~**media box**~~ | ~~`mediabox.rs`~~ | **DELETED 2026-09-12** — transport + live MPRIS seek bar + volume. The only population-A surface built by the autonomous loop (created 2026-09-02, ticked in GRIND.md as `654b88d`), so it went with population B. 469 lines + the `MediaOpen` pill + 22 wiring sites across `main.rs`, `options.rs`, `frame.rs`, `state.rs` and `proto`. The `media` collector still runs and `ContextState.media` is still populated — a curated media OPTION picks it up from there |
| **intellihide** | `hypr.rs`, `main.rs` | the bar's own concealment |
| **trash** | `trash.rs` | the FreeDesktop trash behind `system.empty_trash` |
| **action track** | `action_track.rs` | ACTIONS' answer record: an answered offer files a card into the notification OPTION with the words it asked, your answer, and the time |
| **sunset** | `sunset.rs` + `sunset_provider` | the ACTIONS prototype — the only module that spans both populations |

---

## The finding this census produced

**67 of 76 offers are structurally exempt from pillar 4.**

| Kind | Count | Fades with skill? |
|---|---|---|
| `Control` | **57** | never |
| `Warning` | 10 | never |
| `Info` | 7 | gently — `× (1 − 0.3 · skill)` |
| `Action` | **2** | most — `× (1 − 0.6 · skill)` |

The scaffolding kind, the one dynamic difficulty is really *for*, is used
**twice** in the whole system: `behavior.focus_churn` and
`session.failure_streak`. Everything else either never fades or fades
gently.

Combined with **#79** (the base skill is a hardcoded `0.5`, so only
friction moves it), the entire live dynamic range of pillar 4 today is:
two offers moving between ×0.70 and ×1.00, and seven moving between ×0.85
and ×1.00. **Pillar 4 is real in code and very nearly inert in effect.**

This may be correct rather than broken, and it is Max's call which:
`Control` is documented as *"the heart of the right action at the right
moment — the button you were about to reach for"*, and OPTIONS being
almost entirely Controls is a coherent reading of what OPTIONS is. If so,
dynamic difficulty lives mostly in **ACTIONS**, and pillar 4's home should
be written down as such. If not, most of these 57 Controls have been
labelled to avoid fading rather than because an expert genuinely wants
them unchanged. Carried as **#82**.
