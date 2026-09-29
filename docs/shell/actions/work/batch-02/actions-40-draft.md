# actions-40-draft.md — batch 02, F6

*The draft register: name + one-line trigger + the ONE sentence + the verb pill
label(s). No full blocks — those are P6. Per cut-50.md §"Going into F6", this
unit is not a cut: F6's job here is (interpreting conditions.md §1 F6 and the
F5 directive) the utterance-economy audit (§2), the near-neighbour rulings on
the pairs the F5 file named (§3), the three charged verdicts re-verified rather
than re-lodged (§4), the near-duplicate sweep (§5), and the bench attack (§6).*

**Result: 15 actions drafted, not 14.** Every V-survivor survived the pen —
none was dropped, and each near-drop candidate (A07, A12, A13) is argued
explicitly rather than silently kept. This is not a suspicious zero: F5 already
did this batch's killing (21→15 in one pass, the reverse of batch-01, whose F5
left F6 nothing to cut either), and F6's job was the audit and the pairs, which
is where the real output below is. The batch-02 number is its own and may fall
at P5's slop hunt — nothing here pretends a ceiling was reached.

**F6's own finding (mirroring batch-01's, but milder):** the fifteen are
individually rare, and *together* they are close to rare — the count is 15 (not
39), and seven of them are habit unlocks that speak once and then fall silent.
But the moment actions still cluster at the same two seams of the day (the call,
the download), and the first-week overload is real for a user who hits every
counter at once. The same two structural laws that batch-01's F6 proposed —
and that P5/P8 then ratified for that batch — must bind batch-02's blocks too,
plus batch-02's own cluster map (§2.4) and gates (§2.5).

---

## 1. The register — 15 actions

Lineage carried in parens: `(V-id U-id T-id S-id H-id)`. Type per Constitution
III (moment = the world did something; habit = the user demonstrated, ≥3×).
Feasibility tags per OPTIONS/catalog.md §0 legend. **A-ids are batch-02-local**
(no relation to batch-01's A01–A40 in actions-40.md; the two registers share ids
by convenience across separate files). Sentences are the draft register only —
P6 writes the full blocks, carrying each V-id's `- P:` at-rest shape from
cut-50.md as contract, not garnish.

### communication — 1

**A01 — the unheard hello** (V01 U0001 T0001 S0039 H1328) · moment · communication
- **T:** a call-class app's stream goes live while that source sits muted (audio [live])
- **S:** "Your call just connected and your mic is still muted, do you want it opened?"
- **V:** [open the mic]
- *Register note: the anti-toll (cut-50 casualty V01) — the user CANNOT know they
  are muted from the call's noise; their reflex does not exist, so the offer is the
  only channel. No at-rest shape; live states only.*

### files — 1

**A02 — the download's home** (V02 U0003 T0003 S0057 H1016) · habit · files
- **T:** a finished download whose kind lands in a recurring destination ≥3× (downloads [live]; the move read as a class event on the shell bridge [live])
- **S:** "You always put these in <their folder>, do you want it moved there?"
- **V:** [move it there]
- **P:** the download's kind (mime class) and the destination-dir are BOTH hashed at rest — a class→dir pair-counter; the destination is quoted LIVE at the N+1th move and persisted only on acceptance as user-authored config (name-at-offer-time, F4 doctrine 1).

### coding/work tools — 2

**A03 — the silent build** (V03 U0005 T0005 S0067 H1021) · moment · coding/work tools
- **T:** a build command (shell bridge [live]) still running ~10 min with no new output (CPU-silence proxy [cheap])
- **S:** "Your build has been quiet for ten minutes, do you want it stopped?"
- **V:** [stop it]
- **P:** silence is judged on CPU activity only; the build's stdout is never read (F4 doctrine 4, held stricter than the classifier needs).

**A04 — the landed branch** (V04 U0006 T0006 S0069 H1098) · moment · coding/work tools
- **T:** a merge lands in the current repo (git events [live])
- **S:** "That branch made it into the tree, do you want the local one closed?"
- **V:** [close the branch]
- *Register note: the safest destructive verb in the batch — `git branch -d`
  refuses an unmerged branch, so this action CANNOT lose work. Repo-public state,
  no P.*

### system/settings — 3

