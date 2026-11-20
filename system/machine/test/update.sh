#!/usr/bin/env bash
# test/update.sh — THE UPDATE OF THE /etc/nixos LAYOUT, driven on a made-up
# upstream: Golem checked out as root's copy, updated across versions with
# this machine's edits kept, the conflicting ones set aside, a build that
# fails, a network that fails, the nightly wave and the held versions, and
# going back. The commands are the machine's own (system/machine/layout.nix)
# with ONE thing replaced, the rebuild (test/commands.nix): a stand-in that
# writes down what it was asked to build and answers with /run/stub-rc.
#
#   nix build .#checks.x86_64-linux.machine-update      # the flake's check
#   bash system/machine/test/update.sh <commands env>    # by hand
#
# It gives itself a world: a user + mount namespace with a root of its own
# (/etc/nixos, /var/lib, /run are the test's), so the commands run with their
# real paths and nothing of the machine it runs on is read or written.
set -u
CMDS=$1
if [ -z "${GOLEM_UPDATE_TEST_INNER:-}" ]; then
  me=$(readlink -f "$0")
  exec "$CMDS/bin/unshare" -r -m "$CMDS/bin/env" GOLEM_UPDATE_TEST_INNER=1 GOLEM_UPDATE_TEST_SELF="$me" "$CMDS/bin/bash" "$me" "$@"
fi
if [ "$GOLEM_UPDATE_TEST_INNER" = 1 ]; then
  export PATH="$CMDS/bin"
  root=$(mktemp -d)
  mount -t tmpfs tmpfs "$root"
  mkdir -p "$root"/{nix,proc,dev,etc/nixos,var/lib,run,tmp,work/home}
  mount --rbind /nix "$root/nix"; mount --rbind /proc "$root/proc"; mount --rbind /dev "$root/dev"
  printf 'root:x:0:0:root:/work/home:/bin/sh
' > "$root/etc/passwd"
  printf 'root:x:0:
' > "$root/etc/group"
  cp "$GOLEM_UPDATE_TEST_SELF" "$root/work/update.sh"
  exec chroot "$root" "$CMDS/bin/env" GOLEM_UPDATE_TEST_INNER=2 "$CMDS/bin/bash" /work/update.sh "$CMDS"
fi
export PATH="$CMDS/bin"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null HOME=/work/home
W=/work
cd /work

pass=0; fail=0
ok()  { echo "ok   $*"; pass=$((pass + 1)); }
bad() { echo "FAIL $*"; fail=$((fail + 1)); }
is()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 — got [$2], wanted [$3]"; fi; }
has() { if grep -qF -- "$3" <<< "$2"; then ok "$1"; else bad "$1 — [$3] not in: $(head -c 300 <<< "$2")"; fi; }
hasnt() { if grep -qF -- "$3" <<< "$2"; then bad "$1 — [$3] is in: $(head -c 300 <<< "$2")"; else ok "$1"; fi; }

# ── the upstream: a repository with one branch, `stable` ───────────────────
U="$W/upstream"; UW="$W/upstream-work"
git init -q --initial-branch=stable "$UW"
ug() { git -C "$UW" -c user.name=up -c user.email=up@x "$@"; }
mkdir -p "$UW/dir"
printf '{ }\n' > "$UW/flake.nix"
printf 'line1\nline2\nline3\nline4\nline5\n' > "$UW/a.txt"
echo "b v1" > "$UW/b.txt"; echo "c v1" > "$UW/dir/c.txt"; echo "d v1" > "$UW/d.txt"
printf 'result\n*.bak\n' > "$UW/.gitignore"
ug add -A; ug commit -qm c1; c1=$(ug rev-parse HEAD)
git clone -q --bare "$UW" "$U"
publish() { ug add -A; ug commit -qm "$1"; ug push -q "$U" stable; ug rev-parse HEAD; }

# ── the machine: its folder, and Golem checked out in it ───────────────────
printf '{ outputs = { self }: import ./golem/machine.nix ./.; }\n' > /etc/nixos/flake.nix
echo '{ }' > /etc/nixos/configuration.nix
mkdir -p /etc/nixos/machine; echo '{}' > /etc/nixos/machine/facts.json
out=$(golem-machine-checkout --from "$U" --branch stable 2>&1); rc=$?
is "checkout: made" "$rc" 0
is "checkout: the files are there" "$(cat /etc/nixos/golem/b.txt 2>/dev/null)" "b v1"
is "checkout: .golem-rev names the commit" "$(cat /etc/nixos/golem/.golem-rev)" "$c1"
is "checkout: git's data is out of the folder (a .git FILE points at it)" "$(cat /etc/nixos/golem/.git)" "gitdir: /var/lib/golem/golem.git"
is "checkout: /var/lib/golem is root's alone" "$(stat -c %a /var/lib/golem)" 700
is "checkout: plain git works in the folder" "$(git -C /etc/nixos/golem status --porcelain | wc -l)" 0
is "checkout: origin is the upstream" "$(git -C /etc/nixos/golem remote get-url origin)" "$U"
out=$(golem-machine-checkout --from "$U" 2>&1); is "checkout: a second run refuses" "$?" 1
G=/etc/nixos/golem
tree() { (cd "$G" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -c1-16); }
st() { golem-status 2>&1; }
has "status: nothing changed at first" "$(st)" "No file of Golem's was changed"

