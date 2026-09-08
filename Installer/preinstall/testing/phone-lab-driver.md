# Phone lab driver — the playbook (read this when running ON the phone)

You are Claude Code running on Max's Pixel, acting as the **portable lab
driver**. Your job is the same one the dev-box session does — find a
booted lab machine, run its census + rehearsal, record it — but you are
reachable when the dev box itself is DOWN (being tested). Follow
[CLAUDE.md](CLAUDE.md) (the mechanics) and [constitution.md](constitution.md)
(the rules) exactly as the dev-box session does; this file only adds what
is different about driving from the phone.

## What's the same

Everything in CLAUDE.md: the IP sweep, `ssh -o StrictHostKeyChecking=no
-o UserKnownHostsFile=/dev/null root@<ip>`, building a tmux to drive
golem-setup, polling `/var/log/golem-rehearsal/status`, pulling the
bundle, reading checks.txt first, the record format per laptop file. The
lab SSH key is `~/.ssh/id_ed25519` (golem-vm-loop), already trusted by
every stick. `nix build`/tmux/socat via `nix` may not exist on the phone
— use the system `ssh`, `git`, and plain shell; if you need tmux and
there's no nix, `apt install tmux` is fine on the phone (it is not part
of any frozen artifact).

## What's different — read carefully

1. **The repo is the sync channel. Pull first, push last.**
   Start every session with `cd ~/Golem && git pull`. Do the work. When
   done, `git add -A && git commit && git push`. The dev-box session
   reads your records by pulling — a push is you handing back the baton.
   Never leave the phone's tree uncommitted after a test; the dev box
   can't see uncommitted work.

2. **The dev box (Lenovo) is BOTH a test subject AND where the lab
   normally lives — its NVMe holds the repo, the source, everything.**
   When you rehearse against it, that writes nothing (the stick bakes
   `GOLEM_REHEARSE=1`), and you MUST confirm the target disk is untouched
   before and after, every run (constitution rule). A real
   `golem-install` on the dev box would erase the lab itself. NEVER run
   the engine without `--rehearse`/the baked rehearse env on the dev box.
   Treat its `nvme0n1` as radioactive.

3. **You are on home wifi or you are blind.** The lab machines are on
   192.168.1.0/24. If your sweep finds nothing, first check the phone is
   on wifi (not cellular) and the Debian VM sees the subnet
   (`ip -4 addr | grep 192.168.1`) before concluding a machine is down.

4. **A booting machine resets SSH mid-handshake** until sshd is up
   (`kex_exchange_identification`) — retry with a few seconds' delay,
   same as CLAUDE.md says. On the phone the sweep may be slower; be
   patient.

5. **Identify the machine before trusting a result** (CLAUDE.md's
   which-ISO checks + DMI `cat /sys/class/dmi/id/product_name`). With the
   dev box especially: confirm you are on the MEDIUM (`findmnt /iso`
   resolves), not somehow on a normally-booted box — the medium's root is
   a tmpfs.

## The dev box (Lenovo), specifically

Its record is [lenovo.md](lenovo.md) (currently DEFERRED — this is how it
gets its first contact). What it uniquely proves: the HEALTHY modern
nvidia path on real metal — Iris Xe + RTX 4050 → `gpu = intel` (boot_vga),
`gpu2 = nvidia`, `gpu2Health = working`, `nvidiaGen = turing+` → the
reveal's "GPU 2 … tested, working · apps can use it on demand" and the
target evaluating PRIME offload (gpu-nvidia.nix) on metal, not just by
fixture eval. Capture the gpu2 verdict, watch for a facts-match flap
(#23), and confirm the console is quiet.

## Handoff back

After you push, tell Max the machine can reboot to normal. When the dev
box is back, the dev-box Claude pulls and continues. If you also want the
dev-box Claude to have your session's reasoning (not just the committed
records), put it in the commit message or a note in the record — the
records are the only thing that crosses over.
