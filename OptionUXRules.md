# OPTIONS — UX rules

<!-- The laws every OPTION obeys, independent of which module it is. A rule
     lands here once it has been stated in Max's words, argued through, and
     agreed; the module catalog (options-catalog.md) says WHAT each OPTION is,
     optionsmodules.md says when one is DONE, and this file says how they must
     all BEHAVE. Add rules by appending a numbered section. -->

Rules are numbered in the order they were agreed, not by importance. Each one
states a law, the failure it exists to prevent, and its corollaries — including
the cases where it is allowed to break, because a rule that never admits its
limits gets quietly violated instead.

---

## 1. The Leader

*Agreed 2026-09-04 (Max); reshaped the same day after the first cut failed live
— see "The anchor is a place on the bar". Landed for the window cluster and the
Mind's control row; see "Where it applies".*

**Using an OPTION must never cost you the OPTION.**

An OPTION acts on the current context. Acting changes the context. If the
surface then re-lays-out around its resting anchor, the control you just used
slides out from under your hand — the second use costs a fresh aim, the third
another. Worse, the vacated space is not empty: the neighbours move into it, so
a repeat click can land on a *different* control. Close a tile and the shorter
title can walk `[pseudo]` under a finger that meant `[current task]`. Using
OPTIONS decays into hunting for OPTIONS, and hunting badly.

So: **the pill you click is the leader, and the leader does not move.**

The click pins it to the place on the bar where you clicked it, and its OPTION
re-anchors onto that point. Placement runs outward from the leader — pills to
its left are placed leftward, pills to its right rightward — instead of outward
from the group's resting anchor. A pill that changes width therefore **expands
away from the leader, with its leader-facing edge fixed**. Close a tile by
clicking `[X]`: the next window's name is shorter, the name pill's right edge
holds against `[X]`, and the whole width change plays out on its left. The
animation happens. `[X]` does not move. You click again.

Every animation is the one it always was — same curves, same growth, same
reveal. Only the origin changed.

### The anchor is a place on the bar, never the pointer

The first cut of this rule chose the leader on **hover** and solved for "the
leader lands back under the cursor". It reads correctly and is exactly wrong.
Pinning a pill to the pointer means the whole cluster travels with the pointer:
leave `[current task]` heading for `[X]` and `[X]` is pushed away at precisely
the speed you chase it. The control cannot be reached at all — the rule written
to make OPTIONS repeatable had made one unusable. **A leader you must be able to
aim at cannot be attached to your aim.**

Hence both halves of the law. The leader is chosen by **the click that lands on
it** — an act of intent, not a by-product of passing over it — and anchored to
**the bar**, so it is a fixed point you can travel to.

The leader then holds while the pointer is anywhere on the bar — the gaps
between pills, and any other OPTION's pills too. You can glance at the clock and
come back to a cluster that has not moved. When the pointer leaves the bar the
group **eases home** to its resting position: the name pill centred, exactly as
before. Nothing is permanently displaced.

The consequence is **repeatability**: aim once, act N times. Four tiles, four
clicks, one spot.

### The workflow

The rule is a lifecycle with four moves. Everything else on the bar carries on
underneath it untouched — the toggles revealing, the clock metamorphosing, an
offer arriving and ranking itself in.

**1. Choose — on the press.** The leader is taken on the *press* that begins a
click: not on the release, and never on hover. Pressing is the moment of intent
— it says "this control, at this place, again in a second" — where hovering says
only that you were passing through. Taking it on the press also means the anchor
is the layout you aimed at, captured before the action can move anything. A
press that lands between pills, or on an OPTION the rule does not cover, chooses
nothing and leaves any standing leader alone: you do not lose your grip by
missing.

**2. Hold — until you leave the bar.** From that press the leader's group is
laid out from the anchor instead of from its resting position, so the leader
stays at the same place on the bar however much the action changed the context
underneath it. The hold survives everything except leaving — repeated clicks, a
pointer wandering off to read the clock, a re-rank, a title change, a window
closing. This is the whole point: *aim once, act N times.*

**3. Hand over — on another click.** A click on a different leadable pill moves
the leadership to it, anchored where that pill is *drawn* — which is both where
you see it and where you just clicked. Reading the anchor from the drawn layout
is what makes the hand-over free: the group is displaced exactly as much the
instant after as the instant before, so nothing jumps. If the new leader belongs
to another OPTION, the one being left eases home.

