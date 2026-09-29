# The ACTIONS Constitution

*Laws, not guidelines. A candidate action that breaks ANY law does not ship — there are no waivers. Forged 2026-09-07/08 by Max + Claude. This file outranks every other instruction in this directory.*

## What this is about

Golem is a Linux distribution whose soul is OPTIONS: the shell senses your context through the Brain (`options-engine`) and surfaces exactly the right tool at the right moment, then gets out of the way — game-design philosophy applied to an OS. **ACTIONS are the initiative arm of OPTIONS** — the moments where the system speaks FIRST: it noticed something, formed an intention on your behalf, and offers it as one sentence with a verb in your hand.

The prototype is the sunset OPTION (built and live-verified 2026-09-07): at sunset the current-task pill morphs into *"The sun is set, do you want to turn on eye protection?"* with a nested amber **[turn on]** that fires hyprsunset. Right-click = "not now". That is the register, the scale, and the quality bar for everything that follows.

## I. The Anatomy — every action has exactly five mouths

1. **Trigger** — a sensed condition in the engine: a context predicate (moment) or an evidence counter (habit).
2. **Message** — ONE human sentence.
3. **Verb(s)** — one (rarely two) nested pill(s) that DO the thing in one click.
4. **Refusal** — "no" is one gesture (right-click = not now). It costs nothing, is never punished, and is remembered.
5. **Gear** — grows the action into its palm-sized config box (the same grow-choreography as the notification and clipboard boxes).

## II. The Voice

- **Notifications are the world's voice; ACTIONS are Golem's voice — and Golem only speaks about what it has seen.**
- The voice is a companion, never compliance: observational, warm, zero moralizing, zero guilt. "The sun is set…" is the register. One adjective toward HR-speak and the sentence is wrong.
- One sentence. If the message needs two, the action isn't ready.

## III. Admission — who gets to exist

- **An action must be born from a sensed moment. A feature that cannot name its trigger does not get to be an action.** Trigger first, feature second — never the reverse.
- There are only two legitimate evidence sources:
  - **Moment actions** — the world did something SPECIFIC. Sunset happened; a USB drive containing a camera folder full of photos appeared. Never "a USB was inserted" — specificity is the license to speak.
  - **Habit actions** — the user demonstrated the routine themselves, at least 3 times, and the system offers to carry it ("you erase your history before closing the browser — want me to do it every time?"). The user's manual repetitions are the tutorial; the action is the unlock. The offer describes what the user already does — it never guesses what they might want.
- The admission question, asked of every candidate: **who demonstrated the need — the user, the world, or the designer's imagination?** The first two ship. The third never does. Golem ships observed helpfulness, never imagined helpfulness.
- **The EVERYDAY law:** core actions live in daily-recurring contexts. If the average user would not meet the trigger's context most days, the action is not core.

## IV. The Utterance Economy

- The value of a system that speaks first is INVERSELY proportional to how often it speaks. Sunset speaks once a day, about a real event, offering a real benefit — that is the budget benchmark. The 40 core actions must collectively feel rare.
- Every action carries "don't show this again" in its gear — free, forever. But if users reach for it often, the trigger design already failed.
- **The ladder of automation: offer the hand before the rule.** First assisted ("want me to do it *this time*?"), then — in the gear, or after repeated yeses — automatic ("every time"). Jumping straight to "always" reads as surveillance; the hand first reads as service. A standing rule is automation the user never had to author, only sign — and can read and revoke in the gear.
- A refusal is data: after "not now", the action withdraws until the mind naturally re-offers (next trigger cycle at the earliest). Repeated refusals must escalate toward silence, never toward persistence.

## V. Config Is a Moment, Not a Place

- Settings live INSIDE the action they govern and exist when the topic is alive — not in a Settings app three menus deep. You configure the world by talking to the thing that just spoke to you.
- Gear boxes are palm-sized: a handful of controls. No tabs, no trees, no scrolling. A config box that needs a tree is a Settings app wearing a costume.
- Config contents, in order: (a) domain parameters (temperature, durations, targets), (b) the trigger's own conditions ("headphones only", thresholds, "per 40 min"), (c) the action's lifecycle (frequency, don't show again).
- **The notebook:** the user can always ask "what have you noticed about me?" — every detector listed with its current evidence, a forget button per line, an off switch per detector. There is no silent knowing.

## VI. Privacy — five laws, three disciplines

1. **Local-only as a structural fact.** The engine is INCAPABLE of network — no network dependency exists in `options-engine`, auditable in `Cargo.toml` in ten seconds. "Can't" beats "doesn't"; the architecture is the policy.
2. **Gestures, not content.** Record THAT the user does things, never WHAT the things contain. It may know you erase your history; it must never know what was in it. Detectors watch verbs, not objects.
3. **Aggregates, not diaries.** Detectors live on histograms, counters, and medians — never a timestamped raw log where an aggregate suffices. What was never stored can never leak.
4. **The disclosure is the product.** A detector's entire output is an offer shown to the user's face, which necessarily reveals what was tracked. The brain cannot learn something about you without eventually saying it to you.
5. **The notebook** (law V above): inspectable, erasable, per-detector revocable — one click away.

Disciplines: **no raw keys, ever** (semantic events only — keystrokes are out of scope for actions, permanently); **no detector owns a timer** (detectors are pure functions over the existing event stream and existing polls — zero new wakeups, zero new sensing); **bounded storage** (every detector states its at-rest footprint; whole-disk LUKS is assumed beneath it).

## VII. Anti-Slop

- Clippy failed at admission, not mechanism: too many things earned the right to speak, so the average utterance became worthless. Every action added lowers the average — the admission bar IS the product.
- **Discipline is the product.** The pattern scales beautifully; the permission to use it must not.
- **Quality outranks quota.** If a batch cannot produce 40 actions that pass every law, deliver fewer and say so plainly. Padding a list to hit a number is the definition of slop.
