# The seed blessing gate — Golem #56 ("this one can't be Golem's backdoor").
#
# THE HOLE THIS CLOSES
# --------------------
# The seed flake lives in the owner's HOME, owned by the owner — that is
# Golem's philosophy (your system is yours to hack). But the root apply
# helpers rebuild the SYSTEM from it on every app install, so any code
# running as the user could edit the system configuration and get root
# silently: no sudo prompt, ever. The two sanctioned user→system channels
# (waverunner's packages.list, the postinstall answers) are safe — the
# helpers parse them as DATA and generate the Nix themselves — the hole
# was everything else in the tree.
#
# THE GATE
# --------
# Root keeps a manifest (sha256 per file) of the seed OUTSIDE the seed, in
# /var/lib/golem (root-owned, 0700). Before any unattended rebuild, the
# helpers verify the seed against it, EXCLUDING only the two generated
# data channels. A mismatch refuses the rebuild with a clear message:
#
#     sudo golem-bless
#
# `golem-bless` shows what changed and re-seals. Running it as root IS the
# consent — the one password prompt this design ever costs, and only when
# the system configuration itself was edited. App installs, postinstall
# answers, daily use: never prompted.
#
# First run (fresh install / first boot) is trust-on-first-use: no
# manifest yet → the helper seals what the installer wrote and proceeds.
#
# Residual, accepted + documented: an attacker who already has ROOT can
# rewrite the manifest — the gate guards the user→root ESCALATION, not a
# lost root. And the owner's own edits cost one bless, which is the point.

{ config, pkgs, lib, ... }:

let
  flakeDir = config.golem.flakeDir;
  manifestDir = "/var/lib/golem";
  manifest = "${manifestDir}/seed.manifest";

  # The generated data channels (root-written from validated user data) —
  # exempt from the seal because their content never reaches eval as code.
  exempt = [
    "./system/home/waverunner-packages.nix"
    "./system/home/waverunner-packages.nix.last-good"
    "./hosts/target/apps.nix"            # the same channel on the Modular desktop
    "./hosts/target/apps.nix.last-good"
    "./system/postinstall-generated.nix"
    "./system/postinstall-generated.nix.last-good"
  ];
  exemptArgs = lib.concatMapStringsSep " " (p: "! -path ${lib.escapeShellArg p}") exempt;

  # Shared manifest computation: "sha256  ./path" lines, NUL-walked, sorted.
  computeFn = ''
    compute() {
      (cd ${lib.escapeShellArg flakeDir} && \
        find . -type f \
          ! -path './.git/*' \
          ! -name '*.tmp' \
          ! -name 'result' ! -name 'result-*' \
          ${exemptArgs} \
          -print0 | sort -z | xargs -0 -r sha256sum)
    }
  '';

  # ONE rebuild at a time, for every rebuilder Golem has: the dock's app
  # installs, post-install answers, first boot, the nightly update, Seam's
  # update lane and the owner's rebuild-golem. switch-to-configuration takes
  # its own lock WITHOUT waiting ("Could not acquire lock"), and by then
  # nixos-rebuild has already made the new generation the boot default — so
  # an app install that met the nightly update failed in the dock while the
  # next reboot quietly brought the app in. Here the second rebuilder waits
  # its turn instead. The lock file is Seam's lane's, which already took it.
  rebuild = pkgs.writeShellApplication {
    name = "golem-rebuild";
    runtimeInputs = [ pkgs.util-linux config.system.build.nixos-rebuild ];
    text = ''
      exec 9>>/run/golem-rebuild.lock
      if ! flock -n 9; then
        echo "golem-rebuild: another system rebuild is running — waiting for it…" >&2
        flock -w 7200 9 || { echo "golem-rebuild: still busy after 2 h — giving up" >&2; exit 1; }
      fi
      nixos-rebuild "$@"
    '';
  };
  sealCheck = pkgs.writeShellApplication {
    name = "golem-seal-check";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.diffutils pkgs.gawk ];
    text = ''
      manifest=${lib.escapeShellArg manifest}
      ${computeFn}
      current=$(compute)
      if [[ ! -f "$manifest" ]]; then
        # Trust on first use: seal what the installer wrote.
        mkdir -p ${lib.escapeShellArg manifestDir}
        chmod 700 ${lib.escapeShellArg manifestDir}
        printf '%s\n' "$current" > "$manifest"
        chmod 600 "$manifest"
        echo "golem-seal: first run — seed sealed ($(printf '%s\n' "$current" | wc -l) files)"
        exit 0
      fi
      # A plain string comparison: `diff -q` stopped reading early and the
      # writer died of SIGPIPE ("printf: write error: Broken pipe"), noise
      # that ended up in the error the dock reports.
      if [[ "$current" == "$(cat "$manifest")" ]]; then
        exit 0
      fi
      echo "golem-seal: the system configuration changed since the last blessing." >&2
      echo "golem-seal: changed paths:" >&2
      # < current-only (new/modified), > manifest-only (old/removed).
      diff <(printf '%s\n' "$current") "$manifest" | grep -E '^[<>]' \
        | awk '{print "  " $1 " " $3}' | sort -u -k2 >&2 || true
      echo "golem-seal: review the change, then: sudo golem-bless" >&2
      exit 1
    '';
  };

  bless = pkgs.writeShellApplication {
    name = "golem-bless";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.diffutils pkgs.gawk ];
    text = ''
      if [[ "$(id -u)" != 0 ]]; then
        echo "golem-bless: run with sudo — blessing is the explicit root consent." >&2
        exit 1
      fi
      manifest=${lib.escapeShellArg manifest}
      ${computeFn}
      current=$(compute)
      if [[ -f "$manifest" ]]; then
        if [[ "$current" == "$(cat "$manifest")" ]]; then
          echo "golem-bless: nothing changed — the seed is already blessed."
          exit 0
        fi
        echo "golem-bless: blessing these changes:"
        diff <(printf '%s\n' "$current") "$manifest" | grep -E '^[<>]' \
          | awk '{print "  " $1 " " $3}' | sort -u -k2 || true
      else
        echo "golem-bless: no previous seal — sealing the seed for the first time."
      fi
      mkdir -p ${lib.escapeShellArg manifestDir}
      chmod 700 ${lib.escapeShellArg manifestDir}
      printf '%s\n' "$current" > "$manifest"
      chmod 600 "$manifest"
      echo "golem-bless: sealed ($(printf '%s\n' "$current" | wc -l) files)."
    '';
  };
in
{
  options.golem.seal.check = lib.mkOption {
    type = lib.types.package;
    description = "The seed seal-check tool the root apply helpers gate on.";
  };
  # The re-seal tool, exposed so a TRUSTED unattended channel can re-baseline
  # the manifest without a human bless. Only auto-update uses it, and only
  # after a clean fast-forward pull from upstream (the trust root) — never on
  # a local edit. The interactive `golem-bless` on $PATH is unchanged; this is
  # the same package, referenced by store path.
  options.golem.seal.bless = lib.mkOption {
    type = lib.types.package;
    description = "The seed re-seal tool (golem-bless), for trusted unattended re-baselining.";
  };

  options.golem.rebuild = lib.mkOption {
    type = lib.types.package;
    description = "golem-rebuild: nixos-rebuild behind Golem's one rebuild lock (every rebuilder uses it).";
  };

  config = lib.mkMerge [
    { golem.rebuild = rebuild; }
    (lib.mkIf (flakeDir != null) {
      golem.seal.check = sealCheck;
      golem.seal.bless = bless;
      environment.systemPackages = [ bless rebuild ];
    })
  ];
}