# ── S1: upstream moves, nothing changed here ───────────────────────────────
sed -i 's/^line3$/line3-upstream/' "$UW/a.txt"; echo "b v2" > "$UW/b.txt"; echo new > "$UW/new-upstream.txt"; rm "$UW/dir/c.txt"
c2=$(publish c2)
echo 0 > /run/stub-rc
out=$(golem-update 2>&1); rc=$?
is "S1: the update succeeds" "$rc" 0
has "S1: it says from where to where" "$out" "${c1:0:12} → ${c2:0:12}"
has "S1: the build was asked for the next start, from a root-only copy" "$(cat /var/lib/golem-test/calls)" "boot --flake path:/var/lib/golem/update."
is "S1: the copy it built held the new files" "$(cat /var/lib/golem-test/try/golem/b.txt)" "b v2"
is "S1: …and the machine's own files" "$(cat /var/lib/golem-test/try/configuration.nix)" "{ }"
is "S1: …and the commit they are made of" "$(cat /var/lib/golem-test/try/golem/.golem-rev)" "$c2"
is "S1: the folder has the new version" "$(cat $G/b.txt; sed -n 3p $G/a.txt; cat $G/new-upstream.txt)" "b v2
line3-upstream
new"
is "S1: a file the new version removed is gone" "$([ -e $G/dir/c.txt ] && echo there || echo gone)" gone
is "S1: .golem-rev moved" "$(cat $G/.golem-rev)" "$c2"
is "S1: git agrees (HEAD, and a clean status)" "$(git -C $G rev-parse HEAD) $(git -C $G status --porcelain | wc -l)" "$c2 0"
is "S1: no try left behind" "$(ls -d /var/lib/golem/update.* 2>/dev/null | wc -l)" 0
out=$(golem-update --now 2>&1)
has "S1: a second run builds what is there (the running system is not it yet), switching when asked" "$(tail -2 /var/lib/golem-test/calls)" "switch --flake"

# ── S2: edits here that do not meet upstream's ─────────────────────────────
sed -i 's/^line1$/line1-local/' "$G/a.txt"; echo mine > "$G/mine.txt"; echo keep > "$G/x.bak"; rm "$G/d.txt"
has "S2: status shows what was changed here" "$(st)" "a.txt"
has "S2: …the new file" "$(st)" "new  mine.txt"
has "S2: …and the deleted one" "$(st)" "d.txt"
sed -i 's/^line5$/line5-upstream/' "$UW/a.txt"; c3=$(publish c3)
out=$(golem-update 2>&1); rc=$?
is "S2: the update succeeds" "$rc" 0
is "S2: the same file holds this machine's line AND upstream's" "$(sed -n '1p;3p;5p' $G/a.txt | tr '\n' ' ')" "line1-local line3-upstream line5-upstream "
is "S2: the machine's own file is kept" "$(cat $G/mine.txt)" mine
is "S2: what git ignores here is kept too" "$(cat $G/x.bak)" keep
is "S2: a file deleted here stays deleted" "$([ -e $G/d.txt ] && echo there || echo gone)" gone
is "S2: the copy that was built held exactly these files" "$(sed -n 1p /var/lib/golem-test/try/golem/a.txt) $(cat /var/lib/golem-test/try/golem/mine.txt)" "line1-local mine"
is "S2: .golem-rev moved" "$(cat $G/.golem-rev)" "$c3"
is "S2: nothing was set aside" "$([ -e /var/lib/golem/local-edits ] && echo some || echo none)" none
has "S2: status still shows the machine's changes, against the new version" "$(st)" "${c3:0:12}"
has "S2: …a.txt" "$(st)" "a.txt"
snap="$W/sys-S2/etc/golem/machine"; mkdir -p "$snap"; cp -a "$G" "$snap/golem"; rm -f "$snap/golem/.git"; chmod -R a-w "$snap/golem"
treeS2=$(tree)

