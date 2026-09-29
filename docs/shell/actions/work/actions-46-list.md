# The ACTIONS list — all 46, both batches

Compiled from the closed registers `work/batch-01/actions-40.md` and
`work/batch-02/actions-40.md`. Format per action: **the sentence Golem speaks** ·
the verb pill it offers · the trigger (when it fires) · current status.

Status is the batch's own honest ledger: **[live]** = can speak on today's
engine; **[cheap]** / **[new]** = waits on named work; **dormant** = blocked on
an engine absence. Batch 01 ships 34 (10 live); batch 02 ships 12 (2 live).

---

## BATCH 01 — 34 actions

### A01 — the rogue sound
- **sentence:** "The sound is coming from your browser, do you want it muted?"
- **verb:** [mute it] / [show me]
- **trigger:** browser playback starts while its window has been unfocused ≥10 s
- **status:** [live]

### A02 — the answer you keep typing
- **sentence:** "You have copied this same text on three different days, do you want it kept as a snippet?"
- **verb:** [keep it as a snippet]
- **trigger:** same clipboard content (hashed) on ≥3 separate days
- **status:** [cheap] wait — pinned-row flag on the existing clipboard store

### A03 — the audience
- **sentence:** "Your whole screen is being shared, do you want the rest of the windows tucked away until it ends?"
- **verb:** [tuck the rest away]
- **trigger:** a full-output screencast starts
- **status:** **dormant** — output-share type not exposed by the portal yet

### A04 — quiet the desk
- **sentence:** "Your microphone just went live, do you want your desk quiet?"
- **verb:** [quiet my desk]
- **trigger:** mic active past a 5 s floor (a call)
- **status:** [live]