**4. Release — three ways, all of them ending at rest.**

- **The pointer leaves the bar.** The visit is over, so the group eases home.
  The bar strip is the boundary — going down into an open box counts as leaving.
- **The leader leaves the layout.** Its window closed, its offer withdrew, its
  toggle tucked away. There is nothing left to hold still, so it is dropped and
  its group eases home *from where it stands* rather than snapping.
- **The bar goes away.** Concealed under a fullscreen window there is nothing to
  ease home on, so the displacement is dropped outright and the bar comes back
  resting.

The anchor lives and dies inside a single visit to the bar. It is never
persisted, never restored, never carried across a leave — so a bar you come back
to is always the resting one.

### Corollaries

- **At rest, nothing changed.** Displacement is zero until a click — hovering
  the bar is not using it — and zero again once the pointer leaves. The resting
  layout is the layout that was always there; this rule adds a behaviour under
  the hand, not a new arrangement.
- **The leader is pinned by its centre.** A leader that *itself* resizes — the
  name pill — has no away-side, so it holds its **place** rather than an edge:
  the width change is spent evenly on both sides instead of lunging one way
  under a pointer that is sitting on it. For the fixed-width buttons that do the
  re-flowing work, centre and edges are the same promise: the pill is bit-still.
- **The leader is an identity, not a slot.** Where a group is ranked and can
  reorder — the Mind's controls — the leader is held by *which action it is*,
  not by where it sat. A list that re-ranks must never put a different action
  under a stationary finger. If the action withdraws, the leader is released.
- **The leader yields to the edges.** If holding it still would push its OPTION
  into a neighbouring OPTION, the clamp wins and the leader moves. Correct
  geometry outranks the guarantee. This is the only case where the rule breaks,
  and it breaks visibly.
- **The leader survives reduce-motion.** Holding still is not an animation.
  Under reduce-motion the leader still holds; only the ease home snaps.

### Where it applies

Everywhere an OPTIONS surface reflows in response to its own use: the window
cluster, the Mind's control row, the notification list under repeated dismissal,
the clipboard rows. Anywhere the user can act twice.

Landed so far at the pill level, for the two groups that actually reflow: the
window cluster (`[current task] [X] [pseudo] [fullscreen]`) and the Mind's
ranked control row. The box-internal lists (notification cards, clipboard rows)
are the same law applied one level down and are not done yet.

### Definition of done

This rule adds line 7 to the module DoD in `optionsmodules.md`:

> 7. **Repeatable** — if the action can sensibly be done twice, doing it twice
>    must not require re-aiming. Verified by: act, don't move the pointer, act
>    again, land the same control.

---

## 2. The Still Bar

*Agreed 2026-09-04 (Max), out of the clock→bell friction. Landed for the clock's
date; the Mind's ranked row is the same law and is not done yet.*

**The bar does not re-flow while you are on it.**

A change *you* made re-flows the layout — that is §1's business, and §1 anchors
the control you used so the re-flow plays out around it. A change **nobody asked
for** must not re-flow the bar at all while the pointer is here. It waits until
you leave.

The friction that produced this rule: you hover `[clock]`, it metamorphoses into
the full date, and the notification cluster — pinned a gap to its left — slides
some 180px out of the way to make room. You then set off for `[bell]` to read
the last notification. Three seconds after you left the clock, on a timer, the
date collapses and the bell is dragged back across the bar, out from under a
pointer that was already on it. You did not ask for that. You had stopped using
the clock; you were using the bell, and the bell moved.

§1 does not cover it, because §1 pins on the click and you have not clicked yet.
**Using an OPTION must never cost you the OPTION — and neither must reaching for
one.**

### Why the timing, and not the geometry

The tidier fix would be for a pill's position never to depend on a neighbour's
size. Here it cannot: the date is some 180px wider than the time, the clock
lives at the right edge, and there is nowhere else for it to grow. Reserving the
date's width would leave a hole in the edge of the bar all day for a string that
is read for a few seconds. The coupling is real and it stays.

So the rule governs *when* it may fire instead of pretending it can be removed.
Where a coupling **can** be designed away, design it away; where it can't, it
waits for the visit to end.