# ── S3: the same lines changed here and upstream ───────────────────────────
echo "b local" > "$G/b.txt"; echo "d again" > "$G/d.txt"
echo "b v3" > "$UW/b.txt"; rm "$UW/d.txt"; c4=$(publish c4)
out=$(golem-update 2>&1); rc=$?
is "S3: the update still succeeds (an edit never freezes the machine)" "$rc" 0
is "S3: Golem's version wins on the file both changed" "$(cat $G/b.txt)" "b v3"
aside=$(cat /var/lib/golem/local-edits/latest 2>/dev/null)
is "S3: this machine's version is set aside, not lost" "$(cat "$aside/b.txt" 2>/dev/null)" "b local"
is "S3: a file upstream removed and this machine rewrote: removed, and kept aside" "$([ -e $G/d.txt ] && echo there || echo gone) $(cat "$aside/d.txt" 2>/dev/null)" "gone d again"
has "S3: it says so" "$out" "set aside in $aside"
is "S3: the other edits are still there" "$(sed -n 1p $G/a.txt) $(cat $G/mine.txt)" "line1-local mine"
hasnt "S3: status no longer lists the file that was taken from upstream" "$(st)" "b.txt"

# ── S4/S5: a version that does not build; a network that fails ─────────────
echo "broken" > "$UW/a.txt"; c5=$(publish c5)
before=$(tree); echo 1 > /run/stub-rc
out=$(golem-update 2>&1); rc=$?
is "S4: a version that does not build fails the update" "$rc" 1
is "S4: …and leaves the folder exactly as it was" "$(tree)" "$before"
is "S4: …on the version it had" "$(cat $G/.golem-rev) $(git -C $G rev-parse HEAD)" "$c4 $c4"
is "S4: no try left behind" "$(ls -d /var/lib/golem/update.* 2>/dev/null | wc -l)" 0
echo 75 > /run/stub-rc
out=$(golem-update 2>&1); rc=$?
is "S5: the published pieces could not be asked for: 75, nothing changed" "$rc $(tree)" "75 $before"
mv "$U" "$U.away"
out=$(golem-update 2>&1); rc=$?
is "S5: upstream unreachable: 75, nothing changed" "$rc $(tree)" "75 $before"
mv "$U.away" "$U"

# ── S6: the nightly run: the wave, the held versions ───────────────────────
echo 0 > /run/stub-rc; : > /var/lib/golem-test/calls
out=$(golem-update --nightly 2>&1); rc=$?
has "S6: nightly, wave 2: the new version waits" "$out" "this machine is in wave 2"
is "S6: …nothing built, nothing changed" "$rc $(wc -l < /var/lib/golem-test/calls) $(tree)" "0 0 $before"
echo "$c5" > /var/lib/golem/held-revisions
touch /run/golem-update-now
out=$(golem-update --nightly 2>&1); rc=$?
has "S6: a version that crashed this machine's desktop is held, even when asked now" "$out" "holding until a newer version"
: > /var/lib/golem/held-revisions
out=$(golem-update --nightly 2>&1); rc=$?
is "S6: asked now: the wave is skipped and it updates" "$rc $(cat $G/.golem-rev)" "0 $c5"
has "S6: the nightly build never compiles blind" "$(cat /var/lib/golem-test/calls)" "NEED_CACHE=1 LOCK=1"
is "S6: the request is used up" "$([ -e /run/golem-update-now ] && echo there || echo gone)" gone
# a wave that has passed
echo ok > "$UW/a.txt"; c6=$(publish c6)
echo $(( $(date +%s) - 3 * 86400 )) > /var/lib/golem/update-behind-since
out=$(golem-update --nightly 2>&1); rc=$?
is "S6: behind for longer than its wave: it updates" "$rc $(cat $G/.golem-rev)" "0 $c6"

# ── S7: going back: Golem's files as a system was built from them ──────────
out=$(golem-recover "$W/sys-S2" 2>&1); rc=$?
is "S7: recover succeeds" "$rc" 0
is "S7: the folder is what that system was built from, edits included" "$(tree)" "$treeS2"
is "S7: …on that version, for git too" "$(cat $G/.golem-rev) $(git -C $G rev-parse HEAD)" "$c3 $c3"
is "S7: …and editable again" "$(stat -c %a $G/a.txt | cut -c1)" 6
has "S7: status shows that system's own changes" "$(st)" "mine.txt"
out=$(golem-recover "$W/sys-S2" 2>&1); has "S7: a second recover has nothing to do" "$out" "already holds"
out=$(golem-recover "$W/nowhere" 2>&1); is "S7: a system that kept no copy: refused" "$?" 1
out=$(golem-update 2>&1); rc=$?
is "S7: and from there it updates again, the old edits carried" "$rc $(cat $G/.golem-rev) $(cat $G/mine.txt)" "0 $c6 mine"