**A05 — the corner you catch** (V05 U0009 T0009 S0096 H1600) · habit · system/settings
- **T:** the cursor lands on one hot-corner ≥3× with no intent-moment before it (pointer position via the hyprland event [cheap]; never polled otherwise)
- **S:** "You keep catching this corner, do you want it disarmed?"
- **V:** [disarm it]
- **P:** a per-corner activation counter at rest, nothing more — never a trajectory, never a timing log (A26 discipline).

**A06 — the app this kind wants** (V06 U0010 T0010 S0097 H1604) · habit · system/settings
- **T:** the same mime type lands in one app and is re-opened in another within seconds, ≥3× (window [live] + the open event; mime resolution [cheap])
- **S:** "You keep opening this kind of thing in <app>, do you want that to be the default?"
- **V:** [make <app> the default]
- **P:** a mime-class → app-class pair-counter at rest; the file path classified to mime transiently and discarded; the preferred app read live at the trigger (F4 doctrine 1).

**A07 — the tucking dock** (V07 U0011 T0011 S0098 H1848) · moment · system/settings
- **T:** fullscreen playback starts while the dock is visible (fullscreen via window [live] + media [live])
- **S:** "Your video went fullscreen and my dock is still in front of it, do you want it tucked away?"
- **V:** [tuck it away]
- *Register note: this is the batch's smallest value, and the verdict (cut-50
  flag, re-verified in §4.1) is that it survives on charm carried by a REAL
  first-party verb — the dock is Golem's own component (the launch rail backed by
  the usage-sorted entry list every A-block names), so tucking it is writing the
  dock's own opacity without stepping on a boundary. The hunts hold it as first
  to die if the tight rhythm is missing. No P (own component, live events).*

### search/launch — 2

**A08 — the project's companion** (V08 U0012 T0012 S0099 H1049) · habit · search/launch
- **T:** the same cwd→launch association recurs across days (shell bridge cwd [live] + window [live]; the association memory is the [cheap] part)
- **S:** "You open <app> every time you come to this project, do you want it ready when you do?"
- **V:** [always have it ready]
- **P:** project = cwd HASH at rest with an app-class pair-counter — never the raw path, never a per-session work log; cwd quoted live at the trigger. The standing-rule GIFT form only; a per-instance "want me to?" is the toll cut-50 forbids (the F5 flag verdict, re-verified §4.2).

**A09 — the app in the dead command** (V09 U0013 T0013 S0101 H1148) · moment · search/launch
- **T:** shell exit 127 with a command that matches an installed desktop file (shell bridge [live] + app table)
- **S:** "That command isn't a command, but <app> is — do you want me to open it?"
- **V:** [open <app>]
- **P:** the typed command is matched against the app table transiently and never stored (F4 doctrine 4). Boundary vs the shipped search-the-error OPTION resolved in §3.2.

### power/battery — 2