Anchoring is the wrong tool for it, too. A pill that is mid-morph cannot be
anchored without fighting its own animation — the bell's rect *is* its peek
opening, so pinning it would cancel the very growth the user asked to see.
Holding the layout still is both cheaper and truer than holding one pill still
against it.

### Corollaries

- **Hover growth is reversible only on leave.** An OPTION that grew because you
  looked at it stays grown for the rest of the visit. The growth displaced its
  neighbours; the collapse un-displaces them — under a pointer that has by then
  travelled to one of them.
- **The visit ends at the surface, not at the pill.** Leaving the clock is not
  leaving. Leaving the bar is. And an open box below the bar is part of the
  visit: it is pinned to its OPTION the same way, so a re-flow would slide the
  list you are reading out from under the cursor.
- **Deferred is not cancelled.** A change that waits is still owed, and still
  plays — on leave, with whatever hold it already had. The bar you come back to
  is the correct resting one; nothing is silently dropped.
- **What you asked for is exempt.** Acting re-flows the layout and you must see
  it happen. That is §1's job, not this one. §2 governs only what you did not
  request: timers, hover collapses, the Brain changing its mind.
- **Urgency outranks stillness — the one case where it breaks.** An OPTION that
  must be seen *now* does not wait for you to leave. A Warning arrives when it
  arrives, and if that moves something under your hand, that is the correct
  trade. Like §1's clamp, it breaks visibly and for a reason you can see.

### Where it applies

Every OPTION whose size or presence changes anything but itself, for any reason
the user did not just ask for: hover morphs, timers, the Brain.

- **Landed:** the clock's date. The collapse now waits for the pointer to leave
  the surface, and a return inside the hold abandons it rather than playing it
  under you.
- **Not done:** the Mind's ranked control row. It is left-anchored, so an offer
  arriving or withdrawing shifts every control beside it — spontaneously, while
  you are reaching for one. Same law, same remedy: hold the ranking for the
  duration of the visit, apply it on leave.
- **Tolerated, and worth watching:** the clock's own minute tick re-flows the
  bell by a pixel or two. The same class of change, far below the scale that
  costs you a target — but if the clock ever takes a wider format, it stops
  being negligible.

### Definition of done

This rule adds line 8 to the module DoD in `optionsmodules.md`:

> 8. **Still** — its animations must not move another OPTION while the pointer
>    is on the surface. Verified by: rest the pointer on a neighbour, let the
>    OPTION grow, collapse or re-rank on its own, and watch the neighbour not
>    move.

---

## 3. One Material

*Agreed 2026-09-04 (Max). Landed across the bar; see "Where it applies".*

**Every OPTION moves at the same tempo. A module does not invent its own.**

OPTIONS is one surface made of many modules, written at different times by
whoever needed them. If each picks its own rate, the bar stops reading as one
object and starts reading as a collection of widgets that happen to share an
edge — the clock's sweep, the bell's peek and the buttons' reveal each arguing
a slightly different physics. Nothing is wrong on its own. Together they feel
assembled rather than made.

So: one rate, one settle, one curve family — named once and imported. **The
tempo is a property of the surface, not of the module.**

### What "the same" means

**The same rate, not the same duration.** Every morph is an exponential approach
sharing one time constant, so it has one acceleration profile at every scale: a
long travel starts faster and takes a little longer, a short one starts gently
and is over sooner. That is one material behaving consistently. Giving
everything the same *stopwatch* instead would do the opposite — a 180px sweep
would crawl and a 12px nudge would snap, and they would stop feeling like the
same stuff.

**The same settle, in real units.** A morph is finished when what remains is
smaller than half a logical pixel — below what the screen can show. Stated in
geometry, not in whatever unit each animation happens to run on: a progress
value from 0 to 1 is not a distance, so its threshold is mapped back through the
span it drives. Otherwise identical-looking numbers mean different things, and
two morphs that read as equally done stop at different visible distances.

**The same leave-hold.** How long an OPTION stays open once the pointer is gone
is one number, shared by all of them.

If you want to keep looking at something, you keep the pointer on it. That is
the entire vocabulary the user needs, and it is already in their hand. An OPTION
that lingers for a second and a half after you have left has decided on your
behalf that you were still interested — it is the OPTION choosing when the bar
goes quiet instead of the hand that left. **Leave, and it leaves.**

