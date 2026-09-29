# actions-40-draft.md — batch 01, F6

*The draft register: name + one-line trigger + the ONE sentence + the verb pill
label(s). No full blocks — those are P5. Per cut-50.md §"Going into F6", F5 landed
on 40 by itself and satisfied the ~5-per-category ceiling, so F6 is not a cut: its
four jobs are the utterance-economy audit (§2), the three near-neighbour rulings
(§3), the three flagged singles (§4), and the near-duplicate sweep inside the
at-ceiling categories (§5).*

**Result: 39 actions drafted, not 40.** V08 (the focus playlist) was killed here
on its own flagged honesty problem (§4.1), the bench R01–R12 was attacked in order
for a replacement and **none survived** (§6), so media ships 4 instead of 5 and
batch 1 carries 39 into P5. That is Constitution VII working, not a shortfall —
the alternative was a sentence promising something MPRIS cannot do.

**F6's own finding, and the biggest design output of this unit:** the 40 were
audited one at a time all the way down the funnel, and one at a time every one of
them is rare. Together they are not. Twenty-five of the thirty-nine are habit
unlocks that speak once and then fall silent forever; fourteen are moment actions
that speak whenever the world does the thing — and four of those fire inside the
same three seconds at the start of a call. **The utterance economy cannot be
enforced per action. It has to be enforced across the set**, by a shared budget
and a cluster rule (§2.4). Without them, an unlucky Tuesday in the first week of
ownership hears eleven sentences and Golem becomes Clippy with better taste.

---

## 1. The register — 39 actions

Lineage carried in parens: `(V-id U-id T-id S-id H-id)`. Type per Constitution
III. Feasibility tags per options-catalog.md §0 legend. Sentences are the draft
register only — P5 writes the full blocks (schema: conditions.md §2), carrying
each V-id's `ABSORBS:` list from cut-50.md as gear material.

### browsing — 1

**A01 — the rogue sound** (V01 U0003 T0004 S0017 H0017) · moment · browsing
- **T:** browser MPRIS `is_playing` while that window is unfocused [live]
- **S:** "The sound is coming from your browser, do you want it muted?"
- **V:** [mute it] · [show me]

### communication — 5

**A02 — the answer you keep typing** (V02 U0015 T0018 S0061 H0075) · habit · communication
- **T:** the same clipboard text (hashed) pasted on ≥3 separate days [live] + [cheap]
- **S:** "You have pasted this same text on three different days, do you want it kept as a snippet?"
- **V:** [keep it as a snippet]

**A03 — the audience** (V03 U0023 T0026 S0073 H0093) · moment · communication
- **T:** `is_screencasting` goes true [partial→cheap]
- **S:** "Your screen is being shared, do you want the rest of the windows tucked away until it ends?"
- **V:** [tuck the rest away]

**A04 — quiet the desk** (V04 U0024 T0027 S0074 H0094) · moment · communication
- **T:** the microphone goes live [live]
- **S:** "Your microphone just went live, do you want your desk quiet?"
- **V:** [quiet my desk]

**A05 — the hand-back** (V05 U0026 T0029 S0076 H0097) · moment · communication
- **T:** mic goes inactive after a long live stretch AND Golem is holding a queue it silenced [live]
- **S:** "Your call is over, do you want to see what I held back?"
- **V:** [show me]

**A06 — the app you have already voted on** (V06 U0032 T0036 S0093 H0117) · habit · communication
- **T:** notifications from one source closed within seconds, no focus to that app, ≥5× [live]
- **S:** "You have closed the last five from \<app\> without opening any of them, do you want \<app\> muted?"
- **V:** [mute \<app\>]

### media — 4 *(was 5; V08 killed in §4.1)*

**A07 — pause when I step away** (V07 U0044 T0049 S0109 H0136) · habit · media
- **T:** manual pause followed within seconds by idle, ≥3× [live] + [cheap]
- **S:** "You pause before you step away from the desk, do you want me to do that part?"
- **V:** [pause when I step away]

