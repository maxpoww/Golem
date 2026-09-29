# The OPTIONS constitution

*Max's words, given 2026-09-12. This is the definition OPTIONS is built
from and judged against. It outranks every other file in this directory —
[UXRules.md](UXRules.md) and [modules.md](modules.md) are downstream of
it, and [method.md](method.md) only says how the work is organized.*

---

## The definition — verbatim

> **Options es:**
>
> Un sistema de apoyo dinámico que otorga al usuario las herramientas o
> información necesarias en el momento oportuno para avanzar.
>
> Está siempre accesible de manera indirecta o directa para orientar sin
> romper la inmersión, esto no solo ayuda a mantener el flujo de trabajo
> sino que también mejora la experiencia al evitar frustraciones
> innecesarias.
>
> **Pilares del diseño.**
>
> 1. El entorno es el asistente (narrativa ambiental).
> 2. El sistema lee tus acciones y reacciona (feedback contextual).
> 3. Los recursos aparecen cuando su uso es lógico (diseño sistemico).
> 4. El sistema ajusta la ayuda según tu desempeño (dificultad dinámica).
> 5. La información se integra al entorno (diegetica).
>
> **Options~** brindara las herramientas necesarias, en el momento
> necesario, así también se encargará de sacar del camino las que no lo
> sean, convirtiendo la frustración en revelación, haciendo que el
> usuario se sienta astuto y no dirigido, brindando una sensación de
> control, seguridad y poder.

### Working rendering

*The rest of this directory is written in English, so here is the
rendering the other files quote from. It is a translation, not the
authority — where the two disagree, the Spanish above is what OPTIONS
means.*

**OPTIONS is:** a dynamic support system that gives the user the tools or
information they need, at the opportune moment, to advance. It is always
reachable — indirectly or directly — to orient **without breaking
immersion**, which not only keeps the workflow intact but improves the
experience by heading off needless frustration.

**The five pillars:** (1) the environment is the assistant — ambient
narrative; (2) the system reads your actions and reacts — contextual
feedback; (3) resources appear when their use is logical — systemic
design; (4) the system adjusts the help to your performance — dynamic
difficulty; (5) the information is integrated into the environment —
diegetic.

**And the promise:** OPTIONS will provide the tools that are needed, at
the moment they are needed, and will equally take *out of the way* the
ones that are not — **turning frustration into revelation**, so the user
feels **clever, not directed**, with a sense of **control, security and
power**.

---

## What each pillar means in a shell

*Everything below this line is derivation, not Max's text. It exists so
the pillars can be built and argued against rather than admired. Each
section says what the pillar forbids, how to tell it was broken, and
where the code already honours it — the engine's own comments cite these
pillars by number, so the mapping is not invented here, only written
down. Struck freely.*

### Pillar 1 — The environment is the assistant

There is no assistant. There is no helper, no companion object, no
"Golem Assistant", no help menu, no place you go to be helped. **The bar,
the window, the clock and the dock are the help**, in the same way a
well-built room tells you where the door is without a sign.

- **The failure it prevents:** the thing every other system has — a
  destination for assistance. Going somewhere to be helped means leaving
  what you were doing, which is the immersion break the definition
  names outright. The help must come to you *as* the room you are in.
- **How you tell it broke:** try to point at the assistant. If a finger
  lands on one widget — that panel, that icon, that tray — the room
  stopped being the assistant and a helper object appeared inside it.
- **The standing tension, recorded honestly:** the topbar pill band is a
  nameable object. It was chosen for mechanism reasons (pills already
  exist, animate, hit-test, dispatch — catalog §3), which was the right
  engineering call and is still a debt against this pillar and pillar 5.

### Pillar 2 — The system reads your actions and reacts

The whole sensing architecture is this pillar: collectors perceive and
publish one `ContextState`, deciding nothing; the Mind is the only place
context becomes options. `lib.rs` says so in as many words — *"that
requires the system to continuously read your actions (pillar 2)."*

- **The failure it prevents:** offers assembled from what is *possible*
  rather than from what you *did*. A menu is a list of capabilities; an
  OPTION is a response.
- **Reading is continuous; reacting is not.** The engine reads every
  snapshot and surfaces almost nothing — `settle.rs` makes an offer wait
  1200ms on an unbroken run of decisions before it may take a pill,
  because a suggestion that appears and vanishes teaches you to ignore
  the bar. That asymmetry *is* this pillar: read always, speak rarely.
- **One reading, never two.** A surface that senses for itself puts a
  second picture of the world beside the Brain's, and the drift between
  them is invisible until a user sees a pill disagreeing with the screen.
  This is what DoD line 4 is for.
- **What it reads, it must be able to say.** Reading without disclosure
  is surveillance; the pillar demands a *reaction*, and the reaction is
  what makes the reading visible. `Affordance.reason` carries the why on
  every offer, for exactly this. The notebook — every detector listed,
  with its evidence, erasable — is the same obligation held open
  permanently.
- **How you tell it broke:** ask an offer why it is here *now*. If it
  cannot name the signal, it was not read, it was assumed.

### Pillar 3 — Resources appear when their use is logical

Not when they are available. Not when they are possible. **When using
them is the logical next thing.** And its inseparable other half, which
the closing promise states explicitly: OPTIONS *"se encargará de sacar
del camino las que no lo sean"* — **withdrawal is a duty of equal rank
to offering**, not tidying up afterwards.

- **The failure it prevents:** the tool shelf. Everything reachable all
  the time, which is the same as nothing being surfaced at the right
  moment — the user is back to searching, and a shelf you must search is
  a menu with better graphics.
