# cut-50.md — batch 01, F5

*The usefulness cut, per conditions.md §1 (F5) and Constitution III + VII. One
question asked of all 209 survivors: **would a real user THANK Golem for this
offer?** Not "is the habit real" (F2 settled that), not "can we sense it" (F3),
not "is it clean" (F4) — would the sentence, arriving unbidden, land as a
service? Killed: nags, reminders-to-exist, anything the user's own reflex does
faster than they can read the sentence, and imagined helpfulness.*

**Result: 40 of 209 survive (169 killed, of which 60 were absorbed into a
surviving sibling rather than discarded).** No padding toward 50 and none toward
40 — the number is where the razor stopped. It landed on 40 by itself, which has
a consequence worth stating plainly up front: **F6 is no longer a cut.** Its job
becomes the utterance-economy audit, the category ceiling, and the near-duplicate
sweep; when the slop hunts kill, replacements come from the explicit bench below
(R01–R12), and if the hunts kill more than the bench can cover, batch 1 ships
fewer than 40 and says so (Constitution VII).

This is where the funnel's real killing happened. F4 predicted it: an engine that
is network-incapable, blind behind the browser glass and forbidden raw keys had
already disposed of the privacy villains, so the survivors arrived clean — and
then two thirds of them turned out to have nothing to offer.

## The five F5 doctrines (binding on F6, the hunts, and every P5 block)

1. **Already an OPTION is not an ACTION.** The shipped pill surfaces the verb
   whenever the context is live; a sentence that speaks first about the same verb
   adds noise, not initiative. Verified against options-catalog.md §4:
   `search-the-error` (§4.11), `downloads.open`/`downloads.extract` (§4.28),
   `selection.define` (§4.41), `system.empty_trash` (§4.45), `git.show_commit`
   (§4.36), `coding.terminal_here` (§4.12/13), `system.battery_dim` (§4.29),
   `network.down` (§4.38), the reading-mode and open-url/open-path seams, and the
   amber mic/camera pills. **~22 kills** — the single largest kill family in F5.
   The OPTIONS surface is Golem's answer to "the user is already holding the
   thing"; ACTIONS are for when the user's hands are elsewhere.
2. **The one-keystroke test, and its exception.** If the user's own reflex is
   faster than reading the sentence, a per-instance offer is a toll, not a
   service (open-the-browser-at-login, the morning news site, `git status`,
   `git pull`, "[open the downloads list]"). The exception that proves the rule:
   a ONE-TIME offer of a standing rule that abolishes hundreds of future
   keystrokes is a gift, not a toll (V13 alias, V14 `ls`-after-`cd`, V31 window
   rules). Per-instance hand on a trivial act = toll. One sentence that deletes
   the reflex forever = gift.
3. **No verb, no action.** An insight with no hand to offer is a notification at
   best — the world's voice, not Golem's (Constitution II). The failing charger
   cable (R04) is the batch's finest observation and still fails this test.
4. **The hand-back rule.** Golem owes you a summary only of what Golem silenced.
   V05 (the call ended, here is what came in) survives because V04 did the
   muting; "here is what arrived overnight" dies, because the notification centre
   is one click away and nobody asked Golem to hold the door.
5. **Sense the state, never impute the motive; and never teach the user their own
   tool.** Headphones with nothing playing is a fact, "you are signalling busy"
   is mind-reading (U0162). "The launcher can do that, you know" (U0138) is a
   nag in a cardigan.

**Consolidation doctrine (how 60 of the 169 died):** one verb = one action.
Where a family of habits shared a single verb, the family collapsed into its
sharpest-evidence member and the rest are recorded as `ABSORBS:` on that line —
recoverable material for P5 if a block proves too crowded, not discarded. Five
collapses did most of the work: *quiet-the-desk* (call start), *window rules*
(float/move/monitor/workspace → one "open it that way?"), *the dock* (monitors +
outputs + clamshell), *device routing* (headphones, dock sink, the wrong mic),
and *watch-it-for-me* (CI page, PR page, any title carrying a progress number).

Survivor schema: `V01 (U T S H) [tag] (category) habit — T: trigger
[feasibility] — O: the offer and its verb — P: at-rest constraint (where F4
imposed one) — ABSORBS: absorbed siblings — !: flag for F6/the hunts`.
Feasibility tags on **T** are the catalog's (sensing); where the **verb** needs
work not yet shipped, O carries its own tag honestly.

