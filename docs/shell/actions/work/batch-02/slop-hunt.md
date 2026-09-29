# slop-hunt.md — batch 02, P5 slop hunt #1

**Resulting count: 12.** Fifteen entered this hunt, three were killed, none was
replaced, and 12 is the honest number. This is not the bench doing its work —
it is the funnel doing its work: F5 did batch-02's usefulness cut (21→15),
F6 audited the utterance economy and the pairs, and three rows died here on
evidence read from the tree that no earlier phase had read. The killed three
are A07, A11, A05. Constitution VII: the count is where the razor stopped,
stated plainly.

The hunt re-read, before a single verdict: `constitution.md` top to bottom,
`cut-50.md` §header and its five F5 doctrines, the committed evidence in
`actions-40-draft.md` §7's attack order, and — because three verdicts below
turn on an engine fact — the relevant `launcher/` sources. Verdicts follow
draft §7's mandated order for the first seven, then the remaining rows, then
the voice pass.

---

## §1 The verdicts

Attack order per `actions-40-draft.md` §7.

### The first seven (draft §7's ranked order)

**A12 — the level that worked · KEEP.**
The attack: "the remembered level is ONE accepted source level stored as
config — verify the pre-capture window is actually sensable without a timer."
It is. The trigger is two live states conjunct: a meeting-class window focused
(`window` [live] — the class table that already supplies the meeting/game/editor
classes lives in `mind/activity.rs`) and capture not yet live (`audio` [live] —
`is_mic_active`, `collectors/audio.rs:91`, from the pw-dump the collector
already reads). No timer anywhere: A12's offer exists exactly between focus-land
and the mic going live, a state conjunction, not a duration. A user who never
accepted a level produces no stored level, so the offer never fires — the
sentence survives a user who never accepted it by construction. The stored
level is user-authored config, hence visible and erasable by the same
Constitution V mechanics that govern every other signed preference. KEPT.

**A07 — the tucking dock · KILLED.**
The draft's own note says the value is "the batch's smallest" and the hunts
"hold it as first to die." The engine kills it before the hunts argue charm.
`RELEVANT` subscribes the `fullscreen` event (`hypr.rs:40–47`); `zone_state`
marks any fullscreen client `occupied = true` (`hypr.rs:2087+`); and
`reeval_dock_bar` (`main.rs:2706–2761`) hides the dock the moment the zone is
occupied — with `intellihide: true` the default (`config.rs:331–342`). The dock
tucks itself behind a fullscreen window before the sentence could exist. The
round trip even re-reveals on exit (`main.rs:2756`). A07's trigger — "fullscreen
playback starts while the dock is visible" — names a state the shipped engine
prevents. (The top bar rides the same rail: `frame.rs:1145` conceals it in
fullscreen.) A verb Golem genuinely owns, on a state Golem already handles =
a sentence with no job. KILLED.

**A14 — the clean sleep · KEEP.**
The attack: "verify the speaks-only-when-data gate is mechanically expressible,
else liturgy on every suspend." It is expressible, precisely: the thing that
would be cleared is the daemon's own store (`clipboard-history.json`,
`clipboard.rs:223`, a file Golem writes and rolls), so the gate is a count of
that store's entries before the offer — non-empty speaks, empty is silence. A
machine check, no prose needed. The trigger remains "the session enters Sleep":
honestly [cheap], a logind PrepareForSleep listener — the same new-surface note
as batch-01's idle collector, and batch-02 must share one small D-Bus logind
listener across A14 and A10. Fire-any-suspend (never a bedtime monitor, F4
doctrine 2) is already the drafted shape. KEPT, gate carried into the block.