### A05 — the hand-back
- **sentence:** "Your call is over, do you want to see what I held back?"
- **verb:** [show me]
- **trigger:** mic goes inactive after Golem held the notification queue
- **status:** [live] (after A04's standing form, else silent)

### A07 — pause when I step away
- **sentence:** "You pause before you step away from the desk, do you want me to do that part?"
- **verb:** [pause when I step away]
- **trigger:** manual pause + session going idle, ≥3× across days
- **status:** [cheap] wait — idle source via the compositor's idle-notify

### A09 — game mode
- **sentence:** "A game just took the screen, do you want game mode?"
- **verb:** [game mode]
- **trigger:** a game-class window goes fullscreen
- **status:** [live]

### A10 — keep it on top
- **sentence:** "You put the player in the corner yourself when you go back to work, do you want it to go there on its own?"
- **verb:** [keep it on top]
- **trigger:** a standalone player floated small while focus moves elsewhere, ≥3× across days
- **status:** [live]

### A11 — the whisper cap
- **sentence:** "You keep the volume low at this hour, do you want it to start out quiet after midnight?"
- **verb:** [start quiet after midnight]
- **trigger:** playback starting quiet after a recurring late hour, on ≥3 nights
- **status:** [live]

### A13 — the short name
- **sentence:** "That is the third day you have typed this command out in full, do you want a short name for it?"
- **verb:** [make it `gsu`] (proposed live from the command's words)
- **trigger:** same long command (≥24 chars, exit 0) on ≥3 separate days
- **status:** [live] trigger; [cheap] verb — the aliases file + one `zsh.nix` source line don't exist yet

### A14 — the reflex
- **sentence:** "You type `ls` after almost every `cd`, do you want the shell to do it for you?"
- **verb:** [do it for me]
- **trigger:** cd → ls adjacency ≥20× across ≥3 days covering ≥60% of all cds
- **status:** [cheap] verb — same missing shell-hooks file as A13

### A15 — arrive plain
- **sentence:** "You strip the formatting out of most things you paste, do you want them to arrive plain?"
- **verb:** [keep browser copies plain]
- **trigger:** rich text copied then re-offered seconds later as plain-only, ≥3× (laundering round-trip)
- **status:** [live]

### A16 — the waiting update
- **sentence:** "This update has been waiting a while, do you want it applied the next time you restart?"
- **verb:** [apply it at the next restart]
- **trigger:** a pending nix generation observed on ≥3 separate days
- **status:** [cheap] verb — the apply unit (`nixos-rebuild boot` via intent file) doesn't exist yet

### A17 — the hour you always guard
- **sentence:** "You silence notifications around this time most days, do you want that to happen on its own?"
- **verb:** [every day at this hour]
- **trigger:** DND toggled by hand at a recurring hour, ≥3 days
- **status:** [live]

### A18 — the layout that follows the app
- **sentence:** "You switch the keyboard layout every time you come to this window, do you want it to follow the app?"
- **verb:** [remember the layout per app]
- **trigger:** layout changes within seconds of focus arriving at a class, on ≥3 days
- **status:** [cheap] wait — `activelayout` event plumbing

### A19 — the fresh screenshot
- **sentence:** "You draw on nearly every screenshot you take, do you want them to open in the annotator?"
- **verb:** [open them in the annotator]
- **trigger:** annotator class focused within ~60 s of a new screenshot, ≥3 days
- **status:** [cheap] wait — needs an annotator/screenshots-dir watch; only exists where the user installed an annotator

### A20 — true colours
- **sentence:** "Eye protection is on and you have opened a photo, do you want true colours for a minute?"
- **verb:** [true colours for a minute]
- **trigger:** user has by hand turned eye protection off in front of a photo ≥3×; moment = screen warmed + image class focused
- **status:** [live]

### A21 — the wrong first hit
- **sentence:** "The launcher keeps putting \<app\> first and you keep closing it, do you want it moved down?"
- **verb:** [stop putting it first]
- **trigger:** launcher fires app X for query Q and the window closes within ~15 s, ≥3× for the pair
- **status:** [cheap] wait — the (query, app) → penalty sibling store beside `usage.json`

### A24 — stop at 80
- **sentence:** "This machine lives on the charger, do you want it to stop charging at 80%?"
- **verb:** [stop at 80%]
- **trigger:** machine on wall power ~whole session, ≥3 sessions, and the battery exposes a charge limit knob
- **status:** [cheap] wait — the root apply-unit; only exists on hardware with the sysfs knob

### A25 — stretch it
- **sentence:** "You start saving the battery around here, do you want that to happen on its own from now on?"
- **verb:** [do it at \<N\>% from now on]
- **trigger:** manual move into power-saver at a recurring battery level, ≥3 occurrences
- **status:** [live]

### A26 — the wrist
- **sentence:** "You keep the screen awake by hand while you read, do you want it to stay awake here?"
- **verb:** [keep it awake here]
- **trigger:** resumed from idle with nothing following it, ≥3×
- **status:** **dormant** — Golem ships no idle manager to act on

### A27 — follow my headphones
- **sentence:** "You move the sound over by hand every time these headphones arrive, do you want them to take it automatically?"
- **verb:** [follow my headphones]
- **trigger:** default sink moved by hand to a just-arrived device, same device ≥3×
- **status:** [live]

### A28 — the good sound
- **sentence:** "Your headset drops to phone-call sound when the microphone is used, do you want to keep the good sound and use the laptop's microphone instead?"
- **verb:** [keep the good sound]
- **trigger:** BT headset (current sink) flips to the call profile as capture starts
- **status:** [cheap] wait — one more field read from the parsed pw-dump

### A29 — remember this desk
- **sentence:** "You have arranged these monitors the same way again, do you want this desk remembered?"
- **verb:** [remember this desk]
- **trigger:** a monitor added and the same manual re-arrangement within seconds, ≥3×
- **status:** [new] wait — the `zwlr_output_manager` actuator; does not speak until it exists

### A31 — open it there
- **sentence:** "You move \<app\> over here every time it opens, do you want it to open there?"
- **verb:** [open it there from now on]
- **trigger:** window of class C opened and corrected (moved/floated) the same way ≥3×
- **status:** [cheap] wait — two `parse_event` arms in the hyprland collector

### A32 — watch it for me
- **sentence:** "You keep coming back to check on this, do you want me to tell you when it changes?"
- **verb:** [tell me when it changes] (a notification, not a spoken sentence)
- **trigger:** ≥3 returns within ~15 min to a window with a changing NN% / CI marker in its title
- **status:** [cheap] wait — `windowtitle` event arm

### A33 — the gap before it sleeps
- **sentence:** "You lock the screen by hand whenever you get up, do you want it locked as soon as the screen sleeps?"
- **verb:** [lock as soon as the screen sleeps]
- **trigger:** the user's own lock followed by idle, ≥3×
- **status:** **dormant** — no idle manager and no locker ship with Golem

### A34 — another finger
- **sentence:** "The fingerprint reader has been missing about half the time, do you want to add another finger?"
- **verb:** [add another finger]
- **trigger:** ≥40% of the last 20 fingerprint verifications failed (min 10 attempts); exists only where a reader is detected
- **status:** [new] wait — a new fprintd journal reader collector

### A35 — the open vault
- **sentence:** "Your password vault is still unlocked, do you want it locked?"
- **verb:** [lock it] (the vault's own documented lock command)
- **trigger:** vault window present and unlocked, no focus visit ≥4 hours; desk in use meanwhile
- **status:** [live] (exists only for vaults with a documented D-Bus lock command)

### A36 — the vault clipboard
- **sentence:** "That came from your vault, do you want it cleared from the clipboard in 30 seconds?"
- **verb:** [clear it in 30 seconds]
- **trigger:** a vault-marked clipboard offer still present after the window elapsed, ≥2×
- **status:** [live]

### A37 — on the way out
- **sentence:** "You clear your history most times you finish with the browser, do you want the browser to do it itself on the way out?"
- **verb:** [clear it on the way out] — the browser's own preference, never Golem touching history
- **trigger:** the browser's clear-browsing-data dialog appears, ≥3× across days
- **status:** [new] wait — exists for Firefox, deliberately does NOT exist for the shipped Chrome

### A38 — the second knob
- **sentence:** none — rides "The sun is set, do you want to turn on eye protection?" and adds a pill
- **verb:** [and dim the screen]
- **trigger:** the sunset utterance is on screen + the user dropped the backlight by hand ≥3 evenings
- **status:** [cheap] wait — one brightness read inside an existing `read_dir`

### A39 — the desk ready
- **sentence:** "This is the set you open most mornings, do you want the desk ready?"
- **verb:** [have the desk ready]
- **trigger:** a recurring morning app-set + first-focus hour, stable ≥3 mornings
- **status:** [cheap]-pending wait — the launch path must skip the usage counter (one bool)

### A40 — close up
- **sentence:** "You have started closing up, do you want the rest of it closed?"
- **verb:** [close up] (polite close dispatches, never signals)
- **trigger:** first two closes of the work-set inside a recurring end-of-session window, ≥3 days
- **status:** [cheap] wait — a `closewindow` event arm in the collector

---

## BATCH 02 — 12 actions

### A01 — the unheard hello
- **sentence:** "Your call just connected and your mic is still muted, do you want it opened?"
- **verb:** [open the mic]
- **trigger:** a call-class audio stream goes live while its source sits muted
- **status:** [cheap] wait — read one mute flag out of the event document the audio collector already parses

### A02 — the download's home
- **sentence:** "You always put these in \<their folder\>, do you want it moved there?"
- **verb:** [move it there]
- **trigger:** a finished download's kind lands in a recurring destination on ≥3 separate occasions
- **status:** [cheap] wait — the kind→destination pair counter

### A03 — the silent build
- **sentence:** "Your build has been quiet for ten minutes, do you want it stopped?"
- **verb:** [stop it]
- **trigger:** build process still alive, no new terminal output ~10 min, system CPU ~zero — all three
- **status:** [cheap] wait — a console-class marker on the shell bridge stream

### A04 — the landed branch
- **sentence:** "That branch made it into the tree, do you want the local one closed?"
- **verb:** [close the branch] (`git branch -d` — refuses unmerged branches)
- **trigger:** a merge command exits 0 in the repo, and the local feature branch tip is reachable from HEAD
- **status:** [cheap] wait — one `git merge-base --is-ancestor` subprocess on the merge event

### A06 — the app this kind wants
- **sentence:** "You keep opening this kind of thing in \<app\>, do you want that to be the default?"
- **verb:** [make \<app\> the default]
- **trigger:** the same mime type opened in a different app than the previous open-with, ≥3 occasions
- **status:** [cheap] wait — the mime→app pair counter

### A08 — the project's companion
- **sentence:** "You open \<app\> every time you come to this project, do you want it ready when you do?"
- **verb:** [always have it ready]
- **trigger:** the same cwd→launch association recurs across ≥3 separate days
- **status:** [cheap] wait — the cwd-hash → app-class association memory

### A09 — the app in the dead command
- **sentence:** "That command isn't a command, but \<app\> is — do you want me to open it?"
- **verb:** [open \<app\>]
- **trigger:** shell exit code 127 and the typed command matches an installed desktop file's Exec basename
- **status:** **[live]** — one of the two that speak today

### A10 — the lunch lull
- **sentence:** "It's the hour you usually step away, and the desk has been quiet — do you want a nap until you're back?"
- **verb:** [hibernate]
- **trigger:** the desk idle at one recurring median midday hour
- **status:** **dormant** — needs the one shared logind listener (with A14)

### A12 — the level that worked
- **sentence:** "Your meeting is about to start, do you want your mic set to the level that worked?"
- **verb:** [set my level]
- **trigger:** a meeting-class window is focused and capture is not yet live
- **status:** **[live]** — one of the two that speak today

### A13 — the picture that knows too much
- **sentence:** "That picture is about to leave and it still carries its metadata, do you want it wiped?"
- **verb:** [wipe its metadata]
- **trigger:** a fresh image + a share-class window takes focus; the image still carries an EXIF/XMP marker
- **status:** [new] wait — no EXIF stripper ships; this is the batch's only [new]

### A14 — the clean sleep
- **sentence:** "I'm about to sleep and I still hold your clipboard history, do you want it cleared?"
- **verb:** [clear my clipboard history]
- **trigger:** session enters sleep while the history store is non-empty
- **status:** **dormant** — shares A10's logind listener; verb itself [live]

### A15 — the steady hand
- **sentence:** "You're in the pixel editor, do you want the pointer eased for it?"
- **verb:** [ease the pointer]
- **trigger:** focus lands on a precision-class window (image/CAD/pixel editors) and stays
- **status:** [cheap]-pending wait — a runtime `input.sensitivity` write on the eval rail

---

## How many can speak today

- **12 of 46 speak on today's engine**: batch 01's 10 live, batch 02's A09 + A12.
- **34 wait** on the named work above — the tally row by row.