# ── S8: the installer's case: Golem's files, with no history ───────────────
rm -rf /etc/nixos/golem /var/lib/golem/golem.git /var/lib/golem/local-edits
plain="$W/plain-c3"; mkdir -p "$plain"; git --git-dir="$U" archive "$c3" | tar -x -C "$plain"
echo "$c3" > "$plain/.golem-rev"; chmod -R a-w "$plain"
out=$(golem-machine-checkout --tree "$plain" --url "$U" 2>&1)
is "S8: the checkout is made from plain files" "$?" 0
is "S8: the files are there, and root's to edit" "$(cat $G/b.txt) $(stat -c %a $G/b.txt | cut -c1)" "b v2 6"
is "S8: .golem-rev says what they are made of" "$(cat $G/.golem-rev)" "$c3"
has "S8: status, before any update: no history to compare with yet" "$(st)" "has not arrived yet"
echo "local8" > "$G/mine8.txt"; printf '# mine\n' >> "$G/flake.nix"
out=$(golem-update 2>&1); rc=$?
is "S8: the first update succeeds" "$rc" 0
has "S8: it knew which version the files were" "$out" "${c3:0:12} → ${c6:0:12}"
is "S8: this machine's edits are kept through it" "$(cat $G/mine8.txt) $(tail -n 1 $G/flake.nix)" "local8 # mine"
is "S8: on the newest, and git has taken up the history" "$(cat $G/.golem-rev) $(git -C $G rev-parse HEAD)" "$c6 $c6"
has "S8: status compares now" "$(st)" "flake.nix"
is "S8: nothing was set aside" "$([ -e /var/lib/golem/local-edits ] && echo some || echo none)" none

# ── S9: files whose version upstream does not know ─────────────────────────
rm -rf /etc/nixos/golem /var/lib/golem/golem.git /var/lib/golem/local-edits
plain9="$W/plain-x"; mkdir -p "$plain9"; git --git-dir="$U" archive "$c2" | tar -x -C "$plain9"
echo "lab only" > "$plain9/lab.txt"; echo "b lab" > "$plain9/b.txt"
out=$(golem-machine-checkout --tree "$plain9" --rev 1111111111111111111111111111111111111111 --url "$U" 2>&1)
out=$(golem-update 2>&1); rc=$?
is "S9: a version upstream does not know: the update still succeeds" "$rc" 0
has "S9: it says so" "$out" "not known upstream"
is "S9: the files are the new version's" "$(cat $G/b.txt) $(cat $G/a.txt)" "b v3 ok"
aside=$(cat /var/lib/golem/local-edits/latest 2>/dev/null)
is "S9: what differed here is set aside" "$(cat "$aside/b.txt" 2>/dev/null)" "b lab"
is "S9: a file only this machine had is kept" "$(cat $G/lab.txt)" "lab only"
is "S9: from then on it is a version upstream knows" "$(cat $G/.golem-rev) $(git -C $G rev-parse HEAD)" "$c6 $c6"

# ── S10: the first boot: this machine's own system, with nothing new ───────
: > /var/lib/golem-test/calls
out=$(golem-update --converge 2>&1); rc=$?
is "S10: --converge builds what the folder holds" "$rc $(grep -c 'boot --flake' /var/lib/golem-test/calls)" "0 1"

# ── S11: never backwards: the branch is behind what this machine has ───────
git --git-dir="$U" update-ref refs/heads/stable "$c5"
before=$(tree); : > /var/lib/golem-test/calls
out=$(golem-update --nightly 2>&1); rc=$?
has "S11: upstream behind this machine: it says so" "$out" "is ahead of stable"
is "S11: …and nothing is taken from it" "$rc $(tree) $(cat $G/.golem-rev)" "0 $before $c6"
git --git-dir="$U" update-ref refs/heads/stable "$c6"

