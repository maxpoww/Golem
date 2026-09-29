# OPTIONS — the program

> **OPTIONS is a dynamic support system that gives the user the tools or
> information they need, at the opportune moment, to advance — without
> breaking immersion.** The full definition and the five pillars are
> [constitution.md](constitution.md), in Max's words. Read that first;
> everything here is downstream of it.
>
> Records and plan live in this directory; the implementation is in
> `~/launcher`. Conduct laws: [UXRules.md](UXRules.md). Work discipline:
> [method.md](method.md). What each OPTION is: [catalog.md](catalog.md).
> **The curated lists — the live working documents:
> [contexts.md](contexts.md) and [options-list.md](options-list.md).**
> What was deleted on 2026-09-12 and why:
> [inventory.md](inventory.md). Roster + definition of done:
> [modules.md](modules.md). Ledger: [changes.md](changes.md). Build
> queue: [../GRIND.md](../../../work/GRIND.md).
>
> Directory created 2026-09-12; the records that moved into it date from
> 2026-08-30 → 2026-09-05.

## The pillar scoreboard

The engine is written against the pillars **by name** — `lib.rs` cites
pillars 2, 3 and 4; `decide.rs` heads its calibration section *"pillar 4,
dynamic difficulty"*; one comment says *"frustration into revelation"*.
So this is not a retrofit. It is a progress report against a design that
the code already knows it is serving.

