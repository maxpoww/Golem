# Operations — the runbook

Everything here was executed for real at least once; commands are
verbatim from working sessions. Implementation dir =
`~/Golem/Installer/preinstall/`.

## Cut an ISO

```
cd ~/Golem/Installer/preinstall
nix flake update                                   # NEVER skip — path: inputs are locked
jq -r '.nodes.waverunner.locked.rev' flake.lock    # must equal ~/Golem's own lock
nix build .#iso --out-link result-roundN           # → result-roundN/iso/golem-installer.iso
```

Then verify the BUILT artifacts, not the source:

```
top=$(nix build '.#nixosConfigurations.golem-installer.config.system.build.toplevel' --no-link --print-out-paths)
setup=$(nix-store -qR "$top" | grep -- -golem-setup$)
grep -c <marker-of-this-round's-fix> "$setup/libexec/golem-setup-unwrapped"
```

## Gate it on the VM (mandatory before any flash)

```
./run-vm.sh --headless --uefi --disk golem-target-rN.qcow2:40G --iso result-roundN/iso/golem-installer.iso
echo sendkey ret | socat - unix:/tmp/golem-vm-hmp        # the menu waits forever
ssh -p 2222 <labopts> root@127.0.0.1                     # key-only, golem-vm-loop
```

Minimum gate = audit `ok`, census cross-checked, full six-screen drive,
rehearsal all-green, disk untouched, this round's fixes exercised
live. Record it in `testing/vm.md` — rounds 4/5 skipped the record and
the gap is called out there; don't repeat it. BIOS variant: drop
`--uefi` (SeaBIOS draws no headless menu — the sendkey stands in).

## Flash the stick

```
lsblk -d -o NAME,SIZE,TRAN,MODEL     # confirm the PNY 14.4G usb stick, EVERY time
sudo dd if=result-roundN/iso/golem-installer.iso of=/dev/sdX bs=4M oflag=direct conv=fsync status=progress
```

## Drive a lab machine over SSH

The stick joins HOLA on its own (`golem-lab` profile) and announces
`golem-installer` over mDNS (collides when two are up — sweep by IP).
Full mechanics — tmux driving, key sequences, ISO-marker confirmation,
the record format — are in `testing/CLAUDE.md` (the lab playbook,
archived but still the manual). The short version:

```
for i in $(seq 1 254); do (timeout 1 bash -c "echo >/dev/tcp/192.168.1.$i/22" 2>/dev/null && echo $i) & done; wait
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes root@<ip>
grep -c 'valid_host Golem' /nix/store/*-golem-setup/libexec/golem-setup-unwrapped   # which build am I on?
```

Known machine IPs and quirks: each machine's file in `testing/`
(acer .99, comodore .129 wired-only, hp .150, dell .109 dongle +
dead keyboard + phantom `kec_query` load, thinkpad, macbook).

## A real install (the closure-delivery seam)

Proven on the ASUS (UEFI) and the VM (BIOS). The stick's `golem-setup`
is rehearse-wrapped, so a real install runs the ENGINE with a clean
env:

```
# 1. On the machine: answers via the surface (Ctrl-C at the confirm keeps them)
clear; golem-setup          # drive to confirm, Ctrl-C — /tmp/golem-answers persists

# 2. Real prepare
env -u GOLEM_REHEARSE -u GOLEM_LAB golem-install --disk /dev/sdX \
  --answers /tmp/golem-answers --lab-ssh '<pubkey>' --prepare-only --yes

# 3. On the dev box: pull target files, stage (git flake!), build
scp root@<ip>:/mnt/home/max/Golem/hosts/target/{golem-hardware,hardware-configuration,machine}.nix ~/Golem/hosts/target/
cd ~/Golem && git add hosts/target/*.nix        # STAGE, NEVER COMMIT
nix build .#nixosConfigurations.golem-target.config.system.build.toplevel --no-link --print-out-paths

# 4. Deliver the closure to the mounted target
NIX_SSHOPTS="<labopts>" nix copy --to "ssh://root@<ip>?remote-store=/mnt" $TOPLEVEL

# 5. Finish on the machine (header must say "hostname X (from seed)")
env -u GOLEM_REHEARSE -u GOLEM_LAB golem-install --disk /dev/sdX \
  --skip-prepare --system $TOPLEVEL --yes

# 6. Reboot; first-boot audit over SSH; UNSTAGE the target files after
git restore --staged hosts/target/*.nix
```

First-boot audit checklist: hostname, root device,
`systemctl is-system-running`, zram+swap tier vs RAM, `resume=` on the
cmdline, owner uid 1000 + populated profile, `waverunner-apply.path` +
`golem-postinstall-apply.path` active, the seed's `flake.lock` pinning
the intended waverunner, zero failed units. Then the DockMenu harness
(`~/GolemOne/System/FlowShell/DockMenu/harness/aging-check.sh` +
`state-census.sh`) — first-boot state is free dogfood data.

## After the round

Work `testing/changes.md` top to bottom, move applied entries, cut the
next ISO. Waverunner-side fixes ride: commit in `~/launcher` → push →
`nix flake lock --update-input waverunner` in `~/Golem` → the next cut
carries it (and installed machines pick it up through their seed on the
deploy loop).
