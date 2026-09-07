# CLAUDE.md — lab operating playbook

My working manual for running the five-laptop install lab. The RULES are in
[constitution.md](constitution.md); this file is the MECHANICS — the exact
commands and the record format, so I don't re-derive them each session.
When the two disagree, the constitution wins.

## The discipline (do not break)

- **One frozen ISO per round, across all five laptops.** No ISO change
  lands mid-round. A fix a laptop teaches me goes to
  [changes.md](changes.md), not into a rebuild — the next laptop must meet
  the *same* Golem.
- **Rehearsal writes nothing.** `GOLEM_REHEARSE=1` is baked into the
  stick's `golem-setup` wrapper. Confirm the target disk is virgin after
  every run. Never hand-run `golem-install` without `--rehearse` on a lab
  machine during a rehearsal round.
- **Suspect the harness first.** A wrong-looking census is more likely the
  rig lying than Golem being wrong. Rule out the rig.
- **Record passes too.** "It worked, here are the numbers" is a finding.

## Mechanics

**SSH to a lab machine** (key-only, the golem-vm-loop key is baked into the
ISO; the host key changes each boot so don't check it):

```
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o BatchMode=yes root@<ip-or-golem-installer.lan>
```

**Find the machine** (it auto-joins HOLA and announces `golem-installer`;
with two lab machines up the mDNS name collides, so sweep by IP). My dev
box is on `192.168.1.0/24`:

```
for i in $(seq 1 254); do (timeout 1 bash -c "echo >/dev/tcp/192.168.1.$i/22" \
  2>/dev/null && echo "192.168.1.$i open") & done; wait
```

A booting machine resets SSH mid-handshake (`kex_exchange_identification`)
until sshd is up — retry with a few seconds' delay, don't conclude "down".

**Confirm which ISO it booted** before trusting a result (the reflashed
stick lives in the dev box; a laptop may be on an older image):

```
grep -c 'valid_host Golem' "$(command -v golem-setup)"   # 1 = hostname fix present
grep cores /var/log/golem-audit/golem-hardware.nix       # sysfs cores fix → right count
```

**Drive `golem-setup` over SSH** in tmux (no system tmux; build one):
`tmux=$(nix build --no-link --print-out-paths nixpkgs#tmux)/bin/tmux`

```
$tmux new-session -d -s lab -x 120 -y 34 \
  "ssh -tt -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@<ip>"
$tmux send-keys -t lab "clear; golem-setup" Enter
$tmux send-keys -t lab <keys>        # ENTER, Up, Down, Escape, or literal text
$tmux capture-pane -t lab -p | grep -v '^$' | tail -N
```

Keys: language = ENTER opens list, type to filter, Up/Down, ENTER takes.
Timezone/keyboard/disk = type-to-filter + ENTER. You = type field + ENTER;
hostname now shows a dimmed "Golem" ghost — typing replaces it. Confirm =
ENTER rehearses, ESC walks back.

**The rehearsal is slow on old metal** (full target eval on 4 GB / spinning
disk = 20–40 s). Poll the status file rather than the pane:

```
ssh ... root@<ip> 'cat /var/log/golem-rehearsal/status'   # ok | findings: N
```

**Pull and audit the bundle:**

```
scp ... root@<ip>:/var/log/golem-rehearsal/rehearsal.tar.gz .
# read checks.txt FIRST, then transcript.txt, target/machine.nix, toplevel.drv/eval.err
ssh ... root@<ip> 'lsblk /dev/<target> -o NAME,SIZE,FSTYPE,LABEL'  # must be untouched
```

## The record format (paste into the laptop's file)

Append one block per test to `<laptop>.md`. Keep it scannable:

```
## Round <N> — <date>

- **ISO:** <store-path hash or "round-N">
- **Boot:** UEFI|BIOS · menu drew correct? · joined HOLA on its own?
- **Census:** status, time; facts cross-checked vs known hardware (call out
  any wrong/uncertain). cores/threads sanity.
- **Surface:** anything a stranger could trip on across the six screens.
- **Rehearsal:** checks.txt result (N findings), eval time, disk verified
  untouched (before/after), the checks that fired.
- **Findings → changes.md:** list what got queued (or "none").
- **Verdict:** pass / findings — one line.
```

Raw finding stays in the laptop file; the *change* it implies goes to
changes.md. Fixtures worth keeping → `../fixtures/<machine>/`.

## Known machines

- **acer** — Acer Aspire E5-573, i5-5200U Broadwell (2c/4t), HD 5500,
  QCA9377 wifi+BT, 1 TB WDC spinning disk, ~3833 MB RAM. Boots **UEFI**.
  Baseline census recorded in ../PLAN.md row 1.
- **macbook** — the boss fight: Broadcom `wl` wifi (may not join HOLA
  natively; USB ethernet dongle is the fallback), Apple EFI.
- **dell / hp / comodore** — TBD; fill in on first contact.
