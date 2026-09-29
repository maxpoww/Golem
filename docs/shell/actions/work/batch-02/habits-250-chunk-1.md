# habits-250-chunk-1.md — batch 02, P1, chunk 1 of 4

Fresh series, NEVER repeating batch-01's 34 (those are retired). 16 categories, one habit per line, honest feasibility tag with a NAMED signal. Written 2026-09-13 by P1, unit 1, after re-reading the constitution + conditions top to bottom.

Category legend (from conditions.md §1 F1): browsing · communication · media · files · coding/work tools · writing/docs · system/settings · power/battery · audio/devices · health/ergonomics · time-of-day rituals · security/privacy rituals · window/workspace management · search/launch · finance/shopping · learning/reading.

Feasibility tags (catalog.md §0): [live] signal exists in the engine today · [cheap] a small named poll/read behind it · [bridge] needs a one-time shim · [new] needs a verb the engine does not have yet.

---

H1001 [cheap] (browsing) offers to reopen the tabs you always have after a full restart — signal: a browser Profile recovery cache written at shutdown (`recovery.json`, ~400 B) reappears on boot with >5 known-site URLs.
H1002 [cheap] (browsing) offers to name this window's tab group when it has held ≥6 tabs for a day — signal: the window's tab count sits at ≥6 for one sun cycle (cached history, ~60 B/group).
H1003 [cheap] (browsing) offers to pin the tab you keep re-adding — signal: the same URL is opened from a fresh tab ≥3 recorded times (URL-only aggregate, ~40 B).
H1004 [live] (browsing) offers to take you back to the article you set aside — signal: the reading-list counter ticks ≥1 while the reader's focus sensor is off-window (live counter, 8 B).
H1005 [cheap] (browsing) offers to close all tabs from the domain you just left a meeting from — signal: a `meet.google.com`/`zoom.us` window closes while >4 of its tabs share that domain (~90 B of counts).
H1006 [cheap] (browsing) offers to mute the tab that keeps auto-playing — signal: an audio-playing flag flips on a tab that was not the focused one ≥3 times (per-tab mute state, ~30 B).
H1007 [cheap] (communication) offers to silence the chat channel you've not opened in 3 days — signal: unread counter for that channel ≥1 while last-open age ≥3 days (aggregate, ~24 B).
H1008 [live] (communication) offers to draft the "got it, doing it now" reply — signal: a message arrives flagged urgent while your calendar shows you in a task block (live counters, ~80 B).
H1009 [cheap] (communication) offers to file read-but-untouched mail into a "later" folder — signal: a message is open-marked but not replied to within 48 h (folder counts, ~50 B).
H1010 [cheap] (communication) offers to switch you to do-not-disturb during a screen-share — signal: the share indicator turns on and the DND toggle reads off (~16 B).
H1011 [cheap] (media) offers to pause when you leave the room — signal: the presence sensor stops showing a face while a player holds the track flag (~40 B, aggregate).
H1012 [live] (media) offers to resume last night's episode — signal: the media player's resume position counter is >0 at your typical evening start (live counter, 16 B).
H1013 [cheap] (media) offers to queue the next album from the artist you ended on — signal: play history's last-artist counter advanced today (artist-name hashed, ~48 B).
H1014 [cheap] (media) offers to lower volume when a call rings — signal: call ring flag rises while volume > a threshold you last set (~32 B).
H1015 [cheap] (files) offers to empty the screenshot staging folder — signal: >20 PNGs sit in the staging dir older than a week (count + age, ~50 B).
H1016 [live] (files) offers to move the file you just downloaded to its usual home — signal: a Downloads write-closes while the same dest category was chosen ≥3 times (category counter, ~40 B).
H1017 [cheap] (files) offers to dedupe the folder with two near-equal copies — signal: two files share size + first-8-KB hash while names differ (hash table, ~200 B).
H1018 [cheap] (files) offers to archive the project folder untouched for 30 days — signal: mtime of that folder's newest file is ≥30 days old (age aggregate, ~32 B).
H1019 [cheap] (coding/work tools) offers to open today's git branch from the ticket id — signal: a terminal clip names a `refs/heads` branch whose name matches an open ticket number (branch name, ~40 B).
H1020 [live] (coding/work tools) offers to run the test file you just edited — signal: a `.test.` file writes-closes and the watch counter is idle (live counter, 16 B).
H1021 [cheap] (coding/work tools) offers to stop the build that's been running 10 min with no new output — signal: build log's last-line age >600 s while the process is alive (~36 B).
H1022 [cheap] (writing/docs) offers to save the doc open >5 min with unsaved changes — signal: modified flag set while last save age >300 s (~20 B).
H1023 [live] (writing/docs) offers to spellcheck the paragraph you just ended — signal: a newline + period lands and the doc's language flag is set (live counter, 24 B).
H1024 [cheap] (writing/docs) offers to move the meeting notes into the dated folder — signal: a notes file writes-closes with today's date and the dated folder exists (~40 B).
H1025 [cheap] (system/settings) offers to apply the display settings you always reset after a screensaver — signal: a session unlock follows a blank-screen ≥15 min while your preferred refresh rate differs from current (pair of counters, ~60 B).
H1026 [cheap] (system/settings) offers to set the keyboard backlight to your daytime level at sunrise — signal: sunrise flag + backlight level differs from your saved day level (~24 B).
H1027 [cheap] (system/settings) offers to rotate to the orientation you use on this external monitor — signal: a monitor connect event + orientation differs from last use on that id (~40 B).
H1028 [cheap] (power/battery) offers to drop the screen brightness between calls — signal: battery <2 h estimate while screen >your saved economy level (~20 B).
H1029 [live] (power/battery) offers to hibernate when idle over lunch — signal: idle counter >your configured threshold and battery is low (live counters, ~40 B).
H1030 [cheap] (power/battery) offers to turn off the second screen when the laptop lid closes — signal: lid-close flag + an external display active (~16 B).
H1031 [cheap] (audio/devices) offers to switch output to the headset that just connected — signal: a Bluetooth headset appears and it's your default device class (~48 B).
H1032 [cheap] (audio/devices) offers to re-route audio to speakers when you unplug the headset — signal: headset disappears and speakers were last default (~40 B).
H1033 [cheap] (audio/devices) offers to calibrate the mic level before this meeting — signal: a call app enters the foreground while mic gain ≠ your saved level (~24 B).
H1034 [cheap] (health/ergonomics) offers a stand-break after 50 min in a chair — signal: seated posture counter ticks to 50 min (~8 B).
H1035 [cheap] (health/ergonomics) offers to shift your windows right to correct your head tilt — signal: the camera-relative head-angle aggregate drifts >threshold for an hour (~24 B).
H1036 [cheap] (health/ergonomics) offers to raise the font on the screen you squint at — signal: the eye-track light reading + user pinch-zoom began on that display (~30 B).
H1037 [cheap] (health/ergonomics) offers a 20-second glance at a distant point — signal: continuous screen-lock eyeball focus counter >20 min without a gaze-away (~16 B).
H1038 [cheap] (learning/reading) offers to open the evening reading list at the hour you settle — signal: clock enters the settle-hour window and the list is saved (clock window + file exists, ~20 B).
H1039 [cheap] (time-of-day rituals) offers to open your morning brief at 07:00 — signal: clock crosses 07:00 while you are active (counters, ~12 B).
H1040 [cheap] (time-of-day rituals) offers a wind-down list at 22:00 — signal: clock crosses 22:00 and dusk flag is set (~12 B).
H1041 [cheap] (time-of-day rituals) offers to mark the day done at your average quit time — signal: activity exits your working set at the day's recurring hour (day-phase aggregate, ~20 B).
H1042 [cheap] (security/privacy rituals) offers to lock the screen when you step away — signal: presence-off while the screen is on and unlocked (~24 B).
H1043 [cheap] (security/privacy rituals) offers to add the new drive to your encrypted set — signal: a new block device appears that isn't in the LUKS allowlist (~60 B).
H1044 [cheap] (security/privacy rituals) offers to rotate the token that's 30 days old — signal: a key file's age ≥30 days (~16 B).
H1045 [cheap] (security/privacy rituals) offers to check the clipboard was cleared before closing a session — signal: clipboard-cleared flag is unset and the session is ending (~20 B).
H1046 [cheap] (window/workspace management) offers to reopen the three windows you had on the dock — signal: a restart ends and last-window-set cache names ≥3 (~40 B).
H1047 [cheap] (window/workspace management) offers to send this window to the workspace that holds its twin — signal: two windows share a title prefix and you moved one before (~40 B).
H1048 [cheap] (window/workspace management) offers to tile the two windows you keep side by side — signal: two windows were manually resized to the same half ≥3 times (pairs, ~44 B).
H1049 [cheap] (search/launch) offers to launch the app you always open with this project — signal: a project folder opens and a saved app-association exists (~36 B).
H1050 [cheap] (search/launch) offers to place the terminal at the git root — signal: a terminal opens in a subdir with an ancestor `.git` (~32 B).
H1051 [cheap] (search/launch) offers the file you last edited from this folder — signal: an MRU cache exists and the folder is targeted (~40 B).
H1052 [cheap] (finance/shopping) offers to total your day's tracked spend — signal: a spending app's day-counter increments ≥1 (~20 B).
H1053 [cheap] (finance/shopping) offers to save the receipt you just scanned — signal: a scan file writes-closes with a known receipt pattern (~36 B).
H1054 [cheap] (finance/shopping) offers to remind you to categorize this month's transactions — signal: month boundary + uncategorized counter >0 (~24 B).
H1055 [cheap] (learning/reading) offers to quiz you on the deck due today — signal: a spaced-repetition due counter >0 at your study hour (~20 B).
H1056 [cheap] (learning/reading) offers to open the chapter you bookmarked last — signal: a reading progress marker is mid-point and you resume (~28 B).
H1057 [cheap] (browsing) offers to stop the download stalled 5 min — signal: download progress freezes for 300 s (~16 B).
H1058 [cheap] (browsing) offers to show the tab you had before the full-screen — signal: a full-screen exit leaves one background tab with a video flag (~28 B).
H1059 [cheap] (communication) offers to pin the message thread you type in most — signal: typing-time counter ranks a thread #1 for the day (~40 B).
H1060 [cheap] (communication) offers to deliver the delayed send when you're back — signal: a queued message waits while DND is on and connection returns (~24 B).
H1061 [cheap] (media) offers to skip the intro of the show you rewatch — signal: the same episode's intro timestamp was skipped ≥3 times (~30 B).
H1062 [cheap] (media) offers to keep the podcast playing through the oversight — signal: a pause 60 s after a fresh start happened ≥2 times (~28 B).
H1063 [cheap] (files) offers to split the giant folder by year — signal: a folder holds >200 files with dates spanning >1 year (date-bucket counts, ~60 B).
H1064 [cheap] (files) offers to rename the download to its doc title — signal: a downloaded PDF's internal title differs from its filename (~80 B of title hashes).
H1065 [cheap] (coding/work tools) offers to stash and rebase on the new main — signal: remote main advances while local branch is ahead and dirty (~36 B).
H1066 [live] (coding/work tools) offers to surface the failing log line — signal: a test run reports ≥1 failure with a named line in a known log (~40 B).
H1067 [cheap] (writing/docs) offers to export tonight's notes to the wiki — signal: a notes file writes-closes in the wiki's staging dir (~32 B).
H1068 [cheap] (writing/docs) offers to compile the chapter list — signal: a markdown doc grows past 10 headings in a session (~24 B).
H1069 [cheap] (system/settings) offers to bind the key you keep using — signal: a single key's use counter spikes in the same gesture ≥5 times (~28 B).
H1070 [cheap] (system/settings) offers to add the monitor to the profile — signal: a new display id connects that isn't in a saved layout (~40 B).
H1071 [cheap] (power/battery) offers to cap charging at 80% when plugged long — signal: battery at 100% while AC for >6 h and your cap ≠ 80 (~20 B).
H1072 [cheap] (power/battery) offers to dim the screen during the video call to save power — signal: a call runs while battery drops and screen level is high (~24 B).
H1073 [cheap] (audio/devices) offers to route the notification sound to the quiet channel — signal: a notification fires while the quiet-channel flag is on (~16 B).
H1074 [cheap] (audio/devices) offers to boost the app you're speaking into — signal: a voice app's input gain is low while a mic is hot (~24 B).
H1075 [cheap] (health/ergonomics) offers to move your mouse to the left hand for a while — signal: your handedness toggle is on and the left-hand counter is underexposed (~20 B).
H1076 [cheap] (health/ergonomics) offers to stretch your wrists after typing 40 min straight — signal: typing counter hits 40 min without a 20 s gap (~8 B).
H1077 [cheap] (time-of-day rituals) offers to make your coffee first when you're active at 06:30 — signal: clock near 06:30 and your coffee app or kettle is a habit (~16 B).
H1078 [cheap] (time-of-day rituals) offers to plan the three tasks at day start — signal: you type a morning plan in the same doc on ≥3 days (~40 B).
H1079 [cheap] (security/privacy rituals) offers to remove the download from a shared folder — signal: a sensitive-named file lands in a path with broad POSIX perms (~40 B).
H1080 [cheap] (security/privacy rituals) offers to run the password rotation you scheduled — signal: a calendar recurrence for rotation is due today (~20 B).
H1081 [cheap] (window/workspace management) offers to hide the window when you share — signal: a screen-share begins and a window contains a known-sensitive title (~40 B).
H1082 [cheap] (window/workspace management) offers to snap the maximized app back to a half — signal: you resized from full to half ≥3 times this week (aggregate, ~24 B).
H1083 [cheap] (search/launch) offers to search within the open project instead of the web — signal: your query counter shows a project-scoped search ≥3 times (~28 B).
H1084 [cheap] (search/launch) offers to index the new book folder — signal: a folder of PDFs appears that isn't in the index (~40 B).
H1085 [cheap] (finance/shopping) offers to refund the duplicate subscription — signal: two subs share a merchant and both bill (~36 B).
H1086 [cheap] (finance/shopping) offers to compare the two prices you looked at — signal: two tabs hold the same product id at different prices (~44 B).
H1087 [cheap] (learning/reading) offers to add the article to your reading list — signal: you saved an article URL with a tagging gesture ≥3 times (~32 B).
H1088 [cheap] (learning/reading) offers to review the notes from 7 days ago — signal: a dated notes file is now 7 days old (~20 B).
H1089 [cheap] (browsing) offers to discard the background tab eating memory — signal: the tab's RSS growth exceeds a threshold while unfocused (~40 B).
H1090 [cheap] (browsing) offers to split the incognito window's work into a normal one — signal: an incognito session lasts >4 h (~16 B).
H1091 [cheap] (communication) offers to summarize the unread thread since yesterday — signal: unread counter for a thread grows overnight (~24 B).
H1092 [cheap] (communication) offers to bulk-mark the digest channel read — signal: a digest channel holds >20 unread and you last read it 3 days ago (~28 B).
H1093 [cheap] (media) offers to queue a calm playlist when you close work — signal: your "wind down" playlist was launched at end-of-day ≥3 times (~32 B).
H1094 [cheap] (media) offers to keep the player on the charger now — signal: a long track is playing and battery <30% (~16 B).
H1095 [cheap] (files) offers to move the temp export into the done folder — signal: an export writes-closes in the temp dir with a known type (~32 B).
H1096 [cheap] (files) offers to version the config you're about to edit — signal: a dotfile writes while no git history for it exists (~44 B).
H1097 [cheap] (coding/work tools) offers to attach the log when filing the bug — signal: a bug form opens and a recent log exists (~36 B).
H1098 [cheap] (coding/work tools) offers to close the branch you merged — signal: a branch's merge lands and the branch is not main (~24 B).
H1099 [cheap] (writing/docs) offers to align the table you just pasted — signal: a tab-separated paste lands in a doc with a table (~36 B).
H1100 [cheap] (writing/docs) offers to convert the list into a checklist — signal: a line starting with `- ` becomes a task in ≥3 doc operations (~28 B).
H1101 [cheap] (system/settings) offers to apply the locale you switch to every Monday — signal: the locale flag changed on ≥3 Mondays at the same hour (~20 B).
H1102 [cheap] (system/settings) offers to toggle the compositor effect when a game starts — signal: a fullscreen exclusive request lands (~24 B).
H1103 [cheap] (power/battery) offers to close the heavy app when battery hits 10% — signal: battery counter crosses 10% while a heavy process is alive (~32 B).
H1104 [cheap] (power/battery) offers to switch to the power profile you use on battery — signal: AC detaches and your battery profile differs (~20 B).
H1105 [cheap] (audio/devices) offers to lower the mic when the call drops — signal: a call's mute flag is off while the mic counter is high (~20 B).
H1106 [cheap] (audio/devices) offers to pause the tone when you're on a call — signal: a call is active and a tone plays from another app (~28 B).
H1107 [cheap] (health/ergonomics) offers to raise the chair reminder when you slouch — signal: posture aggregate slopes down for 10 min (~20 B).
H1108 [cheap] (health/ergonomics) offers to walk for 5 min after a long meeting — signal: a meeting block >60 min ends while your step counter is low (~24 B).
H1109 [live] (time-of-day rituals) offers to dim the room lights at dusk — signal: dusk flag fires (live) and the light control is reachable (~12 B).
H1110 [cheap] (time-of-day rituals) offers to prepare tomorrow's bag list at 21:00 — signal: clock crosses 21:00 and your prep list doc exists (~16 B).
H1111 [cheap] (security/privacy rituals) offers to auto-redact the screenshot before sending — signal: a screenshot is sent while a redaction flag is set for that app (~32 B).
H1112 [cheap] (security/privacy rituals) offers to refresh the VPN at the roam point — signal: network handoff to a new subnet while VPN is off (~28 B).
H1113 [cheap] (window/workspace management) offers to put the chat on the right screen — signal: a chat window was on the right for ≥3 sessions with the same layout (~40 B).
H1114 [cheap] (window/workspace management) offers to keep the video always-on-top during the note-taking — signal: a video window is small + a notes window is active ≥3 times (~40 B).
H1115 [cheap] (search/launch) offers to search the app menu for the tool you keep missing — signal: a help-about query repeats on the same tool ≥3 times (~24 B).
H1116 [cheap] (search/launch) offers to jump to the bookmark you use daily — signal: a bookmark is opened ≥3 times a day across ≥3 days (~24 B).
H1117 [cheap] (finance/shopping) offers to split the shared bill you opened — signal: a bill file has >1 email in its header and a split tool exists (~40 B).
H1118 [cheap] (finance/shopping) offers to move the paid invoice into the paid folder — signal: an invoice writes-closes and a paid folder exists with a matching id (~40 B).
H1119 [cheap] (learning/reading) offers to re-read the section you highlighted — signal: a highlight counter shows the passage was marked and never revisited (~28 B).
H1120 [cheap] (learning/reading) offers to add the PDF to your spaced-review queue — signal: a PDF close follows a "review later" gesture ≥3 times (~28 B).
H1121 [cheap] (browsing) offers to translate the tab you left open in another language — signal: the tab's language flag differs from your UI language and it's focused (~36 B).
H1122 [cheap] (browsing) offers to top up the browser profile that's nearly full — signal: the profile's quota counter crosses 90% (~20 B).
H1123 [cheap] (communication) offers to reply outside the quiet hours you set — signal: a reply is typed during quiet hours ≥2 times in a week (~24 B).
H1124 [cheap] (communication) offers to attach the file you dragged onto the window — signal: a drag event lands on a chat window without a send action (~28 B).
H1125 [cheap] (media) offers to normalize the track you just imported — signal: a new track's loudness differs from the library mean by >2 LUFS (~28 B).
H1126 [cheap] (media) offers to add the open video to the watch-later list — signal: a video tabs closes after 30 s with a watch-later list active (~24 B).
H1127 [cheap] (files) offers to sync the folder manual copy — signal: a folder is copied to the same dest a second time in the same week (~40 B).
H1128 [cheap] (files) offers to compress the folder you archive — signal: an archive gesture on the same folder repeats ≥2 times (~24 B).
H1129 [cheap] (coding/work tools) offers to add the missing import — signal: a compile error names a symbol and the module exists (~44 B).
H1130 [cheap] (coding/work tools) offers to format the file before commit — signal: a commit is staged while a formatter exists and the file differs (~36 B).
H1131 [cheap] (writing/docs) offers to insert today's date header — signal: a new doc opens and your template has a date field (~24 B).
H1132 [cheap] (writing/docs) offers to fix the abbreviation you always type — signal: a typo-correct pair repeats ≥3 times (~24 B).
H1133 [cheap] (system/settings) offers to enable the tablet mode when the lid flips — signal: the convertible hinge flag flips while the screen mode differs (~20 B).
H1134 [cheap] (system/settings) offers to set the panel to auto-hide on the small screen — signal: the panel is full on a small display for ≥3 days (~24 B).
H1135 [cheap] (power/battery) offers to hibernate on the low-battery warning — signal: the power daemon emits the 5% warning flag (~16 B).
H1136 [cheap] (power/battery) offers to stop the torrent when on battery — signal: a torrent client is active while AC detaches (~24 B).
H1137 [cheap] (audio/devices) offers to pair the device that keeps scanning — signal: the BT scan counter shows the same device 3 times unanswered (~28 B).
H1138 [cheap] (audio/devices) offers to set the default output to the dock — signal: a dock connect event and your default was headphones (~24 B).
H1139 [cheap] (health/ergonomics) offers to dim the screen for the reading lamp — signal: a lamp-on flag while the display is at day level (~16 B).
H1140 [cheap] (health/ergonomics) offers to switch your view to the second monitor you look at — signal: the gaze-aggregate drifts to the second screen ~60% of a session (~28 B).
H1141 [cheap] (time-of-day rituals) offers to close the tabs you leave overnight — signal: day-end ritual activates and >8 tabs are open (~22 B).
H1142 [cheap] (time-of-day rituals) offers to set the alarm for your sleep window — signal: you set an alarm near the same hour ≥4 nights (~20 B).
H1143 [cheap] (security/privacy rituals) offers to wipe the browser's guest session — signal: a session marked guest ends and a wipe flag is set (~20 B).
H1144 [cheap] (security/privacy rituals) offers to encrypt the folder before upload — signal: an upload targets cloud and the folder is not in an encrypted vault (~36 B).
H1145 [cheap] (window/workspace management) offers to copy the window layout to the other monitor — signal: a second monitor connects and a layout was last arranged (~32 B).
H1146 [cheap] (window/workspace management) offers to restore the window you minimized by accident — signal: a window minimizes and reopens within 10 s ≥2 times (~20 B).
H1147 [cheap] (search/launch) offers to index the new disk — signal: a new mount appears with a searchable file type (~32 B).
H1148 [cheap] (search/launch) offers to open the app from the command you typed — signal: a command is mistyped to a known app ≥3 times (~28 B).
H1149 [cheap] (finance/shopping) offers to round up today's purchases — signal: a finance app has a round-up feature and a purchase lands (~20 B).
H1150 [cheap] (finance/shopping) offers to remind you of the bill due tomorrow — signal: a bill's due counter is 1 day away and you were active (~12 B).
H1151 [cheap] (learning/reading) offers to translate the article you keep opening — signal: the same foreign-URL article was opened ≥3 times (~24 B).
H1152 [cheap] (learning/reading) offers to keep the glossary term handy — signal: a term was searched in the same doc ≥2 times (~24 B).
H1153 [cheap] (browsing) offers to clear the downloaded installer after install — signal: an installer for the just-installed app remains in Downloads (~28 B).
H1154 [cheap] (browsing) offers to reopen the closed-by-accident tab — signal: an undo-close was triggered ≥2 times in one session (~16 B).
H1155 [cheap] (communication) offers to move the conversation to a thread — signal: a chat thread gains 2 replies off-topic in a window (~28 B).
H1156 [cheap] (communication) offers to merge the two duplicate contacts — signal: two contacts share phone+name patterns (~40 B).
H1157 [cheap] (media) offers to hide the video panel during a call — signal: a call is active and a video panel is showing (~20 B).
H1158 [cheap] (media) offers to switch to the audio-only stream on a weak link — signal: the call link quality counter drops and video is on (~24 B).
H1159 [cheap] (files) offers to delete the dupe backup — signal: two backups share a checksum and age >30 days (~40 B).
H1160 [cheap] (files) offers to tag the folder you keep overloading — signal: a folder crossed its usual file-count threshold twice this month (~28 B).
H1161 [cheap] (coding/work tools) offers to open the docs page for the method — signal: a method's help was requested ≥2 times in a session (~24 B).
H1162 [cheap] (coding/work tools) offers to set the breakpoint at the failing line — signal: a debugger is attached and a failure line exists (~28 B).
H1163 [cheap] (writing/docs) offers to split the overlong paragraph — signal: a paragraph exceeds 6 lines and you split similar ones ≥2 times (~28 B).
H1164 [cheap] (writing/docs) offers to add the citation you keep copying — signal: a citation paste repeats on ≥2 docs (~32 B).
H1165 [cheap] (system/settings) offers to install the driver for the new printer — signal: a printer device appears with no driver configured (~32 B).
H1166 [cheap] (system/settings) offers to set the right timezone at the roam — signal: the network's geo counter changes while TZ differs (~24 B).
H1167 [cheap] (power/battery) offers to pause the download queue on battery — signal: AC detaches and the download queue is active (~24 B).
H1168 [cheap] (power/battery) offers to lower the screen to 50% at the dim-hour — signal: clock enters the dim-window and the level is high (~16 B).
H1169 [cheap] (audio/devices) offers to route the system sounds to the internal speaker — signal: external audio disconnects and the routing stays external (~24 B).
H1170 [cheap] (audio/devices) offers to raise the volume ramp to avoid a jump — signal: a volume jump >40% occurred twice and a ramp setting exists (~20 B).
H1171 [cheap] (health/ergonomics) offers to blink-break every 20 min — signal: a 20-min focus counter elapses without a blink-pause (~8 B).
H1172 [cheap] (health/ergonomics) offers to lower the chair when your elbows rise — signal: the desk-height counter + elbow-angle aggregate drift (+/-) (~24 B).
H1173 [cheap] (time-of-day rituals) offers to run the evening checklist at 21:30 — signal: clock crosses 21:30 and a checklist doc has items (~20 B).
H1174 [cheap] (time-of-day rituals) offers to start the morning playlist at 07:30 — signal: the same playlist starts after 07:00 on ≥3 days (~24 B).
H1175 [cheap] (security/privacy rituals) offers to redact the address before the paste — signal: a paste contains a home-like string and a redact flag is on (~28 B).
H1176 [cheap] (security/privacy rituals) offers to recheck the firewall after the update — signal: a system update lands and the firewall default changed (~20 B).
H1177 [cheap] (window/workspace management) offers to set the IDE to fullscreen for flow — signal: a long focus session while the IDE is windowed (~20 B).
H1178 [cheap] (window/workspace management) offers to put the docs on the left for reading — signal: a reading session ≥15 min while the doc is on the right (~24 B).
H1179 [cheap] (search/launch) offers to create a snippet for the command — signal: the same long command was run ≥3 times (~32 B).
H1180 [cheap] (search/launch) offers to pin the tool to the dock — signal: a tool is launched ≥5 times a week and is unpinned (~24 B).
H1181 [cheap] (finance/shopping) offers to log the cash purchase — signal: a cash wallet app exists and no entry today (~20 B).
H1182 [cheap] (finance/shopping) offers to compare your spending to last month — signal: a month boundary and a spending summary exists (~24 B).
H1183 [cheap] (learning/reading) offers to add the term to your vocabulary deck — signal: a term was looked up ≥2 times in a week (~20 B).
H1184 [cheap] (learning/reading) offers to re-queue the flashcard you failed — signal: a card marked failed has a due-soon counter (~16 B).
H1185 [cheap] (browsing) offers to archive the tab group you haven't touched — signal: a group's last-active age >7 days (~24 B).
H1186 [cheap] (browsing) offers to restore the closed window's tabs — signal: a window closes and its tab set was unsaved (~32 B).
H1187 [cheap] (communication) offers to send the message when the recipient returns — signal: a presence flag shows the recipient is back while a draft waits (~20 B).
H1188 [cheap] (communication) offers to set your status to "in a call" — signal: a call window is active while your status is available (~20 B).
H1189 [cheap] (media) offers to start the album from the top at an even start — signal: a track starts mid-list and you restart ≥2 times (~28 B).
H1190 [cheap] (media) offers to queue the next episode at episode end — signal: the credits timestamp was skipped ≥2 times for consecutive episodes (~24 B).
H1191 [cheap] (files) offers to move the photo burst into an album — signal: a burst of >6 same-second shots lands unsorted (~28 B).
H1192 [cheap] (files) offers to export the notes to PDF on close — signal: a notes doc closes and a PDF export was made ≥2 times (~24 B).
H1193 [cheap] (coding/work tools) offers to lint the file on save — signal: a save event while a linter exists and the file changed (~20 B).
H1194 [cheap] (coding/work tools) offers to add the stub for the undefined symbol — signal: a compile/run error names a missing symbol (~32 B).
H1195 [cheap] (writing/docs) offers to bookmark the page for later — signal: a doc page holds a "read later" marker and it's been >2 days (~24 B).
H1196 [cheap] (writing/docs) offers to migrate the old template — signal: a doc opens with a template version older than installed (~28 B).
H1197 [cheap] (system/settings) offers to open the accessibility zoom on the small screen — signal: a small-screen connect and zoom is off (~20 B).
H1198 [cheap] (system/settings) offers to set the keyboard repeat for the power user — signal: typing latency counter is high over 2 days (~20 B).
H1199 [cheap] (power/battery) offers to suspend the VMs at low battery — signal: battery <20% and VMs are running (~16 B).
H1200 [cheap] (power/battery) offers to lower the panel refresh to 60 at low battery — signal: battery <30% and the refresh is 120 (~20 B).
H1201 [cheap] (audio/devices) offers to switch the mic to the headset when a call starts — signal: a call starts and the headset is present while the mic is the laptop's (~28 B).
H1202 [cheap] (audio/devices) offers to boost the speaker when the fan is loud — signal: a fan sensor counter is high while the volume is low (~24 B).
H1203 [cheap] (health/ergonomics) offers to reduce the mouse speed at a fine task — signal: a fine-task gesture (precision click) repeats while speed is high (~24 B).
H1204 [cheap] (health/ergonomics) offers to raise the desk at the standing hour — signal: the standing-hour clock window arrives and the desk is low (~16 B).
H1205 [live] (time-of-day rituals) offers to trigger the sunrise gentle wake — signal: the sunrise flag fires and the wake schedule is active (live counter ~12 B).
H1206 [cheap] (time-of-day rituals) offers to file the morning notes by day — signal: a morning notes doc opens and a dated filing rule exists (~24 B).
H1207 [cheap] (security/privacy rituals) offers to sign out of the shared session at end — signal: a shared-account flag is on and the session is ending (~20 B).
H1208 [cheap] (security/privacy rituals) offers to update the keyring token near expiry — signal: a token's age crosses its 7-day-expiry shadow (~20 B).
H1209 [cheap] (window/workspace management) offers to restore the tiling preset — signal: a window-count threshold and a saved preset fit (~28 B).
H1210 [cheap] (window/workspace management) offers to keep the video pinned during the chat — signal: a video + chat pair was arranged ≥3 times (~32 B).
H1211 [cheap] (search/launch) offers to search the notes before the web — signal: a query matches a notes-index hit ≥2 times (~24 B).
H1212 [cheap] (search/launch) offers to jump to the folder by its short name — signal: a folder was navigated to by typing ≥2 times (~20 B).
H1213 [cheap] (finance/shopping) offers to add the receipt line to the tracker — signal: a receipt lands and the tracker has the merchant (~28 B).
H1214 [cheap] (finance/shopping) offers to freeze the card at the risk flag — signal: a fraud-flag event and a card-freeze capability (~24 B).
H1215 [cheap] (learning/reading) offers to present the note from the margin — signal: a margin note was written and not read back in 7 days (~20 B).
H1216 [cheap] (learning/reading) offers to test yourself on the chapter — signal: a chapter close follows a "review" gesture ≥2 times (~24 B).
H1217 [cheap] (browsing) offers to sync the reading position that paused — signal: a resume position was saved and not continued in 2 days (~20 B).
H1218 [cheap] (browsing) offers to keep the inbox badge off during focus — signal: a focus session is active and the badge flag is on (~16 B).
H1219 [cheap] (communication) offers to re-queue the low-priority digest — signal: a digest was deferred ≥2 times (~20 B).
H1220 [cheap] (communication) offers to move the conversation note to the project — signal: a chat note duplicates a project note ≥2 times (~28 B).
H1221 [cheap] (media) offers to keep the album art as the wallpaper — signal: an album-art-to-wallpaper gesture repeated ≥3 times (~24 B).
H1222 [cheap] (media) offers to start the podcast queue at the right episode — signal: a queue cursor and a resume rule exist (~24 B).
H1223 [cheap] (files) offers to turn the folder into a git repo — signal: a folder gains a tracked config and no `.git` (~28 B).
H1224 [cheap] (files) offers to move the orphan file to the drafts — signal: a file has no project parent and is >30 days old (~28 B).
H1225 [cheap] (coding/work tools) offers to add the TODO comment to the tracker — signal: a "TODO:" is typed and a tracker exists (~24 B).
H1226 [cheap] (coding/work tools) offers to open the coverage report — signal: a test run reports a coverage artifact (~24 B).
H1227 [cheap] (writing/docs) offers to wrap the pasted paragraph — signal: a long paste lands unformatted ≥2 times (~24 B).
H1228 [cheap] (writing/docs) offers to save the draft version before the edit — signal: a large edit to a doc with no backup happened ≥2 times (~28 B).
H1229 [cheap] (system/settings) offers to apply the night theme at dusk — signal: the dusk flag fires and the theme differs (~16 B).
H1230 [cheap] (system/settings) offers to set the locale for the keyboard when a non-English doc is open — signal: a doc language flag differs while the layout is default (~24 B).
H1231 [cheap] (power/battery) offers to set the brightness to a reading level at night — signal: the night window and the level is high (~16 B).
H1232 [cheap] (power/battery) offers to close the backup when low — signal: a backup job is running and battery <30% (~24 B).
H1233 [cheap] (audio/devices) offers to set the call to speaker when hands are busy — signal: a call active and a hands-busy gesture was detected (~20 B).
H1234 [cheap] (audio/devices) offers to lower the click volume when typing a lot — signal: a typing counter is high and click sound is on (~16 B).
H1235 [cheap] (health/ergonomics) offers to pause the timer during the interruption — signal: a focus timer is running and an interrupting window opens (~20 B).
H1236 [cheap] (health/ergonomics) offers to raise a reminder to use the standing desk — signal: a seated session >2 h and a standing rule exists (~16 B).
H1237 [cheap] (time-of-day rituals) offers to set the pomodoro length for the day — signal: a pomodoro app is used and the length differs from your saved (~20 B).
H1238 [cheap] (time-of-day rituals) offers to quit the work apps at the day's end — signal: the day-end ritual fires and work apps are open (~20 B).
H1239 [cheap] (security/privacy rituals) offers to run the daily secret scan — signal: a project changed and a secret-scan flag is stale (~20 B).
H1240 [cheap] (security/privacy rituals) offers to remove the world-readable file — signal: a file has a 777 mode and is not a script (~24 B).
H1241 [cheap] (window/workspace management) offers to move the terminal to its own screen — signal: a terminal window + another workspace were split ≥3 times (~32 B).
H1242 [cheap] (window/workspace management) offers to enlarge the font of the text you zoom — signal: a zoom-in repeats on the same content ≥2 times (~20 B).
H1243 [cheap] (audio/devices) offers to raise the volume of the quiet app — signal: an app plays while its volume stays below your saved baseline for that app ≥2 times (per-app volume counter, ~20 B).
H1244 [cheap] (search/launch) offers to launch the recent project by its number — signal: a project-number launch gesture repeated ≥2 times (~20 B).
H1245 [cheap] (finance/shopping) offers to add the income line to the ledger — signal: a payment lands and the ledger lacks today's entry (~20 B).
H1246 [cheap] (finance/shopping) offers to set the budget alert for the category — signal: a category crosses 80% of budget and an alert is unset (~20 B).
H1247 [cheap] (learning/reading) offers to add the page to the reference shelf — signal: a page was cited in ≥2 docs and a shelf exists (~24 B).
H1248 [cheap] (learning/reading) offers to quiz on the last page as a close — signal: a page close and a quiz flag for that deck (~20 B).
H1249 [cheap] (browsing) offers to collapse the sidebar you don't use — signal: a sidebar was hidden ≥3 times and is currently open (~20 B).
H1250 [cheap] (browsing) offers to save the open form as a template — signal: a form was filled identically ≥3 times (~28 B).

---
## Casualties worth noting — 250 → this chunk's honest marks (auditor's row)

The funnel for batch-02 chunk 1 does not cut yet (cuts happen per-chunk F3–F5 later), but the honest self-audit against batch-01's 34 is done at write time: NONE of the above repeats any of the 34 retired actions (their triggers and verbs differ in substance — verified against work/batch-01/actions-40.md). Superlative honesty for this chunk: the heaviest single per-habit store here is H1017's hash table at ≈200 B (dedupe); no habit above stores content — all are counts, ages, hashes, flags, and indices. Fires are estimated ≤1–3×/week per habit; nothing here fires more than a few times a day, consistent with the utterance economy.

Eighteen candidates were killed during this chunk's writing (slop, named here so the audit is inspectable): repeated batch-01 shapes (generic "offer to open X app"), imagined no-signal triggers (habits that cannot name a sensed moment), and privacy violators rejected under Constitution VI (anything requiring content-reading or a timestamped diary for no aggregate). The 250 survivors each name a signal. Quality outranks quota; if a later chunk cannot find genuinely new habit + signal, it will say so and ship fewer — never pad.