# ── S12: the browser's pin: the newer one stays, and it is nobody's edit ───
mkdir -p "$UW/seam"; printf '{ "version": "150.0", "url": "u" }\n' > "$UW/seam/sources.json"; c7=$(publish c7)
out=$(golem-update 2>&1)
is "S12: the pin arrives with Golem" "$(grep -o '150.0' $G/seam/sources.json)" "150.0"
rm -rf /var/lib/golem/local-edits
printf '{ "version": "151.0", "url": "lane" }\n' > "$G/seam/sources.json"        # Seam's own lane, on this machine
printf '{ "version": "150.5", "url": "u2" }\n' > "$UW/seam/sources.json"; echo more > "$UW/new-upstream.txt"; c8=$(publish c8)
out=$(golem-update 2>&1); rc=$?
is "S12: Golem brings an OLDER browser than this machine has: the machine's stays" "$rc $(grep -o '15[0-9]\.[0-9]' $G/seam/sources.json) $(cat $G/new-upstream.txt)" "0 151.0 more"
has "S12: it says so" "$out" "browser is newer (151.0)"
is "S12: …and that is not an edit to set aside" "$([ -e /var/lib/golem/local-edits ] && echo some || echo none)" none
printf '{ "version": "152.0", "url": "u3" }\n' > "$UW/seam/sources.json"; c9=$(publish c9)
out=$(golem-update 2>&1); rc=$?
is "S12: Golem brings a NEWER one: it is taken" "$rc $(grep -o '15[0-9]\.[0-9]' $G/seam/sources.json)" "0 152.0"
is "S12: …with nothing set aside either" "$([ -e /var/lib/golem/local-edits ] && echo some || echo none)" none

# ── S13: an update that is stopped in the middle (a shutdown) ──────────────
echo "more still" > "$UW/another.txt"; c10=$(publish c10)
before=$(cat $G/.golem-rev); t0=$(tree)
mkdir -p /var/lib/golem/update.left-by-a-killed-run
echo 60 > /run/stub-sleep; rm -f /var/lib/golem-test/started
setsid golem-update > /work/s13.log 2>&1 &
upid=$!
for _ in $(seq 1 100); do [ -e /var/lib/golem-test/started ] && break; sleep 0.1; done
is "S13: the build is running, in its try" "$(ls -d /var/lib/golem/update.* 2>/dev/null | wc -l)" 1
kill -TERM -- "-$upid" 2>/dev/null || kill -TERM "$upid"      # the whole group, as systemd stops a unit
wait "$upid"; rc=$?
rm -f /run/stub-sleep
is "S13: stopped: it ends as a stopped program does" "$rc" 143
is "S13: …and takes its try away (and the one a killed run had left)" "$(ls -d /var/lib/golem/update.* 2>/dev/null | wc -l)" 0
is "S13: …with Golem's files as they were" "$(cat $G/.golem-rev) $(tree)" "$before $t0"
out=$(golem-update 2>&1); rc=$?
is "S13: the next run takes the version" "$rc $(cat $G/.golem-rev) $(cat $G/another.txt)" "0 $c10 more still"

# ── S14: the first boot of a Golem the branch does not know ────────────────
rm -rf /etc/nixos/golem /var/lib/golem/golem.git /var/lib/golem/local-edits
out=$(golem-machine-checkout --tree "$plain9" --rev 2222222222222222222222222222222222222222 --url "$U" 2>&1)
t0=$(tree); : > /var/lib/golem-test/calls; rm -rf /var/lib/golem-test/try
out=$(golem-update --converge 2>&1); rc=$?
is "S14: --converge on an unknown version: this machine's system is built" "$rc $(grep -c 'boot --flake' /var/lib/golem-test/calls)" "0 1"
has "S14: it says what it builds from" "$out" "from them as they are"
is "S14: …the files as they are (the lab's own, not the branch's)" "$(cat /var/lib/golem-test/try/golem/b.txt) $(cat /var/lib/golem-test/try/golem/lab.txt)" "b lab lab only"
is "S14: the system will say the version the files say" "$(cat /var/lib/golem-test/try/golem/.golem-rev)" "2222222222222222222222222222222222222222"
is "S14: nothing of the folder moved, nothing set aside" "$(tree) $([ -e /var/lib/golem/local-edits ] && echo some || echo none)" "$t0 none"
has "S14: status says why there is nothing to compare with" "$(st)" "does not know this version"
out=$(golem-update 2>&1); rc=$?
is "S14: an ordinary update then takes the branch's version" "$rc $(cat $G/.golem-rev) $(cat $G/b.txt)" "0 $c10 b v3"

# ── S15: every run clears what a killed one left, even with nothing to do ──
mkdir -p /var/lib/golem/update.left-by-a-power-cut
out=$(golem-update 2>&1); rc=$?
is "S15: no new version, and the leftover is gone" "$rc $(cat $G/.golem-rev) $(ls -d /var/lib/golem/update.* 2>/dev/null | wc -l)" "0 $c10 0"
echo '{ "version": "153.0", "url": "lane" }' > "$G/seam/sources.json"
has "S15: status names the browser's own update for what it is" "$(st)" "the browser updating itself"

echo "== $pass passed, $fail failed"
[ "$fail" = 0 ]