**A10 — the lunch lull** (V10 U0015 T0015 S0104 H1029) · habit · power/battery
- **T:** idle at a recurring midday window (logind IdleHint on the small idle collector [cheap] + clock [live])
- **S:** "It's the hour you usually step away, and the desk has been quiet — do you want a nap until you're back?"
- **V:** [hibernate]
- **P:** ONE median midday-idle hour at rest — the sanctioned aggregate (batch-01 U0200's exact shape); never a stopwatch over leisure (F4 doctrine 2). The resurrection-with-a-verb of the family batch-01 killed at F5 (those sentences had no hand; this one hibernates).

**A11 — the parked machine** (V11 U0016 T0016 S0109 H1199) · moment · power/battery
- **T:** low battery while qemu/kvm processes run (metrics [live] + process-CLASS presence [cheap])
- **S:** "Your battery is getting low and the machines are awake, do you want them parked?"
- **V:** [park them]
- *Register note: process class + battery percentage, both live aggregates — no P
  beyond that. A virsh save is minutes of deliberate work, so the offer is the
  right hand for it; refusal is cheap and the damage (a battery death taking a
  running VM) is expensive.*

### audio/devices — 1

**A12 — the level that worked** (V12 U0017 T0017 S0117 H1033) · moment · audio/devices
- **T:** a meeting-class app focused, capture not yet live (window [live] + audio [live])
- **S:** "Your meeting is about to start, do you want your mic set to the level that worked?"
- **V:** [set my level]
- **P:** only the accepted source level stored, as user-authored config; verb REFORMULATED from "calibrate" — a true RTA needs your voice at offer time and claiming it would be a lie (the honest-verb discipline, F4). The pre-capture moment is live state.

### security/privacy rituals — 2

**A13 — the picture that knows too much** (V13 U0019 T0019 S0134 H1683) · moment · security/privacy rituals
- **T:** a fresh image right before a share-class app takes focus (image watcher [cheap] + window [live])
- **S:** "That picture is about to leave and it still carries its metadata, do you want it wiped?"
- **V:** [wipe its metadata]
- **P:** EXIF-presence is a transient header class (F4 doctrine 4); pixels never touched; nothing at rest beyond the watcher's file events — privacy-POSITIVE, it REMOVES data from the user's outgoing files.

**A14 — the clean sleep** (V14 U0020 T0020 S0136 H1931) · moment · security/privacy rituals
- **T:** the session enters Sleep (logind sleep [cheap]) while the agent process is resident (process presence [live])
- **S:** "I'm about to sleep and I still hold your clipboard history, do you want it cleared?"
- **V:** [clear my clipboard history]
- **P:** fires on ANY suspend (not a bedtime monitor, F4 doctrine 2); the verb names exactly what is cleared — Golem's own clipboard-history store at $XDG_DATA_HOME, never the user's files or browser (bounded-storage discipline). **Speaks only when the flush actually found data — an empty store is silence, not liturgy** (§2.5).

### health/ergonomics — 1

**A15 — the steady hand** (V15 U0021 T0021 S0137 H1203) · moment · health/ergonomics
- **T:** focus lands on a precision-class window and stays (window [live]; the class table the [cheap] derivation)
- **S:** "You're in the pixel editor, do you want the pointer eased for it?"
- **V:** [ease the pointer]
- **P:** the task class is a window-class derivation — class only (F4 doctrine 4), the same derivation as the meeting/game/editor classes; the pointer write is Golem's own input setting. The precision-class table is named, not waved at (§4.3).

---

## 2. The utterance-economy audit (F6 job a)

### 2.1 What the register is made of

Seven habit unlocks that speak once and then fall silent (A02, A05, A06, A08,
A10; with A12/A15 arming into a standing preference after first acceptance). The
remaining eight are moment actions that speak whenever the world does the thing
(A01, A03, A04, A07, A09, A11, A13, A14). That split — roughly half once-for-life,
half event-anchored — is the healthiest of either batch, because the once-for-life
half cannot stack by construction.

### 2.2 The steady-state day — honest estimate

A typical practitioner day, everything already decided: one call (A01 or A12, not
both — §3.1), a merge or a silent build or a 127 (at most one of A03/A04/A09),
lunch (A10), one shared picture (A13), sleep (A14). **≈3–5 sentences.** The sunset
benchmark is one a day; batch-01's honest steady state was 3–5 as well, and this
one is the same — anchored, spanned, defensible.

### 2.3 The first week — where it can still break

Week one, every habit counter crossing at once: A02 (a download), A05 (a corner),
A06 (an open-with), A08 (the project), A10 (lunch), A03/A04/A09 from the shell and
git bridges, A01/A12 at the first call, A13 at a share, A15 at the first pixel
task. **Nine to eleven sentences on the densest day.** Every one individually
lawful and thankable — and collectively it is Constitution VII's named failure
mode. Batch-01's F6 found the same and fixed it structurally; batch-02 inherits
that fix (§2.4) and adds batch-02's own gates (§2.5).

### 2.4 Two laws (inherited from batch-01's F6, ratified by its P5/P8, binding here) + the batch-02 cluster map

1. **THE DAY'S BUDGET.** All actions draw from one shared allowance — at most 3
   action sentences per day, never two inside the same hour. Detectors that reach
   threshold while the budget is spent wait (their evidence is already an
   aggregate, so waiting costs nothing) and the strongest-evidence candidate
   speaks first tomorrow. A habit unlock that waited three days is not degraded.
2. **ONE MOUTH PER CLUSTER.** Where several actions fire on the same real-world
   moment, exactly one may speak; the rest wait for the next occurrence. The
   batch-02 clusters and their priority:
   - **call start** — A01 (the unheard hello) and A12 (the level that worked)
     never co-fire; they are different sub-moments of the same cluster and their
     split is A12 in the pre-capture window, A01 at stream-live-while-muted
     (§3.1). One mouth, one call.
   - **the download** — A02 (move) vies with the SHIPPED download-finished OPTION
     (open/unpack) and with A06 (open-with). A02 fires only on the N+1th
     occurrence of a recurring destination; by then the OPTION pill has appeared
     dozens of times without the move being the right hand. Priority: A02's move
     outranks the pill the moment the destination recurs; A06 is a different
     trigger (a re-open, not a completion) and never shares the breath (§3.3).
   - **the launch seam** — A08 (project companion) and A09 (dead command) both
     launch an app; A09 fires on a 127 (a dead end), A08 on a cwd-recurrence (a
     routine opening). Different triggers, different registers; if they coincide,
     one mouth — A09 is the rarer and more urgent, A08 waits (its gift is not
     time-sensitive).
   - **the hour boundary** — A10 (lunch lull) is the only action keyed to the
     clock; it may not speak within an hour of any other action (its offer is a
     standing-rule hand, not an event, so waiting costs it nothing).

### 2.5 Gates applied in the register above

- **A14** — the clear-at-sleep sentence fires ONLY when the flush found data; an
  empty clipboard-history store is silence. Otherwise this disclosure-only ritual
  would speak every single suspend and become liturgy (cut-50's flag, made
  mechanical here). At-rest/fires evidence: a non-empty count before the flush.
- **A13** — gated by the "fresh image THEN share-class focus" sequence (the share
  moment is the user reaching for the network), capped at once per session, so a
  mass-share afternoon costs one sentence, not ten.
- **A07** — capped at once per session per fullscreen (tucked stays tucked;
  re-tucking when nothing changed is the toll).
- **A15** — arms the standing preference on first acceptance; per-instance repeat
  offers stop the moment the user signs the standing form (Constitution IV ladder).

---

## 3. The near-neighbour rulings (F6 job b — the pairs the F5 file named)

### 3.1 A01 / A12 — one call, two hands, two windows — RESOLVED by sub-moment

Both fire at the start of a call, and cut-50's directive said they "must never
stack." They cannot be merged (one verb = one action: [open the mic] vs [set my
level] are different verbs at different moments).

