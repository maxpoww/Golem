# actions-40.md — batch 02, the shipping register

*The full action blocks. Schema: conditions.md §2 (nine fields, in order). Source:
`actions-40-draft.md` §1 for the sentence and the verb, `slop-hunt.md` for every
repair, `cut-50.md` for each V-id's at-rest shape carried as contract. The twelve
blocks below are the P6 output of slop hunt #1.*

**The register is 12, not 15.** F6 drafted fifteen; hunt #1 killed three —
**A05, A07, A11** — and no killed row was replaced (the six F5-kill bench was
re-read and none overturned, so the bench rule allows no replacement). Those
ids, together with nothing else, are retired: they are gaps, never reused,
never renumbered, so the lineage stays stable across the file. The count is
stated plainly at the top of the hunt file and again here: **batch 2 ships 12
sentences.** Constitution VII.

## The two system laws every `Fires` line below is written against

Ratified in `slop-hunt.md` §3, inherited from batch-01, binding here — and the
reason a block may not simply assert its own frequency:

1. **THE DAY'S BUDGET — a priority queue, not a gate.** ≤3 action sentences a
   day, never two in an hour, one shared allowance. **Expiring moments** (their
   value dies with the moment) always speak and spend the allowance; **habit
   unlocks** wait, indefinitely and harmlessly, strongest evidence first, and
   never two in the same hour. Unspent allowance does not carry over; a day
   blown through by expiring moments alone tightens tomorrow to one.
2. **ONE MOUTH PER CLUSTER, with back-of-the-queue on refusal.** Where several
   actions fire on the same real-world moment, one speaks and the rest wait for
   the next occurrence; an answered member (yes or no) steps to the back.
   Batch-02's clusters, from draft §2.4:
   - **call start** — A12 (pre-capture) and A01 (stream-live-while-muted) are
     disjoint sub-moments of one call; one mouth per call, by construction
     (§3.1 in the draft).
   - **the download seam** — A02's move outranks the shipped download-finished
     OPTION the moment the destination recurs (its N+1th turn); A06 is a
     different trigger (a re-open, not a completion) and never shares the breath.
   - **the launch seam** — A09 (a 127 dead end) is the rarer and more urgent;
     if A08 coincides, A09 speaks and A08 waits (its gift is not time-sensitive).
   - **the hour boundary** — A10 is keyed to the clock and may not speak within
     an hour of any other action.

## The three classes of repair carried into the blocks

- **A01's trigger is re-anchored** to the mic **source's** mute, read out of
  the same `pw-dump` the audio collector already parses (`mic_active_from_dump`,
  `audio.rs:245`), never to `AudioState.is_muted` — that is the default
  **sink's** mute (`read_sink_volume`, `audio.rs:89/93`). Discharged inside the
  block.
- **A03's proxy is the three-part one** — build process still alive + ~10 min
  with no new terminal output + sustained ~zero CPU — written with all three, in
  the trigger field where it belongs.
- **A09, A10, A12, A13, A14, A15** carry the hunt's repairs verbatim in their
  own blocks (Exec basename matching; dormancy on the absent idle manager; the
  state-conjunction offer; the [new] verb with its actuator named; the
  mechanical store-count gate; the named precision-class table).

## Cross-batch no-repeat verification (conditions.md §4)

Re-read `work/batch-01/actions-40.md` in full (34 blocks) and checked each of
the twelve below in substance — trigger + verb, rewording is repetition:

- **A01** vs batch-01's A04/A28 (mic-live → quiet desk; BT-call → keep the good
  sound): every prior mic action watches a **live** mic; none reads a **muted
  source at deal with a stream**. Trigger and verb are new. ✓
- **A02** vs the shipped download-finished OPTION (a catalog pill: open/unpack,
  every completion): A02's verb is a **move** gated on a **recurring
  destination ≥3×** — a different trigger, a different verb, per draft §3.3. ✓
- **A03** vs batch-01's A32 (watch a changing title → tell me when it changes):
  different verb (stop the build vs. notify on a title) on a different trigger
  (a silently-running build vs. return-to-window focus); shares only the
  shell seam. ✓
- **A04** (merge lands → `git branch -d`): batch-01 has no git merge/close
  action; its shell-pair actions (A13 alias, A14 cd→ls) are different verbs.
  ✓
- **A06** vs batch-01's A21 (wrong first hit → demote in the launcher ranking):
  draft §5's near-neighbour, resolved in substance — A21 learns a launcher-rank
  penalty from a close-without-use signal, A06 writes an open-with **default
  association** from a re-open signal. Different seams, different verbs. ✓
- **A08** vs batch-01's A39 (desk ready — the morning class **set**): both
  launch remembered app(s), and this was the tightest match in the sweep — the
  substance splits on the **trigger**: A39's is the clock and the morning set
  (an hour histogram), A08's is the **project directory** (a cwd recurrence).
  A location-keyed launch and a time-keyed launch are not rewording of one
  action; A39 also *places* windows to workspaces, A08 only *has the app ready*.
  Recorded here so the near-neighbour is on the page rather than a silence. ✓
- **A09** vs the shipped search-the-error OPTION (catalog §4.11): draft §3.2's
  ruling, discharged here — A09's verb is **launch the matching app** and its
  trigger is the subset of 127 that resolves to a desktop entry; the pill's verb
  is **web-search any nonzero exit**. Complementary, never co-firing. ✓
- **A10** (recurring midday-idle → suspend-then-hibernate): batch-01's A26/A33
  live on the same absent idle manager but their verbs are **keep awake / lock
  on sleep**; nothing in batch-01 hibernates. The U0200 lunch-hour family was
  killed at batch-01 F5, resurrected here with a hand attached (draft §3.4) —
  legal: the kill was within the same funnel, overturning happens in-writing.
  ✓
