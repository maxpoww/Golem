# slop-hunt.md — batch 01

*Adversarial rounds per conditions.md §3. Hunt #1 (P4) attacks the 39 entries of
`actions-40-draft.md` §1. Hunt #2 (P8) will attack the finished blocks in
`actions-40.md` and appends below this.*

---

# HUNT #1 — on the draft register (P4)

Constitution re-read top to bottom before the first verdict. Procedure: every
entry is presumed guilty and must survive an attack on a NAMED law — Constitution
III (admission), IV (utterance economy), II (voice), VI (privacy), plus the four
F4 doctrines and the six F5 doctrines carried in STATE.md. The bench is empty
(draft §6), so this hunt cannot replace anything: **every kill lowers the shipping
count, and that is the correct behaviour under Constitution VII.**

## 0. The verdict at a glance

| | count | ids |
|---|---|---|
| attacked | 39 | A01–A40 (no A08) |
| **KILLED** | **5** | A06, A12, A22, A23, A30 |
| **REPAIRED** (survives, changed in a way P5 must honour) | **17** | A01, A03, A09, A10, A11, A15, A16, A18, A19, A20, A25, A26, A28, A35, A36, A40, + A02 (verb condition) |
| KEPT, with a P5 constraint only | 1 | A13 |
| KEPT clean | 16 | A04, A05, A07, A14, A17, A21, A24, A27, A29, A31, A32, A33, A34, A37, A38, A39 |

**Batch 1 now carries 34 actions into P5.** Killed ids are retired, not reused —
A06, A12, A22, A23, A30 join A08 as gaps in the register, so P5's block numbering
stays lineage-stable.

Category distribution after the hunt: system 5, security 5, communication 4,
media 4, power 3, audio/devices 3, coding 2, window/workspace 2, time-of-day 2,
browsing 1, writing 1, search/launch 1, health 1, **files 0**. Sum **34**. Two
categories at the ~5 ceiling, none over.

The hunt killed 13% of the draft and altered 46% of it. It is not a rubber stamp,
and the pattern in what it killed is the unit's real finding (§5).

---

## 1. The ranked attacks (draft §7, in its order)

### 1.1 A19 — the fresh screenshot → **REPAIRED** (moment → standing rule)

The draft's own suspicion was right, and the gate was not the fix. A screenshot
one second old is an object the user's hands are still on: that is OPTIONS
territory by F5 doctrine 1, and adding an evidence gate does not move the
boundary — it only makes Golem speak later about the same object.

But the gate pointed at the real action underneath. If the user has annotated by
hand three times, the thing worth offering is not *this* screenshot, it is the
**rule**: screenshots open in the annotator from now on. Golem owns the
screenshot binding (catalog §4.26, `grim` → `~/Pictures`), so piping its own
output into the annotator is a change inside Golem's own house — no new
mechanism, no reaching into another app.

**Repaired form, binding on P5:**
- Type changes **moment → habit**.
- Trigger: an annotator/OCR class focused within ~60 s of a new file in the
  screenshots dir, ≥3× across days [cheap — window class + the dir watch].
- Sentence: *"You draw on nearly every screenshot you take, do you want them to
  open in the annotator?"*