**Ruling: two actions, split by the call's own sub-moments.** A12's trigger is
strictly PRE-capture (meeting class focused, capture not yet live) — the offer to
set the remembered level exists only in the window of seconds before the mic
goes live; the instant capture starts, A12's condition is false. A01's trigger is
stream-live-WHILE-MUTED — which is at-or-after capture start. The two windows do
not overlap: A12 may speak only before the call is audible, A01 only after. One
mouth per call by construction — the cluster rule (§2.4) exists to stop any
off-by-one where a meeting-class focus triggers both within a minute (refusal
memory on each handles it).

### 3.2 A09 / the shipped search-the-error OPTION — RESOLVED: distinct trigger, distinct verb

Both read the same event (shell exit 127) — the sharpest boundary case in the
batch (doctrine 1, cut-50).

**Ruling: A09 is not a restatement.** search-the-error (catalog §4.11) offers to
web-search a FAILED command — any failed command; A09 offers to LAUNCH AN APP for
a command that matches an installed desktop file. They are different verbs
(launch vs. web-search) on different conditions (a desktop-file match exists vs.
any nonzero exit). By construction they CANNOT co-fire: A09's trigger is the
subset where the 127 resolves to an app; search-the-error's is the complement.
The shared law, written for P6: when a 127 matches an app, the ACTION (A09) is
the offer and the search OPTION stays a pill on the bar; when it does not, the
OPTION pill stands and A09 is silent. One is not a mouth and the other.

### 3.3 A02 / A06 / download-finished — RESOLVED: three verbs, one gate

The download seam has three sentence-owners across two surfaces (the shipped
download-finished OPTION: open/unpack; A02: move to the home; A06: open-with).