**A10 — the lunch lull · KEEP, written dormant as batch-01 wrote A26.**
The attack: "is an idling desk at lunch the user's demonstrated rhythm or a
guess at the hour?" The aggregate answers it: ONE median midday-idle hour is the
sanctioned batch-01 U0200 shape — a pattern the user's own absences produced,
not a clock telling them to go eat. The verb is real (`systemctl
suspend-then-hibernate`, and the distro already wires it on swap machines,
`system/hardware/power-laptop.nix`). The honest caveat is the SENSOR, and it is
the same caveat batch-01 wrote into A26 and A33: catalog §0 ships no idle
collector, there is no idle manager in system/, and `IdleHint` is therefore
[cheap]-new work in our own tree. A10 must be written the same shape A26 got —
dormant on a named absence, explicitly not "as though IdleHint exists" — and it
shares the logind listener with A14. KEPT with the dormancy written in, not
waved at.

**A09 — the app in the dead command · KEEP.**
The attack: "try to break the match table (a name that collides with a binary)."
The collision cannot happen: exit 127 *is* command-not-found, so the typed name
is not on PATH by definition; and the match table is the daemon's own
`.desktop` scan (`apps.rs` — "entries come from `.desktop` files", `apps.rs:58`,
rescan on directory watch, `apps.rs:296`). A name matching a desktop entry
while returning 127 is exactly the intent — the user expected a binary that is
really an app. The one residue to write down, not kill: match on the desktop
Exec basename (the `.desktop` file name), never on the entry's free-text Name,
or a stub like `firefox --help` becomes a second offer. KEPT, table mechanism
named for P6.

**A03 — the silent build · KEEP, trigger hardened.**
The attack: "verify a legitimate long link/network-wait build cannot trip it."
A 10-minute zero-output build that is actually progressing is rare but real
(final linking of a huge binary, a blocked network fetch with no CPU). The
exact discriminants that separate a hung build from a slow one: the build
process is still alive (the shell has not returned), ~10 min have passed with
NO new terminal output (`needs_name` the shell-bridge console class), AND
system CPU has been ~zero the whole stretch — a genuine link never stays truly
silent for ten full minutes. Written that way, the offer is cheap and refusable
and the "stopping a real build" embarrassment is designed out, not wished
away. KEPT with the three-part proxy carried into the trigger field.

**A05 — the corner you catch · KILLED.**
The trigger is "cursor lands on one hot-corner ≥3× with no intent-moment before
it (pointer position via the hyprland event [cheap]; never polled otherwise)."
No such stream exists. The daemon reads cursor position exactly one way —
`wl_pointer` motion over its OWN surface (`main.rs:5426+`, the raw wl_pointer
dispatch), which is why edge-reveal works only in its own bottom strip
(`main.rs:4960–4966`). There is no global cursor-position stream anywhere:
no `cursorpos` reader, no `cursorMove` handler, nothing in `RELEVANT`. The two
paths to a hot-corner detector are (a) `hyprctl cursorpos` polling — which the
draft's own "never polled otherwise" clause forbids — or (b) a new hyprland
cursor subscription that does not exist and would be [new], not [cheap]. And
the "no intent-moment before it" discriminator has no sensor even with a
stream: a sweep that passes a corner and a deliberate landing carry no
distinguishing event. KILLED — the tag is on a mechanism the engine does not
run, under a discipline clause the only cheap actuator would break.

### The remaining rows (draft order)

**A01 — the unheard hello · KEEP, trigger re-anchored.**
The anti-toll survives — the user cannot know they are muted from the call's
noise, so the offer is the only channel. The re-anchor is a fact about the
collector: `AudioState.is_muted` is the default **sink's** mute
(`read_sink_volume`, `audio.rs:89`), but A01's trigger needs the **source's**
mute. The reading is available for free in the dump the collector already
parses (`mic_active_from_dump` walks the same objects, `audio.rs:245`); P6
anchors the trigger to the mic source object's Volume mute from that dump,
never to the sink's. KEPT — the value is intact, the sensor is one parse deeper
in a collector that already runs.