---

### browsing — 1 of 13 survives

V01 (U0003 T0004 S0017 H0017) [reasoned] (browsing) hunts down the tab that is making sound — T: browser MPRIS is_playing while that window is unfocused or focus churns (media+window [live]) — O: "[mute it]" mutes the browser's pipewire stream, "[show me]" focuses the window — honest limit: MPRIS and pipewire resolve to the PLAYER, not the tab, so Golem mutes the browser and the user finishes the job — that is still the whole of the annoyance removed — ABSORBS: U0042 (the instant mute when something blares)

### communication — 5 of 22 survive (at the F6 ceiling)

V02 (U0015 T0018 S0061 H0075) [reasoned] (communication) pastes a canned reply for the recurring question — T: the same clipboard text (hashed) pasted on ≥3 separate days (selection [live] + hash counter [cheap]) — O: "[keep it as a snippet]" writes it into the clipboard box's snippet store, one keystroke away forever — P: hash + day-count at rest; the text itself is written ONLY on acceptance, where it becomes user-authored config
V03 (U0023 T0026 S0073 H0093) [reasoned] (communication) closes or hides sensitive windows before sharing the screen — T: is_screencasting goes true ([partial] today, [cheap] to finish feeding) — O: "[tuck the rest away]" moves every non-shared window to the special workspace and brings them back when the share ends (hyprctl [live]) — must land AT share-start, not after; privacy-POSITIVE — ! the one action in the batch that protects the user from an audience
V04 (U0024 T0027 S0074 H0094) [reasoned] (communication) turns on do-not-disturb for calls — T: mic goes live (audio [live]; the shipped call_dnd seam is the verb's floor) — O: "[quiet my desk]" = notifications held + playback paused, one pill; the ladder's automatic form is the whole value — ABSORBS: U0017 (the recurring standup hour), U0043 (pause the music when a call starts), U0116 (notes-during-calls, which belongs in this action's gear, not in its own sentence)
V05 (U0026 T0029 S0076 H0097) [reasoned] (communication) leaves the call and immediately checks what they missed — T: mic goes inactive after a long live stretch + notifications.active_count>0 (audio+notifications [live]) — O: "[show me]" releases the queue Golem itself held — doctrine 4: this exists BECAUSE V04 did the silencing — ABSORBS: U0119 (DND ends with a queue waiting)
V06 (U0032 T0036 S0093 H0117) [reasoned] (communication) dismisses a notification popup without acting on it — T: notification closed within seconds with no focus change to its app, same source ≥N times (notifications [live]) — O: "[mute <app>]" sets a per-app notification rule in the daemon — P: per-app dismiss counter only, never notification contents — the purest "you have already voted" action in the batch

### media — incl. gaming — 5 of 33 survive (at the F6 ceiling)

V07 (U0044 T0049 S0109 H0136) [reasoned] (media) pauses the video when leaving the desk — T: manual pause followed within seconds by idle, ≥3× (media [live] + logind IdleHint [cheap]) — O: "[pause when I step away]" — assisted form pauses now, standing form pauses on idle and leaves the resume to the user (never auto-resume: returning to noise is worse than returning to silence)
V08 (U0057 T0063 S0133 H0162) [reasoned] (media) replays the same focus playlist every work day — T: same MPRIS title/artist hash recurring daily in work hours (media [live]) — O: "[put it on]" launches the player if needed and presses play — P: one recurring-title hash + counter at rest; name-at-offer-time reads the live title — ! weakest verb on the list: MPRIS can press play, it cannot queue a named playlist without the service's API, so the offer is best-effort on whatever the player has loaded. First candidate to die in slop hunt #1 if the sentence cannot survive that honesty
V09 (U0060 T0066 S0138 H0169) [reasoned] (media) turns on do-not-disturb before gaming — T: a game class goes fullscreen (window+notifications [live]; shipped fullscreen_dnd is the verb's floor) — O: "[game mode]" = DND + the performance profile (powerprofilesctl [cheap]), restored on exit — ABSORBS: U0059 (the recurring evening game hour — the class is already public in the window list; duration stays nobody's business, F4 doctrine 2), U0153 (the manual profile switch)
V10 (U0065 T0072 S0146 H0183) [reasoned] (media) pauses a how-to video to perform the step just shown — T: pause → focus to terminal/editor → resume, ≥3 cycles in one session (media+window [live]) — O: "[keep it on top]" floats, shrinks and pins the player window so the loop stops (hyprctl [live]) — strictly better than the browser's own PiP because it works for any player — ABSORBS: U0008 (the how-to video itself), U0048 (the manual PiP), U0176 (the always-on-top window the day is arranged around)
V11 (U0066 T0073 S0147 H0184) [reasoned] (media) watches at a whisper volume late at night — T: playback starting with the sink in its bottom decile after a recurring late hour, ≥3 nights (audio+media+clock [live]) — O: "[keep it quiet after midnight]" caps the sink's volume in the late window and lifts the cap in the morning — the ears' version of the sunset prototype; about the DESK, never about the hour being late

### files — 1 of 10 survives

V12 (U0078 T0085 S0173 H0237) [reasoned] (files) re-navigates to Downloads inside the site's own file picker — T: an xdg-desktop-portal file-chooser window appears while a download completed in the last minutes (window+downloads [live]) — O: "[use <file>]" hands the fresh download straight to the picker (portal/clipboard path; [cheap]) — the moment is two seconds long and the annoyance is universal — ABSORBS: U0007 (the saved image), U0011 (opening the downloads list), U0070 (sorting Downloads by newest)

### coding/work tools — 2 of 31 survive

V13 (U0093 T0100 S0204 H0283) [reasoned] (coding) keeps aliases for the commands they type most — T: the same long command recurring across ≥3 days via the shipped zsh bridge [live] — O: "[make it `gsu`]" appends to the shell-owned alias file the user's zshrc already sources — P: name-at-offer-time — hash + count at rest; the offer quotes the LIVE N+1th typing and no command text ever sits on disk — the purest habit action in the funnel: the user's own repetitions are the tutorial, the alias is the unlock — ABSORBS: U0097 (the daily ssh target, same verb), U0107 (the cheat-sheet file, same urge)
V14 (U0094 T0101 S0205 H0285) [reasoned] (coding) types `ls` right after `cd` in one unbroken reflex — T: the cd→ls pair via the shell bridge, ≥20× across days [live] — O: "[do it for me]" adds a chpwd hook to the shell-owned file — ! flagged borderline under doctrine 2: the per-instance win is 300 ms, which is nothing; the standing rule deletes the reflex permanently, which is the best keystroke-per-utterance ratio in the batch. Survives as the doctrine's test case; the hunts should decide whether charm is value

### writing/docs — 1 of 7 survives

V15 (U0112 T0119 S0237 H0337) [reasoned] (writing) pastes with Ctrl+Shift+V to strip the formatting — T: rich-text mimetype on the clipboard followed by a plain-paste keystroke in an editing context, ≥3× (mime flag [cheap]) — O: "[keep it plain]" — the shell OWNS the clipboard, so it can re-offer the selection as text/plain only; standing form strips rich text on every copy, gear keeps an exception list — a universally hated annoyance the shell is uniquely positioned to end

### system/settings — 5 of 9 survive (at the F6 ceiling)

V16 (U0117 T0124 S0256 H0381) [reasoned] (system) defers the system-update prompt for another day — T: deploy.stale_generation / not_activated, with the defer counted ≥3× [live] — O: "[apply it when I shut down]" — NixOS switches on the next boot anyway, so the offer is honest and free; the gear holds the only other sane option ("ask me again in a week") — ! nag risk is real: this must escalate toward silence on refusal, never toward repetition (Constitution IV) — ABSORBS: U0149 (suspends for weeks, never reboots)
V17 (U0118 T0125 S0257 H0387) [reasoned] (system) silences notifications for an hour to focus, by hand, at the same times — T: DND toggled manually at a recurring hour, ≥3 days (daemon state + clock [live]) — O: "[every day at this hour]" writes the standing quiet window — the textbook ladder: the hand the user already raises, signed into a rule they can read and revoke — ABSORBS: U0199 (the guarded quiet hour before colleagues arrive), U0114 (fullscreen writing, which the shipped fullscreen_dnd already covers)
V18 (U0122 T0129 S0263 H0415) [reasoned] (system) switches keyboard layout many times a day — T: active_layout changes correlated with the focused window's class, ≥3 days ([partial] today, [cheap] to finish feeding) — O: "[remember the layout per app]" — the shell owns the focus stream, so it can set the layout on focus change (verb [new] but small) — ! audience flag for F6: dozens of times a day for bilingual users, never for monolingual ones. The EVERYDAY law is about the practitioner, not the population (F2's strictness), so it stands — but it is the batch's narrowest audience
V19 (U0124 T0131 S0268 H0429) [reasoned] (system) annotates a screenshot with arrows before sharing it, or wants the text out of it — T: a fresh file in the screenshots dir ([cheap] watcher; [live] via the shell's own binding) — O: two pills, the anatomy's rare maximum: "[draw on it]" (annotator) and "[copy its text]" (OCR at the user's click, output to the user's clipboard, nothing stored) — P: OCR is transient classification of the user's own screenshot, never stored (F4 doctrine 4) — ABSORBS: U0123 (the OCR habit), U0071 (region screenshots many times a day)
V20 (U0125 T0132 S0270 H0436) [reasoned] (system) toggles the night-light shade off to judge a photo's colours — T: hyprsunset active + an image viewer/editor class takes focus (shell state+window [live]) — O: "[true colours for a minute]" disables hyprsunset and restores it automatically — the prototype's mirror twin, and the proof that Golem can notice its own help arriving at the wrong moment

### search/launch — 2 of 13 survive

V21 (U0129 T0136 S0276 H0450) [reasoned] (search/launch) sometimes launches the wrong thing and closes it without shame — T: launcher fires app X, that window closes within seconds, ≥3× for the same query→app pair (first-party launcher + window [live]) — O: "[stop putting it first]" adjusts the launcher's own ranking — ranking learning surfaced as an offer instead of silent ML: Law VI.4 made mechanical (the disclosure IS the feature), at zero privacy cost because the query was always the shell's own signal
V22 (U0137 T0144 S0295 H0477) [reasoned] (search/launch) launches a new instance rather than hunting for the lost window — T: the launcher fires an app whose class already has a live window (launcher+window [live]) — O: "[go to the one you have]" focuses the existing window (and the gear can make it the default for that app) — prevents the mess instead of cleaning it up

### power/battery — 4 of 18 survive

V23 (U0139 T0146 S0308 H0502) [reasoned] (power) plugs in the moment the number slips below a personal comfort line — T: is_charging flips at a recurring personal battery_pct, median over ≥3 occurrences (metrics [live]) — O: "[tell me at 38%]" replaces the distro's late, generic warning with the user's own line — the trigger is the user's demonstrated threshold, not a number a designer picked — ! the only survivor whose verb is purely a future sentence; keep it one line and let refusal kill it permanently
V24 (U0141 T0148 S0311 H0505) [reasoned] (power) keeps the laptop plugged in all day at the desk — T: is_charging near-constant across ≥3 sessions (metrics [live]) — O: "[stop at 80%]" writes charge_control_end_threshold (sysfs; [cheap] where the hardware has it, absent where it does not — ThinkPads yes, Intel MacBooks no, so the action must not exist on machines that cannot honour it) — battery longevity most users never hear about, one click, and exactly Golem's old-hardware care — ABSORBS: U0142 (unplugging at 100% out of tenderness)
V25 (U0144 T0151 S0314 H0510) [reasoned] (power) flips on power-saver mode when the percentage starts to matter — T: the profile change (or the manual dim) at a low battery, recurring (powerprofilesctl [cheap] + metrics [live]) — O: "[stretch it]" = power-saver + a backlight step down + keyboard backlight off, one pill, restored on charge — ABSORBS: U0143 (the manual dim, whose per-instance form is the shipped battery_dim OPTION), U0147 (keyboard backlight off), U0155 (unplugging for the couch)
V26 (U0154 T0161 S0327 H0541) [reasoned] (power) jiggles the mouse to keep the screen from dimming mid-read — T: a tiny cursor burst within seconds of the idle-timeout boundary, ≥3× (hyprctl cursor position [cheap]; pointer state, never input capture) — O: "[keep it awake]" takes an idle inhibitor for the current window, dropped on focus change — the user is already telling Golem with their wrist; this just listens

### audio/devices — 3 of 14 survive

V27 (U0067 T0074 S0148 H0188) [reasoned] (audio/devices) switches playback to the headphones by hand every time they connect — T: a default-sink change to the same device within seconds of that device appearing, ≥3× (pw events [cheap]) — O: "[follow my headphones]" writes a device-preference rule (wpctl set-default on appearance) — the gear covers the input side too, which is why it absorbs the mic case — ABSORBS: U0158 (re-picking the output after every dock), U0160 (the bluetooth connect ritual), U0164 (the mic that keeps reverting to the webcam)
V28 (U0161 T0168 S0341 H0582) [reasoned] (audio/devices) curses the headset dropping to the tinny profile when the mic engages — T: the card profile flips to HSP/HFP as capture starts (pw profile [cheap]) — O: "[keep the good sound]" holds the A2DP profile and takes the mic from the laptop instead — the single most thanked fix on Linux audio, and one almost no user knows is possible; Golem knowing it is the entire value
V29 (U0167 T0174 S0347 H0608) [reasoned] (audio/devices) checks the monitors are still arranged left-of-laptop after every replug — T: a monitor add followed within seconds by a manual re-arrangement, the same layout ≥3× (hyprland events [live]) — O: "[remember this desk]" persists the monitor layout (and, in the gear, the clamshell rule and this dock's audio output) and applies it on every arrival — ABSORBS: U0156 (the dock's power double-check), U0165 (the clamshell moment), U0166 (the HDMI blink), U0170 (the evening TV input)

### window/workspace management — 3 of 14 survive

V30 (U0171 T0178 S0353 H0626) [reasoned] (window/workspace) alt-tabs between the same two windows dozens of times an hour — T: focus alternation locked to one window pair, ≥N flips inside a short window (focus stream [live]; live state, no stored pair diary) — O: "[put them side by side]" tiles the pair on the current workspace — the alternation is the user shouting the request in the only language the focus stream speaks — ABSORBS: U0172 (snapping halves by hand), U0173 (the editor/browser transcription pair), U0092 (the save-and-check hot-reload loop)
V31 (U0180 T0187 S0382 H0664) [reasoned] (window/workspace) sends a window to its workspace with a keystroke the moment it opens — T: a move/float/monitor-change within seconds of a class's window opening, the same correction ≥3× (hyprland [live]; class→slot map, an aggregate) — O: "[open it there from now on]" writes the window rule at runtime and persists it to the shell-owned rules file — config authored by observation instead of by editing a file the user has never opened — ABSORBS: U0178 (ferrying an app off the wrong monitor), U0179 (one workspace per project), U0183 (the app that refuses to be tiled)
V32 (U0182 T0189 S0391 H0674) [reasoned] (window/workspace) babysits a progress number in a window title, or a CI/PR page in a tab — T: repeated focus visits to a window whose title carries a changing NN% or a strong CI/PR state marker (title+window [live]; the detector reads the number and the marker, never the rest of the title) — O: "[tell me when it changes]" watches the title Golem already polls and fires one notification at the transition — converts polling into waiting, using nothing the engine was not already collecting; the browser tab does all the fetching, so the engine stays network-incapable — ABSORBS: U0085 (watching CI until it turns green), U0102 (re-checking the PR page for comments)

### security/privacy rituals — 5 of 8 survive (at the F6 ceiling)

V33 (U0185 T0192 S0404 H0691) [reasoned] (security) locks the screen with the shortcut every time they stand up — T: manual lock events clustering before idle, ≥3× (hypridle/loginctl [cheap]) — O: "[lock as soon as the screen sleeps]" shortens the gap the user keeps closing by hand — ! flag for F6: if the distro's default already locks on sleep, the habit is evidence the TIMEOUT is wrong, and the offer must be about the timeout or not exist
V34 (U0186 T0193 S0409 H0698) [reasoned] (security) unlocks with the fingerprint reader, falls back to the password when it sulks — T: fprintd verify outcomes, failure ratio over a window (dbus [cheap]) — O: "[add another finger]" runs fprintd-enroll — P: attempt-outcome counter only; no biometric data is ever visible to the engine — the reader that half-works is a Golem speciality, and this is the rare action that repairs the hardware relationship instead of working around it
V35 (U0187 T0194 S0411 H0701) [reasoned] (security) unlocks the password vault once and lets it sit open all day — T: a vault class present and unlocked across hours, with the desk idle (window [live] + idle [cheap]) — O: "[lock it]" locks the vault, the gear offers "whenever I walk away" — privacy-POSITIVE; the sentence must describe the door, never the person ("your vault is still open", never "you left it open")
V36 (U0188 T0195 S0413 H0710) [reasoned] (security) copies the password from the vault and worries about the clipboard afterwards — T: a clipboard write while a vault class is focused (selection+window [live]) — O: "[clear it in 30 seconds]", standing form "always" — P: a provenance flag ONLY; the engine must never classify, hash or store a vault-born clipboard — its existence is the entire signal — the best privacy-to-effort ratio in the batch
V37 (U0192 T0199 S0421 H0732) [reasoned] (security) erases the browser history before closing, every time — T: the browser's "Clear browsing data" dialog title appears, ≥3× (title [live]) — O: "[do it every time I close the browser]" — the verb is local cleanup of the profile at the moment the profile unlocks, i.e. browser exit (verb [new], feasible, unshipped) — P: it may know THAT, it never knows WHAT (Constitution §III/§VI.2's own example) — ! the constitution's illustration has standing here, but the verb is the only [new] one among the 40; if P5 cannot write it honestly, it dies with a note rather than a hand-wave

### health/ergonomics — 1 of 4 survives

V38 (U0196 T0203 S0430 H0809) [reasoned] (health) turns the brightness down at night when the display turns torch — T: a late hour (or post-sunset) with the backlight still at day level, and the user's own manual correction ≥3× (backlight+clock [live]) — O: "[dim it for the evening]" steps the backlight to the user's own observed evening level — ! near-neighbour of the live sunset prototype: same moment, different knob (brightness, not colour temperature). F6 must either justify both or fold this into the prototype's gear — ABSORBS: U0194 (the morning brightness nobody brings back down)

### time-of-day rituals — 2 of 8 survive

V39 (U0197 T0204 S0434 H0818) [reasoned] (time-of-day) opens the same apps in the same places every morning without deciding to — T: a recurring morning class SET plus a stable class→slot map, ≥3 mornings (window+clock [live]) — O: "[have the desk ready]" launches the set and places it; the ladder's automatic form runs at login — P: set-not-order — the class set + a first-focus hour histogram; a per-morning ordered log is a diary and is not needed for the offer — ABSORBS: U0175 (rebuilding the layout by hand after every reboot), U0001 (the browser as the first act), U0013 (the morning webapp set), U0014 (email first thing), U0027 (chat right after login), U0036 (music as the first act), U0079 (the terminal as the first act)
V40 (U0203 T0210 S0451 H0853) [reasoned] (time-of-day) closes the work apps at quitting time as the act of leaving — T: the work-class set closing inside a recurring end-of-session window, ≥3 days (window+clock [live]) — O: "[close up]" closes the work set and stops playback — V39's mirror, and the pair together are the only two actions in the batch that frame the whole day — ! must never speak at the hour; it speaks when the user has ALREADY begun leaving (the first two closes are the trigger), or it becomes a clock telling you to go home — ABSORBS: U0184 (closing every window before shutdown), U0068 (the music off as the closing act), U0034 (the last email check), U0035 (the call app left running)

### extinct at F5 — learning/reading (5→0), and finance/shopping (already 0 at F4)

*Learning/reading is the instructive extinction: every survivor's verb was already
a shipped OPTION (`selection.define` and its siblings) or needed the network. The
structural reason is the same one that thinned files (10→1) and writing (7→1):
**when the user is already holding the object, Golem has nothing to speak first
about.** The selection, the file and the paragraph are OPTIONS territory by
design. ACTIONS live where the user's hands are NOT — at a threshold they did not
notice, a device that just arrived, an annoyance about to repeat for the fiftieth
time.*

## The bench — runner-ups for the slop hunts

*Killed at F5, but on judgement rather than on law — promote from here (in order)
when a hunt kills a survivor. R-ids, deliberately not V-ids: the survivor count
stays honest at 40.*

R01 (U0031 T0035 S0092 H0116) holds chat to set times instead of live — "[hold chat between your reading times]" — killed as inferred preference (the user never declared the rhythm; V17 is the version they actually demonstrated). The strongest bench entry.
R02 (U0121 T0128 S0262 H0412) light/dark by mood or season — "[dark at sunset]" — killed as not-daily (mood and season are not a daily act) and as the third sunset sibling after the live prototype and V38.
R03 (U0198 T0205 S0435 H0819) reads the overnight notifications first — killed by doctrine 4 (Golem did not silence the night) and by the notification centre being one click away.
R04 (U0150 T0157 S0323 H0529) the charger that only bites at one angle — is_charging flapping within seconds. The batch's finest observation and a doctrine-3 casualty: no hand exists. Promote ONLY if a verb appears; otherwise it belongs to the notification daemon, not to ACTIONS.
R05 (U0145 T0152 S0315 H0511) the app draining the battery fastest — "[quit it]" is a destructive verb on unsaved work; "[show me]" is useless. Shelved on verb risk, not on value.
R06 (U0074 T0081 S0168 H0225) the same USB stick, the same folder — "[open it]" saves one click, and the constitution's own USB example is the *photo-import* moment, which F2 already sent to the weekly tier. Batch 3's material.
R07 (U0189 T0196 S0415 H0720) the VPN before anything internal loads — killed because identifying "internal" means guessing; survives only if the user's own app→VPN sequence carries it.
R08 (U0193 T0200 S0426 H0764) bigger text in the evening — fourth sunset sibling; real, but the family is full.
R09 (U0168 T0175 S0349 H0610) undocks without ejecting — "[unmount it first]" prevents real data loss but the moment is not daily for most.
R10 (U0174 T0181 S0367 H0640) the windows hidden this morning and forgotten — borderline nag ("you forgot something"), and the verb is ambiguous between show and close.
R11 (U0063 T0069 S0142 H0176) the launcher the game dragged along — "[close Steam too]" is a genuine tidy-up one click wide; shelved as not-daily and small.
R12 (U0164 T0171 S0344 H0592) the mic that keeps reverting to the webcam — absorbed into V27; split it back out if V27's block proves too crowded, because the call case deserves its own sentence.

## Casualties worth noting

- **U0009 search-the-error (T0010 S0034 H0038) — doctrine 1's namesake.** A command exits non-zero and Golem offers to search the error: perfect moment, real value, and *already shipped as an OPTION* (options-catalog.md §4.11 — the shell bridge's actionable "Search the error"). This is the boundary the whole batch had to learn: OPTIONS answer the context the user is standing in; ACTIONS speak about what the user has not noticed yet. Twenty-two kills followed this one.
- **U0002 the morning news site (T0002 S0011 H0011)** — F3 fought to keep one site-title carrier alive through the per-site massacre, and F5 killed it in a sentence: Ctrl+T and two letters is faster than reading "do you want your news?" The offer taxes a reflex it cannot beat.
- **U0053 browsing the platform without ever pressing play (T0059 S0126 H0155)** — F4 deferred it explicitly ("F5 must find a thankable offer or kill it"). There is none. Every sentence Golem could say about twelve minutes of indecision is a comment on the user's character.
- **U0162 headphones with nothing playing (T0169 S0342 H0586)** — doctrine 5. The state is clean and live; the habit's entire meaning is the MOTIVE (signalling busy), and an OS that offers DND because it inferred your social intent has started reading minds.
- **U0090 forty-seven activity switches an hour (T0097 S0197 H0275)** — [observed], beautifully sensable, and unutterable. Every available sentence is a focus nag, and the only verb (blocking things) is a punishment the user did not ask for.
- **U0190 the tenth sudo password of the day (T0197 S0416 H0723)** — the verb would be extending the sudoers timeout. **Golem does not offer to weaken your own authentication**, however sincerely you sigh at the prompt. A new law in practice, if not in text.
- **U0138 launching the calculator app when the launcher can already do it (T0145 S0302 H0488)** — the tutorial nag. Teaching users their own tool is a feature the designer wants, not help the user demonstrated; doctrine 5's second half.
- **U0204 scrolling back through the day's commits (T0213 S0460 H0879)** — F4 flagged it as F5's case. The thin version is a shortcut for a command typed in three seconds; the rich version is the day-diary F3 already killed (S0218). Nothing survives in between.
- **U0200 the lunch hour (T0207 S0443 H0832)** — F4 asked F5 to find the thankable offer. A median lunch hour is a fact with no hand attached; any offer built on it (quiet, away-status, "enjoy it") is either V17 in disguise or a greeting card.
- **U0082 / U0083 commit hygiene (T0089/T0090)** — "you wrote a one-line message", "you staged without reading the diff". Both sentences are a code reviewer Golem was never hired to be; the teacher's voice is out of register (Constitution II) before privacy even gets a turn.
- **U0021 unmutes to speak, re-mutes after (T0024 S0070 H0088)** — push-to-talk is a feature request wearing a trigger's clothes. The habit is real, the offer is something the user must learn and bind; an ACTION cannot hand over a new motor skill in one click.
- **U0019 joins meetings muted (T0022 S0068 H0085)** — the verb lives inside the meeting app, where the engine has no reach. No verb, no action (doctrine 3) — and muting the pipewire source instead would make the user inaudible in a way the app's own button will not explain.
- **U0069 Downloads as the universal dumping ground (T0076 S0150 H0191)** — the user demonstrated NOT sorting. Offering to file their downloads by type is the designer's tidiness wearing the user's habit as a costume, and it moves files the user still knows how to find.
- **U0105 the full suite before every push (T0112 S0220 H0310)** — a pre-push hook the user did not author is a trap: the one day they need to push red, Golem is standing in the doorway. Standing rules must be revocable in the moment they bite, and this one is not.
- **U0151 plugging in before the call (T0158 S0324 H0538)** — clean, recurring, sensable, and mute: the insight ("you are at 31% and your call is in four minutes") has no verb. A notification at most; Golem does not speak to say things.
- **U0040 looping one song / U0046 the 1.5× podcast (T0044/T0051)** — the player already has a loop button and already remembers the rate. Offering to press a button the user is resting their hand on is the utterance economy run in reverse.
- **U0208 the daily flashcard review (T0218 S0473 H0963)** — a reminder to exist. Conditions §1 names this kill by name, and the category it ends (learning/reading, 5→0) is the one where OPTIONS already does everything ACTIONS could.
- **U0033 clearing all notifications in one sweep (T0037 S0094 H0118)** — the act is already one gesture; the only richer offer (auto-expiry) is V06 with less evidence behind it.