**Ruling: no pair is a duplicate, and the cluster rule decides who speaks.** A02's
verb is a MOVE and fires only when the kind recurs to a destination ≥3× (a
demonstrated routine); download-finished's verb is OPEN/UNPACK and fires on every
completion; A06's verb is SET-A-DEFAULT and fires on a RE-OPEN (a different
moment from completion entirely). Because A02 is gated (§2.4, §2.5), it goes
silent after acceptance and its N+1th-turn has already seen dozens of OPTION
pill-appearances go unused for the move — the archetypal "the user sold the idea
of unpack and never took it." Priority at the N+1th completion: A02's move offers;
the pill stays; A06 waits for its own trigger. Written down because the download
seam is where two surfaces both reach.

### 3.4 A10 / the batch-01 lunch-hour kill — RESOLVED: the resurrection is legitimate

Batch-01's F5 killed U0200 (the lunch hour) as "a fact with no hand attached."
cut-50.md resurrected the family with THIS sentence because it has one:
hibernate. The distinction is the verb, and it is real (systemctl hibernate,
offer-first). The P-shape is the sanctioned U0200 aggregate. **Ruling: kept, with
the cluster-boundary in §2.4** — it is the batch's only clock-keyed action and
must never speak within an hour of anything else.

---

## 4. The three charged verdicts — re-verified here, not re-lodged (F6 job c)

### 4.1 A07 (the tucking dock) — RE-VERIFIED: charm carried by a real first-party verb

The flag was "charm doing the value's work." Verification of the verb first: the
the dock — the launch dock the OPTIONS constitution names
as one of the three surfaces Golem is uniquely positioned to own ("the window,
the clock and the dock are the help"), backed by the usage-sorted entry list the
batch-01 A-blocks already write to. Tucking it = a one-line write to the dock's
own opacity, the same first-party surface A39/A21 already touch. That is a real
hand, currently unshipped only in the trivial sense that opacity-write is a P6
implementation detail. The sentence re-read in register: "Your video went
fullscreen and my dock is still in front of it" — the A20 species (Golem noticing
its own help arriving at the wrong moment). **Verdict stands: kept.** The value is
small and the hunts hold it as first to die.

### 4.2 A08 (the project companion) — RE-VERIFIED: gift in standing form only

The F5 flag's verdict was GIFT, standing form only. Re-check against the
threshold: a per-instance "want me to?" at every project open would be a toll on
a routine the user's own hands already own (they open the app themselves — a
launcher is one gesture) — the exact reason cut-50 forced the standing form. The
one-time offer "always have it ready" abolishes the launch-recognition forever
(doctrine 2's exception, V39/V40 precedent). **Verdict stands.** The only
softening P6 owes: the standing rule must be revocable where it bites (the gear
and the notebook), the U0105-trap test batch-01 ran on A14.

### 4.3 A15 (the steady hand) — RE-VERIFIED: the class table is named, not waved at

The flag was: "the precision-class table must be named, or the sentence is a
guess." Named: the precision-class complement is the image-editor set (gimp,
krita, inkscape, darktable), the CAD set (freecad, openscad, blender), and the
pixel-tool set (aseprite, pixelorama) — the same class-derivation discipline that
already supplies the meeting/game/editor classes elsewhere, and one a P6 block can
enumerate literally. **Verdict stands: kept.** The pointer write is Golem's own
input setting (the hyprland/wlroots sensitivity), and the trigger is window-class
focus, never pointer noise — so the A26 pointer-discipline worry does not apply.
Residual for the hunts: a user in gimp doing 1:1 pixel zoom-and-nudge is the
target; a user in gimp doing brush-painting at speed is not — the knob must be
the fine-moment, not the class (the class is the gate, the moment is the offer's
timing, and the standing form stays in the gear).

---

## 5. Near-duplicate sweep (F6 job d)

Fifteen, nine categories, none near five — the ceiling is far under. Within
categories: **coding (2)** A03 (stop a silent build) vs A04 (close a merged
branch) share only the git/shell seam, opposite verbs, opposite moments.
**system (3)** A05 (corner) / A06 (open-with) / A07 (dock) — no shared trigger.
**search/launch (2)** A08/A09 resolved in §3.2. **power (2)** A10 (idle-clock
hibernate) vs A11 (low-battery park) — different emergencies, different hands.
**security (2)** A13 (strip metadata on the way out) vs A14 (clear Golem's own
store at sleep) — different objects (the user's outgoing file vs Golem's store),
different moments, both privacy-POSITIVE. **No duplicates in the register.**