- **Appearance is slow, withdrawal is immediate**, and the asymmetry is
  principled: an offer that arrives too eagerly costs trust, an offer
  that leaves too late costs a *wrong click* — "Commit all" for a repo
  you have already left. `settle.rs` implements exactly this and says
  why. Warnings skip the wait entirely: *"Your camera is on"* is not a
  suggestion.
- **"We could sense it" is never a reason to surface it.** The Mind ranks
  and caps at five pills, and the cap is not a rendering limit — it is
  the design. Every offer added lowers the average worth of what is on
  the bar, so the admission bar is the product.
- **How you tell it broke:** for each thing on the bar, say why *now*. If
  the answer would have been just as true five minutes ago, it is not
  logical, it is ambient — and ambient belongs to pillar 5's treatment,
  at pillar 4's fading, not to a pill.

### Pillar 4 — The system adjusts the help to your performance

**Help fades; power does not.** This is the pillar with the most
machinery already built, and `AffordanceKind` *is* its axis — the four
kinds are four different promises about fading:

| Kind | What it is | Calibration |
|---|---|---|
| `Action` | scaffolding, a hand offered | `× (1 − 0.6 · skill)` — fades most |
| `Info` | ambient information | `× (1 − 0.3 · skill)` — fades gently |
| `Control` | the button you were reaching for | **never faded** — an expert wants their controls as much as a novice |
| `Warning` | safety, time-critical | **never suppressed** — always relevant when true |

And the skill it calibrates against is not static: `effective_skill` =
base − friction, where friction is assembled from focus churn, failed
shell commands, editor diagnostics and hesitation. **So when you start
struggling, the scaffolding comes back on its own.** That is the
mechanism of "frustration into revelation", and `decide.rs` names it in
that phrase.

- **The failure it prevents, in both directions:** the tutorial that
  never ends, which patronizes the expert until they stop looking at the
  bar; and the expert-only surface that abandons the beginner at the
  exact moment they are stuck.
- **The kind is a design act, not a label.** Because the kind determines
  the fading, calling a control an `Action` makes it desert the people
  who use it most, and dressing scaffolding as a `Control` makes it nag
  an expert forever. Every new offer must argue its kind out loud.
- **The half that is missing:** friction is live, but **demonstrated
  competence is not learned** — `brain.rs` hands the Mind a constant
  `skill: 0.5`. The system adjusts to your last few seconds and never to
  your history, while the pillar says *desempeño*. Finding #79.
- **How you tell it broke:** run the same offer past a novice context and
  an expert one and watch the relevance move the right way — there is
  already a test shaped like this (`calibrate_scales_scaffolding_by_
  skill_but_never_safety`).

### Pillar 5 — The information is integrated into the environment

Diegetic, in the sense the word carries in games: the information is part
of the world rather than a layer painted over it. Not a readout *about*
the state — **the thing that has the state shows it.**

- **The failure it prevents:** the notification-area mindset. A strip
  where unrelated facts queue up because a strip existed and they had to
  go somewhere. Once that place exists, every future fact has a home and
  nobody has to earn a place in the world again.
- **What already qualifies:** the clock metamorphosing into the date —
  the object that holds the time is the object that tells you more about
  time. The bell peeking. Intellihide. These are the register.
- **What does not:** a band of glyph circles standing for arbitrary
  affordances is a HUD with rounded corners, however well it animates.
- **Diegesis reaches the words, not only the placement.**
  `Affordance.reason` is documented as being for "debugging and for
  diegetic phrasing" — the intent that an offer speaks in the voice of
  the thing it is about was designed in from the start.
- **This is the program's largest open design question**, and it is named
  here rather than left to accumulate: the pill band is where the
  architecture landed, and pillar 5 says the destination is elsewhere.
  Finding #80 carries it.

---

## The acceptance test

The closing sentence is not decoration — it is the only test that
outranks the twelve-line definition of done, because an OPTION can pass
all twelve and still fail this:

> **…convirtiendo la frustración en revelación, haciendo que el usuario
> se sienta astuto y no dirigido, brindando una sensación de control,
> seguridad y poder.**

**1. Clever, not directed.** If the feeling afterwards is *"it told me
what to do"*, the OPTION failed — even if it worked, even if the user
clicked it gratefully. If the feeling is *"I did that"*, it passed. The
practical consequence: **put the means in reach and let the user perform
the act.** An OPTION that explains is already directing; an OPTION that
hands you the thing lets you be the one who knew.

This is also the boundary with [ACTIONS](../actions/), which the ACTIONS
batch found empirically and could not explain: *OPTIONS answer the
context the user is standing in; ACTIONS speak about what the user has
not noticed yet.* Speaking risks *dirigido* — which is exactly why
ACTIONS needs a brutal utterance economy and OPTIONS does not. Offering
does not carry that risk. **Same soul, different licence.**

**2. Frustration into revelation.** The moment to arrive is the moment of
friction, and the reward is the user feeling they figured it out. This is
why pillar 4 measures friction at all, and why the right response to a
struggling user is *more reach*, never more explanation.

**3. Control, security and power** — three feelings, and each of the six
UX laws serves one of them. This is the clearest evidence the laws were
not arbitrary:

| Feeling | The laws that produce it |
|---|---|
| **Control** | §1 The Leader (act twice without re-aiming) · §2 The Still Bar (nothing moves that you did not move) · §6 One Motion (you never watch the machinery) |
| **Security** | §4 Sticky OPTIONS (the way back is never taken away) · §5 One Kills the Other (the state shown is the state you are in) · `Warning` never faded (the dangerous truth always arrives) |
| **Power** | `Control` never faded (mastery is never punished with hand-holding) · §3 One Material (one surface, one physics — a thing you can learn completely) |

A seventh law, when one comes, should be able to say which feeling it
serves. If it serves none of the three, it is a preference, not a law.