**A02 — the download's home · KEEP.** The [live] downloads collector ships
(`downloads.rs`); the move is a class event on the shipped zsh bridge; the P is
strictly hashed kind + destination with name-at-offer-time. A recurring
destination ≥3× is a demonstrated routine, the reason F5 kept it over the
shipped OPTION-pill. The N+1th gate (draft §2.4/§3.3) holds. KEPT.

**A04 — the landed branch · KEEP.** `git branch -d` refuses an unmerged branch,
so the most destructive verb in the batch literally cannot lose work; the git
collector ships (`git.rs`) and branches are live state. KEPT.

**A06 — the app this kind wants · KEEP.** Window [live] + the open event +
[cheap] mime resolution; a `mime-class → app-class` pair-counter is the exact
class-not-content shape F4 doctrine 4 sanctions; name at offer time. Distinct
from A02 and from the shipped OPTION per draft §3.3 — three verbs, three
sub-moments, the cluster rule decides. KEPT.

**A08 — the project's companion · KEEP.** The gift-in-standing-form ruling
(re-verified F6 §4.2) holds; cwd is hashed at rest, quoted live at the trigger;
the standing rule is revocable (gear + notebook). The one deliverable P6 owes
from F6 stands: the U0105-trap test. KEPT.

**A11 — the parked machine · KILLED.**
The process CLASS the trigger names — qemu/kvm — does not exist on this
machine's lifecycle. There is no `virtualisation`/`libvirtd`/`virt-manager`
host config anywhere in `system/`: the qemu matches are (i) `hardware-detect`
Golem-as-guest detection, (ii) preinstall fixtures, and (iii) the `vm-guest`
matrix. Golem's machines are guests, not hosts. The verb is equally absent:
`virsh` is not in the distro, so even a hypothetical qemu guest has no [park
them] actuator. Another sentence whose trigger and verb are both on machinery
that is not here — the same species as A07 (a state the machine won't reach),
one layer deeper. KILLED.

**A13 — the picture that knows too much · KEEP, actuator named.**
The value is genuinely privacy-POSITIVE (it removes data from the user's
outgoing files; F4 doctrine 4 class-not-content holds; the fresh-image-then-
share-focus sequence is window [live]). The repair the hunt found is in the
VERB field: no EXIF-stripping tool ships in the distro (no `exiftool`, no
`mat2` anywhere in `system/`). "[wipe its metadata]" is therefore [new], not
[cheap], and must be tagged honestly — either a tiny in-tree stripper or
`exiftool` added to `packages.nix`. The once-per-session cap (draft §2.5) is
mechanical and stays. KEPT with the verb's actuator named, as batch-01 wrote
its three [new] verbs.

**A15 — the steady hand · KEEP.** The precision-class table is named in F6
§4.3, not waved at (image-editor / CAD / pixel-tool sets), and class derivation
is the shipped discipline `mind/activity.rs` already supplies for the
meeting/game/editor classes. The pointer write is Golem's own input setting.
The §4.3 residual — the knob must serve the fine-moment, not the class — is
carried: the class is the gate, the offer's timing is the moment, the standing
form lives in the gear. KEPT.

---

## §2 The voice pass

Fifteen sentences read aloud, the last eight (the survivors' full list then at
12):

- "Your call just connected and your mic is still muted, do you want it opened?"
  — a fact about the hardware's state the user cannot perceive. Thankable. ✓
- "You always put these in <their folder>, do you want it moved there?" — an
  observed routine, offer-first, refusable. ✓
- "Your build has been quiet for ten minutes, do you want it stopped?" — the
  one voice line the batch feared, lives or dies on the hardened proxy. ✓
- "That branch made it into the tree, do you want the local one closed?" — a
  fact about the repo, a safe destructive hand. ✓
- "You keep opening this kind of thing in <app>, do you want that to be the
  default?" — a routine the user demonstrated. ✓
- "You open <app> every time you come to this project, do you want it ready
  when you do?" — the gift in standing form. ✓
- "That command isn't a command, but <app> is — do you want me to open it?" —
  a dead-end rescue. ✓
- "It's the hour you usually step away, and the desk has been quiet — do you
  want a nap until you're back?" — the "usually" and "been quiet" are both
  evidence; no clock-telling-the-user-to-eat. ✓
- "Your meeting is about to start, do you want your mic set to the level that
  worked?" — pre-capture window, honest verb. ✓
- "That picture is about to leave and it still carries its metadata, do you
  want it wiped?" — privacy-positive, alarm-free. ✓
- "I'm about to sleep and I still hold your clipboard history, do you want it
  cleared?" — speaks only when data exists. ✓
- "You're in the pixel editor, do you want the pointer eased for it?" — the
  fine-moment hand. ✓

Constitution II's own test — does any sentence tell the user something about
themselves they did not ask to hear? — is re-asked over the survivors: every
observation left in the register is a fact about a THING (a folder, a repo, a
command, a store, a window class) or a demonstrated routine the user's own
hands produced ≥3×, never a verdict about the user. Zero moralizing survives.
The three pattern-observers (A02, A06, A08) state the pattern as an offer on
the thing, not as a judgment on the person. Voice pass killed nothing the
evidence didn't already kill.

---

## §3 The law and doctrine rulings

**The two structural laws (draft §2.4) — RATIFIED, in writing, binding on P6.**
Re-read against `constitution.md` and the batch-01 precedent this batch
inherits:

1. **THE DAY'S BUDGET — kept as ratified in batch-01, with batch-02's own
   cluster map.** At most 3 action sentences per day, never two inside the same
   hour; every batch-02 block's Fires line is written against it. The draft's
   honest steady state is ≈3–5/day and its first week is 9–11 — exactly the
   overload the budget exists to absorb, which is why the hunt re-reads the
   law into every Fires line rather than restating it. KEPT.
2. **ONE MOUTH PER CLUSTER — kept, with the draft's §2.4 priority map as the
   written order.** Call start (A12 pre-capture / A01 stream-live-while-muted —
   disjoint sub-moments, one mouth per call), the download seam (A02's move
   outranks the shipped OPTION pill at the N+1th; A06 never shares the breath),
   the launch seam (A09 over A08 when they coincide), the hour boundary (A10
   never within an hour of anything). KEPT.

**The five gates in draft §2.5 — ruled, in writing:**
- **A14** — mechanically expressible (a count of the daemon's own
  clipboard-history store > 0 before the offer). Rule is discharged; it is a
  machine check, not prose.
- **A13** — once-per-session is a session token; capped by construction. Holds.
- **A07** — the gate is moot; the row is dead.
- **A15** — standing form signed at first acceptance; per-instance repeats stop
  the moment the constitution's ladder locates the rule in the gear. Holds.

**The bench — locked, re-checked, not overturned.**
The directive forced the re-check rather than the rubber-stamp. The six F5
kills (U0002 U0004 U0007 U0008 U0014 U0018) were re-read against draft §6's
one-liners and no verdict was beaten: U0004 (reflex beats sentence, standing
form is an un-authored hook), U0007 (code-reviewer register / Constitution II),
U0018 (the verb IS the shipped media-volume OPTION), U0014 (toll twin of
shipped A38), U0002 (user demonstrated NOT emptying), U0008 (sunset family is
full). Each beats its F6 one-liner. No killed row was replaced — that is the
honest reading of the bench rule: a replacement needs an overturned verdict,
and none was overturned, so batch 2 ships 12.

**Why the hunt killed three and not more or fewer (the not-suspicious-zero
clause, answered honestly):** the funnel already did the broad killing — F5
took 21→15 in one pass and F6's bench re-attack held all six — so a 15-row
hunt was never a 39-row hunt. What remained was the field the earlier phases
could not read: whether each draft's trigger and verb exist on today's engine.
Three did not, on evidence only the tree could supply (the dock's own
intellihide for A07, the absent host-virtualization lifecycle for A11, the
absent cursor stream + self-forbidding discipline for A05). That each kill is
an engine reading rather than a taste call is why the hunt is confident in
12 and in nothing less defensible.

---

## §4 What P5 block-writing must carry from this hunt

- **The count is 12.** The register is A01, A02, A03, A04, A06, A08, A09, A10,
  A12, A13, A14, A15. The killed three (A05, A07, A11) do not get blocks, and
  no killed row is replaced by bench padding.
- **A01's trigger is re-anchored** to the mic **source's** mute, parsed from
  the pw-dump the audio collector already reads (`audio.rs:245` region), never
  to `AudioState.is_muted` (the sink's).
- **A03's proxy is the three-part one**: build process still alive + ~10 min
  with no terminal output + sustained ~zero CPU. It must be written with all
  three, or the sentence is the one that embarrasses the batch.
- **A09 matches on the .desktop Exec basename**, never the free-text Name.
- **A10 is written dormant on the absent idle manager**, in A26/A33's shape,
  sharing ONE small logind listener with A14 (both [cheap] on the same new
  collector; two rows, one seam).
- **A13's verb is tagged [new]** and names its actuator (tiny in-tree stripper
  or `exiftool` added to `packages.nix`) — the wipe does not exist in the
  distro today.
- **A12's stored level** must land in visible-and-erasable user-authored
  config (Constitution V), and the pre-capture offer is a state conjunction,
  not a timed window — if a draft introduces a timer, the draft is wrong.
- **Every Fires line** is written against the ratified budget (≤3/day, never
  two in an hour) and the cluster map (§2.4): the A12/A01 call pair speaks one
  mouth per call by sub-moment, and A10 never speaks within an hour of
  anything.

---

*Counts: 15 rows hunted in draft §7 order plus the remainder; 12 kept, 3
killed (A07, A11, A05), 0 replaced. The kept 12 span: communication 1, files
1, coding/work tools 2, system/settings 1, search/launch 2, power/battery 1,
audio/devices 1, security/privacy rituals 2, health/ergonomics 1 — 9 categories,
system down from 3 to 1 and power down from 2 to 1. Sum: 12. Batch 2 ships
twelve sentences.*

(End of file)

---

## Hunt #2 (P7) — the twelve blocks, field by field

The first hunt worked from the draft upward. Hunt #2 works from the register
down: it re-reads the twelve surviving blocks in the final register and attacks
each field against the real tree. Procedure was conditions.md §3; the sentence,
verb, type, refusal, gear, ladder, privacy note, fires, and the cross-batch
no-repeat law were all checked. Kill threshold: a clause that names a signal the
tree does not carry (a restated condition or an invented seam). Nothing was
killed — the four hits were all repairable in-place, and the register is the
better for it. This verdict section is appended, never spliced.

### §H1 The verdict at a glance

| Block | Verdict | Why |
|---|---|---|
| A01 unheard hello | KEEP | source-mute out of pw-dump survived (one field out of the already-parsed dump). |
| A02 download's home | KEEP | downloads poll shape exists (3s, 90s RECENT, PARTIAL-proof). |
| A03 silent build | KEEP | [live] CPU aggregate grounded (`system.rs:43–67`); proxy conjunctions all conjunction-gated. |
| A04 landed branch | REPAIR | the "branch list the collector already carries" did not exist — collector reads HEAD/porcelain/origin only. |
| A06 app this kind wants | REPAIR | "never nix-managed" was false — `home.nix:529` xdg.mimeApps. |
| A08 project's companion | KEEP | trigger/verb distinct from A39 (cwd → morning + placement; real check). |
| A09 app in dead command | KEEP | basename discipline holds; launch path verified (`main.rs:4303`). |
| A10 lunch lull | KEEP | single shared logind listener [cheap]; idle-hour on it; fires never within an hour. |
| A12 level that worked | KEEP | state conjunction (class ∧ capture-not-live), never a timer; distinct from A28. |
| A13 picture knows too much | REPAIR | watch a dir that is never watched; identity never named; EXIF gate belongs live. |
| A14 clean sleep | KEEP | fiscal gate survives (`clipboard-images/history` non-empty speaks); sleeps share A10's logind seam. |
| A15 steady hand | REPAIR | "sensitivity one line the daemon already drives" — no sensitivity write exists anywhere. |

### §H2 The four repairs (all applied in-place, all verified in the register)

- **A04** — the actuator half fell on "the branch list the collector already
  carries". `git.rs` carries only `HEAD`, `--porcelain`, and origin config. The
  repair anchors the reachable-test to a **[cheap] new in our own tree**
  subprocess (`git merge-base --is-ancestor <branch> HEAD`, same rail as
  porcelain); until it ships, the action silently doesn't speak. Read of the
  whole register confirms auto-form "close whenever it lands" then equals real
  closed-at-last-merge, up-to-the-minute.
- **A06** — "the file was never nix-managed" is contradicted by
  `home.nix:519–545` (`xdg.mimeApps`, fixed defaultApplications and a comment
  telling the user to move a hand-written list aside so it can be replaced).
  The repair reverses the verb to the true mechanism: a one-off
  `xdg-mime default` write is effective now and reverted at next rebuild; the
  recurring (automatic) rung is a readable line in `defaultApplications`.
- **A13** — "a new-file event on the watched pictures dir" names a watcher that
  does not exist (no pictures watch; the only file poll is `downloads.rs` on
  `~/Downloads`; the only inotify is the `.desktop` rescan, `apps.rs:297–334`).
  Repair: the arrival half is the daemon's own screenshot spawn
  (`catalog.md §4.26` grim → `~/Pictures`) — the one image whose path the daemon
  knows it just wrote; the EXIF/XMP presence read moves into the trigger where
  the sentence's truth lives (sentence claims "still carries its metadata", so
  the offer must gate on the marker, or nothing about a metadata-free PNG gets
  said).