| Pillar | Built | Missing |
|---|---|---|
| **1 — the environment is the assistant** | no helper object exists anywhere in Golem: no assistant panel, no help menu, no mascot. Intellihide, the bar's own conceal, the clock and the bell carry the help as furniture | the topbar pill band is a **nameable object** — chosen for mechanism reasons, and a standing debt against this pillar (**#80**) |
| **2 — reads your actions and reacts** | **the reading half is complete and untouched by the deletion.** Eleven collectors → one `ContextState`. Two app-bridge clients (zsh, nvim). The Mind is still the only place context becomes options | **it reacts to nothing today** — `PROVIDERS` is empty by design until the curated list is built in (one entry went in and out on 2026-09-13). Four surfaces still sense for themselves (**#70**); window-pills is fed the raw snapshot rather than the `OptionSet` (**#71**) |
| **3 — appear when their use is logical** | **the machinery is strong and intact.** `settle.rs`: 1200ms appear-dwell on an unbroken run, immediate withdrawal, Warnings skip the wait. Relevance ranking, the cap, the bystander cap, the freshness gate | it has nothing to rank. `primary_modules` and `fits_activity` are empty seams — they are **the curated context list expressed in code**, and they get filled a row at a time from [contexts.md](contexts.md) |
| **4 — adjusts the help to your performance** | `calibrate()` per kind (Action ×(1−0.6·skill), Info ×(1−0.3·skill), Control and Warning never faded) and `effective_skill` = base − friction, where friction is churn + shell errors + diagnostics + hesitation. Unit-tested and kept | **half the pillar.** `brain.rs` hands the Mind a constant `skill: 0.5` — demonstrated competence is never learned, so it calibrates to your last few seconds and never to your history (**#79**). The curated list is also the chance to fix **#82**: the deleted set was 57 Controls to 2 scaffolding Actions, which left pillar 4 almost nothing to act on |
| **5 — integrated into the environment (diegetic)** | the clock metamorphosing into the date, the bell's peek, intellihide — the object that holds the state is the object that shows it | the pill band is a HUD with rounded corners (**#80**), and `reason` — the field documented as being for *"diegetic phrasing"* — is written 77 times in the engine and **read zero times by the surface** (**#81**) |

**The shape of the debt:** pillars 2, 3 and 4 are architecture, and the
architecture got built. Pillars 1 and 5 are about *where the help lives
and what it sounds like*, and they are where almost everything is still
owed. That is not an accident — a pill band was the one surface that
already existed, so it absorbed every new offer.

## What is on the bar (after the 2026-09-12 deletion)

**Everything the autonomous build queue produced is gone.** Max's call:
it was never curated, so it does not get to stay. That removed all 32
Mind providers and their 76 offers (3,912 lines out of `decide.rs`) and
the one hand-made surface the loop had also built, the **media box**.

The provenance test was the date the loop started, 2026-09-02: anything
created before it came out of a Max-directed session and stays. What is
left on the bar is exactly what was built by hand.

- **The surfaces that remain** — the bar itself and window-pills
  (2026-07-30), trash (07-29), notifications (08-04), clipboard and its
  dictionary panel (08-15 → 08-21), battery v2 (08-29, Max's ladder
  spec), intellihide, sunset (the ACTIONS prototype), and the
  in-progress action-track.
- **The Mind still decides nothing.** `PROVIDERS` is empty and every table
  that named an offer — `primary_modules`, `fits_activity`,
  `contextual_relevance`, `temporal_affordances` — is an empty seam
  waiting on the curated lists. One OPTION went in and came out again on
  **2026-09-13** (`space.empty`, the empty room — cut on sight, see
  [options-list.md](options-list.md)). The machine underneath is untouched
  and tested: freshness gate, `calibrate`, `effective_skill`, the bystander
  cap, `settle.rs`, the four kinds, the action vocabulary, the pill
  rendering and dispatch.
- **Three pieces of that attempt were kept**, because each is general and
  none of them carries the offer: a provider now sees **both axes**
  (`fn(&ContextState, &ShellState)` — `fits_shell` can only *suppress*, so
  an OPTION whose whole trigger is the arrangement needs the arrangement as
  an input); an offer can **decline the appear-dwell**
  (`Affordance::immediate` — `settle.rs` defends against *sampling* noise,
  and a discrete act has none, so waiting reads as lag); and the
  current-task pill's module costume is **generalised** (`options::Module`,
  `module_box.rs`), so the next module is a variant and a match arm rather
  than a rewrite of the sunset one.
- **Nothing was lost that cannot be recovered** — git `9ed17b1`. What may
  be worth recovering is a deleted offer's *plumbing*, never the offer.

The eleven collectors all still run, so `ContextState` is as rich as it
ever was. The engine can still see everything; it has simply stopped
being told what to say about it.

### The hand-built surfaces

| Module | State | What is owed |
|---|---|---|
| **window-pills** | sensed + shown via the Brain (2026-08-30); driven from `ContextState.window` over the `brain.rs` bridge, `hyprctl` poll kept as the degrade path | **Decided** (no Mind provider) and **Wired** via `OptionSet` — **#71** |
| **battery** | **v2 shipped 2026-08-30**, the first module through the Spine. The ladder (≤10% red bell · ≤7% beat · ≤5% suspend · woken-still-low hibernate) senses only via the Brain; notification verified | growth, not debt: % readout, charging surface, power profiles |
| **clipboard** | live, pre-Brain | re-wiring **#70**; the Leader inside its rows **#69** |
| **notifications** | live, pre-Brain | re-wiring **#70**; the Leader inside its cards **#69** |
| **dictionary** | live — a *panel inside the clipboard OPTION*, not a standalone module, whatever modules.md's roster says | finish-up notes owed; re-wiring **#70** |
| **intellihide** | live, pre-Brain | re-wiring **#70** |
| **trash** | live, pre-Brain (2026-07-29) | — |
| **sunset** | the ACTIONS prototype, live-verified with Max 2026-09-07 | it is ACTIONS' business, not this program's |

### What replaces population B

The curated lists: **[contexts.md](contexts.md)** (17 primary contexts +
9 ambient states, replacing the engine's coarse eight-value `Activity`)
and **[options-list.md](options-list.md)** (35 OPTIONS, two lines each —
the name and effect, then the context that shows it).

They get built into the engine **one value at a time, with Max** —
`PROVIDERS` gains one entry per curated OPTION, and `primary_modules`
gains one row per curated context. Never by a queue choosing its own
targets. Finding **#78** (the 45 slices were never audited against DoD
6–12) closes by deletion rather than by audit.

## The conduct laws

| Rule | Landed | Not done |
|---|---|---|
| §1 **The Leader** | the window cluster; the Mind's ranked control row | box-internal lists — notification cards, clipboard rows (**#69**) |
| §2 **The Still Bar** | the clock's date | the Mind's ranked row is left-anchored and shifts spontaneously (**#68**); the clock's minute tick tolerated (**#77**) |
| §3 **One Material** | one rate, settle and leave-hold in `animation.rs`; six local rates and two inline ×1.3 multipliers gone | the entry/exit asymmetry is undecided (**#74**); the bar/body scope boundary is undecided (**#75**) |
| §4 **Sticky OPTIONS** | fullscreen — the sticky control + the `[ ]` doorway | no ground of its own over bright fullscreen content (**#73**) |
| §5 **One Kills the Other** | four exclusive window modes; `[float]` pill, Super+P through the same switch | nothing on the bar SHOWS which mode is active (**#72**) |
| §6 **One Motion** | one eval chunk per mode change; the tile is remembered on the way past | — |

Each law serves one of the acceptance test's three feelings — the table
is in [constitution.md](constitution.md#the-acceptance-test).

## Where it has actually run

Worth stating precisely, because it is easy to get wrong in both
directions.

- **The golem-vm** proved all 45 slices — batched sessions, screenshots,
  virtio GPU on a fast host. **And that proof bought nothing**, because
  the slices were never curated and are now deleted. The lesson is worth
  more than the slices were: *validating a thing well does not make it
  the right thing.* The VM answered "does it work", and nobody was asking
  "should it exist".
- **Real machines have lived in it:** Max's dev box daily (i9, Vulkan),
  the ASUS (Haswell, GL fallback), and a 2013 MacBook Air — where the
  finding behind `settle.rs` came from: with `follow_mouse = 2`, a
  pointer crossing a terminal rewrote the whole OptionSet, and the bar
  alternated between a git set and a media set every one to three seconds
  while Max was just watching a video. **No VM session finds that.**
- **What is still unproven:** the slowest metal under the conduct laws.
  A rate is a rate, and §3's tempo has never been watched at 20fps on a
  5400rpm Haswell; the Leader's guarantee is a different promise when you
  can see the re-layout frame by frame. Installing's stage 1 is what
  delivers those machines.

## The frontier

1. **Settle the two lists.** [contexts.md](contexts.md) and
   [options-list.md](options-list.md) are proposals until Max has cut
   them. Nothing else matters until they are his.
2. **Build the engine values one at a time.** Each approved context
   becomes an `Activity` variant and a `primary_modules` row; each
   approved OPTION becomes one `PROVIDERS` entry, arguing its
   `AffordanceKind` out loud (pillar 4, and the #82 correction).
3. **Pillars 1 and 5 — where the help lives.** The pill band absorbed
   everything because it existed; with the bar empty, this is the moment
   to decide what diegetic means for a desktop (#80) and to let an offer
   speak in the voice of the thing it is about (#81), *before* a new
   population accumulates against the same default.
4. **Finish pillar 4.** Friction is live; competence is a constant (#79).
   The half that is missing is the half the pillar names.
5. **Slow metal.** Every claim about tempo and stillness is still a claim
   about fast hardware.

## Where the pieces live

- **Engine:** `~/launcher/crates/options-engine` — `collectors/` (eleven:
  hyprland, system, git, media, bridge, selection, audio, deploy,
  notifications, downloads, daylight), `state.rs` (`ContextState`),
  `mind/` — `activity.rs` (the context model the curated list replaces),
  `affordance.rs` (the four kinds), `decide.rs` (the machine + the empty
  seams), `session.rs` (temporal memory), `settle.rs` (the appear-dwell).
- **Surface:** `~/launcher/crates/daemon` — `brain.rs` (runs the Mind,
  streams the `OptionSet`, holds the `Tuning`), `options.rs` (pills +
  dispatch), `animation.rs` (the one tempo).
- **Notification arm:** `~/launcher/crates/options-notify`.
- **Distro integration:** `~/Golem` — the flake lock pinning waverunner,
  `system/home/zsh.nix` (the shell bridge client).
- **The initiative arm:** [../Actions/](../actions/) — ACTIONS is OPTIONS
  speaking first, which is why it needs a far higher admission bar; the
  constitution's acceptance test explains the difference.
- **Siblings:** [../Installer/installing/](../../../Installer/installing/) —
  which machine ever sees any of this; `~/GolemOne/System/FlowShell/
  DockMenu/` — the dock, same surface, same number line.
