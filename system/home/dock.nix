# The dock (waverunner) in the owner's session: its service on an install,
# the small tier for a weak machine, the package list its Install section
# offers, and its configuration file.
# (On the dev box — golem.home.devCheckout — the dock runs from its live
# checkout and is not a systemd unit: see ./hyprland.nix's facts.)
{ config, osConfig, pkgs, lib, ... }:

let
  dev = config.golem.home.devCheckout;
  # VK_LOADER_DRIVERS_SELECT from the GPUs present (PCI vendor ids), then
  # exec the command. No GPU found or one we don't know: no selection.
  vulkanDrivers = pkgs.writeShellScript "golem-vulkan-drivers" ''
    sel=""; known=1
    for v in /sys/class/drm/card*/device/vendor; do
      [ -r "$v" ] || continue
      case "$(cat "$v")" in
        0x8086) sel="$sel,*intel*" ;;
        0x1002) sel="$sel,*radeon*" ;;
        0x10de) sel="$sel,*nouveau*,*nvidia*" ;;
        0x1af4) sel="$sel,*virtio*" ;;
        *) known=0 ;;
      esac
    done
    if [ "$known" = 1 ] && [ -n "$sel" ]; then
      export VK_LOADER_DRIVERS_SELECT="''${sel#,}"
    fi
    exec "$@"
  '';
in
{
  # Tell systemd-oomd (enabled at the system level for the low-RAM freeze
  # guard) to never pick the dock daemon as its victim under memory pressure —
  # it should reap the runaway app instead. This lives here, not in
  # configuration.nix, because waverunner is a home-manager user unit and a
  # NixOS-level systemd.user override is shadowed by the ~/.config copy.
  # (Installs only: on the dev box the dock is not a systemd unit.)
  systemd.user.services.waverunner = lib.mkIf (!dev) {
    Service.ManagedOOMPreference = "avoid";
    # Only the Vulkan drivers for the GPUs this machine has. The loader opens
    # EVERY installed driver otherwise — 13 of them on a Golem, ~200 MB, and
    # lavapipe + radeon pull in LLVM (180 MB) — once per dock surface. On
    # the Acer's spinning disk that cost ~5 s before the first pixel (night
    # dogfood, 2026-10-03). An unknown GPU keeps the loader's full list.
    Service.ExecStart = lib.mkForce "${vulkanDrivers} ${config.programs.waverunner.package}/bin/waverunner";
    Service.SyslogIdentifier = "waverunner";   # not the wrapper's store name
  };

  programs.waverunner.enable = !dev;
  # THE SMALL TIER (2026-10-29): a weak machine (light effects, or under
  # 6 GB) runs the dock built with 128² icon tiles — a quarter of every tile
  # on disk, in RAM, on the GPU and in every upload (the 2013 MacBook Air's
  # first frame was 460 ms of icon uploads on GL). Picked here, at install
  # time, like the rest of the tier; the dev box keeps the full tiles.
  programs.waverunner.smallIcons =
    let ram = osConfig.golem.hardware.ramMB or 0;
    in (osConfig.golem.desktop.effects or "full") == "light" || (ram > 0 && ram < 6144);
  # The Install section offers Golem's checked package list, never the
  # launcher's raw one: only packages that can actually install on this
  # nixpkgs (617 of ~23,700 could not, 2026-10-01), and no laptop ever runs
  # the ~6.5 GB evaluation that builds it. tools/package-index/refresh.sh
  # regenerates it whenever flake.lock's nixpkgs moves (the matrix insists).
  programs.waverunner.packageIndex = pkgs.runCommand "golem-package-index" { } ''
    install -D -m644 ${./package-index.tsv} $out/share/waverunner/nixpkgs-index.tsv
  '';

  # Waverunner config
  xdg.configFile."waverunner/config.toml".text = ''
    [theme]
    icon_theme = "Golem"
  ''
  # Weak GPU (golem.desktop.effects = "light"): the compositor does not blur
  # what is behind the shell, so the dock's glass (the dock, the apps card,
  # the box panels: all built from this one colour, 50% by default) showed
  # the raw page straight through its labels. Denser glass, still glass
  # (Max, 2026-10-01, picked on the MacBook: 90%). `or`: the fat profile
  # doesn't declare the option and keeps the default.
  # Every OPEN box (the menubox, group boxes, OPTIONS boxes) goes denser: at 90% a
  # page's titles read straight through it with nothing blurring them (ASUS
  # X550LC, 2026-10-02; tried live at 98 and 95 %, Max: "95 it is").
  + lib.optionalString ((osConfig.golem.desktop.effects or "full") == "light") ''
    background = "#050709e6"
    open_opacity = 0.95
  ''
  + ''

    [options]
    # Fetch each copied link's title + og:image over the network
    # (one request per copied URL) so link clips show a real miniature.
    link_unfurl = true
  '';
}