- **A15** — "the input config the daemon already drives" is not driven:
  `sensitivity = 0` is a static nix line. Repair: runtime write = **[cheap]-pending**
  through the shipped `hyprctl eval` rail (fork-runtimes input key = the A29
  unknown), standing form = the gear's readable `input.sensitivity` line via the
  same rebuild path as every other setting.

### §H3 Why nothing died (the count stays 12)

A hunt that kills nothing owes the reader the reason. Kill candidates
periodically: A13's missing watcher was the closest. It was repairable because
the value is privacy-positive and the honest seam (`grim`→`~/Pictures`) already
exists in the catalog. This is the line between a kill and a repair, and it is
the one the outline told the first hunt to be strict about: **a fail is a kill
only when no honest seam holds the value**. Every one of the four had a real
seam within reach: A04 = the same subprocess rail, A06 = xdg-mime + home.nix,
A13 = the in-house screenshot spawn, A15 = `eval` + rebuild. Killed nothing,
added nothing, renumbered nothing.

### §H4 The engine work the register now names (the honest tab)

Read together, the four repairs ask the engine for the following, none of it
shipping today:

- the **[cheap]-new** git reachable-test (`git merge-base --is-ancestor`) on the
  porcelain rail — A04;
- nothing new for A06 (xdg-mime + home.nix both exist);
- the daemon's own `grim`→`~/Pictures` spawn returning the written path to the
  engine, plus a *transient* EXIF/XMP header check — A13 (the header read is
  [cheap], one classification of bytes the daemon already wrote);
- the **[cheap]-pending** `eval`-rail `input.sensitivity` write — A15.

Hunt #1's register footer counted "exactly three new seams" (logind listener,
idle-hour source, EXIF actuator). The honest tab above is the corrected,
field-checked inventory: A04's reachable-test, A13's spawn-path return + header
read, A15's eval write. The register footer and this section are the same tab
in two voices; the footer stays as written pre-hunt, this section is the audit.
*(Sections H1–H4 verify the register at P7; the footer's pre-hunt tally is
superseded by §H4.)*

(End of file)