- Verb: **[open them in the annotator]** — one verb, not two. The OCR half
  (`[copy its text]`) is dropped from ACTIONS: it has no rule form (nobody wants
  every screenshot OCR'd) and belongs on the OPTIONS side as a per-instance pill.
- Fires: once, ever. It stops being the highest-frequency speaker in the batch
  and becomes one of the quietest.

Recorded for P5 and for `implementation.md`: this is the second structural shape
of the batch after A38's "growth on an existing action" — **when OPTIONS already
gives the per-instance hand, the ACTION is the standing rule** (§5, doctrine 4).

### 1.2 A20 — true colours → **REPAIRED** (evidence gate added)

The draft asked whether a colour-accurate minute is a daily need or a
photographer's need. Both framings miss the actual defect: *opening an image does
not demonstrate that the user wants colour accuracy.* The moment is real; the
need is imputed from it, which is F5 doctrine 5 (sense the state, never impute
the motive) and, underneath it, Constitution III — the designer demonstrated this
need, not the user.

The repair is the same one that saved A19: make the user demonstrate it.

**Repaired form:** trigger gains a gate — the user has manually turned hyprsunset
off (or warmed it) while an image viewer/editor class was focused, **≥3×**, and
turned it back on afterwards. Only then may A20 speak, and only once per evening.
The gate also dissolves the audience objection: a gated action has no audience
problem, because it never fires for people who have not shown the behaviour.
Photographers get it; everyone else never hears it exists.

### 1.3 A22 — the one you already have → **KILLED**

Three independent failures, any one sufficient:

1. **Utterance economy (IV).** Launching an already-running app happens several
   times a day for ordinary users. This is a moment action with no gate, firing
   on one of the most common interactions with a computer.
2. **It imputes a mistake the user may not have made.** Single-instance apps
   (browser, chat) already raise their existing window — nothing to fix. The apps
   where a second window *does* open (terminal, editor, file manager) are apps
   where a second window is usually the point. So the trigger fires either where
   there is no problem or where the "problem" is the user's intent.
3. **The verb arrives after the thing it would have saved.** By the time a
   sentence renders, the new window is on screen and visible. The user has
   already learned everything the sentence tells them by looking.

Residue, recorded so it is not lost: the honest home for this is the **launcher
itself** — mark a running app in its own result row. That costs zero utterances
and is an OPTIONS/launcher affordance, not an ACTION. Handed to the catalog, not
to batch 2.

### 1.4 A23 — your own line → **KILLED**

The draft flagged it as "the only verb that is purely a future sentence"; the law
it breaks is Constitution IV, and the reasoning is worse than the flag suggested.

The evidence *is* the refutation. The action's premise is that the user reaches
for the charger at a consistent personal median (38%). A user with a consistent
median is a user who notices reliably, unaided, every day — with a battery
percentage that is already on the topbar. Golem would spend an utterance to
install a **permanent stream of future utterances** telling someone a number they
have proven they already read. The value of a system that speaks first is
inversely proportional to how often it speaks; this action trades one sentence
for many, forever, in exchange for nothing.

Generalised as doctrine 2 in §5 — and the same test *acquits* A32, which is why
the doctrine is written with its boundary attached.

### 1.5 A16 — the waiting update → **REPAIRED** (escalation clause)

The sentence survives the voice test cleanly (it is about the update; the drafted
alternative "you have put this off three times" was correctly rejected in the
draft). The nag risk is real but it is a *lifecycle* defect, not a sentence
defect, and Constitution IV requires escalation toward silence to be structural.

**Repaired form:** at most **one utterance per pending generation** — not per
day, per generation; a second "not now" on the same generation silences the
action until the user applies an update by hand, which is the signal that the
channel still works. The gear's lifecycle control is therefore not an on/off but
a real escalation ladder, and P5's block must show it. Without this clause A16 is
the one action in the batch that could speak weekly forever about the same fact.

### 1.6 A18 — the layout that follows the app → **REPAIRED** (verb specified)

Narrow audience is not a defect once the trigger is evidence-gated (§1.2) — it
simply never speaks to monolingual users. The real weakness was the verb: F5
flagged V18 as one of only two [new] verbs, and "remember the layout per app" has
no Hyprland feature behind it.

It does not need one. The options daemon already watches focus changes live
(catalog §0, hyprland collector) and `hyprctl switchxkblayout` exists. The verb
is therefore **the daemon doing on focus-change what the user does by hand**, out
of a small golem-owned class→layout map.

**Repaired form:** verb tag drops **[new] → [cheap]**, mechanism named in the
block. One of only two [new] verbs in the batch is now retired; V37/A37 stands
alone.

### 1.7 A26 — the wrist → **REPAIRED** (trigger re-specified)

The draft's attack was the right one and the trigger fails it as written. "A tiny
cursor burst within seconds of the idle-timeout boundary" requires sampling
pointer position on a clock — a detector owning a timer, which Constitution VI's
second discipline forbids outright (zero new wakeups, zero new sensing), and it
reads intent out of pointer noise, which cannot distinguish a jiggle from a hand
resting on the trackpad.

There is an event-shaped evidence source that needs no timer: the idle manager
already emits idle-entered / resumed. **Count resumes that are followed by
nothing** — no focus change, no new window, no command through the shell bridge,
within ~30 s. A genuine return to work always produces one of those; a jiggle
produces none. The detector becomes a pure function over events that already
exist, which is exactly the discipline's requirement.

**Repaired form:** trigger = "resumed from idle with no subsequent activity,
≥3×", the inhibitor is scoped to the class that was focused when it happened, and
the pointer is never sampled. Tag stays [cheap] (a small idle collector — idle is
not in catalog §0's nine collectors and P5 must say so honestly).

---

## 2. The voice pass — every sentence against Constitution II

One question, asked of all 39: *does this sentence tell the user something about
themselves they did not ask to hear?* Golem's voice is observational and warm; a
fact about a **thing** is an observation, a fact about a **person** is a verdict.

| id | the word that decides it | verdict |
|---|---|---|
| A01 | "the sound is coming from your browser" | thing. clean |
| A02 | "you have pasted this same text on three different days" | the user's own act, stated without evaluation; the offer is the reason for stating it. clean |
| A03 | "your screen is being shared" | thing. clean |
| A04 | "your microphone just went live" | thing. the register benchmark |
| A05 | "your call is over" | thing. clean |
| A06 | "you have closed the last five from \<app\> without opening any of them" | a tally of the user's behaviour used as evidence of what they want — **the sentence is fine, the counter behind it is not.** Killed in §3 on admission, not on voice |
| A07 | "you pause before you step away" | habit named neutrally, offer follows. clean |
| A09 | "a game just took the screen" | thing. clean |
| A10 | "you keep going back and forth" | borderline — see §3, kept because the alternation is the cost being removed, not a flaw being pointed out |
| A11 | "you keep the volume low at this hour" | clean; the *verb* moralised ("capped"), repaired in §3 |
| A12 | "you downloaded \<file\> a moment ago" | clean. killed on the verb, not the voice |
| A13 | "that is the third day you have typed this command out in full" | clean — the count is the license to speak and reads as attention, not audit |
| A14 | "you type `ls` after almost every `cd`" | clean, and charming without being cute |
| A15 | "you strip the formatting out of most things you paste" | clean (evidence repaired in §3) |
| A16 | "this update has been waiting a while" | thing. the draft's own rejected variant was the scold |
| A17 | "you silence notifications around this time most days" | clean |
| A18 | "you switch the keyboard layout every time you come to this window" | clean |
| A19 | "you draw on nearly every screenshot you take" | clean (repaired sentence, §1.1) |
| A20 | "eye protection is on and you have opened a photo" | two states, no judgement. clean |
| A21 | "the launcher keeps putting \<app\> first and you keep closing it" | the subject is the launcher; the user's closing is evidence against the *tool*. clean, and the best example in the batch of blaming the machine |
| A22 | "\<app\> is already open over here" | clean on its face, but it is the one sentence in the batch whose *implicature* is a correction of the user. killed in §1.3 on frequency and verb |
| A23 | "you reach for the charger around 38%" | clean. killed on the verb |
| A24 | "this machine lives on the charger" | thing, and gently funny. clean |
| A25 | "the battery is down where you usually start saving it" | thing first, habit second. clean |
| A26 | "you keep the screen awake by hand while you read" | clean |
| A27 | "you move the sound over by hand every time these headphones arrive" | clean |
| A28 | "your headset drops to phone-call sound" | thing — the defect is the device's. clean; sentence extended in §3 for honesty, not voice |
| A29 | "you have arranged these monitors the same way again" | clean |
| A30 | "you have been going back and forth between these two" | clean. killed on doctrine 2 |
| A31 | "you move \<app\> over here every time it opens" | clean |
| A32 | "you keep coming back to check on this" | borderline-clean: it names a small anxiety, but the verb dissolves it in one click, which is the kindest possible thing to do with that observation. kept |
| A33 | "you lock the screen by hand whenever you get up" | clean |
| A34 | "the fingerprint reader has been missing about half the time" | thing — the reader is failing, not the finger. clean. the draft was right to flag it and right to keep it |
| A35 | "your password vault is still unlocked" | thing. the rejected variant ("you left your vault open") is the textbook scold |
| A36 | "that came from your vault" | thing. clean |
| A37 | "you clear your history most times you finish with the browser" | clean, and notable: the constitution's own example sentence survives its own voice law |
| A38 | *(no sentence — rides the prototype's)* | n/a |
| A39 | "this is the set you open most mornings" | clean |
| A40 | "you have started closing up" | clean — present tense, describes what is already happening, never predicts |

**Voice pass result: zero kills, two repairs (A11's verb, A28's sentence), two
borderlines recorded (A10, A32).** No sentence moralises, none uses an
HR-register adjective, all are one sentence. That the voice pass killed nothing
is not a failure of the hunt — the voice was the thing F6 worked hardest on, and
the kills in this hunt are all upstream of the sentence, in admission and in the
verb. **Where a sentence is fine and the action still dies, the sentence was
never the problem** — which is itself worth knowing before P5 spends four units
writing prose.

---

## 3. The sweep — the remaining verdicts

### KILLED

**A06 — the app you have already voted on.** The evidence is an act the user
**could not avoid performing**. Closing a notification is the only way to make it
leave the screen; it is forced, not chosen, so it carries no information about
desire. The user demonstrated *tolerance*, and Golem would read it as a
*complaint* — Constitution III's admission question answered honestly gives "the
designer's imagination". Worse, the failure mode is asymmetric: the notifications
most often dismissed without a follow-up are the glanceable ones that did their
whole job in the popup ("build finished", "she's here"), so an accepted offer
blinds the user to exactly the messages that were working. Contrast A17, which is
lawful precisely because toggling do-not-disturb is a voluntary act performed to
obtain relief. **Communication ships 4.**

**A12 — the file you just got.** Killed on the verb, by the same test that killed
V08 at F6. `[use <file>]` promises to put a file into another process's portal
file-chooser dialog. Golem cannot do that: the picker is
`xdg-desktop-portal-*`, it exposes no preselect API, and the only routes are key
injection into a foreign window or building a replacement picker. A sentence that
promises what the verb cannot honour is a lie, and the honest downgrade ("[copy
its path]") is a toll on an act the user finishes with two clicks. Residue: the
right layer is the picker's own recent-files list, not an utterance. **Files
ships 0** — the third category to go extinct in this batch, after
learning/reading and finance/shopping, and for the same reason F5 identified:
**where the user's hands are already on the object, it is OPTIONS territory.**

**A22 — the one you already have.** §1.3.

**A23 — your own line.** §1.4.

**A30 — side by side.** Two failures. First, doctrine 2: in a tiling compositor
putting two windows side by side is a keybind, and a per-instance offer of a
one-keybind act is a toll — and unlike A25 or A27 there is no standing form to
graduate to, because "these two windows" is a pair that exists for ten minutes.
Second, and decisive: **Golem runs Hyprland.** Two windows the user alternates
between are either already tiled together, or deliberately on separate
workspaces. In the second case the offer proposes to undo an arrangement the user
chose, on evidence that is nothing more than ordinary work rhythm — alternating
between an editor and a terminal is not a complaint, it is programming.
**Window/workspace ships 2.**

### REPAIRED

**A01 — the rogue sound.** As drafted the trigger is "browser MPRIS is_playing
while that window is unfocused", which is the single most common media pattern in
existence: music in a background tab. It would speak every day, wrongly, about
audio the user started on purpose. Constitution III's specificity requirement
("never *a USB was inserted*") applies: the sensed thing must be **playback that
began while the window was already unfocused** — audio the user did not start
from anything they could see. Repaired trigger: MPRIS transitions to `is_playing`
while that window has been unfocused ≥10 s. Verb honesty stays as F5 flagged it:
[mute it] mutes the browser, not the tab, and the sentence already says "your
browser" — no repair needed there.

**A02 — the answer you keep typing.** Kept; one condition. The verb needs
somewhere to put a snippet, and `optionsmodules.md` lists the clipboard module as
known-incomplete. P5 must verify the clipboard box can pin an entry: if it can,
the verb is [cheap] as drafted; if it cannot, **the block states [new]** rather
than implying a store that does not exist. No sentence may imply retrieval the
surface cannot perform (the V08 rule).

**A03 — the audience.** Scope condition. If the user is sharing a single window
(the common case in a call), the other windows are not visible and "tuck the rest
away" is noise, or worse, it hides the window they were about to share next.
Repaired: the action speaks only for a **full-output share**; if the portal
cannot distinguish output-share from window-share, the action waits rather than
guessing. P5 must state which it is, honestly, rather than tagging
`is_screencasting` [partial] and moving on.

**A09 — game mode.** Ladder clause. As drafted it asks at every game launch,
forever — a recurring speaker whose answer never changes. Repaired: after the
first yes it graduates to the automatic form and stops asking; after a refusal it
waits for a different game class before speaking again. Constitution IV's ladder
is not optional decoration here, it is the only thing that keeps the action rare.

**A10 — keep it on top.** Scope condition, from F5's V01 caveat. MPRIS resolves
to the player, not the tab: if the video is a browser tab, "pin it in a corner"
pins the entire browser window, which is not what the sentence promises. Repaired:
**the action exists only when the playing window's class is a standalone player**
(mpv/vlc/celluloid) — the same treatment A24 gets for the charge threshold.
Flagged for hunt #2: if P5 cannot give it a standing form, re-test it against
doctrine 2, because a per-instance float-pin-resize is three keybinds, not one,
which is the only reason it survives today.

**A11 — the whisper cap.** The verb moralised where the sentence did not. A
"cap" is a ceiling that fights the user on the night they want it loud, and
enforcement is not a register Golem has. Repaired to a *starting point*, not a
limit: verb **[start quiet after midnight]** — playback started after the hour
begins at the user's own observed low level and any manual change wins
immediately and permanently for that session. Sentence: *"You keep the volume low
at this hour, do you want it to start out quiet after midnight?"*

**A13 — the short name.** Kept; one P5 constraint. On a NixOS distro the shell
config is generated, so the alias must be written to a **golem-owned,
human-readable aliases file that the shell sources**, never into a
nix-managed file and never behind a rebuild. Revocation is deleting a line the
user can read.

**A15 — arrive plain.** The drafted evidence does not exist. Detecting a
"plain-paste" means either reading a keystroke (Ctrl+Shift+V — permanently out of
scope, Constitution VI) or knowing which mime type the receiving app requested,
which requires Golem to *own* the clipboard as a data source. It does not:
`wl-clipboard` is installed as a watcher and catalog §0 feeds `selection.*` from
`wl-paste`. An action whose trigger cannot be sensed does not get to exist
(Constitution III) — so the question is whether a sensable form of the same habit
survives.

One does, and it is better. The laundering round-trip is fully visible to the
collector that already ships: rich text copied, then **the same content re-offered
seconds later as text/plain-only from an editor class**. That is the user
stripping formatting by hand, observed without reading a key or holding content
(hash comparison only). Repaired: trigger = that round-trip ≥3× [live]; verb =
`wl-copy` of the plain version, which is a real one-shot command, not a new
architecture; and the offer is **the standing rule scoped to the source classes
where the laundering was seen** (in practice, the browser), so intentional rich
copies between documents are untouched. Audience narrows, honesty is restored,
tag stays [live].

**A16 — the waiting update.** §1.5.

**A18 — the layout that follows the app.** §1.6.

**A19 — the fresh screenshot.** §1.1.

**A20 — true colours.** §1.2.

**A25 — stretch it.** As drafted it offers to do, this time, a thing the user
does with one click in the bar — doctrine 2's toll. Repaired to the standing
form, which is doctrine 2's stated exception: *"You start saving the battery
around here, do you want that to happen on its own from now on?"* The general
rule is doctrine 3 in §5: for habit actions the repetitions **were** the ladder's
first rung, so the rule is the first offer and Constitution IV's "offer the hand
before the rule" is already satisfied by the user's own hands.

**A26 — the wrist.** §1.7.

**A28 — the good sound.** The verb takes something and the sentence did not say
so: holding A2DP means the headset's microphone is not used, and the call runs on
the laptop's mic instead. A user who says yes and then sounds distant was not
offered that. The V08 rule has a mirror image — **do not hide what the verb
takes.** Repaired sentence: *"Your headset drops to phone-call sound when the
microphone is used, do you want to keep the good sound and use the laptop's
microphone instead?"* Longer, still one sentence, and now true.

**A35 — the open vault.** Two conditions. (i) The per-instance verb must name a
**documented lock command per vault app**; where none exists the action does not
exist for that app (the A24/A37 treatment — never a kill signal aimed at another
program's process). (ii) The automatic form on the ladder is **the vault's own
idle-lock preference**, not a Golem timer that races the app's — the A37 ruling
generalised: when an app owns the behaviour, Golem flips the app's switch rather
than doing the app's job.

**A36 — the vault clipboard.** Most password managers already clear the clipboard
after ten to thirty seconds. Offering to do it anyway is Golem teaching the user
their own tool (F5 doctrine 5) and, at a paste or two a day, a recurring speaker
for something that was never broken. Repaired with a gate that is itself sensable:
Golem speaks only if it has **observed vault-sourced clipboard content still
present after the window** (≥2 occurrences) — if the vault clears, the action
never comes into existence. And once the gate opens it speaks **once**, offering
the standing rule ("clear anything that comes from the vault after 30 seconds"),
not at every paste. A multi-daily moment becomes a one-shot unlock.

**A40 — close up.** R05 was killed at F6 partly because `[quit it]` destroys
unsaved work; A40 closes a whole work set and inherits the same hazard. Repaired
by mechanism: the verb sends **polite close requests only** (the compositor's
closewindow, exactly what clicking the X does), never a signal, so every app's own
save prompt still stands between the user and a loss. P5's block states this in
the verb line, not in a footnote.

### KEPT CLEAN

**A04** (quiet the desk) — the batch's closest sibling to the sunset prototype;
trigger specific, verb reversible, refusal cheap. **A05** (the hand-back) —
survives on the provenance guard F6 attached; it may only speak about a queue
Golem itself held. **A07** (pause when I step away) — a standing rule that
deletes a reflex; the idle dependency is [cheap] and must be declared. **A14**
(the reflex) — F6's ruling holds; the doorway trap is genuinely absent.
**A17** (the hour you always guard) — the cleanest habit action in the batch and
the counter-example that condemns A06: a voluntary relief gesture, repeated.
**A21** (the wrong first hit) — offers something the user cannot do by hand at
all, since launchers expose no demote control. **A24** (stop at 80) — hardware
condition already correct. **A27** (follow my headphones) — textbook.
**A29** (remember this desk) — textbook. **A31** (open it there) — a window rule
authored from the user's own corrections, revocable in one line. **A32** (watch
it for me) — future speech as a verb, *acquitted* under doctrine 2's boundary: it
replaces repeated manual checking of something not otherwise visible. **A33**
(the gap you keep closing) — F6's ruling holds: the offer is about the timeout.
**A34** (another finger) — a fact about the reader, a verb that fixes it once.
**A37** (on the way out) — survives on F6's re-specification; the three
conditions in draft §4.3 must not be softened in P5. **A38** (the second knob) —
zero new sentences by construction; the safest action in the batch.
**A39** (the desk ready) — one unlock, then silence.

---

## 4. Ruling on the two proposed system-level laws (F6 → P4)

### 4.1 THE DAY'S BUDGET — **RATIFIED, with one amendment**

The diagnosis is correct and no per-action law can reach it: 39 individually rare
actions are collectively not rare, and the onboarding week is the proof. A shared
allowance is the right instrument, and the justification F6 gives for making
detectors wait — evidence is already an aggregate, so waiting costs nothing — is
sound.

**The amendment: the budget is a priority queue, not a gate.** As proposed, a hard
cap of three lets two habit unlocks crowd out a vault paste or a screen share,
which is a safety failure dressed as restraint. Ranking, binding on P5's `Fires`
lines and on `implementation.md` ¶2/¶5:

1. **Expiring moments** — actions whose entire value dies with the moment (A03
   share, A36's gated one-shot, A05 hand-back, A01 rogue sound). These always
   speak, and they spend the day's allowance.
2. **Habit unlocks** — these wait, indefinitely and harmlessly, strongest
   evidence first, and never two in the same hour.

Two further clauses: **unspent allowance does not accumulate** (a quiet week must
not fund a loud Monday), and a day in which the budget is exceeded by expiring
moments alone tightens tomorrow's allowance to one. The cap as a number stays
where F6 put it: **≤3 sentences per day.**

### 4.2 ONE MOUTH PER CLUSTER — **RATIFIED, with one amendment**

Correct as stated, and the call-start collision (three sentences in three seconds)
justifies it alone. The five clusters and their priority orders are adopted
unchanged, except that **A06 leaves the silence family** (killed) and **A30 leaves
the window cluster** (killed), which makes both clusters easier, not harder.

**The amendment: a refused cluster member goes to the back of its cluster's
order.** Without it, the highest-priority member re-offers the same refused thing
at every occurrence of the moment while lower-priority members never get to
speak — a cluster whose rank is fixed converts "a refusal is data" (Constitution
IV) into "a refusal is ignored". With it, the cluster drains: each occurrence
offers the best thing not yet answered, and a cluster whose members have all been
answered falls permanently silent.

---

## 5. Doctrines established by hunt #1 (binding on P5 and on hunt #2)

1. **EVIDENCE MUST BE A CHOSEN ACT.** An act the user could not avoid performing
   carries no information about what they want. Dismissing a notification, closing
   a modal, acknowledging a dialog — these are tolls the world charges, not
   gestures the user offered. Only a voluntary act performed *to obtain relief*
   licenses Golem to offer that relief. (Killed A06; acquitted A17.)
2. **A VERB THAT ONLY SCHEDULES SPEECH IS NOT A HAND** — *unless it replaces
   repeated manual checking of something not otherwise visible.* Golem's verbs
   change the world; an action that spends one utterance to install a stream of
   future utterances inverts Constitution IV. The boundary is information
   availability: a battery percentage is already on the bar (A23, killed), a CI
   run's state is not (A32, kept).
3. **FOR HABIT ACTIONS, THE RULE IS THE FIRST OFFER.** Constitution III says the
   user's manual repetitions are the tutorial and the action is the unlock — so by
   the time a habit action speaks, the ladder's first rung has already been climbed
   by the user's own hands. Offering the one-time act instead is doctrine 2's toll.
   (Repaired A25; governs A07, A11, A15, A27, A31, A33, A36.)
4. **WHEN THE ASSISTED FORM IS AN OPTION, THE ACTION IS THE RULE.** Where OPTIONS
   already puts a per-instance hand on the object, ACTIONS may not re-offer that
   hand in a sentence; the only thing left worth saying is the standing rule. This
   is the clean version of F5 doctrine 1, and it is how the OPTIONS/ACTIONS border
   is drawn without either side losing the capability. (Repaired A19.)
5. **DO NOT HIDE WHAT THE VERB TAKES.** The V08 rule (never promise what the verb
   cannot do) has a mirror: never omit the cost the verb imposes. If accepting
   trades something away, the sentence says so and stays one sentence.
   (Repaired A28.)
6. **WHEN AN APP OWNS THE BEHAVIOUR, FLIP THE APP'S SWITCH.** Generalised from
   F6's A37 ruling and applied to A35: Golem prefers turning on another program's
   own documented setting over performing that program's job from outside. Where
   no documented setting exists, the action does not exist for that app.

---

## 6. The bench — still empty, no resurrections

Draft §6 attacked R01–R12 and found all twelve failing a named law. This hunt
killed five actions and therefore had five slots to fill; it re-read all twelve
verdicts and **overturned none.** The closest call was R09 (undocking without
ejecting) — it prevents real data loss and its verdict was EVERYDAY, not quality.
It stays benched: EVERYDAY is a law of this batch, and conditions.md §4 reserves
the weekly tier for batch 3 onward, where R09 should be the first name on the
list. Resurrecting it here to protect a number would be padding with extra steps.

**Batch 1 ships 34 unless hunt #2 finds more, and hunt #2 should expect to find
some** — five of the survivors carry conditions that P5 must discharge in writing
(A02's snippet store, A03's share scope, A10's standing form, A13's aliases file,
A37's per-browser keys), and a condition that cannot be discharged is a kill in
waiting.

---

## 7. What hunt #2 (P8) must attack first

1. **The five conditional survivors above** — check the block discharged the
   condition rather than restating it. An unresolved condition is a kill.
2. **A10** — if P5 gave it no standing form, apply doctrine 2 and doctrine 3
   without mercy.
3. **The `Fires` line of every block** against the ratified budget (§4.1). Any
   block claiming a frequency that the priority queue would not actually permit is
   describing a system that does not exist.
4. **A15 and A26** — both were repaired by relocating their evidence. Verify P5
   wrote the *repaired* trigger and not the drafted one; a repair that does not
   survive into the block is a fiction.
5. **The onboarding week, recomputed on 34.** The audit in draft §2.3 was run on
   39. Redo it on the shipped set with the budget applied and state the honest
   number of sentences a first-week user hears.
6. **Every privacy note** for a detector that stores more than a counter, a
   hash, a median or a histogram — Constitution VI.3, checked against the block's
   own stated at-rest footprint.

---

# HUNT #2 — on the finished blocks (P8)

*Unit 1 of 2: **A01 A02 A03 A04 A05 A07 A09 A10 A11 A13 A14 A15 A16 A17 A18 A19
A20 A21** — eighteen of the thirty-four. Unit 2 takes A24–A40 and the cross-block
sweep. Hunt #1's §1–§6 stand unaltered and its six doctrines are still binding;
nothing below overturns a verdict above.*

Constitution re-read top to bottom before the first verdict.

**The target has moved, and that is the whole point of this round.** Hunt #1
attacked names, triggers and sentences on a draft register — and its voice pass
over 39 sentences killed nothing, because the voice was never the hard part. What
P5 then wrote is seven fields per block that **no hunt has ever read**: Verb(s),
Refusal, Gear, Ladder, Privacy note, Fires, and the mechanism half of Trigger &
evidence. That is where a block can look finished and be fiction, so the attack
was field by field, with one instruction above the others: **a feasibility tag is
a claim about a NAMED mechanism, and a condition restated in other words is a
kill.**

## 0. The verdict at a glance

| | count | ids |
|---|---|---|
| attacked | 18 | A01 A02 A03 A04 A05 A07 A09 A10 A11 A13 A14 A15 A16 A17 A18 A19 A20 A21 |
| **KILLED** | **0** | — |
| **REPAIRED** (survives, changed in the field where the fault sat) | **15** | A01 A02 A03 A04 A05 A07 A09 A10 A11 A13 A14 A15 A16 A17 A20 |
| KEPT CLEAN (nine fields, no finding) | 3 | A18, A19, A21 |
| of the repaired, **CONDITIONAL** on unit 2 | 1 | A10 |

**Shipping count after this unit: 34, unchanged.** Zero kills is a claim that has
to be defended rather than announced; §5 defends it.

**Two numbers moved, and one of them is a headline.** The register carries **two
[new] verbs, not three** (A02 is [cheap] — §1.1), and A11's at-rest store grows
from ≈28 B to ≈47 B because the threshold that was doing its work without being
stored now is (§1.5). Nothing moved the 13-of-34 verdict: every block that could
not speak this morning still cannot.

**Method note, because it decides how much this hunt is worth.** P5 discharged its
conditions *against the tree*, so a hunt that only re-read the prose could check
nothing. Eight of this unit's findings were settled by going back to that tree,
and five came out of source files rather than out of reasoning:
`options-engine/src/collectors/hyprland.rs`, `collectors/audio.rs`,
`mind/activity.rs`, `daemon/src/clipboard.rs`, `daemon/src/hypr.rs` — plus
`OPTIONS/catalog.md` §0 read as a table of *definitions* rather than as a list of
names. Two of those readings **acquitted** a block that argument alone would have
convicted (§1.6). Prose review would have produced the opposite verdict in at
least three places, which is the argument for hunt #3 being a reading of code, not
of documents.

---

## 1. The six findings that move a fact

### 1.1 A02 — the verb was tagged **[new]** on a store that already exists → **[cheap]**

P5 discharged hunt #1's condition honestly and got the answer wrong. It found the
box's dead **"New note"** button (`ClipHit::NewNote`, *"editor not yet wired"*,
`clipboard.rs:3153`) and the MAX-GATED editor call in GRIND.md, and concluded that
**no durable store exists behind the clipboard box**. The module disagrees:
`HISTORY_FILE = "clipboard-history.json"` (`clipboard.rs:225`) is written by
`save_clip_history()` (`:1573`) from five call sites and rolled at `MAX_HISTORY` in
two places (`:1201`, `:1437`). **Every clip the box shows is already a row in a
file Golem writes.** What A02 needs is not a store but *permanence*: a `pinned:
bool` on a row that is already serialised, plus a skip for pinned rows at those two
truncations. That is small work in our own tree — [cheap] by the catalog's own
legend, and structurally identical to A21's sibling penalty map beside
`usage.json`, which P5 tagged [cheap] three blocks later. **Two blocks cannot carry
different tags for the same shape of work.**

Consequences, stated so P9 cannot miss them: the register has **two [new] verbs,
A29 and A37**; `implementation.md` ¶2's "three [new] verbs A02/A29/A37" needs the
same one-word correction, and units 3 and 4's closing notes in `actions-40.md` say
three. What does *not* change: the flag still has to be written, so A02 still
speaks zero times today and the 13-of-34 verdict stands.

### 1.2 A02 again — the sentence claimed a sense Golem does not have

*"You have **pasted** this same text on three different days."* Golem is a
clipboard **watcher**: `selection.*` carries offers — copies. Which application
asked for the data, and when, is knowledge only the clipboard's owner has, which is
exactly the limit that forced A15's evidence to be relocated **three blocks further
down the same file**. A02 claimed on its face what A15 proves cannot be seen.
Repaired to *"You have **copied** this same text…"* — one word, and the trigger was
right all along. Recorded because it is the prose form of the failure this hunt was
sent to find: **a sentence whose verb-tense outruns its sensor is a restated
condition wearing better clothes.**

### 1.3 A10 — the evidence licensed the opposite verb → **evidence RELOCATED**

The hardest verdict of the unit, and the one closest to a kill. P5's trigger was
the alternation: pause → focus to the editor → resume, ≥3 cycles. The verb keeps
the video **playing** in a corner. But what the user demonstrated is *pausing*.
Both readings live in the same signal — "I want to see it while I type" and "I must
not miss it, so I stop it" — and the block picked one. That is F5 doctrine 5 (sense
the state, never impute the motive) and, under it, Constitution III: the offer must
describe what the user does, not guess what they might want. Worse, the verb the
pause-evidence *would* license — pause it for me when focus leaves — is A07 wearing
a different trigger.

It is not a kill, because the unambiguous gesture exists and is already on the
wire. It is the action's own absorbed sibling **U0048, the manual
picture-in-picture**: the user putting a playing player into a corner **by hand**.
`changefloatingmode` is in the engine's own subscribed event set
(`collectors/hyprland.rs:326`; the daemon's list at `hypr.rs:39`) and `is_floating`
is already parsed into context state (`:257`, `:296`) — **[live]**, no new sensing.
The alternation stays in the block as a strengthener; it no longer licenses the
sentence. The sentence changes subject accordingly: *"You put the player in the
corner yourself when you go back to work, do you want it to go there on its own?"*

This is the fifth time in the batch that relocation has saved an action (A15, A19,
A20, A26, now A10), and the pattern is worth naming: **when an action is in
trouble, the fault is almost never the verb — it is which act was counted.**

A10 is therefore a **conditional survivor**: if unit 2's sweep finds the float
gesture is not what the engine actually receives, the relocation is a fiction by
hunt #1's own rule and A10 is the first block struck.

### 1.4 A05 — a `Fires` line the queue would have honoured into a famine

A05 is an expiring moment, so under the ratified budget it speaks **ahead of every
habit unlock and spends the day's allowance**. Its trigger is the end of a call.
For a user with three calls a day, A05 takes all three slots, every day — and the
budget's own tightening clause ("a day blown through by expiring moments alone
tightens tomorrow to one") then starves every other action in the register,
permanently, on behalf of the one action whose answer never changes. P5's `Fires`
line saw the collision and mis-diagnosed it as a property of a busy day.

The repair is hunt #1's own A09 repair, applied where it matters more: **graduate
on the FIRST yes**, not the second — plus the escalation A05 never had, a second
refusal retiring it. The action is now bounded at **two sentences in a machine's
life in either direction**. Recorded as the first case where the day's budget was
not a constraint on an action but a weapon one action could turn on all the others.

### 1.5 A11 — "the bottom decile" is a threshold with nothing to be a decile *of*

The trigger read *playback starting with the default sink in its bottom decile*. A
decile ranks a value against a distribution, and the block's only store was a
24-slot **hour** histogram. No volume distribution exists anywhere in the action, so
the load-bearing word in the trigger was unsupported — the exact shape this hunt
kills for. Repaired in the shape the verb already needed: **two ten-bucket
histograms of the sink volume at playback start**, one for all starts and one for
starts after the late hour (u8, 10 B each); "quiet" is a late start below the
median bucket of the all-day one. Comparative, so it works for the person who lives
at 20 % and the person who lives at 80 %; aggregate, so no night is recoverable;
and it yields the verb's "observed low level" out of the same store instead of a
second number invented for it. At-rest ≈28 B → **≈47 B**, and an honest 47 beats an
unsupported 28.

### 1.6 A09 and A01 — the same question, opposite answers, and only the tree could tell them apart

Two triggers named a thing the prose could not justify. Both looked like the same
defect. They were not.

- **A09 — "a window whose class is in the game set".** Which set? Nothing in the
  block said, and the gear called it "the observed set". **Acquitted by the tree:**
  the engine already ships the list. `mind/activity.rs` carries a
  games/launchers/emulators class table (`:289–295`, `gamescope` and the emulators
  among them) which the classifier deliberately checks *before* the file-manager
  table so `dolphin-emu` is never mistaken for KDE's `dolphin` (`:118`, `:486`,
  `:693`). The set is read from the module that already answers "what kind of thing
  is in front of you". Tag **[live]** survives; the block now names it, and the gear
  offers the shipped table rather than pretending to have observed one.
- **A01 — the ≥10 s unfocused clause, tagged [live] on
  `behavior.focus_switch_velocity`.** **Convicted by the tree:** catalog §0 defines
  that field as *window switches per second (churn)* — a rate over all windows, not
  a per-window stopwatch. It cannot answer "has **this** window been out of sight
  for ten seconds", and the clause it was supporting is the entire repair hunt #1
  made to this action. The mechanism that can is one level deeper in the same
  collector: `FocusTracker` already records focus instants *in order to compute that
  velocity* (`collectors/hyprland.rs:157–176`). Repaired, and the clause's tag drops
  **[live] → [cheap]**.

Same symptom, opposite verdicts, and the difference was ten minutes of reading.

---

## 2. Field-by-field verdicts, all eighteen

**A01** — trigger: tag on the wrong signal, **REPAIRED** (§1.6). Privacy: the
shared lifecycle row is *defined* here for the whole batch, and it lists id,
last-offered day, answer and **refusal** count — yet a dozen blocks offer their
automatic rung "after two acceptances", which that row cannot count. **REPAIRED
batch-wide:** an accept count (u8) joins the row, inside the same ≈32 B. It is the
only counter in the register whose purpose is to make Golem stop talking. Verb,
Refusal, Gear (4 controls), Ladder, Fires: clean — and the ladder's argument that
the *hand* beats the *rule* here is the batch's only deliberate inversion of
doctrine 3, argued rather than slipped in.

**A02** — verb tag **REPAIRED** (§1.1), sentence **REPAIRED** (§1.2), ladder
wording followed the sentence. Gear (4, ordered; the vault-provenance control is
reused from A36 rather than re-invented), Refusal (retires on the second no),
Privacy (11 B × 64 ring ≈700 B, hashes only), Fires (zero until the flag ships):
clean.

**A03** — trigger: the dormancy is discharged, not restated, and the honest reason
is named — the portal's `SelectSources` exchange is between the sharing app and the
portal, Golem is neither party, and reading it is the surveillance posture VI
forbids. Verb [live], unblock named as [cheap] work on our own portal. **Refusal:
REPAIRED** — "silent for this cast" is a reset, not an escalation, and Constitution
IV requires repeated refusals to walk toward silence; two refusals now retire it.
Gear, Ladder, Privacy (nothing stored — the batch's cleanest), Fires (zero today):
clean.

**A04** — trigger: the 5 s floor had no stated mechanism, and A04 is the one block
in the unit where **no second event arrives** to settle the interval. **REPAIRED**
by naming the audio collector's existing **2 s heartbeat**
(`collectors/audio.rs:28`, `:121` — the heartbeat is kept *because `pw-mon` is a
signal, not a poll*), so the floor is "still live at the third heartbeat" and the
detector still owns no clock. Privacy: **REPAIRED** — its hour histogram was quoted
at ≈48 B where A11's and A17's identical structures are u8 at 24 B; the three are
now one width, because the batch publishes its arithmetic. Verb (a shipped daemon
action, proven end to end at catalog §4.17), Refusal, Gear, Ladder, Fires: clean.

**A05** — Ladder and Fires **REPAIRED** (§1.4); Refusal **REPAIRED** (escalation
added). Privacy: **REPAIRED** — the gear offers "only after calls longer than N
minutes" while A04's note forbids the stopwatch in so many words; the block now
says the length is computed live between the two mic transitions and dies with the
call. F4 doctrine 2 forbids a duration reaching **disk**, where it becomes a diary
of how long the user talks; a length that exists for one comparison is no length at
all. Trigger (the provenance guard — Golem may only speak about a queue it held),
Verb, Gear: clean.

**A07** — trigger **REPAIRED**. P5 wrote the idle source as "logind's `IdleHint`
**or** the compositor's idle-notify", and only the second half is true on a stock
Golem: `IdleHint` is set by whatever manages the session, and nothing in the tree
sets it — no `hypridle`, no `swayidle`, no idle client of any kind, the same absence
A26 and A33 are dormant on. A detector reading it would read a property that never
moves. `ext-idle-notify-v1` is the opposite case: the compositor is the source and
an idle daemon is merely another client of it. Verb (never auto-resume — *returning
to a room that starts talking at you is worse than returning to silence*), Refusal
(90 days, then permanent), Gear, Ladder, Privacy (3 B × 16 ≈48 B), Fires: clean.

**A09** — trigger **REPAIRED** by citation (§1.6); the gear's "observed set"
corrected to the shipped table, extendable. Ladder carries hunt #1's first-yes
graduation. Verb, Refusal (permanent per class), Privacy (9 B × 16 ≈144 B — hashes,
so the disk never holds a readable list of what the user plays), Fires: clean.

**A10** — evidence **RELOCATED** (§1.3); sentence, ladder and privacy note follow
it. **CONDITIONAL SURVIVOR.** Verb (three dispatches, all [live]), Refusal (60
days), Gear, Fires: clean.

**A11** — trigger **REPAIRED** (§1.5); privacy follows it. Verb: hunt #1's repair
survived intact, and the *label* is the repair — **[start quiet after midnight]**,
with any manual change winning immediately and permanently for that session.
Refusal, Gear, Ladder (the rung above is deliberately given to A27 — *one verb, one
action*), Fires (waits for the evening cluster's mouth): clean.

**A13** — **Fires REPAIRED:** it claimed a "shell mouth" cluster, and no such
cluster exists. Draft §3.3 gives A13 and A14 **one shared slot inside an existing
cluster**, and §2.4 — the list ratified in §4.2 — puts that slot in the **morning**
cluster, ranked **A39 > A34 > A13/A14**. A block may not invent a queue structure to
describe its own patience. Trigger ([live] on the shipped zsh bridge, with two
filters correctly placed in the trigger rather than the gear: a length floor, and
exit-0 only, because *an alias for a typo is a trap with a name on it*), Verb (the
aliases file discharged in full), Refusal, Gear, Privacy (11 B × 128 ≈1.4 kB), and
the **Ladder — the batch's boundary case** — survive unaltered: doctrine 3 binds
when the verb writes a *rule*, not when it assigns a *name*, and an engine quietly
minting `gsu` into a user's shell is authorship without consent.

**A14** — **Fires REPAIRED** (same cluster correction). **Verb REPAIRED:** the
block promises the hook runs *the user's own `ls`*, and the gear caps the listing at
100 entries — but piping through `head` makes `ls` drop its columns and its colour,
so the capped listing would visibly not be the user's own. The hook now **counts
first and runs second**: a bare zsh glob (`f=(*(N))`) is a builtin with no fork;
over the cap it prints the count and the revocation line *instead of* listing, under
it runs the user's command untouched. Trigger (a ratio, ≥60 %, which is what
licenses the word "almost" in the sentence), Refusal (doubles the evidence bar),
Gear, Ladder, Privacy (≈6 B, the second-smallest in the batch): clean — and the
revocation-where-it-bites repair is intact and remains the best single idea in the
unit.

**A15** — **Privacy REPAIRED:** P5's note put a 32-entry hash ring **at rest** at
≈350 B and then said the hashes expire after ~60 s. Both cannot be true, and the
more alarming reading — a disk ring of clipboard content hashes — was the one the
arithmetic published. Split: the comparison ring is **memory-only** and dies with
its window; what reaches disk is the evidence, which is per **source class** (class
hash + counter + last-seen day, 11 B, capped at 8, **≈88 B**). The detector must
remember *that a class launders*, never *what was laundered*. Trigger (the
relocated round-trip, `best_text_mime` cited, [live]), Verb (and it says out loud
what it takes — the formatted version is gone), Refusal, Gear, Ladder, Fires: clean.

**A16** — **Gear REPAIRED:** "only when a restart is actually required
(kernel/initrd drift)" is a control with no mechanism until the comparison is named
— the `kernel` and `initrd` symlink targets under `/run/booted-system` against
those under `/nix/var/nix/profiles/system`, two `readlink`s in the collector that
already reads those profiles. Trigger: the best paragraph in the unit, because it
*refuses* the draft's evidence — "count the defers" — on the ground that **there is
no defer button in Golem to press**, and counting an act that does not exist is hunt
doctrine 1 read backwards. Verb (the intent-file / `systemd.path` / root-oneshot
shape, twice proven in our own tree; `boot` not `switch`; absent on the ISO by
design, so it never speaks there), Refusal (the escalation clause, intact), Ladder,
Privacy, and a **Fires line that improved the law it was written against** — a
pending update is a moment whose value does not die with the moment, so the queue
ranks by *expiry*, not by type: clean.

**A17** — **Gear REPAIRED:** "still show calls and alarms" needed its mechanism,
and it is the A36 shape — a notification declares its own `urgency` and `category`
hint, the module already receives both, so the rule reads a **declared type name**
and never the summary, the body or the sender; an app that declares nothing is held,
which is the safe direction. Trigger: the own-hand-only repair survived and is the
batch's first instance of *never learn from your own hand*. Verb, Refusal, Privacy
(24 B histogram + median), Fires (silence family), and a **Ladder whose rung above
is deliberately nothing** — a quiet hour that grows teeth of its own is the
surveillance register: clean.

**A18** — **CLEAN, nine fields.** The tag honesty is exemplary in both directions:
`active_layout` is [partial] in catalog §0, so the block writes **[cheap]** and
names the cost (Hyprland's socket emits `activelayout`; the daemon is already
connected to it) rather than claiming [live], and the verb's [new] → [cheap] repair
is carried with its mechanism. Two honest limits sit in the verb line where they
belong (the map holds layout *indexes*, so re-ordering re-points the rules; a manual
switch wins while that window keeps focus). Narrow by construction, which is what
narrow should mean.

**A19** — **CLEAN, nine fields.** The moment→habit conversion is intact, the OCR
pill is gone with its absorption visibly spent rather than quietly dropped, and the
block states the fact that decides whether it ever exists: **no annotator ships with
Golem**, so on a stock machine the gate never opens. Noted for the record: A19 is
the lawful answer to A09's question — its "annotator class" needs no class table
because *the evidence itself defines the set*. Where a trigger can be its own
classifier, it should be.

**A20** — **Trigger REPAIRED:** the gate counted the user turning the warmth "off
**or down**", and the engine carries a **boolean** — warmed or not. A change of
degree moves nothing the detector can see, so half the gate was counting an event
that does not arrive. Struck; the on/off pair is both sensable and the stronger
evidence. Verb ([live], and the daemon knows the exact value it replaced, so the
restore is exact rather than a guess at "warm"), Refusal, Gear, Ladder, Privacy,
Fires (third in the evening cluster, gated audience only): clean.

**A21** — **CLEAN, nine fields**, and the model block for what this hunt was looking
for. The verb goes to the tree and comes back with the answer rather than a promise:
`UsageDb` is a flat `{app-id: count}` JSON (`usage.rs`) consulted by a single sort
key (`main.rs:2501`), **it has no query dimension**, so the honest shape is a sibling
store plus one extra term — *"named here so it cannot be read as a wish"*. Its
ladder also names the alternative Golem is refusing (silent ranking ML, which is
what every other launcher does), which is Constitution VI.4 argued rather than
asserted.

---

## 3. The thirteen binding repairs — did they survive into the block?

STATE.md named thirteen repairs P5 was required to carry *into* the blocks rather
than restate in a preamble. **All thirteen survived, verbatim in substance:** A01's
playback-began-while-already-unfocused-≥10 s · A03's full-output-share-only · A09's
graduate-after-the-first-yes · A10's standalone-player-classes-only · A11's **[start
quiet after midnight]** with any manual change winning · A13's golem-owned
human-readable aliases file, revocation = deleting a line · A14's listing cap plus
revocation surfaced where it bites · A15's laundering round-trip on hash comparison
only · A16's one-utterance-per-pending-generation · A17's own-hand-only DND counting
· A18's [cheap] mechanism (focus watcher + `hyprctl switchxkblayout` + a class→layout
map) · A19's moment→habit conversion with ONE verb · A20's
demonstrated-hyprsunset-off gating at evening rank 3.

**And that is the unit's structural finding.** Fifteen blocks needed repair, and
**not one defect sat in a sentence hunt #1 had already audited.** Every fault was in
material P5 wrote fresh, un-attacked, while discharging a condition next door: the
wrong catalog field cited in the same paragraph as a repair that was correct (A01);
a store researched thoroughly and concluded wrongly (A02); a cluster invented in a
`Fires` line while the trigger above it was exact (A13). Attention is not a property
of a document, it is a property of a **sentence** — and the sentences under audit
were all fine. Hunt #3, and every later batch, should assume the same: the defect
will be next to the thing everyone was looking at.

---

## 4. Rulings and doctrines established by hunt #2

Continuing hunt #1's numbering; binding on unit 2, on P9, and on batch 2.

7. **NAME THE MECHANISM OR DO NOT TAG IT.** A feasibility tag is a claim about a
   named signal, file, socket, counter or threshold — not a mood about difficulty.
   Citing a catalog field that measures something adjacent (A01's churn rate doing
   duty as a per-window stopwatch), or a threshold with no stored distribution
   behind it (A11's decile), is a restated condition with a tag stapled to it. The
   test that caught both: *point at the thing that would have to change in the
   tree.* If the pointer lands on a sentence instead of a mechanism, the tag is
   fiction.
8. **THE EVIDENCE MUST LICENSE THE VERB, NOT MERELY CO-OCCUR WITH IT.** A signal
   compatible with two opposite intentions licenses neither. Count the act the verb
   would perform on the user's behalf — not the friction around it (A10: the
   alternation was the friction; the hand-cornering is the act). This is F5 doctrine
   5 pushed one step further: it is not enough to sense the state rather than impute
   the motive, because a state can *contain* two motives.
9. **THE NO-TIMER DISCIPLINE BINDS DETECTORS, NOT VERBS.** Constitution VI's second
   discipline forbids a *detector* owning a timer — zero new wakeups for sensing. A
   verb that restores a value after sixty seconds (A20) or hands a queue back at the
   end of a call (A05) is an effect the user asked for by clicking, and the live
   sunset prototype is itself time-based. Stated because unit 2 will meet the same
   shape and must not kill an effect under a sensing law. The corollary is the half
   with teeth: an interval **inside a trigger** must be settled either by a second
   event arriving (A01, A15, A19, A21) or by a poll that already runs for another
   reason (A04's 2 s audio heartbeat, A17's topbar clock) — never by a wakeup the
   detector books for itself.

---

## 5. Zero kills — the defence

A hunt that kills nothing is suspicious, and this one killed nothing while repairing
fifteen of eighteen blocks. Why that is the honest outcome rather than a soft round:

1. **Admission was already spent.** Hunt #1 killed five on admission — the question
   *who demonstrated the need* — and that was the right place to lose actions. This
   hunt could only ask *is the thing you named real*, and a failure there names its
   own repair: the mechanism either exists in the tree or it does not. In every case
   here, one did. A kill would have been warranted where **no** mechanism could be
   found — the A03 posture, where reading another program's portal session is
   forbidden rather than merely missing — and A03 was already written as dormant by
   P5, honestly, rather than as a promise.
2. **The one block that earned a kill got a relocation instead** (A10, §1.3), and
   relocation is this batch's established remedy, applied by hunt #1 four times
   (A15, A19, A20, A26) and never yet overturned. It is also weaker than a kill in
   exactly the right way: A10 is now conditional, and unit 2 can finish the job in
   one line if the wire does not carry what the block claims.
3. **The bench is still empty.** Hunt #1 §6 disqualified R01–R12 and **no verdict has
   been overturned here** — none was even examined, because with zero kills there is
   nothing to fill. R09 remains the first name for the weekly tier of batch 3.

Under Constitution VII this is the correct shape: the count did not fall because
nothing deserved to fall, and nothing was resurrected to protect a number. **34
stands into unit 2**, where a kill is likelier — A24–A40 holds the batch's two
dormancies, its only [bridge], and its largest at-rest stores.

---

## 6. Handed to unit 2 — A24–A40 plus the cross-block sweep

1. **A26's and A33's dormancy may be describing the absence of the wrong thing**
   (§2, A07). The tree has no idle *daemon* — that is certain. But under
   `ext-idle-notify-v1` the **compositor** is the idle source and a daemon is just
   another client of it, and the launcher is already a Wayland client. Rule on it in
   writing: if idle is one protocol subscription away, A26 is [cheap] rather than
   dormant and the batch's "13 of 34 can speak today" is understated. A33's *other*
   half — no locker ships at all — stands regardless, so A33 probably does not move.
2. **Two headline numbers now need re-checking rather than re-asserting:** two [new]
   verbs (§1.1), and whatever unit 2 does to the dormancy count. P9's SUMMARY must
   publish the corrected pair, and `implementation.md` ¶2 still carries the stale
   "three".
3. **Run the Refusal field of every remaining block for ESCALATION**, not merely for
   a re-offer rule. Two of eighteen here (A03, A05) said "silent for this
   occurrence", which is a **reset**, and Constitution IV asks for a walk toward
   silence. It is the cheapest defect to miss, because it reads like discipline.
4. **Run every `Fires` line against the cluster list in draft §2.4 as ratified**, not
   against the cluster a block names for itself (A13/A14 invented one). The five are:
   call start, evening, morning, device arrival, the silence family.
5. **The onboarding week, recomputed on 34** (hunt #1 §7.5, still unpaid): with the
   budget applied and A05 now bounded at two, state the honest number of sentences a
   first-week user hears, and check that one day's queue can carry all 34 `Fires`
   lines.
6. **The ~5-per-category ceiling and near-duplicates** across the whole register —
   and note that A07 and A10 now sit *closer* than they did, since A10's relocation
   moved it off the pause behaviour A07 owns. If any pair in the batch is a
   near-duplicate today, it is that one.

---

## 7. Unit 2 — the second sixteen (A24 A25 A26 A27 A28 A29 A31 A32 A33 A34 A35 A36 A37 A38 A39 A40)

**Sixteen attacked. ZERO killed, NINE repaired, SEVEN clean. The shipping count
stays 34.** Constitution re-read top to bottom first; the seven-field test is unit
1's, and it found something in nine of sixteen — a slightly lower density than unit
1's fifteen of eighteen, and the reason is legible: this is the hardware half of the
register, where P5 was already discharging conditions against the tree line by line,
so the prose had less room to drift. What it did not have less of was **arithmetic**,
and that is where two of the unit's three headline findings landed.

**The unit's method find, and it decides how batch 2 should read the tree.** Three
blocks in this unit lean on the fact that the dock and the engine are **two halves of
one process** — A40 states it perfectly (*"the event is already arriving in this
process and needs an arm, not a subscription"*), A39 uses the launcher's own launch
seam, and **A29 forgets it entirely** and reports an absence the other half of its own
binary contradicts. The register is written as though `options-engine` were the whole
program. It is not, and the difference is worth ~150 lines of unbuilt work in one
block alone. *A tree sweep that stops at the crate boundary reports absences that are
merely elsewhere.*

### 7.1 A29 — the trigger reported an absence the same process contradicts, twice

P5 wrote: *"`parse_event` has no arm for them … and the engine has **never** queried
`j/monitors`, so Golem holds **no monitor inventory at all** today."* The first clause
is true of the collector. The second is false of the program:

- **`monitoradded` / `monitorremoved` are already subscribed and already acted on** —
  they are the `SCREEN_DRIFT` list (`crates/daemon/src/hypr.rs:33`), matched at
  `:861`, where a monitor arriving calls `app.reassert_screen_state()` because the
  DRM rebuild drops hyprsunset's colour matrix. Monitor arrival is a **live wakeup in
  this process today**.
- **`j/monitors` is already queried and already parsed** — `focused_monitor()`,
  `hypr.rs:898–900`, into a `MonitorInfo` carrying connector name, scale and active
  workspace. What is missing is not the query: it is the `.find(focused)` filter at
  `:905`, which throws away every output but one. A29 needs the **set**, which is the
  same read with the filter dropped.

Under doctrine 7 the tag must point at a thing that would have to change in the tree.
It does — but at a much smaller thing than the block claims. Trigger stays **[cheap]**
and the premise is repaired.

**And the verb's [new] was argued on a second false premise.** The block presents
`zwlr_output_manager_v1` as a protocol the landscape survey *spec'd field by field*,
which reads as a family Golem does not speak. Golem speaks it:
**`wayland-protocols-wlr` is already a dependency** (`crates/daemon/Cargo.toml:32`),
and the daemon **already binds and drives a sibling manager end to end** —
`zwlr_screencopy_manager_v1` / `zwlr_screencopy_frame_v1` with full `Dispatch` impls
(`screencopy.rs:31–34`, `:978–1013`), including the build → submit → wait-for
`Ready`/`Failed` handshake that is structurally the same as output-config's
`apply` → `succeeded`/`failed`.

**The tag nevertheless stays [new]**, and the reasoning matters for batch 2: the
catalog's legend is precise — [cheap] is *a small addition to an existing collector*,
and there is no existing collector to add to, because this is an **actuator**, a new
module beside `screencopy.rs`. Bigger than A02's flag, smaller than a new dependency.
What changes is the honest *size* of the gap, not the count: **A29 still does not
speak.** One unverified assumption is named rather than smuggled: Hyprland implements
wlr-output-management, and Golem's fork changed the config parser rather than the
protocol set — **not verified on the fork**, and it is one `wayland-info` away.

### 7.2 A34 — the [bridge] tag points at a socket the action never touches → **[new]**

The catalog's legend is not a mood scale. It reads: *"**[bridge]** needs an app to
talk to the bridge socket (`$XDG_RUNTIME_DIR/options/bridge.sock`)"* (catalog §0,
lines 31–34) — one named socket, the seam the zsh and nvim clients use. A34's evidence
is **Golem reading fprintd's outcome lines out of the system journal**. fprintd does
not talk to Golem's bridge and never will. The tag was used to mean *awkward,
second-class, someone else's cooperation* and it named a mechanism the action does not
use — doctrine 7 exactly, in the one place in the batch nobody thought to check,
because the tag itself looked like an admission of weakness.

The honest tag: **nothing in the engine reads the journal** (`grep -i journal` over
`crates/options-engine/src` returns **zero matches**), and no existing collector has
authentication as its subject, so this is a **new collector** — **[new]** by the
legend's own words. It is a cheap [new]: one scoped `journalctl -u fprintd.service`
line reader on exactly the `pw-mon` watcher pattern the audio collector already ships
(`audio.rs:156–168`). But it is not an addition to anything that exists.

**Consequences, both of which P9 must publish:**

1. **The register carries THREE [new] verbs again — A29, A34, A37** — not the two
   §1.1 corrected it to. Unit 1 moved A02 out of the [new] column on a real finding;
   unit 2 moves A34 in on an equally real one. The net is unchanged from P5's
   original three, arrived at by two independent corrections that happen to cancel.
   *This is worth saying plainly: the number was right by accident and wrong in both
   its members.*
2. **The batch ships ZERO [bridge], as F3 did.** P5 flagged its single [bridge] as a
   deliberate regression needing ratification or a kill. Neither is needed: the
   regression never happened. There was a mislabelled [new].

**And the posture question P5 handed up is answered rather than shrugged at.** A34's
block says reading the `pam_fprintd` ↔ `fprintd` D-Bus exchange would be *"the exact
posture A03 was made dormant for"* and escapes to the journal. Is the journal the same
posture? **No, and the distinction is principled.** A03 would have to become a monitor
on a **private session between two other programs** — an exchange neither party
published, observed without either knowing. The journal is a **published system log**,
ACL'd to `wheel` by systemd's own design (`system/Modular/base/users.nix:13–18`),
read-only, and read by every administrator on every Linux machine. Eavesdropping on a
conversation is not the same act as reading a notice board. The posture is admitted;
the tag was the defect.

The action is not killed. Its admission, verb (`fprintd-enroll` **visibly**, in the
user's own session), refusal escalation, ladder (no automatic rung — *"an action that
quietly climbed that rung would be the single worst thing in this batch"*) and privacy
note are all sound, and no law is broken once the tag is honest. **But P9 now weighs
three dormant verbs in a thirty-four-action batch, and A34 is the one whose prize is
smallest** — one sentence, ever, on machines that have a fingerprint reader *and* a
flaky one. If P9 wants a kill to hold the [new] count at two, this is the block to
take, and taking it would be defensible. Unit 2 does not take it, because a tag error
names its own repair and a small prize is not a broken law.

### 7.3 A39 — "the largest evidence store in the batch" is wrong by a factor of three

The block's privacy note closes: *"**≈206 B**, the largest evidence store in the
batch."* Every privacy note in the file was re-added for this sweep. It is not the
largest; it is **fourth**:

| block | at rest | arithmetic |
|---|---|---|
| **A02** | **≈700 B** (+32 row ≈ **732 B**) | 11 B × 64-clip ring |
| **A21** | **≈550 B** (+32 ≈ **582 B**) | 17 B × 32-pair ring |
| **A31** | **≈180 B** (+32 ≈ **212 B**) | 11 B × 16 classes |
| A39 / A40 | ≈206 B | 150 + 24 + 32 |

The claim has propagated: it is in **A39's block**, in **actions-40.md's closing
note**, in the P5 hand-off notes, and — the one that matters, because it is the
document a reader who has read nothing else will read — in **`implementation.md` ¶4**:
*"the heaviest, A39's and A40's, are 206 bytes."* All three copies are repaired here
except the last, which belongs to P9 with §10's list.

**The claim it was serving survives, and that is the point of checking.** Summing all
thirty-four privacy notes gives **≈3.7–3.8 KB** for the batch's entire memory of its
user (A01's and A11's own stores read approximately). *"A few kilobytes of counters,
hashes, medians and histograms"* is **true**. Only the superlative was false — and a
superlative is exactly the kind of claim that gets repeated, which is why it had to be
the one that was wrong. **Privacy stated as arithmetic has to be arithmetic that was
added up.**

### 7.4 A35 — doctrine 9's interval, in the one block that meets it

Predicted by STATE and found where predicted. A35's trigger is *"no focus visit has
reached the vault for **≥4 hours**"*. Doctrine 9's corollary: an interval inside a
trigger must be settled **either by a second event arriving or by a poll that already
runs** — never by a wakeup the detector books for itself. A35's interval can be
settled by neither of the obvious candidates, because the trigger is an **absence**:
no second event is coming, that is the whole observation. The block never says what
notices the four hours passing, which leaves the reader to assume a timer — the one
thing Constitution VI forbids outright.

It is a repair, not a kill, because a poll that already runs is right there: the
system collector's **3 s tick** (`system.rs:19`), the same one A24 rides, and the
topbar clock A17 rides. Comparing a stored last-focus instant against a tick that is
already firing costs nothing and books no wakeup. Named in the block now.

**A36 met the same shape and passes on a second event** — *"still the current offer
after the window elapsed"* is settled when the **next** clipboard offer arrives and
its arrival is compared against the previous one's. No tick needed at all. Also named,
because doctrine 9 asks for the mechanism to be stated, not merely to exist.

### 7.5 Field-by-field, all sixteen

Seven tests: (i) trigger names a mechanism (ii) verb named, tag honest (iii) `Fires`
legal under the ratified queue (iv) gear ≤5, ordered, absorbed habits spent
(v) ladder / doctrines 3 and 6 (vi) privacy shape + bytes, no detector timer
(vii) refusal **escalates**.

- **A24 — stop at 80 · CLEAN.** (i) The strongest trigger in the unit: `"Full"` is
  explicitly not-charging and *the test asserts it* — verified,
  `charging_from_status` at `system.rs:363`, `assert!(!charging_from_status("Full"))`
  at `:439`. (ii) The root-unit pattern is real: `waverunner-apply.nix:184`
  `systemd.paths`, `:188` `PathChanged`, `:98` the reject-invalid-entry guard —
  P5's citation is exact. (vii) 90 days → **second refusal retires permanently** ✓.
  (v) No assisted rung, defended on doctrines 2 and 3 ✓.
- **A25 — stretch it · CLEAN.** (i) `laptop.nix:13`
  `services.power-profiles-daemon.enable = true;` — verified verbatim. (ii) Doctrine 4
  argued in the block, and the rule fires at **the user's median**, not the distro's
  15 % — which is the reason the action is not the shipped `battery_dim` OPTION
  wearing a sentence. (vii) discharge cycle → 60 days → two retire ✓.
- **A26 — the wrist · REPAIRED** (§8.1). Dormancy stands, premise corrected, at-rest
  total stated (≈182 B). (vii) class answered → two anywhere retire ✓.
- **A27 — follow my headphones · REPAIRED (minor).** At-rest total was not stated
  where every other block states one and P9 has to add them up (≈104 B). Everything
  else clean, and the privacy note carries the sharpest observation in the unit:
  **a Bluetooth device name is often a person's name**, which is why the hash is the
  only thing at rest.
- **A28 — the good sound · CLEAN.** (ii) `wpctl set-profile` / `set-default`, named.
  (iii) Call-start **rank 1** — legal, and it silences A04 and A03 on that call by the
  ratified cluster rule. (vi) *"Calls are never counted"* — Constitution VI.3 read
  strictly, and correctly: a count of calls is a diary of a working life in one
  integer. (vii) three refusals per device retire ✓.
- **A29 — remember this desk · REPAIRED ×2** (§7.1). Tag stays [new]; both premises
  corrected.
- **A31 — open it there · REPAIRED (one clause).** Same species as A29 and much
  milder: *"dropped on the floor"* is true of `parse_event` and misleading about the
  process, since `openwindow` and `movewindow` are both in the dock's `RELEVANT` list
  (`hypr.rs:35–45`) and already drive `on_layout_changed()`. No tag moves — it was
  [cheap] and stays [cheap]. (ii) The `eval()` → `hl.window_rule` path with the
  `hyprctl reload` wipe (`:1135–1142`) is the best-argued verb in the unit.
- **A32 — watch it for me · CLEAN.** (ii) The doctrine-2 acquittal is argued **inside
  the block** as required, on the information-availability boundary, and the block
  states plainly that what it installs is a **notification** — the world's voice — so
  it does not spend the budget. (v) One rung by design ✓. (vii) window answered
  forever → three retire ✓.
- **A33 — the gap before it sleeps · CLEAN, dormancy AFFIRMED.** Re-verified
  independently rather than inherited: `hypridle|hyprlock|swayidle|swaylock|waylock|
  gtklock|xss-lock|physlock` over all of `/home/max/Golem` matches **only this
  batch's own files**. Nothing locks; nothing sleeps. The block is also careful in a
  way A26 was not — it never writes `hypridle` config as though it existed.
- **A34 — another finger · REPAIRED ×2** (§7.2: [bridge] → [new]; `Fires` cluster).
- **A35 — the open vault · REPAIRED** (§7.4). (ii) Condition (i) discharged as a rule
  — no documented lock command, no action for that app ✓. (v) Doctrine 6 at its
  clearest: the automatic rung is **the vault's own idle-lock preference**, because a
  Golem timer racing the vault's timer produces two locks and an unreproducible bug.
- **A36 — the vault clipboard · REPAIRED (minor, §7.4).** (i) Verified in the shipped
  code: `x-kde-passwordManagerHint` at `clipboard.rs:519/525`, *"sensitive clip
  (password-manager hint) — not recorded"* at `:526`. (vii) **Single refusal retires
  outright** — attacked as a possible escalation failure and **acquitted**: it is
  maximum escalation, not a reset, and the block defends it.
- **A37 — on the way out · REPAIRED (precision).** (i) *"[live] on the title stream
  Golem already watches"* overstates by the exact amount A32 spends a paragraph
  correcting three blocks earlier: `windowtitle` / `windowtitlev2` are **unparsed**.
  The tag survives on a different mechanism — a clear-browsing-data dialog **takes
  focus**, and focus events re-read the title (`activewindow` → `RefreshWindow` →
  `j/activewindow`, `hyprland.rs:326`, `:289`) — so the trigger is live for modal
  dialogs and only for those. Named. (ii) The Chrome refusal, with the
  managed-by-your-organization consequence, is the batch's best example of a verb
  declining a mechanism that would work.
- **A38 — the second knob · CLEAN, and the best block in the unit.** Every citation
  verified: `has_backlight()` is a bare `read_dir` existence check at
  `system.rs:214`; `sunset_nested_rects()` returns a **2-tuple**, `options.rs:1804`
  (and again at `:3548`); `SUNSET_MSG` at `:137`; the width math's single inner label
  at `:2114`. (iii) *"Literally zero new sentences, forever"* — the only `Fires` line
  in the register the queue cannot possibly refuse.
- **A39 — the desk ready · REPAIRED ×2** (§7.3 privacy superlative; §9.4 cluster).
  (iv) Seven absorbed habits spent as five controls — the batch's largest absorption
  and the model for what a gear box is.
- **A40 — close up · CLEAN.** (i) The model statement of the process finding, and it
  is verified: `closewindow` is in `RELEVANT` (`hypr.rs:37`), handled at `:824–829`.
  (ii) `hypr::dispatch` at `:69` — and the doc comment confirms the block's caution
  about the fork: *"Fire a Hyprland dispatch (**this Hyprland's Lua form**)"*.
  (v) The automatic rung **never closes the first window** — *"a machine deciding your
  day is over is not a rung, it is a different product."*

---

## 8. The four things unit 1 handed over — ruled on in writing

### 8.1 A26 and A33: is the dormancy naming the absence of the wrong thing? — **PARTLY YES, AND THE DORMANCY STANDS ANYWAY**

Unit 1 was right to be suspicious and right about the mechanism. A26's block says the
premise *"itself is missing"* and reaches for the nine collectors to prove it. That
conflates two different absences:

- **Idle SENSING is not missing.** Under `ext-idle-notify-v1` the **compositor** is
  the idle source; a daemon is merely another client, and the launcher is already a
  Wayland client. A07's block (unit 1's territory) already states this correctly.
  Honest cost, checked rather than assumed: `crates/daemon/Cargo.toml` carries
  `wayland-client 0.31`, `smithay-client-toolkit 0.19`, `calloop-wayland-source` and
  **`wayland-protocols-wlr`** — but **not `wayland-protocols`**, the crate that
  carries the `ext-*` staging and `wp-*` unstable families. So idle notification
  (`ext_idle_notify_v1`) and the inhibitor A26's verb needs
  (`zwp_idle_inhibitor_v1`) are **one dependency line plus a registry bind plus a
  `Dispatch` impl** on a connection and an event loop that already exist — the same
  shape `screencopy.rs` already ships. That is [cheap], not dormant.
- **What IS missing is anything that ACTS on idle**, and that is what A26 is actually
  about. The action's premise is a user **fighting the screen dimming**. On a stock
  Golem the screen never dims, never blanks, never locks. So: the habit **cannot be
  performed**, the counter can never reach three, and the verb — an idle inhibitor —
  would inhibit an idle **nothing consumes**. Both mouths still fail, on firmer
  ground than the block gave.

**Therefore: A26 and A33 stay dormant, and the "13 of 34" is NOT understated on their
account.** The repair is to A26's *reasoning*, not to its status — and the correction
is worth making because the current sentence would be read, correctly, as *Golem
cannot sense idle*, which is false and would mislead whoever implements it.

A33 needs no repair: its other half — nothing locks at all — was re-verified over the
whole tree and stands regardless. It is the harder dormancy of the two, exactly as
unit 1 predicted.

### 8.2 The corrected headline numbers — **and BOTH of the pair need re-checking, not just one**

**The [new] count is THREE: A29, A34, A37.** §7.2 puts A34 back in the column A02
left. P9 publishes three, and `implementation.md` ¶2's *"three [new] verbs A02, A29,
A37"* is stale **in its members, not in its number** — the cheapest possible way for a
correction to be missed, and the reason unit 1's hand-off said "re-check, don't
re-assert."

**"13 of 34 can speak today" is OVERSTATED and P9 must recount.** Two blocks were
counted as speaking that cannot, and both are unit 1's territory rather than this
unit's, which is why the sweep exists:

1. **A01** was in P5 unit 1's *"7 of 9 can speak"*, and then **hunt #2 §1.6 downgraded
   its tag [live] → [cheap]** (the churn rate cannot answer "has THIS window been out
   of sight for ten seconds"; repaired onto `FocusTracker`'s focus instants). A block
   waiting on [cheap] work does not speak today. **−1.**
2. **A07** was also in that seven, and its own block declares *"the idle half is
   **[cheap]** and must be declared honestly: idle is not among the engine's nine
   collectors"* — and P5's own STATE note says so too (*"Idle declared [cheap] and NOT
   a collector (A07)"*). It was counted as speaking anyway. **−1.**

**So the honest figure is 11 of 34, not 13** — subject to P9's per-block recount,
which is the right place for it because units 3 and 4 also counted by hand. Nothing in
unit 2 moves the count: A26 and A33 stay dormant (§8.1), A34 was already not speaking,
A29 still cannot speak.

One correction runs the other way and P9 should apply it: **A10 undersells itself.**
Its trigger says the corner-ness of the geometry is *"one more field out of the
`j/clients` inventory ([cheap])"*, but `at` and `size` are **already parsed** into
every `ClientWindow` (`hyprland.rs:258–265`). Only `pinned` is unparsed, and `pinned`
belongs to the **verb**, not the trigger. A10's trigger is fully **[live]**.

### 8.3 A10's conditional — **DISCHARGED. The gesture is on the wire; A10 survives.**

Unit 1 relocated A10's evidence to the user's own hand-cornering of a playing player
and left it conditional: *if the float gesture is not what the engine actually
receives, the relocation is a fiction and A10 is the first block struck.* Checked at
the wire:

- **`changefloatingmode` is parsed** — `parse_event` maps it to `Event::RefreshWindow`
  alongside `activewindow`/`fullscreen`/`workspace` (`hyprland.rs:326`), and there is
  a unit test feeding it a real payload (`:386`).
- **`is_floating` is parsed twice** — in the clients inventory (`:257`) and in the
  focused-window reply (`:296`).
- **The daemon subscribes to it independently** — `changefloatingmode` is in
  `RELEVANT` (`hypr.rs:39`).

One honest limit, which does not break the relocation: `parse_event` **discards the
event payload** and re-queries `j/activewindow`, so what is observed is the floating
state of the **focused** window. For A10's gesture that is exactly right — a user who
reaches out and floats a player has focused it in the same motion — but a window
floated *without* focus (by a rule, or a dispatcher aimed elsewhere) would be invisible
to this detector. Stated so nobody discovers it later and calls it a bug.

**A10 stands, unconditionally, and it is [live] rather than [cheap] (§8.2).**

### 8.4 The arithmetic — re-added, and one superlative fails

Unit 1's four corrections carried forward and applied: 33 lifecycle rows at ≈32 B ≈
**1.06 KB** (the accept-count byte lives inside the same row); **A11 ≈47 B** not ≈28 B;
**A15 ≈88 B** not ≈350 B; **A04's histogram 24 B** not 48 B. Added to those, from this
unit's own re-add of all thirty-four privacy notes:

- **The largest per-action store is A02 at ≈700 B (≈732 B with its row), not A39/A40
  at ≈206 B** (§7.3). Order: A02 ≈732 · A21 ≈582 · A31 ≈212 · A39 ≈206 · A40 ≈206 ·
  A26 ≈182 · A18 ≈192 · A09 ≈176.
- **Batch total ≈3.7–3.8 KB.** The qualitative claim — *a few kilobytes of counters,
  hashes, medians and histograms, no timestamped diary* — **survives intact.**
- **A38 remains the floor at ≈2 B** with no lifecycle row of its own, because growth
  on an existing action inherits that action's bookkeeping.
- Two blocks stated a ring size and a row but no total (A26, A27); both now state one,
  so the file is addable end to end as unit 1 intended.

---

## 9. The cross-block sweep — the half of this unit nobody had done

### 9.1 The ~5-per-category ceiling — **PASSES, verified by count**

Every lineage line in `actions-40.md` re-read: browsing 1 (A01) · communication 4
(A02 A03 A04 A05) · media 4 (A07 A09 A10 A11) · coding 2 (A13 A14) · writing 1 (A15) ·
**system 5** (A16 A17 A18 A19 A20) · search/launch 1 (A21) · power/battery 3
(A24 A25 A26) · audio/devices 3 (A27 A28 A29) · window/workspace 2 (A31 A32) ·
**security 5** (A33 A34 A35 A36 A37) · health/ergonomics 1 (A38) · time-of-day 2
(A39 A40) · **files 0**, learning/reading 0, finance/shopping 0. **Sum 34**, two
categories at the ceiling, none over. Matches the post-hunt-#1 tally exactly.

### 9.2 Near-duplicates — **A07 vs A10 acquitted; a different pair found**

**A07 vs A10 is NOT a near-duplicate, and the relocation moved them apart rather than
together.** Unit 1's worry was reasonable and turns out to be backwards: A07 counts a
**pause followed by idle** and its verb **stops playback**; A10 now counts a **float
gesture followed by a focus move** and its verb **keeps playback going**. Different
act counted, opposite verb, different moment (leaving the desk vs staying at it). They
are complementary rules a single user could sensibly hold both of — *pause when I
leave, corner it while I work* — and the queue's never-two-unlocks-in-an-hour rule
already prevents them sharing an occasion. **No sixth cluster**, which is the obvious
wrong repair and the one A13/A14 were corrected for inventing.

**The real near-duplicate is A31 vs A39 — not of trigger, but of MECHANISM.** Both
author window-placement rules by class, both through `hl.window_rule` over `eval()`,
and both into **`~/.config/golem/rules/windows`**. Their triggers differ honestly
(three manual corrections of one class vs a recurring morning set), so this is not
repetition under conditions.md §4. But two gear boxes editing the same lines of the
same file is a real product defect: a user who removes a placement in A39's gear and
finds it still applied by A31's rule has met a bug we designed. **Repaired in A39's
gear**, which now points at the shared list rather than implying a second one.

Also swept and cleared: A27 vs A29 (same cluster, different subject) · A24 vs A25
(ceiling vs saver) · A33 vs A35 (screen vs vault) · A36 vs A02 (opposite directions on
one flag, and A36 names it for A02 to reuse) · A40 vs A07 (both can stop playback, at
different moments, idempotently).

### 9.3 Can one day's queue carry all 34 `Fires` lines? — **YES, and the worst
realistic day is FIVE sentences, not three**

The worst day that is actually plausible, built from the register's own `Fires` lines:

| when | action | kind | verdict |
|---|---|---|---|
| 08:40 | **A39** desk ready | unlock, morning rank 1 | speaks (1) |
| 08:41 | A34, A13/A14 | unlocks, morning rank 2–3 | **silenced** — one mouth per cluster |
| 10:15 | **A28** good sound | expiring, call rank 1 | speaks (2) |
| 10:15 | A04, A03 | call rank 2–3 | **silenced** |
| 13:00 | **A35** open vault | expiring, ≤1/day | speaks (3) — budget spent |
| 16:30 | **A16** waiting update | expiring | speaks (4) — **overrun** |
| 19:20 | **sunset prototype** (+A38 riding) | expiring | speaks (5) — **overrun** |
| 22:00 | A40 close up | unlock, evening rank 4 | **silenced** |

**Every habit unlock is correctly starved and every expiring moment is correctly
heard** — but the total is five, and **the ratified law does not actually say ≤3.** It
says *"≤3 action sentences a day"* **and** *"expiring moments always speak and spend
the allowance"*, which cannot both hold. Read together the only coherent meaning is:
**the budget is a debt, not a gate** — expiring moments speak and overrun it, habit
unlocks may never exceed it, and *"a day blown through by expiring moments alone
tightens tomorrow to one"* is how the overrun is repaid. Under that reading the day
above is legal and self-correcting: tomorrow is capped at one.

**This is a clarification the two laws need and no block could have found alone.**
Handed to P9 for `implementation.md` ¶5, which currently states the cap without the
debt.

Two consequences worth stating rather than hiding:

- **The live sunset prototype spends a slot.** It must, or the user hears four
  sentences on a "three-sentence" day. It is an expiring moment, so it always speaks —
  the correct outcome, since silencing Golem's flagship to protect an arithmetic
  would be the budget eating the product.
- **A32 is the only recurring expiring moment with no cluster and no daily cap**
  (*"a few times a week"* for someone who runs builds). It is the one line in the
  register that could, on a bad week, push several days into overrun on its own. Not a
  defect today — its speech is a *notification*, which the block correctly excludes
  from the budget, and the **offer** is one sentence per window. Flagged for batch 2:
  if a second watch-shaped action ever ships, they need a cluster.

### 9.4 Every `Fires` line against the five ratified clusters — **one three-way contradiction**

The ratified five (draft §2.4 as §4.2 ratified them): **call start · evening · morning
· device arrival · the silence family.** No block invents a sixth (A13/A14's "shell
mouth" was unit 1's kill and stayed dead).

- **call start** — A28 rank 1 > A04 > A03. All three name it. ✓
- **evening** — sunset prototype (+A38) > A11 > A20 > A40 rank 4. All name it. ✓
- **device arrival** — A27, A29. Both name it, both name each other. ✓
- **the silence family** — A04, A09, A17, at most one silencing offer a **week**
  across all three. A09 (*"as a silence-family member"*) and A17 (*"the third member
  of the silence family (A04, A09, A17)"*) both name it. ✓
- **morning — BROKEN, three ways.** A13 states the ratified ranking **A39 > A34 >
  A13/A14** (unit 1's own repair, binding). A14 agrees. But **A39 claims it is the
  "MORNING cluster's only member, so it has no rival for that mouth"** and **A34
  claims "no cluster, waits behind everything expiring."** Two blocks written in P5
  units 3–4, before unit 1 corrected A13/A14 into that cluster, and never revisited.
  A39's claim is the load-bearing one: *"no rival for that mouth"* is the reason its
  `Fires` line promises a fast landing, and it is false. **Both repaired**; the
  ranking A13 cites is the survivor, because it is the one a hunt ratified.

Blocks correctly outside all five clusters, re-checked: A10, A15, A19, A32, A35, A37
(and A38, which has no rank because it has no sentence). A34 was in this list and is
not any more.

### 9.5 The onboarding week, recomputed on 34 — **4 to 7 new sentences, not 11 to 13**

Unpaid since hunt #1 §7.5 and computed on 39 in the draft. Recomputed on 34, with the
budget applied and A05 bounded at two sentences in a machine's life:

**The draft's fear was an artefact of a bad assumption** — that counters cross
simultaneously. They cannot. **Nineteen of the thirty-four are habit unlocks requiring
≥3 occurrences across separate days or sessions**, so the earliest any of them can
speak is day 3, most need a week or more of the *specific* behaviour, and several
(A24, A25, A29, A34) need hardware or a routine most first-week users do not have.

Week one, honestly:

- **Habit unlocks that can plausibly cross by day 7: two to four** — A39 (three
  mornings), then whichever of A07/A17/A27/A31/A13 the user's own week actually
  demonstrates. One-mouth-per-cluster and never-two-unlocks-in-an-hour then stagger
  even those.
- **Expiring moments: two to four** — A28 on the first call with a Bluetooth headset,
  A32 for someone running builds, A16 if an update lands, A35 or A36 for a vault user.
  Most users meet a subset.
- **Not counted as new speech: the sunset prototype's seven evenings**, which shipped
  in 2026-09 and is the register's benchmark rather than its addition. A38 rides it
  and adds nothing.

**So: 4–7 new sentences in the first week, most days silent, no day above the
overrun ceiling in §9.3.** The binding constraint in week one turns out to be
**evidence accrual, not the budget** — the budget only bites on the two or three worst
days of a mature install. That is the healthier failure mode of the two, and it is
worth P9 stating in SUMMARY: the day's budget was ratified to solve the onboarding
spike, and the arithmetic now says the ≥3-occurrence thresholds had already solved it.

---

## 10. Zero kills in unit 2 — the defence, and what P9 inherits

**Sixteen attacked, none killed. 34 stands. Batch 1 ships 34.**

Unit 1 defended its zero on the grounds that admission was already spent. Unit 2's
defence is different and narrower, because this unit *did* have kill material — the
batch's two dormancies, its only [bridge], its largest stores — and it declined all
four:

1. **A26 and A33 stay dormant rather than dying** because dormancy is an honest state
   and this batch invented it deliberately: a block written in full, with its unblock
   named, is worth more to whoever builds Golem than a gap in the numbering. They are
   *flagged for the kill they still deserve* if batch 1 ships before an idle manager
   does — that flag is P9's to act on, and it is now better argued than it was (§8.1).
2. **A34's [bridge] was a tag error, and a tag error names its own repair.** The
   posture it was flagged for is defensible (§7.2), the prize is small, and P9 has an
   explicit, argued option to kill it if three [new] verbs in thirty-four is one too
   many. Unit 2 does not spend a kill to improve a ratio.
3. **A39's superlative was arithmetic, and arithmetic is repaired by re-adding it**,
   not by removing the block that got it wrong. The claim it served survived the
   re-add, which is the outcome that should be reported and was.
4. **The bench is still empty.** R01–R12 remain disqualified by hunt #1 §6 and **no
   verdict has been overturned** — none was examined, because with zero kills there is
   nothing to fill. Nothing was resurrected to protect a number, in either unit.

**Hunt #2 total across both units: 34 attacked, 0 killed, 24 repaired, 10 clean.** A
hunt that kills nothing twice is suspicious by conditions.md §3, so the honest
statement of what these two units were: **hunt #1 was an admission hunt and killed
five; hunt #2 was a verification hunt and killed none, because its question — *is the
thing you named real* — has a repair as its answer whenever the tree contains a
mechanism, and it did every time.** Where the tree contained nothing (A26, A33) the
blocks were already written as dormant, honestly, before the hunt arrived. The kill
that hunt #2 could have made and did not is A34, and it is documented above with the
argument for it, so P9 can make it without redoing the work.

**Handed to P9 — the finalize unit:**

1. **`actions-40.md`** — repairs applied in this unit: A26 (premise + total), A27
   (total), A29 (both premises), A31 (clause), A34 (**[bridge] → [new]**, cluster),
   A35 (doctrine 9), A36 (doctrine 9), A37 (title mechanism), A39 (privacy superlative,
   cluster, shared rules file), and the file's closing note. **Verify the structure
   still greps to 34 blocks × 9 fields.**
2. **`implementation.md` has THREE stale claims, not one:** ¶2's *"three [new] verbs
   A02, A29, A37"* (right number, wrong members — it is **A29, A34, A37**); ¶4's
   *"the heaviest, A39's and A40's, are 206 bytes"* (**A02's ≈700 B is the heaviest**;
   the *few kilobytes* claim stands); and ¶2's **13 of 34**, which should be **11 of
   34** subject to the recount in §8.2.
3. **`SUMMARY.md` publishes the pair honestly** — 34 shipped (not 40), and the
   recounted speak-today figure (not 34, and not 13 either).
4. **Two rulings for P9 to record rather than rediscover:** the day's budget is a
   **debt, not a gate** (§9.3), and the batch ships **zero [bridge]** (§7.2).
5. **One optional kill, fully argued and ready:** A34 (§7.2). Taking it makes the
   batch 33 with two [new] verbs; leaving it makes it 34 with three. Either is
   defensible; neither is padding.