Cross-batch near-neighbours worth recording for the hunts: A06 (open-with
preference) sits near batch-01's A21 (wrong-first-hit launcher ranking) — both
learn an app preference from observed corrections, but A21 rewrites the launcher's
ranking from a close-without-use signal, A06 writes an open-with default from a
re-open signal: different seams, both on the launch rail. And A12 vs batch-01's
A28/V27 (the headphone output rule): A28 routes audio to a device, A12 sets the
mic's LEVEL — a level is not a route, but both live in the audio/seams cluster and
P6 must ensure they never speak in the same minute.

---

## 6. The bench — attacked, and empty

No F6 kill occurred, so no replacement is owed; but the standing rule from
cut-50.md is that a P5-hunt kill may only be replaced by overturning an F5 kill
IN WRITING. The six F5 kills re-attacked here in one line each and still stand:

- **U0004 run-the-test-file** — the reflex still beats the sentence; the standing
  form is still an un-authored hook (the U0105 trap). **Still dead.**
- **U0007 format-before-commit** — still the code-reviewer register (Constitution
  II) in per-instance form and a trap in standing form. **Still dead.**
- **U0018 speaker-boost-over-the-fan** — the sink-volume verb is still the shipped
  media-volume OPTION; the fan event still only justifies noticing a knob already
  on the bar. **Still dead.**
- **U0014 brightness-between-calls** — still the toll twin of batch-01's A38 (the
  user demonstrated the dim themselves; per-instance races their hand; standing is
  A38 in a suit). **Still dead.**
- **U0002 empty-the-screenshot-folder** — still a tidy-up the user did not request
  (they demonstrated NOT emptying). **Still dead.**
- **U0008 night-theme-at-dusk** — the sunset family (prototype + A20 + A38) is
  still full; a fourth mouth is Constitution IV stacking. **Still dead.**

**The bench is empty and P6 must be told so plainly: every P5 kill reduces the
shipping count, no padding.** If the hunt kills three, batch 2 ships 12, stated
in the register. Constitution VII.

---

## 7. What slop hunt #1 (P5) must attack first

Ranked by this unit's suspicion, not by V-id order:

1. **A12** — the held but least-sensed verb: the "remembered level" is ONE accepted
   source level stored as config. Does the sentence survive a user who never
   accepted it, and does the gear make the stored level visible and erasable
   (Constitution V)? Verify the pre-capture window is actually sensable without
   a timer.
2. **A07** — the charm walk: is a two-second annoyance worth a sentence at all,
   even with a real verb? This is the batch's tightest "would you thank" call.
3. **A14** — the disclosure-only ritual: verify the speaks-only-when-data gate is
   mechanically expressible, else the sentence becomes liturgy on every suspend.
4. **A10** — clock-keyed by construction: is an idling desk at lunch the user's
   demonstrated rhythm or a guess at the hour? The U0200-shaped aggregate holds,
   but the sentence must never read like a clock telling the user to go eat.
5. **A09** — the 127+desktop-file-match is the cleanest trigger in the batch; the
   hunt should try to break the match table (a name that collides with a binary).
6. **A03** — the CPU-silence proxy: verify a legitimate long link/network-wait
   build cannot trip it (the offer is cheap and refusable, but a false "stop it?"
   during an actual build is the one sentence that would embarrass the batch).
7. **A05** — the corner: "no intent-moment" is the whole trigger; verify the
   detector cannot fire on an ordinary pointer sweep that merely PASSES the corner.
8. **Every sentence** re-read against Constitution II with the batch's own
   question: does any of them tell the user something about themselves they did
   not ask to hear? A05, A08, A02 are the three expressing observed patterns —
   all are facts about a THING or a routine, which is why they survive the draft.

---

*Counts: 15 action entries (A01–A15). Category distribution: communication 1,
files 1, coding/work tools 2, system/settings 3, search/launch 2, power/battery
2, audio/devices 1, security/privacy rituals 2, health/ergonomics 1. Sum: 15.*
*The ~5-per-category ceiling holds with room; the shipped-budget and
one-mouth-per-cluster laws from §2.4 bind P6's blocks; A-ids are batch-02-local.*

(End of file)