**A09 — game mode** (V09 U0060 T0066 S0138 H0169) · moment · media
- **T:** a game class goes fullscreen [live]
- **S:** "A game just took the screen, do you want game mode?"
- **V:** [game mode]  *(notifications held + performance profile, both restored on exit)*

**A10 — keep it on top** (V10 U0065 T0072 S0146 H0183) · habit · media
- **T:** pause → focus to terminal/editor → resume, ≥3 cycles in one session [live]
- **S:** "You keep going back and forth between the video and your work, do you want it pinned in a corner?"
- **V:** [keep it on top]

**A11 — the whisper cap** (V11 U0066 T0073 S0147 H0184) · habit · media
- **T:** playback starting with the sink in its bottom decile after a recurring late hour, ≥3 nights [live]
- **S:** "You keep the volume low at this hour, do you want it capped after midnight?"
- **V:** [keep it quiet after midnight]

### files — 1

**A12 — the file you just got** (V12 U0078 T0085 S0173 H0237) · moment · files
- **T:** a portal file-chooser window appears within minutes of a completed download [live] — **gated** (§2.5): only after the user has been seen navigating to Downloads inside a picker ≥3×
- **S:** "You downloaded \<file\> a moment ago, do you want that one?"
- **V:** [use \<file\>]

### coding/work tools — 2

**A13 — the short name** (V13 U0093 T0100 S0204 H0283) · habit · coding
- **T:** the same long command recurring across ≥3 days via the shipped zsh bridge [live]
- **S:** "That is the third day you have typed this command out in full, do you want a short name for it?"
- **V:** [make it `gsu`]  *(the proposed alias is read live at offer time, never stored)*

**A14 — the reflex** (V14 U0094 T0101 S0205 H0285) · habit · coding
- **T:** the `cd`→`ls` pair via the shell bridge, ≥20× across days [live]
- **S:** "You type `ls` after almost every `cd`, do you want the shell to do it for you?"
- **V:** [do it for me]

### writing/docs — 1

**A15 — arrive plain** (V15 U0112 T0119 S0237 H0337) · habit · writing
- **T:** rich-text mimetype on the clipboard followed by a plain-paste in an editing context, ≥3× [cheap]
- **S:** "You strip the formatting out of most things you paste, do you want them to arrive plain?"
- **V:** [keep it plain]

### system/settings — 5

**A16 — the waiting update** (V16 U0117 T0124 S0256 H0381) · moment · system
- **T:** `deploy.stale_generation` / `not_activated` with the defer counted ≥3× [live]
- **S:** "This update has been waiting a while, do you want it applied when you next shut down?"
- **V:** [apply it when I shut down]
- *Register note: the sentence is about the update, never about the user. "You have put this off three times" was drafted and rejected — it is the same fact wearing a scold.*

**A17 — the hour you always guard** (V17 U0118 T0125 S0257 H0387) · habit · system
- **T:** do-not-disturb toggled by hand at a recurring hour, ≥3 days [live]
- **S:** "You silence notifications around this time most days, do you want that to happen on its own?"
- **V:** [every day at this hour]

**A18 — the layout that follows the app** (V18 U0122 T0129 S0263 H0415) · habit · system
- **T:** `active_layout` changes correlated with the focused window's class, ≥3 days [partial→cheap]
- **S:** "You switch the keyboard layout every time you come to this window, do you want it to follow the app?"
- **V:** [remember the layout per app]