The grace period is not for reading. It exists only so that crossing a gap
between two parts of the same OPTION — the bell and its mute pill, a pill and
the box under it — does not count as leaving. It is sized for a hand in transit,
which is why it is short, and why one value fits every OPTION: hands cross gaps
at the same speed everywhere on the bar.

### What stays each OPTION's own

Tempo is shared. **Choreography is not.**

- **Stagger.** The `[X]` cluster's children emerge inner-first and retract
  outermost-first, 60ms apart. That is overlapping action, and it is what gives
  the cluster its character. One rate does not mean one moment.
- **Auto-withdraw dwell — and only this kind of dwell.** How long something
  that appeared *on its own* stays before it withdraws: a notification's flash,
  ranked by urgency, from a brief low-priority blink to a critical one that
  lingers for eight seconds. This is not a leave-hold and the shared one does
  not govern it. It answers "how long does this need to be readable", not "is
  the user still here" — nobody's pointer ever arrived, so nobody's pointer can
  leave. Collapsing a critical notification in a leave-hold's time would be a
  data-loss bug wearing a consistency costume.
- **Entry dwell.** The delay *before* something opens — the fullscreen bar's
  reveal at the screen edge. That is an intent filter, the opposite direction of
  travel, and it is deliberately longer than any hold.
- **Direction and order.** What comes from above, what emerges from a parent,
  what becomes more — the three base flows.
- **Entry versus exit.** These are allowed to differ from each other, provided
  every OPTION differs the *same* way. A shared asymmetry is still one material;
  a per-module asymmetry is not.

### Corollaries

- **The number lives in one place.** `animation.rs` holds the vocabulary and a
  module imports it. A module-local copy is a defect even while it is still
  equal — it is equal only until someone tunes one of them, and then the drift
  is invisible until it is felt.
- **A deviation is argued in the file, not typed at the call site.** A rate
  multiplier inline (`RATE * 1.3`) is how a surface stops being one material:
  nobody reviews it, and it reads as intentional forever. If an OPTION genuinely
  needs a different tempo, that is a change to the vocabulary, with a name.
- **Uniform is not the same as lively.** This rule flattens the *physics*, never
  the choreography above. A bar where everything also moves at the same moment,
  in the same direction, would be worse than one that merely disagreed about
  speed.

### Where it applies

Every animated property of every OPTION.

The audit that produced this rule found the bar already closer to one material
than it looked: six modules had independently declared the same rate. That is
the state the rule exists to protect — equal **by coincidence** is not a system,
and module twelve will pick its own number.

- **Landed:** one shared rate, one settle threshold and one leave-hold in
  `animation.rs`, imported by the window cluster, the clock, the Leader's ease
  home, the notification OPTION and the clipboard OPTION. The six local rate
  constants are gone, along with *two* inline `× 1.3` multipliers on the
  notification and clipboard boxes — the only genuinely off-tempo animations on
  the bar. The clock's 1500ms leave-hold is gone too: it now lets go 300ms after
  the pointer does, like everything else.
- **Deliberately untouched:** the bar's own conceal grace in fullscreen, and the
  launcher's page slide. Both belong to the surface rather than to an OPTION —
  whether One Material governs the whole body or only the OPTIONS bar is a
  scoping decision, not an oversight.
- **Open:** entry and exit are currently the same symmetric ease. The design
  language (the UX/UI guidelines, §3 Animation & micro-physics) calls for a
  spring with slight
  overshoot on entry and a heavier decay on collapse. That asymmetry is
  permitted by this rule — it just has to be *one* asymmetry, shared. Not yet
  decided whether to build it.

### Definition of done

This rule adds line 9 to the module DoD in `optionsmodules.md`:

> 9. **On tempo** — it animates on the shared rate, settle and leave-hold from
>    `animation.rs`; it declares no rate of its own and multiplies nobody's.
>    Verified by: search the module for a rate or a hold constant — there isn't
>    one, unless it is an auto-withdraw dwell, which is a different thing.

---

## 4. Sticky OPTIONS

*Agreed 2026-09-04 (Max). Stated generally; fullscreen is the only case we know
of today, and Max is confident there are others we have not met yet — so the
trigger is written as a condition, not as a name.*

**Undoing must cost what doing cost.**

§1 protects you from an OPTION that *moves* when you use it. This one protects
you from an OPTION that **disappears** when you use it: the same law pushed to
its hardest case, and the more expensive failure.

