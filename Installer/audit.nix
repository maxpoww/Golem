# The census, run by the machine itself, at boot.
#
# Max, 2026-09-04: "i press [start] — Golem audits the device, makes the
# decisions, chooses the modules, and generates a summary that you audit
# via ssh."
#
# That is the whole lab loop (PLAN.md steps 2-4) collapsed into one boot.
# Before this, a machine had to be driven by hand over SSH: run the
# collector, run the probe, run decide, pull the results. Now the stick
# does all four the moment it comes up, as root, and leaves everything in
# one directory. On a laptop that has not joined wifi yet, the audit has
# ALREADY happened — the console shows the verdict, and the network is
# only needed to come and collect it.
#
#   /var/log/golem-audit/
#     summary.txt          the decision table — what Golem chose, and why
#     decision.json        the same, machine-readable
#     golem-hardware.nix   the facts the probe measured (the future fixture)
#     evidence/            the raw dump: lspci, DMI, sysfs, lsmod, rfkill…
#     evidence.tar.gz      the same, ready to scp into fixtures/<machine>/
#     status               ok, or which stage failed
#
# NOTHING HERE TOUCHES A DISK. It is read-only detection plus a pure
# evaluation; the medium has no persistence, so a reboot re-runs it clean.
#
# It runs on BOTH boot entries on purpose. Start and Install boot the same
# system (the entry only adds a kernel marker), and an audit is harmless
# either way — so the answer is there whichever one gets pressed.
# `golem.install` stays reserved for the disk flow, which is a separate
# question from "what would Golem decide here".
{ pkgs, lib, hw-decide, hw-detect, hw-evidence, ... }:

{
  systemd.services.golem-audit = {
    description = "Golem census: probe this machine and decide what it needs";
    wantedBy = [ "multi-user.target" ];
    # The probe reads sysfs and the evaluation reads the medium's own
    # store — neither wants the network. Ordering after udev settles is
    # what matters: lab row 1 taught us a USB bluetooth radio can register
    # late and read as absent if you look too early.
    after = [ "systemd-udev-settle.service" "local-fs.target" ];
    wants = [ "systemd-udev-settle.service" ];

    # All three tools named explicitly. A systemd unit does NOT inherit the
    # system profile: the first run of this service found neither
    # golem-hw-detect nor golem-hw-evidence ("command not found") because
    # they reach the shell through environment.systemPackages, which is
    # /run/current-system/sw/bin — not on a unit's PATH.
    path = [ hw-detect hw-evidence hw-decide pkgs.coreutils pkgs.gnugrep pkgs.jq ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # The eval is the long pole (~6 s on a 4 GB machine); give a slow
      # spinning-disk laptop room without hanging the boot forever.
      TimeoutStartSec = "10min";
    };

    script = ''
      out=/var/log/golem-audit
      rm -rf "$out"
      mkdir -p "$out"
      : > "$out/status"

      fail() { echo "FAILED at: $1" > "$out/status"; }

      # ── 1. raw evidence — the fixture this machine will leave behind ──
      # Best-effort: a machine that refuses to dump is still worth
      # deciding about, and an absent file IS evidence (evidence.nix).
      if ev=$(golem-hw-evidence -t 2>"$out/evidence.log"); then
        tarball=$(echo "$ev" | head -1)
        dir=$(echo "$ev" | tail -1)
        [ -d "$dir" ] && cp -a "$dir" "$out/evidence"
        [ -f "$tarball" ] && cp -a "$tarball" "$out/evidence.tar.gz"
      else
        echo "evidence collection failed (see evidence.log)" >&2
      fi

      # ── 2. the facts ──────────────────────────────────────────────────
      if ! golem-hw-detect > "$out/golem-hardware.nix" 2>"$out/detect.log"; then
        fail "golem-hw-detect"; exit 0
      fi

      # ── 3. the decision, from those exact facts ───────────────────────
      # --facts, not a re-probe: the summary and the JSON must describe
      # ONE measurement, or the audit is two different machines.
      if ! golem-hw-decide --facts "$out/golem-hardware.nix" \
             > "$out/summary.txt" 2>"$out/decide.log"; then
        fail "golem-hw-decide"; exit 0
      fi
      golem-hw-decide --json --facts "$out/golem-hardware.nix" \
        > "$out/decision.json" 2>/dev/null || true

      echo ok > "$out/status"

      # ── 4. say so on the console ──────────────────────────────────────
      # A laptop with no network yet still has to be able to tell you what
      # it found. Full table to tty1; the getty helpLine points at it.
      # ASCII only: the kernel console font has no box-drawing glyphs and
      # renders them as replacement blocks (seen on the first run).
      # The facts are indented FOUR spaces inside `golem.hardware = {`, so
      # match "<indent>word = " — a two-space match catches only the
      # attrset's own opening line, which is how the first banner managed
      # to print a completely empty `golem.hardware = { };`.
      # The first three sections are cpu / ram / gpu by decide.nix's
      # ordering, which is exactly what someone standing in front of the
      # laptop wants; the rest is a `cat` away. Taking a slice rather than
      # naming sections means the banner follows the report instead of
      # having its own opinion about what matters.
      if [ -w /dev/tty1 ] && [ -s "$out/decision.json" ]; then
        {
          echo
          echo "-------- Golem census: this machine --------"
          jq -r '
            def pad($n): . + (" " * ($n - length));
            .[0:3][]
            | "  \(.name)",
              ( (.rows | map(.k | length) | max) as $w
                | .rows[] | "    \(.k | pad($w))   \(.v)" )
          ' "$out/decision.json" || true
          echo
          echo "  full census: /var/log/golem-audit/summary.txt"
          echo "-------------------------------------------"
        } > /dev/tty1 2>/dev/null || true
      fi
    '';
  };

  # The console's job is telling you where the machine is and that the
  # verdict is ready; both are one command away over SSH.
  # "rehearse", not "install", while setup.nix's wrapper carries
  # GOLEM_REHEARSE=1 — the two flip together when the lab graduates to
  # real installs (the mode ladder, documented in setup.nix).
  services.getty.helpLine = lib.mkForce ''

    ssh nixos@\4  (key-only)
    census:   cat /var/log/golem-audit/summary.txt
    rehearse: sudo golem-setup   (runs the install flow, writes nothing)'';
}