**A19 — the fresh screenshot** (V19 U0124 T0131 S0268 H0429) · moment · system
- **T:** a new file in the screenshots dir [live via the shell's own binding] — **gated** (§2.5): only after the user has annotated or OCR'd a screenshot by hand ≥3×, and at most once per session
- **S:** "That screenshot is ready, do you want to draw on it or take its text?"
- **V:** [draw on it] · [copy its text]  *(the anatomy's rare two-pill maximum)*

**A20 — true colours** (V20 U0125 T0132 S0270 H0436) · moment · system
- **T:** hyprsunset active AND an image viewer/editor class takes focus [live]
- **S:** "Eye protection is on and you have opened a photo, do you want true colours for a minute?"
- **V:** [true colours for a minute]

### search/launch — 2

**A21 — the wrong first hit** (V21 U0129 T0136 S0276 H0450) · habit · search/launch
- **T:** launcher fires app X for query Q, that window closes within seconds, ≥3× for the same pair [live]
- **S:** "The launcher keeps putting \<app\> first and you keep closing it, do you want it moved down?"
- **V:** [stop putting it first]

**A22 — the one you already have** (V22 U0137 T0144 S0295 H0477) · moment · search/launch
- **T:** the launcher fires an app whose class already has a live window [live]
- **S:** "\<app\> is already open over here, do you want that one?"
- **V:** [go to the one you have]

### power/battery — 4

**A23 — your own line** (V23 U0139 T0146 S0308 H0502) · habit · power
- **T:** `is_charging` flips at a recurring personal battery percentage, median over ≥3 occurrences [live]
- **S:** "You reach for the charger around 38%, do you want me to say so when you get there?"
- **V:** [tell me at 38%]  *(the number is the user's own median, read at offer time)*

**A24 — stop at 80** (V24 U0141 T0148 S0311 H0505) · habit · power
- **T:** `is_charging` near-constant across ≥3 sessions [live], **and** the hardware exposes `charge_control_end_threshold` [cheap] — the action does not exist where it does not
- **S:** "This machine lives on the charger, do you want it to stop charging at 80%?"
- **V:** [stop at 80%]

**A25 — stretch it** (V25 U0144 T0151 S0314 H0510) · habit · power
- **T:** a manual power-saver switch or backlight dim at a recurring low battery level [live] + [cheap]
- **S:** "The battery is down where you usually start saving it, do you want it stretched?"
- **V:** [stretch it]

**A26 — the wrist** (V26 U0154 T0161 S0327 H0541) · habit · power
- **T:** a tiny cursor burst within seconds of the idle-timeout boundary, ≥3× [cheap] (pointer state, never input capture)
- **S:** "You keep the screen awake by hand while you read, do you want it to stay awake here?"
- **V:** [keep it awake]

### audio/devices — 3

**A27 — follow my headphones** (V27 U0067 T0074 S0148 H0188) · habit · audio/devices
- **T:** a default-sink change to the same device within seconds of that device appearing, ≥3× [cheap]
- **S:** "You move the sound over by hand every time these headphones arrive, do you want them to take it automatically?"
- **V:** [follow my headphones]

**A28 — the good sound** (V28 U0161 T0168 S0341 H0582) · moment · audio/devices
- **T:** the card profile flips to HSP/HFP as capture starts [cheap]
- **S:** "Your headset drops to phone-call sound whenever the microphone is used, do you want to keep the good sound instead?"
- **V:** [keep the good sound]  *(hold A2DP, take the mic from the laptop)*

**A29 — remember this desk** (V29 U0167 T0174 S0347 H0608) · habit · audio/devices
- **T:** a monitor add followed within seconds by the same manual re-arrangement, ≥3× [live]
- **S:** "You have arranged these monitors the same way again, do you want this desk remembered?"
- **V:** [remember this desk]

### window/workspace — 3

**A30 — side by side** (V30 U0171 T0178 S0353 H0626) · habit · window/workspace
- **T:** focus alternation locked to one window pair, ≥N flips inside a short window [live], live state only
- **S:** "You have been going back and forth between these two, do you want them side by side?"
- **V:** [put them side by side]

**A31 — open it there** (V31 U0180 T0187 S0382 H0664) · habit · window/workspace
- **T:** the same move/float/monitor correction within seconds of a class's window opening, ≥3× [live]
- **S:** "You move \<app\> over here every time it opens, do you want it to open there?"
- **V:** [open it there from now on]

**A32 — watch it for me** (V32 U0182 T0189 S0391 H0674) · moment · window/workspace
- **T:** repeated focus visits to a window whose title carries a changing NN% or a CI/PR state marker [live]
- **S:** "You keep coming back to check on this, do you want me to tell you when it changes?"
- **V:** [tell me when it changes]

### security/privacy — 5

**A33 — the gap you keep closing** (V33 U0185 T0192 S0404 H0691) · habit · security
- **T:** manual lock events clustering before the idle/sleep boundary, ≥3× [cheap]
- **S:** "You lock the screen by hand whenever you get up, do you want it locked as soon as the screen sleeps?"
- **V:** [lock as soon as the screen sleeps]
- *Register note (F5's flag resolved): the offer is about the TIMEOUT, not about locking — if the distro already locks on sleep, the user's hand is evidence the gap is too long, and that gap is what the verb shortens.*

**A34 — another finger** (V34 U0186 T0193 S0409 H0698) · habit · security
- **T:** fprintd verify outcomes, failure ratio over a window [cheap]
- **S:** "The fingerprint reader has been missing about half the time, do you want to add another finger?"
- **V:** [add another finger]

**A35 — the open vault** (V35 U0187 T0194 S0411 H0701) · moment · security
- **T:** a vault class present and unlocked across hours with the desk idle [live] + [cheap]
- **S:** "Your password vault is still unlocked, do you want it locked?"
- **V:** [lock it]
- *Register note: the sentence describes the door, never the person. "You left your vault open" was drafted and rejected.*

**A36 — the vault clipboard** (V36 U0188 T0195 S0413 H0710) · moment · security
- **T:** a clipboard write while a vault class is focused [live] — a provenance flag only, never a hash of the content
- **S:** "That came from your vault, do you want it cleared from the clipboard in 30 seconds?"
- **V:** [clear it in 30 seconds]

**A37 — on the way out** (V37 U0192 T0199 S0421 H0732) · habit · security
- **T:** the browser's "Clear browsing data" dialog title appears, ≥3× [live]
- **S:** "You clear your history most times you finish with the browser, do you want the browser to do it itself on the way out?"
- **V:** [clear it on the way out]  *(verb re-specified in §4.3 — Golem flips the browser's own clear-on-shutdown preference while the browser is closed; it never touches the history store itself)*

### health/ergonomics — 1

**A38 — the second knob** (V38 U0196 T0203 S0430 H0809) · habit · health
- **T:** the live sunset OPTION is firing AND the user has manually dropped the backlight after sunset ≥3× [live]
- **S:** *no new sentence* — A38 adds a second nested verb to the prototype's existing utterance ("The sun is set, do you want to turn on eye protection?"). Ruling and reasoning in §3.1.
- **V:** [and dim the screen]  *(steps the backlight to the user's own observed evening level; the prototype's [turn on] is unchanged)*

### time-of-day — 2

**A39 — the desk ready** (V39 U0197 T0204 S0434 H0818) · habit · time-of-day
- **T:** a recurring morning class SET plus a stable class→slot map, ≥3 mornings [live]
- **S:** "This is the set you open most mornings, do you want the desk ready?"
- **V:** [have the desk ready]

**A40 — close up** (V40 U0203 T0210 S0451 H0853) · habit · time-of-day
- **T:** the first closes of the work-class set inside a recurring end-of-session window, ≥3 days [live] — the trigger is the user ALREADY leaving, never the hour
- **S:** "You have started closing up, do you want the rest of it closed?"
- **V:** [close up]

---

## 2. The utterance-economy audit (F6 job a)

### 2.1 The shape of the set

| | count | what it costs the day |
|---|---|---|
| **habit unlocks** — speak once on reaching evidence, then silent forever whether accepted or refused | 25 | a handful of sentences spread over the first weeks of ownership, then nothing |
| **moment actions** — speak whenever the world does the thing | 14 | the entire recurring budget |

The 39 are therefore not 39 daily utterances. In steady state — every rule signed
or refused, every unlock spent — the recurring speakers are: A01 (a tab playing
out of sight), A03 (screen share), A04 and A05 (the call pair, and A04 goes silent
the moment its standing form is accepted), A09 (game launch), A12 (a download
meeting a picker), A16 (≈weekly), A19 (a screenshot, gated), A20 (a photo in the
evening), A22 (a duplicate launch), A28 (until accepted), A32 (a watched title),
A35 (a vault left open), A36 (a vault paste).

### 2.2 The steady-state day — honest estimate

A typical practitioner day, everything already decided: sunset (1), one or two
calls × A05 (1–2), one vault paste (1), zero to two of {A01, A12, A20, A22}. **≈3–5
sentences.** Against the sunset benchmark of one a day that is already three to
five times the budget benchmark, but each is anchored to a real event the user
would notice anyway, and the set spans the whole day rather than clustering. This
is defensible.

### 2.3 The onboarding week — where it breaks

The same day in week one, when every habit counter is crossing its threshold at
once: A39 at the morning desk, A34 at the lock screen, A13 and A14 from the shell
bridge, A28 and A04 and A03 at the 10:00 call, A05 after it, A27 when the
headphones arrive at lunch, A30 mid-afternoon, A25 when the battery drops, the
sunset pill, A40 at quitting time. **Eleven to thirteen sentences.** Every one of
them is individually lawful, individually observed, individually thankable — and
collectively it is exactly the failure mode Constitution VII names: *"too many
things earned the right to speak, so the average utterance became worthless."*

The funnel cannot fix this, because the funnel judges candidates one at a time.
The fix is structural and belongs in P5's blocks and in implementation.md.

### 2.4 Two laws proposed by this audit, binding on P5

1. **THE DAY'S BUDGET.** All actions draw from one shared allowance — **at most 3
   action sentences per day, and never two inside the same hour.** Detectors that
   reach threshold while the budget is spent do not speak; they wait. Evidence
   keeps accumulating (it is already an aggregate, so waiting costs nothing), and
   the strongest-evidence candidate speaks first tomorrow. A habit unlock that
   waited three days is not degraded — the habit is still there. This makes the
   utterance economy a property of the SYSTEM rather than a hope about the set.
2. **ONE MOUTH PER CLUSTER.** Where several actions fire on the same real-world
   moment, exactly one may speak and the rest wait for the next occurrence of that
   moment. The five clusters in this batch, with their priority orders:
   - **call start** — A28 (a defect being repaired) > A04 (quiet the desk) > A03
     (the audience). Three sentences currently fire within about three seconds of
     the microphone going live; this is the sharpest collision in the batch.
   - **evening** — the sunset prototype + A38 > A11 > A20 > A40. One mouth per
     evening, and since A38 rides the prototype's own pill (§3.1), the evening
     costs one sentence.
   - **morning** — A39 > A34 > A13/A14 (the shell bridge fires while the user is
     warming up).
   - **device arrival** — A29 (the desk) > A27 (the headphones) > A28. A plug-in
     is one event, not three.
   - **the silence family** — A04, A06, A09, A17 all offer to quiet something.
     Different triggers, different scopes, not duplicates (§5), but no more than
     **one silencing offer per week** or Golem reads as a system that mostly wants
     you to stop being interrupted.

### 2.5 Two gates applied in the register above

- **A19** was the highest-frequency speaker in the draft: users take screenshots
  many times a day and the pill would have appeared at every one. It is now
  evidence-gated (the user must have annotated or OCR'd by hand ≥3× first) and
  capped at once per session. This also repairs a doctrine-1 wobble — a screenshot
  the user took one second ago is an object their hands are still on, which is
  OPTIONS territory; the gate makes the utterance about the DEMONSTRATED follow-up
  rather than about the file.
- **A12** is gated the same way (≥3 observed picker-to-Downloads navigations),
  turning a moment that could fire several times a day into one that fires for
  users who have proved the annoyance is theirs.

---

## 3. The three near-neighbour rulings (F6 job b)

### 3.1 A38 versus the live sunset prototype — RESOLVED: one mouth, two verbs

Same evening, same complaint (the screen is hurting), two knobs — colour
temperature (the shipped prototype) and backlight level (V38). Two sentences
minutes apart about the same discomfort is precisely what §2 forbids, and folding
V38 into the prototype's gear box would bury the bigger eye-strain lever in a
settings panel the user opens once.

**Ruling:** V38 ships as a **second nested verb on the prototype's existing
utterance**, gated on its own evidence (the user has manually dimmed after sunset
≥3×). The prototype's sentence is unchanged; its pill grows from one amber verb to
two — [turn on] and [and dim the screen]. Constitution I permits one, rarely two
nested pills, and this is the case the "rarely" was written for: one moment, one
sentence, two hands for the same discomfort. **The evening cluster therefore costs
exactly one sentence, and the second knob costs zero.**

This also makes A38 the batch's proof that an ACTION can be delivered as growth on
an action that already exists — a shape P5 and implementation.md should both name,
because it is how the next 200 actions avoid becoming 200 more mouths.

### 3.2 A04 / A05 — RESOLVED: two actions, one conversation

They cannot merge: one verb = one action (the consolidation doctrine), and
[quiet my desk] and [show me] are different verbs at different moments with
different refusals. But they are not independent either — A05 exists only because
A04 silenced something (the hand-back rule, F5 doctrine 4).

**Ruling: two actions, bound by three constraints carried into P5.** (i) A05 may
never fire unless Golem itself held the queue — if A04 was refused, or its standing
form is off, A05 has nothing to hand back and stays silent; the existing
`notifications.active_count>0` guard is necessary but not sufficient, the
provenance is. (ii) In the assisted phase the pair costs two sentences per call,
which is over budget on a three-call day — so A04 and A05 are one cluster member
for §2.4 purposes until A04's standing form is signed. (iii) Once it is signed, A04
stops speaking permanently and A05 becomes the only utterance in a call: one
sentence, at the end, about what the user missed. **The pair is designed to
converge on a single sentence per call, and that convergence is the point.**

### 3.3 A13 / A14 — RESOLVED: two actions, not one "standing shell rule"

A single "want a shell rule?" action would be a designer's abstraction wearing a
trigger's clothes — nobody experiences "a shell rule moment". The moments are
genuinely different (the N+1th typing of one long command; a reflex pair counted
twenty times), the sentences share no material, and the verbs write different
kinds of line.

**Ruling: two actions.** With one shared constraint for P5: both write to the same
shell-owned file, both are one-click revocable from the notebook, and they share a
cluster slot (§2.4) so the shell never makes two offers in a week. A13 stays the
purest habit action in the funnel; A14's ruling is in §4.2.

---

## 4. The three flagged singles (F6 job c)

### 4.1 V08, the focus playlist — KILLED

F5 flagged the verb honestly: MPRIS can press play, it cannot queue a named
playlist. Two attempts at a sentence, both fail:

- *"You put the same thing on most mornings, do you want it playing?"* — names a
  thing Golem cannot guarantee to deliver. If the player is closed, the verb
  launches it and the player resumes whatever it last had, which may not be the
  observed title. **A sentence that promises what the verb cannot honour is not a
  register problem, it is a lie.**
- *"Your player is where you left it, want it going?"* — honest, and a toll: the
  play button is on screen and the user's hand is already there (F5 doctrine 2,
  the one-keystroke test).

And the residue is already shipped elsewhere: **A39 absorbs U0036 (music as the
first act of the morning)**, so the workday-morning launch is inside "[have the
desk ready]" already. Killing V08 loses nothing but a sentence that could not keep
its word. Media ships 4.

### 4.2 V14, `ls` after `cd` — charm or value? — KEPT, as value

The per-instance win is ~300 ms; the standing rule abolishes the reflex
permanently. Twenty observed pairs across a few days extrapolates to hundreds a
month, which is the best keystroke-per-utterance ratio in the batch, and the offer
costs exactly one sentence in a lifetime. That is doctrine 2's stated exception,
not an evasion of it.

The real objection is not charm, it is the U0105 trap (the pre-push hook that
stands in the doorway on the day you need to push red). **Ruling: kept, with the
trap tested and found absent** — an automatic `ls` never blocks anything; its worst
case is a flooded terminal in a huge directory, which is an annoyance, is visible
the instant it happens, and is undone by removing one line. P5's block owes: a
listing cap in the gear, and the revocation surfaced in the moment it bites, not
only in the notebook. *Standing rules must be revocable where they hurt.*

### 4.3 V37, the only [new] verb — KEPT, with the verb re-specified

The constitution's own illustration deserves better than a hand-wave. The original
verb ("local cleanup of the profile at browser exit") means Golem writing into
another application's private data store — corruption risk, sync side-effects,
profile locks, and a maintenance burden that renews with every browser release.

**Ruling: keep the action, change the hand.** Golem does not clear anything; it
turns on **the browser's own clear-on-shutdown preference**, written while the
browser is closed (Firefox's sanitize-on-shutdown family, scoped to history only;
Chromium's equivalent is narrower and per-profile). The action then requires
nothing new in the engine, only a supported setting in a config file the browser
already owns, and the browser does the deleting it has always known how to do.
Three conditions carried to P5, which must not be softened: (i) the exact
preference keys are verified per browser and per version, and where no documented
scoped key exists **the action does not exist for that browser**; (ii) the sentence
and the gear must name exactly what will be cleared, because "clear on shutdown"
in some browsers takes cookies and sessions with it and a user logged out of
everything tomorrow morning was not offered that; (iii) the verb writes only while
the browser is not running. Tag stays **[new]** — unshipped, but now small,
bounded and honest rather than speculative.

---

## 5. Near-duplicate sweep inside the at-ceiling categories (F6 job d)

**communication (5)** — A02 snippet / A03 share / A04 call quiet / A05 hand-back /
A06 app mute. No pair shares a trigger or a verb. A04 and A06 both silence, at
different scopes (this call vs this app forever) from different evidence (the mic
vs the user's own dismissals). **No duplicates; both join the silence family cap
(§2.4).**

**media (4)** — A07 pause-on-idle / A09 game mode / A10 pin the player / A11 the
night cap. A07 and A10 both act on a player but in opposite directions (stop it
when you leave; keep it visible while you work). A09 is the only one whose verb is
about the machine rather than the media. **No duplicates.**

**system (5)** — A16 update / A17 quiet hour / A18 layout / A19 screenshot / A20
true colours. A17 joins the silence family. A20 is a member of the colour-temperature
family (prototype, A38, A20) but is its INVERSE — it turns the help off for a
minute because the help arrived at the wrong moment — so it is a near-neighbour by
topic and an opposite by verb. **No duplicates; A20 flagged for slop hunt #1 on a
different question: is a colour-accurate minute a daily need, or a photographer's
need?**

**security (5)** — A33 lock timing / A34 fingerprint / A35 vault lock / A36 vault
clipboard / A37 history. A33 and A35 are the closest pair in the batch: both lock
something when the user walks away. They survive as distinct because the objects
differ (the session vs one application), the evidence differs (manual lock events
vs a vault idle for hours), and a user who accepts both gets a coherent posture
rather than the same offer twice. A35 and A36 share the vault but not the moment
(sitting open all afternoon vs a paste two seconds ago). **No duplicates.**

Cross-category near-neighbours worth recording for the hunts: **A27/A28/A29** all
fire on a device arriving (clustered in §2.4, not duplicated — the verbs are route
the sound, hold the codec, restore the desk); **A30/A31** both rearrange windows
from observed corrections, but one reads an alternation and tiles a pair while the
other reads an opening and writes a rule.

---

## 6. The bench after F6 — attacked, and empty

Conditions §3 says replacements come from the bench and face the same attack. V08's
slot was offered to R01–R12 in order; every one of them fails a law, which is why
they were on the bench rather than in the 40:

- **R01** (hold chat to set times) — imagined helpfulness (Constitution III): the
  user never declared the rhythm. Also a near-duplicate of A17, which is the
  version they actually demonstrated. **Fails admission.**
- **R02** (dark theme at sunset) — not daily, and a third mouth in the evening
  cluster. **Fails EVERYDAY + §2.4.**
- **R03** (the overnight notifications) — the hand-back rule: Golem did not silence
  the night, so it owes no summary of it. **Fails doctrine 4.**
- **R04** (the charger that only bites at one angle) — still no verb. **Fails
  doctrine 3.** The finest observation in the batch and still not an action.
- **R05** (the battery-draining app) — `[quit it]` destroys unsaved work,
  `[show me]` is a notification. **Fails doctrine 3.**
- **R06** (the same USB stick) — weekly at best; batch 3 material. **Fails EVERYDAY.**
- **R07** (VPN before internal apps) — "internal" cannot be known without guessing.
  **Fails admission.**
- **R08** (bigger text in the evening) — fourth sunset sibling. **Fails §2.4.**
- **R09** (undocking without ejecting) — prevents real data loss, genuinely good,
  and not daily. **Fails EVERYDAY.** The strongest candidate for a weekly tier.
- **R10** (this morning's hidden windows) — "you forgot something" is a nag and the
  verb is ambiguous. **Fails voice + doctrine 3.**
- **R11** (the launcher the game dragged along) — not daily, small. **Fails EVERYDAY.**
- **R12** (the mic reverting to the webcam) — absorbed into A27; splitting it out
  would be un-consolidating one verb into two actions. **Fails the consolidation
  doctrine.**

**The bench is therefore empty for practical purposes, and P4/P8 must be told so
plainly: every kill from here on reduces the shipping count.** If the hunts kill
three, batch 1 ships 36. Constitution VII: say it, do not pad it.

---

## 7. What slop hunt #1 (P4) must attack first

Ranked by this unit's suspicion, not by V-id order:

1. **A19** — even gated, is a screenshot an ACTION or an OPTION? The hands are on
   the object. The gate may not be enough.
2. **A20** — daily for a photographer, rare for everyone else. The EVERYDAY law is
   about the practitioner (F2's strictness), but this is the thinnest practitioner
   in the batch after A18.
3. **A22** — "\<app\> is already open over here" may be faster for the user to
   discover by simply looking at the window that just appeared. Test the
   one-keystroke rule against it.
4. **A23** — the only verb in the batch that is purely a future sentence. It
   promises a notification, which is the world's voice, not Golem's.
5. **A16** — nag risk, explicitly flagged at F5. Check the escalation-toward-silence
   requirement is expressible in the gear.
6. **A18** — the batch's narrowest audience (bilingual users only).
7. **A26** — is the wrist-jiggle detector reading intent from pointer noise? Verify
   the trigger cannot fire on ordinary cursor motion near the timeout.
8. **Every sentence** re-read against Constitution II with one question: does any of
   them tell the user something about themselves they did not ask to hear? A06 and
   A34 are the two closest to that line (five dismissals, a reader that misses half
   the time) — both are facts about a THING, which is why they survive the draft.

---

*Counts: 39 action entries (A01–A40, no A08). Category distribution after the V08
kill — communication 5, system 5, security 5, media 4, power 4, audio/devices 3,
window/workspace 3, coding 2, search/launch 2, time-of-day 2, browsing 1, files 1,
writing 1, health 1. Sum: 39. The ~5 ceiling holds with four categories at it and
none over.*
