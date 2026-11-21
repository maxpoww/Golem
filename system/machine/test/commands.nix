# test/commands — the layout's commands as a machine has them, with ONE thing
# replaced: the rebuild. The stand-in writes down what it was asked and what
# the folder it was given holds (/var/lib/golem-test), and answers with the
# code a test left in /run/stub-rc (after the seconds a test left in
# /run/stub-sleep). Everything else is the real thing: the
# checkout maker, golem-update, golem-recover, golem-status, the wave.
{ machine }:

let
  s = (machine ../fixtures/qemu).system.extendModules {
    modules = [ ({ lib, pkgs, ... }: {
      standard.update.wave = 2;
      standard.rebuild = lib.mkForce (pkgs.writeShellScriptBin "golem-rebuild" ''
        log=/var/lib/golem-test; mkdir -p "$log"
        echo "$*" >> "$log/calls"
        flake=""; prev=""
        for a in "$@"; do [ "$prev" = --flake ] && flake=$a; prev=$a; done
        d=''${flake#path:}; d=''${d%%#*}
        rm -rf "$log/try"; cp -a "$d" "$log/try"
        echo "NEED_CACHE=''${GOLEM_REBUILD_NEED_CACHE:-} LOCK=''${GOLEM_REBUILD_LOCK_HELD:-}" >> "$log/calls"
        # (A build that takes its time, for the test that stops one.)
        : > "$log/started"
        if [ -e /run/stub-sleep ]; then sleep "$(cat /run/stub-sleep)"; fi
        exit "$(cat /run/stub-rc 2>/dev/null || echo 0)"
      '');
    }) ];
  };
  inherit (s) pkgs;
  desktop = (machine ../fixtures/thinkpad).system;
  names = [ "rebuild-golem" "golem-update" "golem-recover" "golem-status" "golem-machine-checkout" ];
in
pkgs.buildEnv {
  name = "golem-layout-commands";
  paths = builtins.filter (p: builtins.elem (p.name or "") names) s.config.environment.systemPackages
    # (Built here so that every script of the layout is shell-checked by the
    # check, the desktop's dock helper included.)
    ++ [ desktop.config.standard.machine.applyCommand desktop.config.standard.machine.answersCommand ]
    ++ (with pkgs; [ git coreutils diffutils gnugrep gnused gnutar findutils util-linux bash ]);
}
