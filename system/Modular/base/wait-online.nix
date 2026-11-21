# base/wait-online — THE CONNECTIVITY GATE every updater of Standard shares
# (the nightly update of both layouts: base/autoupdate.nix and
# system/machine/update.nix): wait for the channel/cache hosts before
# touching anything, so a run that fires before Wi-Fi is back (the DNS race
# after a wake from sleep) does not quietly rebuild against stale state — it
# waits, or gives up loudly. 90 x 10s = 15 min ceiling, then a non-zero exit
# rather than a silent cache no-op. Verbatim from the rice
# (waverunner-apply.nix), so the systems share one behaviour.
pkgs:

pkgs.writeShellApplication {
  name = "golem-wait-online";
  runtimeInputs = [ pkgs.curl pkgs.coreutils ];
  text = ''
    hosts=( "https://channels.nixos.org/" "https://cache.nixos.org/nix-cache-info" )
    tries=90   # 90 x 10s = 15 min ceiling
    for i in $(seq 1 "$tries"); do
      for u in "''${hosts[@]}"; do
        if curl -fsS --max-time 8 -o /dev/null "$u"; then
          if [ "$i" -gt 1 ]; then
            echo "golem-wait-online: reachable after ~$(( (i - 1) * 10 ))s"
          fi
          exit 0
        fi
      done
      sleep 10
    done
    echo "golem-wait-online: still offline after $(( tries * 10 / 60 )) min — giving up" >&2
    exit 1
  '';
}