## Going into F6

**Distribution (F6's ~5-per-category ceiling, Constitution IV):** communication 5,
media 5, system 5, security 5 — all four exactly AT the ceiling, none over.
Then window/workspace 3, audio/devices 3, power 4, coding 2, search/launch 2,
time-of-day 2, browsing 1, files 1, writing 1, health 1. Learning/reading and
finance/shopping are extinct. **The ceiling is therefore already satisfied and is
not a constraint on F6** — which is the clearest sign that F5 did F6's work.

**What F6 must actually do, since it has nothing left to cut:** (a) the
utterance-economy audit — count the sentences a single user would hear per day
across all 40 and check that the set still feels rare (the morning/evening pair,
the call pair and the sunset family are the ones that stack); (b) resolve three
flagged near-neighbour risks — V38 against the live sunset prototype, V04/V05 as
one action or two, V13/V14 as one "standing shell rule" action or two; (c) decide the three flagged
singles — V08 (the weak playlist verb), V14 (charm vs. value) and V37 (the only
[new] verb) — explicitly rather than by omission; (d) confirm the four at-ceiling categories are
not near-duplicates inside themselves.

**Honest caveat for SUMMARY.md:** the funnel's stated shape (250→100→50→40) did
not survive contact with the material. The engine's architecture killed the
privacy villains before F4, so the cut-100 stage could not cut, and the
usefulness bar at F5 did all the work at once — 209→40 in one pass. The
compensation is that every one of the 40 carries a named verb, a named moment and
a stated at-rest footprint; the bench (R01–R12) is thin by design, so if slop hunt
#1 and #2 are doing their job, batch 1 may well ship 35–38 actions rather than 40.
That is the constitution's instruction, not a failure of the run.