- **A12** vs batch-01's A28 (BT headset → keep the good sound): draft §5's
  cross-batch note is the law here — A28 **routes audio to a device**, A12 sets
  the **mic's level**; a level is not a route. The two never speak in the same
  minute (written into A12's Fires). ✓
- **A13** (strip EXIF before a share): nothing in batch-01 touches metadata;
  its privacy blocks A36/A37 clear Golem's own or the browser's stores. ✓
- **A14** vs batch-01's A36 (vault-born clip → clear after 30 s): A36 clears a
  **single flagged clip** on a timeout via a standing rule; A14 clears
  **Golem's whole clipboard-history store** at a **suspend**, and only when the
  store is non-empty. Same surface, different object and moment. ✓
- **A15** (precision-class focus → ease the pointer): batch-01 has no pointer /
  input-setting action; its health block (A38) dims the backlight. ✓

**Result of the sweep: all twelve pass.** No batch-02 block is a restating of a
batch-01 block; the three closest neighbours (A06/A21, A08/A39, A12/A28) are
resolved above on trigger and verb.

---

### A01 — the unheard hello
*(V01 U0001 T0001 S0039 H1328) · moment · communication*

- **Type:** moment
- **Trigger & evidence:** a call-class app's **audio stream goes live** while
  **its own source sits muted** — the anti-toll: the user cannot know they are
  muted from the call's noise, so the reflex does not exist and the offer is the
  only channel. **The re-anchored mechanism, in full because the hunt found the
  drafted one read the wrong object:** `AudioState.is_muted` is the default
  **sink's** mute (`read_sink_volume`, `collectors/audio.rs:89/93`) — a sink
  mute is the *output* being silent, which is not at all "the mic is closed".
  The mic's own mute is on the **source** object's Volume parameter in the same
  `pw-dump` the collector already shells out to and walks for `is_mic_active`
  (`mic_active_from_dump`, `audio.rs:245`). The trigger reads that document:
  a running mic-capture stream **and** its Audio/Source volume's mute flag.
  `audio.*` is **[live]**; reading one mute flag out of a document already
  parsed is **[cheap]**, zero new wakeups, no new sensing. The stream-live half
  is `mic_active_from_dump` as shipped. No counter, no history: live state only.
- **Sentence:** "Your call just connected and your mic is still muted, do you
  want it opened?"
- **Verb(s):** **[open the mic]** — un-mutes the source (`wpctl set-mute
  <source> 0`; the source id resolved from the same pw-dump object that carried
  the mute flag — PipeWire metadata's `default.audio.source`). **[live]** path
  via an already-installed wireplumber tool. One verb; if the acquisition is a
  meeting, the level is A12's business, not this pill's.
- **Refusal:** right-click = not now, and **this call's jump is done**: no
  re-offer until a *new* stream-live-while-muted event on a later call. Three
  refusals retire the action permanently — a user who takes every call muted
  has told us the mute is deliberate.
- **Gear:** (a) **which app classes count as a call** — the observed call-class
  set, each removable (the same class table the meeting/editor categories live
  in); (b) **also offer for any stream, not just call classes** — off by
  default; (c) don't show this again.
- **Ladder:** assisted = this call, opened. Automatic = *"open the mic whenever
  a call connects while it is muted"*, offered after two accepted opens — the
  rare case where the rule is arguably better than the hand (a user cannot feel
  a mute). Deliberately **not** the default: automatic unmuting is exactly the
  surprise a muted source exists to prevent, and the gear says so next to the
  ladder.
- **Privacy note:** nothing about the call is stored — the audio collector
  already senses *that* the mic is live and never *what* it carries (VI.2). At
  rest: the shared lifecycle row every action has — id, last-offered moment,
  answer, refusal count ≈ **32 B**. Live states only, per the register contract.
- **Fires:** expiring moment (the mute is now, the offer dies with the
  residual of the stream) — queue rank 1 in the **call-start** cluster, but the
  cluster's other member is A12's **pre-capture** sub-moment (`draft §3.1`):
  A01's trigger is stream-**live** (at-or-after capture), A12's is capture **not
  yet live**, so one mouth per call **by construction**, and an off-by-one where
  both test within a minute is settled by refusal memory on each. A call that
  hears A12 pre-capture does not hear A01 after. Honest frequency: **≤1 per
  muted call**, and zero for anyone whose calls are never muted. Spends one of
  the day's three when it fires.

---

### A02 — the download's home
*(V02 U0003 T0003 S0057 H1016) · habit · files*

- **Type:** habit
- **Trigger & evidence:** a finished download whose **kind** (mime class, e.g.
  torrent, iso) lands in a **recurring destination directory on ≥3 separate
  occasions** — a class→destination pair counter. The finish is **[live]** (the
  shipped downloads collector, `collectors/downloads.rs`); the move the user
  makes is read as a **class event on the shipped zsh bridge** (`system/home/zsh.nix`
  posts `{"kind":"shell","last_cmd":…,"exit_code":…,"cwd":…}` on `precmd`,
  catalog §4.11) — a move command whose target is the same directory as before,
  **[live]**. The pair threshold is 3 *occasions*, so a session of two moves is
  one act. The recurring-destination test is what separates a demonstrated
  routine (the offer's license) from a one-off tidy — and it is the reason this
  survived over the every-completion OPTION pill (draft §3.3).
- **Sentence:** "You always put these in \<their folder\>, do you want it moved
  there?"
- **Verb(s):** **[move it there]** — moves the finished download into the
  recurring destination (a rename between user-owned paths; the collector
  already knows the file's path). **[live]** in our own house — no new actuator.
  The folder name is the user's own, quoted live, never guessable.
- **Refusal:** not now = this **kind/destination pair** is answered and never
  raised again, however often it recurs — the user moves these by hand and that
  is the answer. The action stays alive for other kinds; **two refusals, on
  different kinds, retires the whole action** — twice is a verdict on the idea,
  not on the file.
- **Gear:** (a) **the destination** — prefilled from the observed folder,
  editable; (a) **which kinds** — the observed list, each removable; (b) how
  many recurrences before offering (default 3); (c) spend: the absorbed
  **U0193** (filing downloaded files into their homes) is this control, one
  row, never its own action; (c) don't offer moves.
- **Ladder:** assisted = this file, moved once (the standing form is NOT the
  first offer — a move is a per-file act and an auto-filer for every download
  of a kind is a decision bigger than one click deserves at first). Automatic =
  *"move this kind there from now on"*, offered only after **two accepted
  moves** of the same kind — and then it writes one readable line
  (`~/.config/golem/rules/downloads`), revocable in the gear and the notebook.
- **Privacy note:** per pair at rest: an 8-byte mime-kind hash, an 8-byte
  destination hash, a u8 count and a u16 last-seen day — **≈19 B**, ring capped
  at 16 kinds, **≈0.3 kB**. The destination is **hashed** until the N+1th move,
  then quoted **live** at offer time and persisted only on acceptance as
  user-authored config (F4 doctrine 1, name-at-offer-time). No filenames, no
  per-file history, no storage of what was downloaded.
- **Fires:** a habit unlock — it waits for a free slot in the budget,
  indefinitely, and never two unlocks in an hour. At the download seam,
  **priority over the shipped download-finished OPTION** the moment the
  destination recurs (the pill has appeared dozens of times unused for the move
  — the archetypal unresolved offer); A06 never shares the breath (it fires on
  a re-open, a different trigger). Honest: **one sentence, then rarely** — most
  users have one or two recurring destinations, and each new kind needs its own
  three.

---

### A03 — the silent build
*(V03 U0005 T0005 S0067 H1021) · moment · coding/work tools*

- **Type:** moment
- **Trigger & evidence:** the three-part proxy, written whole because a silence
  detector that rests on one part is the sentence that embarrasses the batch.
  A legitimate long build (final linking of a huge binary, a blocked fetch) is
  rare but real, and each of the three discriminants exists to rule it out:
  1. **the build process is still alive** — the shell has not returned: the
     shell bridge's last post is a build-class command and no new `exit_code`
     has followed it **[live]** (`zsh.nix` bridge, catalog §4.11);
  2. **~10 minutes have passed with NO new terminal output** — the console
     class `needs_name` on the bridge's stream; a build that is writing either
     posts or the bridge is the only window Golem has, and the absence of any
     new console-shaped post across the stretch is this half (the spare name is
     a P8 engine task);
  3. **system CPU has been ~zero for the whole stretch** — the CPU aggregate
     the metrics layer already reads **[live]**; a genuinely progressing build
     draws CPU in spikes over ten minutes and a link does not stay truly silent
     AND truly still.
  All three, conjunct. Tag: shell + metrics **[live]**, the proxy's "~10 min
  since the last console post" and "~zero CPU" read off existing streams — no
  detector-owned timer (VI discipline 2), and build **stdout is never read**
  (F4 doctrine 4, held stricter than the classifier needs — the P contract).
- **Sentence:** "Your build has been quiet for ten minutes, do you want it
  stopped?"
- **Verb(s):** **[stop it]** — a TERM of the build's process group (`kill`
  to the sinking pid the bridge/comm scan can resolve; if a TSTP-then-TERM
  sequence is needed the daemon's existing spawn seam carries it). It is a
  one-click stop of a process the user started; the build's own output is not
  saved or read. **[live]**, ours.
- **Refusal:** not now = the build is left running, and the offer is finished
  **for this command** — no re-offer at 20 minutes about the same build; the
  next occasion is a *different* silent build. Two refusals retire the action
  permanently: someone who lets a ten-minute-silent build run has a reason
  (a huge link with CPU they accept), and Golem has been told twice it is
  not the build's judge.
- **Gear:** (a) **how many silent minutes** count (default 10); (a) **the
  classes that count as builds** — the build-tool set (make/ninja/cargo/nix
  build/…), editable, so a long `scp` is not offered against; (b) **only when
  the CPU has been at zero** — the third part, switchable off only at the
  user's risk; (c) don't show this again.
- **Ladder:** assisted = this build, stopped once. Automatic = *"stop anything
  that builds and then goes silent for ten minutes at zero CPU"* — offered
  after two accepted stops, and it stays listed in the notebook with one
  clicking revocation. The automatic form is safe precisely because all three
  discriminants still gate it.
- **Privacy note:** at rest: a build-start instant (u64, ≈8 B)? **No** — the
  "~10 min" window is judged **live** against the last console post / metrics
  timestamps, which already exist; nothing reaches disk beyond the shared
  **≈32 B** lifecycle row. Silence is judged on CPU activity only; the build's
  stdout and stderr are never stored or read.
- **Fires:** expiring moment — the hung build is now, so it speaks when
  triggered and spends one of the day's three (queue rank 1). Honest frequency
  with the three-part proxy: **rare** — a genuinely still-silent-alive build
  at ~zero CPU is the machine's way of saying something is stuck, and it
  happens to a practising developer **a few times a month**; zero for anyone
  who does not compile. Belongs to no cluster.

---

### A04 — the landed branch
*(V04 U0006 T0006 S0069 H1098) · moment · coding/work tools*

- **Type:** moment
- **Trigger & evidence:** a **merge lands in the current repo** — read in two
  halves: the merge **act** is the shell bridge's last command — a merge-class
  command (`git merge`/`git pull`) exiting 0 in the bridge's `cwd`, which is the
  repo **[live]** (the shipped `zsh.nix` bridge post); the merge **result** —
  the local feature branch's tip **reachable from HEAD** — is the honest
  reading of "landed", and **hunt #2's repair is that this second half is NOT
  carried by the collector as shipped.** `collectors/git.rs` reads `.git/HEAD`
  (the branch), `git status --porcelain` (dirty) and the origin config — that is
  all: no branch enumeration, no ancestry test. Without the reachable half the
  act alone is a lie (a failed or conflicted merge also exits non-zero, but a
  merge that *ran* leaves the branch unlanded until it completes). The
  reachable-test is therefore **[cheap] new in our own tree** — one
  `git merge-base --is-ancestor <branch> HEAD` (or `git branch --merged`) fired
  on the merge-event, the same subprocess rail the porcelain call already rides;
  until it ships, the branch-not-yet-landed case has no signal and the action
  does not speak. Repo-public state throughout — this action sees nothing the
  user is not already looking at in the terminal.
- **Sentence:** "That branch made it into the tree, do you want the local one
  closed?"
- **Verb(s):** **[close the branch]** — `git branch -d <name>` (the branch
  quoted live). **The safest destructive verb in the batch, and the reason is
  structural:** `git branch -d` refuses an unmerged branch, so this action
  **cannot lose work** — a branch that is not actually landed refuses the
  pill. The remote is untouched; only the local ref goes.
- **Refusal:** not now = this branch keeps its local ref and is **finished**:
  no re-offer for it, ever — the same branch recurring in the tree again is a
  new event. Three refusals retire the action permanently: a dev who keeps
  landed branches around is keeping them for a reason Golem does not need to
  know.
- **Gear:** (a) **also offer for freshly pushed branches** (off by default —
  the absorbed U0099, closing the branch after the push lands); (b) **never
  offer for these repos** — an exclusion list (the monorepo where 'closing'
  feels like loss); (c) don't show this again.
- **Ladder:** assisted = this branch, closed once. Automatic = *"close the
  local branch whenever it lands"* — offered after two accepted closes, and
  still one `git branch -d` per landed branch, still refused-by-git when
  unmerged. The automatic form is the safe kind of rule: the verb cannot
  over-reach because the repository itself enforces the safety.
- **Privacy note:** no evidence store — branches and repo paths are read live
  and dropped (the bridge's cwd is used, never persisted here; VI.2: we know
  *that* a branch landed, never its contents). At rest: the shared **≈32 B**
  lifecycle row.
- **Fires:** expiring moment — the just-landed branch is the moment; speaks
  and spends one of the day's three (queue rank 1). Honest: **≤1 per merge**,
  and the day's budget keeps it to its share of the shell cluster — a real
  dev merges a few branches a week, so **~1–4 sentences a month**; zero for
  non-developers.

---

### A06 — the app this kind wants
*(V06 U0010 T0010 S0097 H1604) · habit · system/settings*

- **Type:** habit
- **Trigger & evidence:** the **same mime type** is opened, within seconds, in
  a **different app than the one that handled the previous open-with**, on
  **≥3 separate occasions** — a mime-class → app-class pair-counter. Window
  class focus and the open event are **[live]** (the hyprland collector; the
  launcher is who opens files, so "opened with X then Y" is in-house). The mime
  resolution (path → mime type) is **[cheap]** — one lookup the daemon's
  affordance layer already shells to via the shipped `xdg-open` family
  (`mind/affordance.rs:55`). The discriminator is the **re-open in another
  app**: an open-with decision is a demonstrated correction, the CC-style
  signal F5 doctrine 5 sanctions (sense the state, never impute).
- **Sentence:** "You keep opening this kind of thing in \<app\>, do you want
  that to be the default?"
- **Verb(s):** **[make \<app\> the default]** — writes the default association
  (`xdg-mime default <app>.desktop <mime>` — the standard MimeApps seam, which
  lands in `~/.config/mimeapps.list`). **Hunt #2's repair, and it reverses the
  drafted claim in the other direction:** the file is NOT "never nix-managed" —
  `home.nix:529` declares `xdg.mimeApps` with `enable = true` and a fixed
  `defaultApplications` map, and its own comment says a hand-written
  `mimeapps.list` will be reported as in-the-way and replaced on the next
  rebuild. So a one-off `xdg-mime` write is effective **now** and **reverted at
  the next rebuild** — the block must not sell it as durable. The honest shape:
  the per-instance hand ([cheap], `xdg-mime` is already the seam `apps.rs`
  shells through) is a here-and-now correction the user sees immediately; the
  **standing** form (the ladder's automatic rung) is a line in `home.nix`'s own
  `defaultApplications` — written by the daemon as a proposed nix edit and
  applied at the next rebuild, revocation = removing that line from a
  user-readable file. Both shapes stated; neither mis-sells the other.
- **Refusal:** not now = this **mime type** is answered and never offered
  again for it — the user prefers to keep choosing by hand for that kind. A
  *different* kind can earn one new offer later. Two refusals anywhere retire
  the action.
- **Gear:** (a) **the observed kind→app pairs**, one row each, removable —
  the entire learned map, readable (VI.4 mechanical); (b) how many re-opens
  count (default 3) and how fast a re-open is (default within a minute);
  (b) **only for OpenWith explicit choices** vs also auto-handled files; (c)
  forget what I know / stop offering. Absorbed: **U0173** (re-picking the same
  app for a kind every time) is the row list, spent as controls.
- **Ladder:** assisted = this default, written once. Automatic = *"set the
  default whenever this repeats, and list it instead of asking"* — offered
  after two accepted defaults, and every learned pair stays one readable
  removable line in the notebook.
- **Privacy note:** per pair at rest: a mime-hash (8 B), an app-hash (8 B), a
  u8 count and a u16 last-seen day — **≈19 B**, ring of 16, **≈0.3 kB**. The
  file **path** is classified to its mime **transiently** and discarded; the
  preferred app is read live at offer time (F4 doctrine 1). Class-not-content
  (VI.2): mime classes and app classes, never filenames or contents.
- **Fires:** habit unlock — waits for a free slot, never two unlocks in an
  hour. The launch/download seam's third mouth: it fires on a **re-open**, not
  a completion, so it cannot co-fire with A02; if it would coincide with the
  shipped OPTION or A02, the recovery rule applies and it waits. Honest:
  **one sentence, then rarely** — most kinds get one real correction.

---

### A08 — the project's companion
*(V08 U0012 T0012 S0099 H1049) · habit · search/launch*

- **Type:** habit
- **Trigger & evidence:** the **same cwd→launch association** recurs across
  days — entering a project directory and, within a short window, opening the
  same app, **on ≥3 separate days**. `cwd` from the shell bridge is **[live]**
  (the shipped `zsh.nix` post); window class on launch is **[live]** (the
  launcher is in-house). The association memory (cwd-hash → app-class with a
  day-bucketed counter) is the **[cheap]** part, ours. Days, not instances: two
  opens in one sitting are one act. **The GIFT ruling (draft §4.2, re-verified
  by the hunt) is the trigger's whole reason:** the user opens this app
  themselves — a launcher is one gesture — so a per-instance "want me to?"
  would be a toll on a ritual the user's own hands own. The *standing* form is
  the only license; the offer is the gift that abolishes a forever-repeated
  launch-recognition.
- **Sentence:** "You open \<app\> every time you come to this project, do you
  want it ready when you do?"
- **Verb(s):** **[always have it ready]** — the standing rule: when `cwd`
  matches the project hash, launch the app if not already running, through the
  launcher's own seam (`launch::launch(exec, needs_terminal, terminal)`,
  `main.rs:4303`) — **without touching the usage ranking** (the dock sorts by
  `usage.json`; a Golem-run launch must not teach the launcher a click the user
  never made — the A39 lesson applied here). Rule lives as one readable line in
  `~/.config/golem/rules/projects`, re-asserted by the daemon, revocable in the
  gear and the notebook (the U0105-trap test batch-01 ran on A14 is owed here:
  the standing rule must be revocable where it bites, and it is — deletion).
- **Refusal:** not now = this project is answered and never raised again, and
  the action stays quiet for that cwd. **Deliberately generous to the gift:**
  no recurring re-offer — the one offer *is* the gift's shape. Two refusals
  anywhere retire the whole action.
- **Gear:** (a) **the projects**, one readable line each (*"\<project\> →
  \<app\>, ready on open"*), each removable — the entire learned map, readable
  (VI.4) — where the absorbed **U0133** (the per-project editor/IDE ritual)
  is spent as rows; (b) **only when the project is the focused repo** — off by
  default; (b) how many days before offering (default 3); (c) forget my
  projects / stop offering.
- **Ladder:** **the rule IS the offer** (doctrine 3) — there is no assisted
  rung, because the user has already performed the assisted act three times by
  hand and the per-instance form is the toll the F5 flag killed. Above the
  rule: nothing — a ladder that auto-adds projects is a machine curating the
  user's work.
- **Privacy note:** per project at rest: a **cwd hash** (8 B), an app-class
  hash (8 B), a u8 count and a u16 last-seen day — **≈19 B**, ring of 8,
  **≈0.2 kB**, plus the **≈32 B** lifecycle row. The raw path is never written
  (a cwd is a fact about the user's work); it is quoted live at the trigger and
  dropped. No per-session work log, no order of what was opened.
- **Fires:** habit unlock — one sentence, ever, in practice. In the launch
  seam it yields to A09 when they coincide (A09's dead-end is the more urgent;
  the gift is not time-sensitive). Shares no hour with another unlock. Honest:
  lands in the first weeks for a user who returns to the same projects;
  **zero** for anyone whose opening varies.

---

### A09 — the app in the dead command
*(V09 U0013 T0013 S0101 H1148) · moment · search/launch*

- **Type:** moment
- **Trigger & evidence:** the shell bridge reports **exit code 127** (command
  not found) and the typed command **matches an installed desktop file** — the
  app table is the daemon's own `.desktop` scan (`daemon/src/apps.rs:58`,
  rescan on directory watch, `apps.rs:296`), so the match is in-house. **The
  match key is the repair, carried from the hunt:** compare against the
  `.desktop` **Exec basename** (the desktop file's name / binary), **never the
  entry's free-text `Name`** — a user-friendly Name like "Firefox" could match
  a typed stub (`firefox --help`) and manufacture a second offer. The collision
  the hunt probed cannot happen: a 127 means the typed name is not on PATH, and
  a desktop entry matching an un-PATH'd typed name is exactly the intent. `shell` **[live]**
  (bridge), app table **[live]**. Boundary, from draft §3.2: A09's trigger is
  the **subset** of 127 that resolves to an app; the shipped search-the-error
  OPTION (any nonzero exit) is the complement — they **cannot co-fire**.
- **Sentence:** "That command isn't a command, but \<app\> is — do you want me
  to open it?"
- **Verb(s):** **[open \<app\>]** — launches the matched desktop app through
  the launcher's own seam (`main.rs:4303`), the app named live. **[live]**, in
  our own house, no new actuator, no shell-execution of the failed command.
- **Refusal:** not now = this **typed command** is finished and never offered
  again, however often it recurs — the user owns a stub and knows it. The
  action stays alive for other commands; **two refusals on different commands
  retire it entirely**.
- **Gear:** (a) **which app table** — desktop apps only (default) or also the
  launcher's `assets` strip; (b) **also suggest on other nonzero exits**
  (default off — 127 is the clean case; a 1 is a real command that failed);
  (c) don't show this again.
- **Ladder:** assisted = this app, opened once. There is **no automatic rung
  worth climbing** — an auto-open of anything matching would run apps the user
  never chose to run; the dead-command moment is exactly the case where the
  hand should stay in control, and the ladder says so.
- **Privacy note:** the typed command is matched against the app table
  **transiently** and **never stored** (F4 doctrine 4); a 127 string is a
  failed command, not content. At rest: the shared **≈32 B** lifecycle row —
  nothing else.
- **Fires:** expiring moment (the dead-end is now, the offer dies with the
  fresh failure) — queue rank 1, spends one of the day's three. Honest: **a
  few times a month** for a terminal user who types near-misses; zero for
  Mousers. Launch-seam priority over A08 when they coincide.

---

### A10 — the lunch lull
*(V10 U0015 T0015 S0104 H1029) · habit · power/battery*

- **Type:** habit — **written DORMANT. The sensor is the absence, not the
  habit; read the trigger before the sentence.**
- **Trigger & evidence:** the desk is idle at a **recurring midday hour** —
  ONE **median** midday-idle hour, the sanctioned batch-01 **U0200 aggregate**
  shape: a pattern the user's own absences produced, never a clock telling them
  to go eat (draft §3.4). **The dormancy, stated exactly as batch-01 wrote A26
  and A33:** catalog §0 ships **no idle collector**, there is no idle manager
  anywhere in `system/` (no hypridle, no swayidle), and `IdleHint` is set by
  nothing in the tree — so the idle half is **[cheap] NEW work in our own
  tree**, and **A10 does not speak "as though IdleHint exists"** any more than
  A26 does. The one new seam this batch's two idle-needing rows share: **a
  single small logind listener** (D-Bus `PrepareForSleep` / session-idle, on
  the connection `zbus` already gives the daemon) that serves **A10 and A14
  together** — two rows, one seam, both [cheap]. The clock half (the hour) is
  **[live]** (the topbar clock layer). Until that listener ships, both mouths
  stay closed.
- **Sentence:** "It's the hour you usually step away, and the desk has been
  quiet — do you want a nap until you're back?" — the "usually" and "been
  quiet" are both evidence, never a clock telling the user to go eat.
- **Verb(s):** **[hibernate]** — `systemctl suspend-then-hibernate`, which
  the distro already wires on swap-backed laptops
  (`system/hardware/power-laptop.nix`: `HandleLidSwitch =
  "suspend-then-hibernate"`, `HibernateDelaySec = "120min"`); on a swapless
  machine the unit's own comment says the second leg fails, so where swap is
  absent the action's verb is reduced to `suspend` — a detail the trigger
  states. **[live]** systemctl; the offer-first hand is the resurrection the
  family was killed for (batch-01 F5 killed U0200 *because the fact had no
  hand*; hibernate is the hand).
- **Refusal:** not now = silence until the **median hour recurs a further 30
  days** (an aggregate keeps counting while it waits) and only then one more
  offer; two refusals retire it permanently — someone who does not want their
  desk to nap has decided the lid is theirs.
- **Gear:** (a) **the hour** — prefilled from the observed median, editable;
  (a) **what to do** — suspend-then-hibernate (default) / suspend only / off;
  (b) **only on battery / wall** or always; (c) never before N minutes of idle
  in that hour (default 20); (c) revoke / don't offer again.
- **Ladder:** the standing form **is** the offer (doctrine 3 — the user's own
  absences were the tutorial); a per-instance "nap now?" at an hour would be
  exactly the clock-telling-the-user-to-eat the hunt killed. Above the rule:
  nothing.
- **Privacy note:** at rest: ONE median value — a 24-bucket u8 hour histogram
  of idle-window presence (the U0200 shape, **24 B**) plus the **≈32 B**
  lifecycle row. Never a stopwatch over leisure (F4 doctrine 2): no durations,
  no per-day record, no "how long the desk stood empty".
- **Fires:** **zero until the logind listener ships** (dormant, with A14, on
  one seam); after that, **one sentence, ever**, as a habit unlock. Clock-keyed,
  so the hour boundary law is absolute: **never within an hour of any other
  action** — its offer is a standing-rule hand, not an event, so waiting costs
  nothing.

---

### A12 — the level that worked
*(V12 U0017 T0017 S0117 H1033) · moment · audio/devices*

- **Type:** moment
- **Trigger & evidence:** a **meeting-class window is focused and capture is
  not yet live** — a state conjunction, **never a timed window**. The two
  halves, both **[live]**: the window class from the field's own classifier (the
  meeting/game/editor class table in `mind/activity.rs`), capture from
  `audio.is_mic_active` (`mic_active_from_dump`). The pre-capture moment is the
  seconds before the user presses unmute/join; the instant capture starts,
  A12's condition is false. **The hunt's repair is that there is no clock
  anywhere in the sentence's existence:** the offer sits *between* focus-landing
  and the mic going live, two events already arriving, so no detector owns a
  timer (VI discipline 2). A user who never accepted a level produced no stored
  level, so the offer never fires for them — the sentence survives a user who
  never accepted it **by construction**.
- **Sentence:** "Your meeting is about to start, do you want your mic set to
  the level that worked?"
- **Verb(s):** **[set my level]** — writes the remembered source level to the
  mic (`wpctl set-volume <source> <level>`, the level read from the store). The
  verb is honestly the remembered-setting act — **not** "calibrate": a true
  RTA needs the user's voice at offer time, and claiming one would be a lie
  (the honest-verb discipline that reformulated the verb at F5). **[live]**,
  wpctl, already on the audio path.
- **Refusal:** not now = the mic stays at its current level for **this
  meeting**; the next pre-capture window may offer again. Three refusals retire
  it.
- **Gear:** (a) **the remembered level, shown** — the stored source level,
  editable, and the whole point (Constitution V: the stored level is
  **visible and erasable user-authored config**, not a hidden preference);
  (b) **which classes count as a meeting** — the observed set, removable;
  (c) remember/edit per app or one level for all; (c) stop offering.
- **Ladder:** assisted = this meeting, set once — and after the first
  acceptance something has already changed: the stored level exists, so *next*
  offer carries it. Automatic = *"always pre-set my mic when a meeting focus
  lands"* — offered after two accepted sets, writes the standing rule, still
  one line in the rules dir.
- **Privacy note:** at rest: the **accepted source level** as user-authored
  config (a few bytes in `~/.config/golem/rules/audio`), plus the **≈32 B**
  lifecycle row. Nothing about the meeting, the caller, or the conversation;
  focus-and-capture are live booleans, never a history (VI.3 — a meeting log is
  a diary).
- **Fires:** expiring moment — the pre-capture window is now, dies the moment
  capture starts; queue rank 1, spends one of the day's three. **Call-start
  cluster, one mouth per call by sub-moment:** A12 owns pre-capture, A01 owns
  stream-live-while-muted — the two windows do not overlap (draft §3.1), so
  per-construction a call hears one of them, never both. Cross-batch holding
  from draft §5: **never speaks in the same minute as batch-01's A28** (both
  live in the audio seam; a level and a route are different verbs but one
  minute is not the place to find out). Honest: **≤1 per meeting start**, a
  handful per day for the always-in-calls user, and the budget caps the day.

---

### A13 — the picture that knows too much
*(V13 U0019 T0019 S0134 H1683) · moment · security/privacy rituals*

- **Type:** moment
- **Trigger & evidence:** a **fresh image** and **a share-class window takes
  focus** within the short window after — the share moment is the user reaching
  for the network, i.e. the image is about to leave. **Hunt #2's repair is in
  the arrival half, because it named a watcher that does not exist:** there is
  no pictures-dir watch anywhere in the tree (the only file poll is
  `downloads.rs` on `~/Downloads`; the only inotify is the `.desktop` rescan,
  `apps.rs:297–334`). The honest seam the block owns is the **daemon's own
  screenshot spawn** — the shipped `window.screenshot` affordance
  (`catalog.md §4.26`: `grim` → `~/Pictures`) fires **in-house** through the
  affordance layer, so the daemon knows the exact path it just wrote: **the
  image that is about to leave is the one Golem itself just captured**
  ([live], zero new sensing, identity solved by construction). For a fresh
  image that is not Golem's (a photo dropped off a camera), the arrival half is
  **[cheap]-pending** on a small new poll of `~/Pictures` in the downloads.rs
  shape — named here, not smuggled; until that poll ships, the action speaks
only on Golem's own screenshots. **The second half of the trigger is the
   "still carries its metadata" gate, and hunt #2 puts it in the trigger where
   the sentence's truth lives:** the captured image's header is read
   **transiently** for an EXIF/XMP marker (a header-class check, pixels never
   touched — whether the metadata exists, never what it contains); no marker,
   no offer, because the sentence would otherwise lie about a PNG that carried
   nothing. The share-class focus is **[live]**
   (hyprland window class; the chat/share classes — signal, telegram, discord,
   element, slack, whatsapp — are the `MESSAGING_APPS` table,
   `mind/activity.rs`). The evidence is *the sequence*, so a user who captures
   images and never shares costs nothing. Gated by caps below, so a mass-share
   afternoon costs one sentence, not ten.
- **Sentence:** "That picture is about to leave and it still carries its
  metadata, do you want it wiped?" — privacy-positive, alarm-free, and it tells
  no one what the picture is.
- **Verb(s):** **[wipe its metadata]** — **tagged [new], and the actuator is
  named, without decoration:** no EXIF-stripping tool ships in the distro (no
  `exiftool`, no `mat2`, nothing in `system/`), so the pill either runs a
  **tiny in-tree EXIF stripper** (strip the EXIF/XMP blocks of one JPEG/PNG
  in-process) or `exiftool` is added to `packages.nix` **— the block commits to
  the one, and until it ships the verb does not exist and the action does not
  speak.** Pixels are never touched; only metadata paragraphs are removed; the
  file is rewritten in place (shareable immediately).
- **Refusal:** not now = this image keeps its metadata and is **finished**; no
  re-offer for the same file. Capped at **once per session** (the gate, ruled
  mechanical in the hunt — a session token): a share-heavy afternoon costs one
  sentence. Two refusals retire the action.
- **Gear:** (a) **which metadata** — EXIF/XMP (default, everything) / GPS only /
  nothing past the strips, editable; (a) **which share classes count** — the
  observed set, removable; (b) **also strip on export** (off by default);
  (b) once per session (default) / once per share moment; (c) stop offering.
- **Ladder:** assisted = this image, wiped once. Automatic = *"strip any image
  I'm about to share"* — offered after two accepted wipes; the automatic form
  is unusually clean here because the verb is the *removal* of data (the best
  kind of standing rule: its worst failure is a metadata-less file).
- **Privacy note:** EXIF-**presence** is read as a **transient header class**
  (F4 doctrine 4) — the engine knows *that* metadata exists, never *what* it
  contains; pixels are never touched or examined. At rest: a u8 sequence count
  and a u16 last-seen day — **≈3 B**, plus the **≈32 B** lifecycle row; the
  file watcher's events are in-memory. Privacy-POSITIVE: it removes data from
  the user's outgoing files.
- **Fires:** expiring moment (the share is now; if the window closes, the
  image may already be gone) — queue rank 1, spends one of the day's three,
  capped once per session. Honest: **a few times a month** for the user who
  shares photos, zero otherwise. Belongs to no cluster.

---

### A14 — the clean sleep
*(V14 U0020 T0020 S0136 H1931) · moment · security/privacy rituals*

- **Type:** moment
- **Trigger & evidence:** the **session enters Sleep** while the agent process
  is resident — logind sleep **[cheap]** on the **one small listener this block
  shares with A10** (one seam, two rows; the daemon already holds the D-Bus
  connection via `zbus`), process presence **[live]**
  (the agent is trivially itself). **The speaks-only-when-data gate, made
  mechanical per the hunt's ruling:** the thing that would be cleared is the
  daemon's own store — `clipboard-history.json` (the file the clipboard module
  persists and rolls) — so the gate is a **count of that store's entries
  before the offer: non-empty speaks, empty is silence.** Liturgy is
  structurally impossible: a user who has never copied has an empty store and
  never hears the sentence. The trigger fires on **ANY suspend**, never a
  bedtime monitor (F4 doctrine 2).
- **Sentence:** "I'm about to sleep and I still hold your clipboard history, do
  you want it cleared?" — speaks only when data exists; the store is Golem's,
  so "I hold" is the literal truth.
- **Verb(s):** **[clear my clipboard history]** — empties **Golem's own
  `clipboard-history.json`** at `$XDG_DATA_HOME` (the store the clipboard box
  already rolls) — never the user's files, never the system clipboard's current
  contents, never a browser (bounded-storage discipline). **[live]**, in-house:
  the file and its truncation sites are shipped code.
- **Refusal:** not now = the store is left intact **for this suspend**.
  Refusing is genuinely free — nothing is lost by not clearing (the file's
  lifetime is a rolling cap anyway); the offer may return on the next suspend
  that finds data. Two refusals retire it — a user who wants the history kept
  at sleep has said so.
- **Gear:** (a) **what gets cleared** — the whole store (default) / entries
  older than N days; (a) **when** — every sleep / only when I haven't cleared
  by hand; (c) **clear it silently from now on** — the automatic rung, off by
  default; (c) revoke / stop offering.
- **Ladder:** assisted = this sleep, cleared once. Automatic = *"clear my
  clipboard history every time you go to sleep, no more asking"* — offered
  after two accepted clears, and it is the exact shape the disclosure-product
  law builds: the offer's entire job is to state what is tracked, so the
  automatic form is the one place the disclosure stops happening at the user's
  request. Still listed in the notebook with one-click revocation.
- **Privacy note:** everything at rest is the **store itself** — which already
  exists independent of this action and is documented (rolled, capped,
  Golem-owned). This action adds **no new at-rest shape**: the gate is a count
  of existing entries; the shared **≈32 B** lifecycle row is the whole
  addition. No timestamps, no "what you copied" (VI.2 — a roll of hashes and
  offers, never content).
- **Fires:** expiring moment (the suspend is now) — queue rank 1, spends one
  of the day's three, and **only on suspends where the store is non-empty**.
  Honest: for a user who suspends nightly and copies during the day, **~most
  suspends** — which is precisely why the gate is the whole action: without it
  the sentence is liturgy, with it it is a true statement every time.
  Cluster: this is the **SLEEP cluster's only member** and shares the logind
  seam with A10, but the hour boundary means A10 never speaks within an hour.

---

### A15 — the steady hand
*(V15 U0021 T0021 S0137 H1203) · moment · health/ergonomics*

- **Type:** moment
- **Trigger & evidence:** focus lands on a **precision-class window and stays**
  — the class table **named, not waved at** (draft §4.3, carried): the
  image-editor set (gimp, krita, inkscape, darktable), the CAD set (freecad,
  openscad, blender), and the pixel-tool set (aseprite, pixelorama), derived by
  the same class discipline that already supplies the meeting/game/editor
  classes (`mind/activity.rs`). Window class focus is **[live]**; the
  *precision-class* derivation over it is **[cheap]** — a classification of
  what is already sensed, no new wakeup. **The residual the hunt wrote down is
  a verb sentence in the trigger's field:** the class is the **gate** and the
  offer's **timing is the moment** — the class proves the user is in a
  fine-moment environment, but the offer's warmth is the focus-landing + stay,
  never pointer noise (the A26 pointer-discipline worry does not apply; nothing
  samples the pointer).
- **Sentence:** "You're in the pixel editor, do you want the pointer eased for
  it?"
- **Verb(s):** **[ease the pointer]** — lowers the pointer sensitivity
  (Golem's own input setting — the hyprland/wlroots sensitivity write, the
  same seam the distro's own input block manages), while the precision-class
  window holds focus. **Hunt #2's repair is in the one-line feasibility it
  leaned on:** the daemon drives the compositor by `hyprctl eval`
  (`hypr.rs` `dispatch`/`dispatch_checked`, a shipped seam), but it does *not*
  drive the input config today — `sensitivity = 0` is a static nix line
  (`hyprland.lua:291`), and no sensitivity write exists anywhere in
  daemon/options-engine. So the runtime write half is **the A29-unknown**:
  the fork rejects legacy `hyprctl keyword` (non-legacy parsers), and whether
  its eval accepts a runtime `input.sensitivity` assignment is unverified.
  The honest tags split the verb: **the runtime half is [cheap]-pending** — a
  small addition to the shipped `eval` channel (effect takes the moment's
  span) — and **the standing half is in-tree and verified**: the gear's
  recurring rule writes the `input.sensitivity` line into `hyprland.lua` via
  the same gear/rebuild path the other settings use, applied at next rebuild,
  revoked by removing the line.
- **Refusal:** not now = this class is answered and never raised **again by
  itself**; the pointer stays as it is for this task. Two refusals retire the
  action.
- **Gear:** (a) **the easing** — how much (a sensitivity value, default a
  gentle step, editable) and whether pixel-tools get more than CAD;
  (a) **the classes** — the nameable precision set, each removable;
  (b) **only while the window stays focused** (default, the moment) / for the
  whole session; (c) **make it a standing rule** — the automatic rung, off by
  default, revocable in the gear.
- **Ladder:** assisted = this task, eased once. Automatic = *"ease the pointer
  whenever a precision app is in front"* — the standing form, offered from the
  gear after a first acceptance (draft §2.5, A15's gate: standing form signed at
  first acceptance; per-instance repeats stop the moment the rule is written —
  the constitution's ladder locating the rule in the gear).
- **Privacy note:** per class at rest: an 8-byte class hash and a u8 count —
  **≈9 B**, ring of 16, **≈144 B**, plus the **≈32 B** lifecycle row. Class
  only (F4 doctrine 4): never window titles, never what the pixel editor is
  being used on, no durations (the "stays" is a live focused-state, not a
  stopwatch over the artwork).
- **Fires:** expiring moment at queue rank 1 in the first moments of the task;
  in practice **one sentence, ever** for a given precision class — first
  acceptance signs the standing form and the recurrence falls silent, which is
  the reduction the gate exists to enforce. Honest: a few sentences total for
  an artist or CAD user; zero for everyone else.

---

*Counts: 12 action blocks (A01 A02 A03 A04 A06 A08 A09 A10 A12 A13 A14 A15 —
kills A05, A07, A11 are retired gaps, never renumbered). Category distribution:
communication 1, files 1, coding/work tools 2, system/settings 1,
search/launch 2, power/battery 1, audio/devices 1, security/privacy rituals 2,
health/ergonomics 1 — 9 categories, sum 12. Every Fires line is written against
the ratified budget (≤3/day, never two in an hour, no carryover) and the
batch-02 cluster map; the new seams this register asks of the engine are
exactly three — the **logind listener shared by A10 and A14** ([cheap], one
seam, two rows), the **idle-hour source for A10** ([cheap], on that same
listener), and the **[new] EXIF actuator named for A13** — and the dormant
rows wait on them rather than pretending they exist. Cross-batch no-repeat
verified in full against work/batch-01/actions-40.md — all twelve pass.*