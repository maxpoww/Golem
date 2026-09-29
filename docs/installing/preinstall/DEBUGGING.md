# Debugging — logs, failure classes, and the rules that find bugs

## Where everything is written (on the medium)

| File | What it tells you |
|---|---|
| `/var/log/golem-audit/status` | `ok` or `FAILED at: <stage>` — read FIRST |
| `/var/log/golem-audit/golem-hardware.nix` | the census facts |
| `/var/log/golem-audit/summary.txt`, `decision.json` | what the facts decided |
| `/var/log/golem-audit/detect.log`, `decide.log` | the probes' own stderr |
| `/var/log/golem-audit/evidence*` | the raw hardware dump (fixtures) |
| `/var/log/golem-rehearsal/status` | `ok` \| `findings: N` — poll this, not the pane |
| `/var/log/golem-rehearsal/checks.txt` | the six preflight checks — read FIRST in the bundle |
| `/var/log/golem-rehearsal/transcript.txt` | every engine line; `would`/`run` counts prove writes |
| `/var/log/golem-rehearsal/target/` | the four dropped files, incl. `postinstall-questions.json` |
| `/tmp/golem-answers`, `/tmp/golem-machine.nix` | the surface's outputs (persist across runs) |
| `/tmp/golem-drv.*`, `/tmp/golem-kb-orig.*` | run-scoped temps — MUST vanish on any exit (#34) |

On an installed system: `journalctl -u waverunner-apply -u
golem-postinstall-apply`, `~/.config/…/postinstall-apply-status.json`
(phase/ok/error), `/var/lib/golem/` (the seal manifest, root 0700).

## Disk-untouched proof (any guarded machine, before AND after)

```
lsblk -o NAME,UUID /dev/sdX ; sfdisk -d /dev/sdX | head -3
awk '{print $5}' /sys/block/sdX/stat      # writes-completed — 0 the whole session
```

## The failure classes the lab already paid for

Check these BEFORE inventing a new theory. Each one cost a session.

1. **The artifact doesn't carry the fix (the #41 family).** A locked
   `path:` flake input is never re-read by `nix build` (the round-6 cut
   shipped a 7-day-old seed); a dev-box `--override-input` deploy
   reverts on the machine's next self-rebuild; a stick is always older
   than the repo. *Always verify the built artifact: grep the store
   path, `jq` the embedded lock.*
2. **Git flakes see only tracked files (the #35 family).** An untracked
   file is invisible to the eval: `golem-target` "does not exist" until
   the dropped files are staged; a generated module changes nothing
   until something imports it; `git add … || true` swallows the
   evidence. Plain-path seeds (no `.git`) see everything — which also
   makes their drv version read `19700101.dirty` (cosmetic).
3. **Success reported without the effect (the #35c family).** Exit
   codes lie: a switch can succeed while the config ignored the input;
   `ok:true` must mean the observable exists. When a pipeline "worked
   but nothing changed," find what consumed the output — often nothing.
4. **writeShellApplication's clean PATH.** A tool used but not in
   `runtimeInputs` works interactively and breaks silently under
   systemd (gawk in golem-seal, systemctl in the appliers — twice).
5. **The lab rig lying (harness-first).** Root SSH creates `user@0` and
   breaks activation on a machine no product user could break (#44);
   a store glob picked by `head`/`tail` runs the WRONG binary (the
   orphan-daemon incident); `sudo -n` silently returns nothing; the
   phone's randomized MAC looks like a lab machine; a flaky router
   makes three machines "fail" wifi the same day. Rule out the rig.
6. **Slow-hardware races.** Windows that are ~0 on the dev box are
   seconds-to-minutes on 5400 rpm metal: oneshot `activating` ≠
   `is-active`, async user activation lands minutes after the switch,
   overlapping rebuilds lose Done events. If it "only fails on the
   ASUS," it's a race, and the ASUS is right.
7. **Terminal input is not what it looks like.** F1 arrives as three
   different sequences (`\eOP`, `\e[[A`, `\e[11~`); tmux `send-keys F1`
   may land as literal text — send hex (`-H 1b 4f 50`); an unhandled
   key NAME can leak into a filter (R5-3). Reproduce key bugs with
   exact bytes.
8. **Cross-generation GPU assumptions.** Device-id heuristics break on
   ancient parts (#12), probe timing breaks on runtime-PM (#23), a
   sibling PCI function is not a second GPU (#26), nvidia module
   internals are null on the iron-law floor (#22). New GPU logic gets a
   fixture and both directions of the health question.

## Reproducing without hardware

`fixtures/<machine>/` in the implementation dir holds each lab
machine's census + evidence snapshots; the eval matrix builds
golem-target shapes from them (`flake.nix` — "committed lab fixtures
included"). A crash like #22 is reproduced by evaluating
`lib.golem.decide` against the fixture's fact shape — no metal needed.
The VM (`run-vm.sh`) reproduces everything hardware-independent,
including full BIOS/UEFI installs onto disposable qcow2s.
