# golem-setup — the installer surface, packaged for the medium.
#
# THIS IS WHAT MAKES THE LAB TEST POSSIBLE AT ALL. The surface was built and
# argued over as `mockup/install-cli`, but a mockup in a directory the flake
# never reads is not on the stick: until this file existed, a lab machine
# booting MiniGolem had golem-install and the census and NO WAY to answer
# the six questions. The whole idea of "minimal Golem, no graphics, tested
# on five old machines" hinged on a script that never left the dev box.
#
# NOT writeShellApplication, deliberately. That would run shellcheck over
# 2,600 lines of interactive TUI bash at every build, and the surface's
# redraw tricks (cursor-park loops, parked FIELD_* globals) fail lints that
# writeShellApplication treats as errors. `bash -n` runs here instead; the
# deep testing this script gets is tmux-driven screens, which catch what
# shellcheck never could (see the 2026-09-06 debug round: both real bugs
# were invisible to static analysis).
#
# THE TABLES COME FROM lib.golem AT BUILD TIME. The script carries dev
# fallbacks of the keyboard table so it runs from a bare checkout, but the
# package must not trust them: GOLEM_KEYBOARDS is baked into the wrapper
# pointing at a table rendered from the SAME nix data CI verifies
# (keyboard-table check), so the stick and the checks cannot drift.
{ pkgs, keyboardsTable }:

let
  tableFile = pkgs.writeText "golem-keyboards.table" keyboardsTable;
in
pkgs.runCommand "golem-setup"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    src = ./mockup/install-cli;
  }
  ''
    install -Dm755 "$src" $out/libexec/golem-setup-unwrapped
    # env-shebang → store bash: the script must not depend on whatever the
    # medium's profile happens to link, or on there being a profile at all.
    patchShebangs $out/libexec/golem-setup-unwrapped
    ${pkgs.bash}/bin/bash -n $out/libexec/golem-setup-unwrapped

    # Default output paths, baked in: a lab user types `golem-setup`, not
    # `golem-setup --out ...`, and answers that vanish with the screen are
    # a step that never happened. /tmp on the medium is tmpfs — RAM — which
    # is exactly where an answers file that may name a LUKS keyfile belongs.
    # Explicit flags still win: bash's later-flag-wins parsing means a
    # caller's --out overrides these.
    # THE MODE LADDER lives here, one env line per rung (see step_go in the
    # script): GOLEM_REHEARSE=1 makes ENTER on the confirm run the real
    # installer with the destructive verbs recorded — the lab phase (Max,
    # 2026-09-06): five laptops rehearse their installs and the dev box
    # audits the bundles until the installer is trusted. Deleting the
    # REHEARSE line drops to GOLEM_LAB's prepare-only seam (real install,
    # closure delivered from the dev box); deleting both is the product.
    makeWrapper $out/libexec/golem-setup-unwrapped $out/bin/golem-setup \
      --add-flags "--out /tmp/golem-answers --write /tmp/golem-machine.nix" \
      --set GOLEM_REHEARSE 1 \
      --set GOLEM_LAB 1 \
      --set GOLEM_KEYBOARDS ${tableFile} \
      --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [
        coreutils gnugrep gnused gawk findutils
        util-linux   # lsblk, findmnt — the disk step's eyes
        iproute2     # ip — the rehearsed screen prints where to ssh
        jq           # the reveal reads decision.json, the census as data
        kbd          # loadkeys — the keyboard step applies what it proposes
        mkpasswd     # the password is hashed the moment it is typed
        pciutils     # lspci -k — the hardware reveal names GPU/Wi-Fi/audio
        usbutils     # lsusb — the reveal's Bluetooth/fingerprint rows
      ])}
  ''
