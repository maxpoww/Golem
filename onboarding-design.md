# Diegetic onboarding — what the tour has to be

> Design doc for **S8 — First run & onboarding** (roadmap), written as the
> `todo/todo8.md` item asks ("design doc first"). It answers *what the tour
> is and where it attaches*; it does not build it, and it cannot — the tour
> is waverunner code and S8 has not opened (Arc 1 is SH→S7→S9, under the
> fix-don't-grow freeze).
>
> **Provenance.** Everything about Golem's current behaviour is cited to a
> file:line in this repo and is checkable. Nothing here describes waverunner
> internals: that tree (`github:maxpoww/launcher`) is a pinned flake input,
> not readable from this repo, so where the design needs something from the
> daemon it says so as a *requirement*, never as an observation.
>
> Written 2026-09-01. Companion to `system-landscape.md` (same job for S4).

## 0. The rule

> "Game designers solved the problem desktop designers never did: teaching
> complete novices to master complex systems — no manual, no training, no
> fear. They did it with dynamic, diegetic, context-aware design that
> surfaces the right tool at the right moment and removes the rest."
> — `Golem.md:20`

The tour is not an exception to OPTIONS. It **is** OPTIONS, pointed at the
one context every user passes through exactly once. So it inherits the
module Definition of Done (`optionsmodules.md:56`) unchanged — including
rule 6, *"if it needs a manual to use, it's not done"*, which a tour that is
itself a manual fails by definition.

Three refusals, from `Golem.md:53` ("Interruptions dressed as help") and the
item's own wording ("game onboarding, not a slideshow"):

1. **No mode.** There is no "tour running" state to be in or to escape. A
   lesson is an ordinary affordance that happens to be about Golem.
2. **No sequence.** No step 1-of-7, no progress bar, no "next". Ordering is
   emergent — whatever the user does next decides what is teachable next.
3. **No repetition.** Every lesson has a *learned* predicate that retires it
   permanently. Without that, a lesson is a nag, and a nag is the thing
   Golem's front page says it refuses.

## 1. What "first run" means today

Two first-runs exist already, and neither teaches anything.

**System first boot.** `boot.kernelParams` (`system/configuration.nix:60`)
strips every console message, greetd autologins straight into Hyprland
(`configuration.nix:151`), and `misc.disable_splash_rendering`
(`system/home/hyprland.lua:218`) removes the compositor's own splash. The
first frame a person sees is a finished desktop: wallpaper, dock, OPTIONS
topbar, and not one word of text. That is the right aesthetic and the whole
problem — there is currently no moment between power-on and "you're on your
own".

**Daemon first run.** The SH cold-start test (`todo/todoSH.md:17`) records
what waverunner does with an empty HOME: creates the recycle bin, indexes
apps, builds icon caches. All mechanical bookkeeping. The daemon already
knows it has never run before; it just has nothing to say about it.

So S8 is not adding a first-run *detection* — one exists. It is adding the
first-run *intent*.

## 2. The teaching debt

Everything a stranger has to acquire, sorted by how it can be acquired. The
keys are the full bind table in `system/home/hyprland.lua:262-330`.

**Tier 0 — learned by looking.** The dock, the topbar, the window pill, the
notification bell, boxes that are visibly boxes. No lesson needed; if one is
needed, that surface has a design bug, not a teaching gap.

**Tier 1 — learned by trying, once you know there is something to try.**
Super+LMB window drag (`hyprland.lua:313`), 3- and 4-finger workspace
gestures (`:112`), resize-on-border (`:129`), clicking the window pill.
These reward a fidget. A lesson here is a *hint*, not an instruction.

**Tier 2 — invisible until a key is pressed. This is the whole debt.**
Roughly thirty binds, of which a stranger genuinely needs about six:

| Key | Does | Why it matters on day one |
|---|---|---|
| `Super+Space` (`:270`) | the openbox — launcher, search, **Install** | every app, every search, every install is behind this one chord |
| `Super+R` (`:275`) | waveview 3×3 overview | the only way to see the whole session |
| `Super+Tab` / `+Shift+Tab` (`:273`) | frecency focus cycle | the Alt+Tab replacement |
| `Super+Q` (`:267`) | close window | windows have no close button in the frame |
| `Super+1…0` (`:302`) | workspaces | where the second window goes |
| `Super+E` / `Super+F` (`:265`, `:268`) | terminal / files | both open `foot`; `Super+F` is `foot yazi`, a TUI |

The rest (`Super+Z` float, `Super+P` pseudo, `Super+J` movetoroot,
`Super+WASD`, `Super+arrows`, `Super+Escape` suspend) are power moves. They
are teachable *later*, by the same machinery, and must not compete for
attention on day one.

Ranked by damage, `Super+Space` is not first among equals — it is the tour's
entire reason to exist. A person who never presses it has a computer that
runs only what the dock was seeded with. **If S8 ships exactly one lesson,
this is the one.**

`Super+F` is worth flagging separately: it opens `yazi`, a modal terminal
file manager, at a person who has been promised they never need a terminal
(`Golem.md:51`). Teaching that bind to a novice would be actively harmful
until `Super+F` points at Nautilus, which `apps.md` already ships and which
owns `inode/directory` (NOTES, todo5). A lesson is not a fix for a bind
pointed at the wrong thing.

## 3. The moment map

A lesson needs a trigger the Brain can already sense. These are the moments,
best first. "Sensing" names the collector each one needs; the window
collector exists (S2, `optionsmodules.md:10`), the rest are marked *new*.

**M1 — the unbound reflex.** *The highest-signal trigger in the system, and
it is free.* A person arriving from another OS presses the chord their hands
know. In `hyprland.lua`, most of those chords are **bound to nothing**:

| Reflex | From | Golem's answer | Today |
|---|---|---|---|
| `Alt+Tab` | Windows, Linux | `Super+Tab` | unbound — nothing happens |
| `Super` alone | Windows | the openbox | unbound — nothing happens |
| `Alt+F4` | Windows | `Super+Q` | unbound — nothing happens |
| `Ctrl+Alt+→` | Windows, GNOME | `Super+[n]` | unbound — nothing happens |
| `Cmd+Space` | macOS | `Super+Space` | **already works** — same physical key |

An unbound-but-meaningful keypress is a stated intention that produced
nothing. The user has told Golem what they want, in a language Golem
understands, and Golem knows for a fact they did not get it. No other
trigger in the OS is that unambiguous — and `Golem.md:31` already promises
exactly this ("the topbar welcomes the Mac user, the openbox welcomes the
Windows user"). *Sensing: new — a bind on the dead chord itself, which is
also the cheapest possible collector.* See the fork in §6.1.

**M2 — the openbox has never been opened.** Session has been live past some
threshold, windows have opened and closed, `Super+Space` count is still
zero. The one lesson that must not be missed, so it gets the most patient
trigger. *Sensing: new (skill counters, §5).*

**M3 — the workspace is full.** The window collector already perceives the
active window; N tiled windows on one workspace with the overview never used
is the moment `Super+R` and `Super+[n]` mean something. Before that they are
answers to a question nobody asked. *Sensing: window collector (exists).*

**M4 — the app isn't there.** Search in the openbox returns no installed
match. The Install section is the answer, and this is the natural moment for
the one honest sentence of §6.3 — because what happens next is a
`nixos-rebuild`, and it is slow (`todo/todo7.md:114`, "the first run is
still legitimately building"). *Sensing: openbox search (exists, in
waverunner).*

**M5 — first real-world event.** First battery drop, first device paired,
first screenshot. Each already has, or will have, a module; the lesson is
just that module surfacing for the first time with slightly more presence.
The battery ladder (`optionsmodules.md:30`) is the shipped template.
*Sensing: per-module (exists).*

**M6 — the first idle.** No input for a while with nothing playing: the one
moment where a small, ignorable offer costs nothing, because by definition
it interrupts nothing. This is the only place a "there's more" hint belongs.
*Sensing: new (idle — `system-landscape.md` §4 covers the logind side).*

## 4. The shape of a lesson

Grounded in the DoD (`optionsmodules.md:56`), a lesson is:

- **an OptionSet entry like any other**, ranked by the Mind against real
  options — and it must *lose* to them. A person who is mid-task is not
  available to be taught. This is rule 6 stated as a ranking constraint.
- **shown on a surface that already exists.** The design's main claim: the
  tour adds **zero new surfaces**. Lessons ride the topbar, its boxes, and
  the openbox. A bespoke tour window would be a new OPTIONS surface — the
  exact thing the Arc-1 freeze forbids, and a slideshow by another name.
- **retired by evidence, not by acknowledgement.** The learned predicate is
  "the user did the thing", never "the user clicked OK". A lesson the user
  satisfies before it fires should never fire — someone who found
  `Super+Space` on their own has finished that lesson.
- **silent about lessons it is not giving.** No index, no "8 tips
  remaining", nothing that turns the set into a checklist.

## 5. What has to be built that does not exist

One new sensing organ, and it is the whole of it:

**The skill collector.** Per-capability counters — has this person ever
opened the openbox, used a workspace, opened the overview, installed an app,
dragged a window — with recency, persisted across sessions. Everything in §3
is a predicate over that store plus what the Brain already senses.

Two consequences worth deciding early:

- **It is the same store `Tuning.skill` reads** (todo8 item 3). Item 3 is
  not separate work; it is this store's second reader. Building the skill
  collector for the tour and the skill seed for Tuning as two things would
  produce two disagreeing models of the same person.
- **It is behaviour data.** `Golem.md:51` refuses telemetry inside the OS.
  Local-only, user-readable, user-deletable, never leaves the machine —
  and stated as such where a person can find it. waverunner's existing
  user-visible state files (`groups.json`, `pins.json`, `todoSH.md:97`) are
  the precedent for where it lives and what shape it takes.

Beyond that: a Mind provider to rank lessons, and a set of predicates. No
new surface, no new transport, no new daemon.

## 6. The forks — Max's, not an agent's

**6.1 Teach the reflex, or bind it?** M1 can be answered two ways. Teach:
`Alt+Tab` surfaces "Golem uses Super+Tab" and the person learns Golem's
language. Bind: `Alt+Tab` simply *does* the focus cycle and there is nothing
to teach. Bind is cheaper, invisible, and closer to "you should not operate
a computer; you should *use* it" (`Golem.md:15`) — but it makes Golem a
dialect of Windows in the places it is copied, and the muscle memory it
builds is not Golem's. This decision sets the ceiling on how large S8 is:
bound reflexes delete whole lessons. It is a values call about what Golem
is, so it is the owner's.

**6.2 Where do language and user get chosen?** todo8 item 1 says first boot;
roadmap S9 says the installer ("disk, user, wifi, done"). They cannot both
own it. Today both are baked at build time and hardcoded to one person:
`i18n.defaultLocale` and `time.timeZone` (`configuration.nix:98`),
`users.users."max"` (`:112`), greetd's `user = "max"` (`:157`), and — the
one with teeth — `user = "max"` in `system/waverunner-apply.nix:31`, which
is the path an install request travels. On an account not named `max`,
installing an app does not work at all. Whoever owns the choice, that
hardcode has to go with it.

**6.3 Does a lesson ever use words?** Diegetic game onboarding teaches
without prose. But `Super+Space` is a chord — there is no way to depict a
chord pictorially that is faster to read than the word. A doctrine of zero
text may cost more than it buys on exactly the one lesson that matters most
(§2). One sentence, once, on M2 is the modest position; it is still a
taste call.

**6.4 How patient is patient?** Every trigger in §3 has a threshold (how
long, how many windows, how idle). Numbers are feel, and feel is measured by
daily driving, not derived in a doc.

## 7. Acceptance — the "first five minutes" walk

todo8 item 4 is `boot → browse → install an app, no help`. Written as a walk
it is: power on → land on the desktop → get to a browser → search for
something → install it → use it. Three things must be true before that walk
can be *scripted*, let alone run, and none of them is true today:

1. **"Browse" has no answer yet.** The default browser is an open owner
   decision (todo5, NOTES) and the shipped webapp engine is `google-chrome`,
   not chromium. A script cannot say which icon the person clicks.
2. **"Install" is the slow step, not the hard one.** The openbox writes
   `packages.list`; a systemd.path fires the root apply
   (`system/waverunner-apply.nix`, header) and the machine rebuilds. Minutes,
   with the daemon's own F10 history of reporting a queued install as failed
   (`todo/todo7.md:110`). The first-five-minutes risk is not that the person
   can't find Install — it is that they think it broke. Whatever M4 surfaces
   has to cover the wait, or the walk fails on patience.
3. **"Install" needs a flake checkout.** The apply service is
   `lib.mkIf (flakeDir != null)` (`waverunner-apply.nix:125`) and both
   configurations point it at `/home/max/Golem` (`flake.nix:88`,
   `hosts/vm.nix:21`). An ISO-installed machine has to end up with a
   git checkout at that path, owned by that user, or the Install section is
   inert on a stranger's computer. That is S9's to arrange; it is recorded
   here because the walk is what would discover it.

## 8. What this doc does not do

It does not decide §6. It does not describe waverunner's provider API,
OptionSet ranking, or surface internals — that tree is not readable from
here, and a made-up API in a design doc is worse than a gap. It does not
schedule S8: the roadmap does, and S8 is Arc 2.