### The failure

Two tiles — editor on the left, the site in a browser on the right. You want to
see the site full. You go up to the bar, click `[current task]` to focus the
browser, move along to `[fullscreen]`, click. The browser fills the screen.

And the bar is gone, because that is what fullscreen means. The control you will
want four seconds from now, to undo the thing you just did, was taken away *by
the thing you just did*.

Coming back costs: travel down off the edge, travel back up to it, hold still
for the reveal dwell, find `[fullscreen]` again among pills that have
re-laid-out around it, click. **Doing cost one click. Undoing costs a journey.**
And you knew you were going to undo it — you were only looking.

An OPTION that removes its own means of reversal has set a trap, and the user
pays for it every time, having done nothing wrong.

### The rule

**When an action takes the bar away, the OPTION that did it stays.**

It stays exactly where your pointer left it. The rest of the bar goes — the
screen is what fullscreen is *for* — but that one pill remains under your hand.
Click it again and you are back: two clicks, one spot, no journey.

Beside it, on the side its group lives on, sits **`[ ]` — an empty pill. The
doorway.** It is not an action. It is the promise that the bar is still there if
you want it. Put the pointer on it — no click, no dwell — and it *becomes* the
next OPTION along, here `[pseudo]`, while the rest fade in behind it. That is
not a new animation; it is the second base flow, options begetting options,
emerging from a parent.

The whole bar is reachable from where you already are, without returning to the
screen edge to re-enter a bar you never really left.

### The three ways it goes

- **Toggle and return.** Click, look, click. `[fullscreen]` is still under the
  pointer, so the second click costs no aim. Out.
- **Walk away.** Don't click. Move off and the pair fades. Nothing was added to
  the screen, nothing has to be dismissed, and the bar reverts to its ordinary
  rules — top edge, dwell, exactly as before. **Stickiness is a grace, not a
  mode.** It costs nothing when unused, which is why it can always be offered.
- **Go further.** You want to stay fullscreen and do something else. Move left
  onto `[ ]`, it becomes `[pseudo]`, the rest arrive, move one more and close
  the tile. You never left the bar, so you never had to re-enter it.

### Corollaries

- **The trigger is a condition, not a list.** An OPTION goes sticky when *its
  own effect removed the means of undoing it*. Fullscreen is the only one we
  have met; written this way, the next one inherits the behaviour without anyone
  noticing it needed to.
- **The doorway is empty because it is honest.** What it becomes depends on
  which group it belongs to and what the context asks for. An empty container is
  the only truthful drawing of "the rest of the OPTIONS": it promises nothing
  specific, so it is free to become anything.
- **The doorway stands where its successor will.** It occupies the exact slot
  the next OPTION along will occupy, so "it becomes `[pseudo]`" is literal — one
  pill metamorphosing in place, not a pill replaced by a different pill
  somewhere else.
- **The pair is one OPTION for the purpose of leaving.** Crossing the gap from
  the sticky control to the doorway is transit, not departure — precisely what
  §3's shared leave-hold is sized for. The rules compose; no new timer.
- **The sticky control is a Leader that outlived its bar.** It holds the place
  §1 pinned it to. A second click must land on it, or this rule is decoration.
- **It dies when what you did stops being current.** This is the way back to
  *the action you just took*. If focus moves to another window or the workspace
  changes, the way back is stale and it goes. A pill offering to un-fullscreen
  something you are no longer looking at is worse than no pill at all.
- **It answers to a pointer, never to a timer.** No countdown, no lingering.
  Leave and it leaves — §3's law, applied here without exception.

### Where it breaks

The pill is a piece of chrome on a screen the user asked to be left alone. That
is the deliberate trade: one moment of chrome against a journey every single
time. But where a fullscreen exists precisely so that *nothing* overlays it, the
correct answer is no pill — and it must break by **not appearing at all**, never
by appearing and being unreachable.

### Definition of done

This rule adds line 10 to the module DoD in `optionsmodules.md`:

> 10. **Reversible** — if using it takes away the way back, it leaves the way
>     back. Verified by: use it, don't move the pointer, and undo it with one
>     click; then use it again and walk away, and confirm nothing is left on
>     screen.

---

## 5. One Kills the Other

*Agreed 2026-09-04 (Max), building the window-mode controls. Landed for the
window modes; the law is written for any OPTION that presents a state.*

**A thing is in one state at a time, and choosing a state leaves the one
before it.**

Underneath, a system rarely works that way. A window in the compositor carries
*independent flags*: floating, pseudo, fullscreen, each free to be on while the
others are. They combine into positions nobody designed — floating **and**
fullscreen; pseudo **and** fullscreen, where pseudo silently does nothing at
all. Those combinations have no name, no picture of their own, and no obvious
exit. The user is left doing arithmetic on booleans to work out what they are
looking at and which button will undo it.

So OPTIONS does not pass that through. It presents the states a thing can
actually **be in** — for a window: tiled, floating, pseudo, fullscreen —
mutually exclusive, each one reachable and each one escapable. Choosing one
leaves whatever was on. **One kills the other.**

### Corollaries

- **There is always a base state, and the active control returns you to it.**
  Press the mode you are already in and the window goes back to the layout. You
  never need to know which combination you are in to get out of it: pressing the
  lit thing always means *stop*.
- **Precedence is by visibility.** Where the flags underneath really do overlap,
  the state presented is the one you can **see** — fullscreen over floating over
  pseudo. The name has to match the picture, or the bar is lying about a window
  you are looking at.
- **A state you cannot read is a state you cannot present.** The compositor
  exposes pseudo nowhere at all, so OPTIONS keeps its own record of it. Blind
  toggling is not presenting a state; it is hoping, and it is how a control ends
  up meaning "sometimes".
- **The exclusivity is ours, not the system's.** We do not fix the layer below
  or take its flags away. We refuse to hand its ambiguity to the user.

### Where it breaks

**Not every flag is a state.** Something that meaningfully coexists with all the
others — pinned, always-on-top, visible-on-every-workspace — is a *modifier*,
and forcing it into the exclusive set would be the same mistake pointing the
other way: it would make "pinned" kill "fullscreen" for no reason anyone asked
for. The test is whether the thing has a picture of its own that replaces the
others, or merely decorates whatever is already there.

### Definition of done

This rule adds line 11 to the module DoD in `optionsmodules.md`:

> 11. **Exclusive** — if it presents a state among several, exactly one is true
>     at a time, pressing the active one returns to the base state, and the
>     state shown matches what is on screen. Verified by: reach every state from
>     every other state, and get out of each one by pressing it again.

---

## 6. A Transition Is One Motion

*Agreed 2026-09-04 (Max), from watching a window bounce through a size nobody
asked for on the way between two modes.*

**A change is one motion. The user never watches the machinery.**

Going from fullscreen to pseudo used to take two visible beats: leave fullscreen,
wait for the window to settle back into its tile so it could be *measured*, then
shrink it to a fraction of what was measured. Big, then medium, then small — and
the medium was nobody's intent. It was the implementation needing a ruler.

Every step the machinery takes is a step the user has to read as meaning
something, and it does not mean anything. Worse, it teaches the wrong thing: a
window that visibly passes through the tile on its way to pseudo suggests those
are two separate acts, and that some third state exists between them.

So: everything a change needs is done at once. One dispatch, one goal, one
motion, whatever the layer underneath would have preferred.

### Corollaries

- **If a step needs something only knowable in another state, take it on the way
  past.** A window's tile can only be measured while it is *in* the layout — so
  the tile is remembered on the trip **into** fullscreen, rather than fetched
  afterwards by going back for it. Remembering is free; a second beat is not.
- **One motion is not one instant.** The motion may take exactly as long as §3's
  tempo says it should. What it may not do is stop, change its mind, and start
  again.
- **A necessary intermediate is a design failure, not a technicality.** When a
  transition cannot be expressed as one act, that is usually the transition
  being wrong, not the machine being awkward.

### Where it breaks

Where a step genuinely **cannot** be known in advance — a window that arrived in
a state without ever passing through us, so nothing was remembered — the staged
version survives as a fallback. It stays the exception, with a name and a
comment saying why; the moment it becomes the normal path, the rule has been
lost and the user is watching the machinery again.

### Definition of done

This rule adds line 12 to the module DoD in `optionsmodules.md`:

> 12. **One motion** — the change it makes goes out as a single act, and the
>     user never sees a state on the way that nobody asked for. Verified by:
>     watch it happen. If you can count the steps, it is not done.
