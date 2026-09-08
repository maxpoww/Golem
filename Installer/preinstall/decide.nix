# golem-hw-decide — run the census on THIS machine and print what Golem
# decided from it, before a single byte is written to a disk.
#
#   golem-hw-decide                 # probe this machine, print the table
#   golem-hw-decide --json          # same, machine-readable
#   golem-hw-decide --facts FILE    # replay a committed fixture instead
#
# WHY THIS EXISTS (PLAN.md, Max 2026-09-03: "we need to know Golem will
# make the right choices"): the eval matrix proves the modules react to
# facts correctly, but it runs in CI on fixtures. This runs on the metal,
# against facts measured seconds earlier, through the SAME
# lib.golem.mkTarget composition `nixos-install --flake …#golem-target`
# builds. It is the install flow's brain with the disk writes removed.
#
# OFFLINE BY CONSTRUCTION. hosts/iso.nix:83-85 flagged the trap: carrying
# the flake SOURCE on a medium is not an offline eval, because resolving
# its lock still wants to fetch every input. Nothing here fetches — each
# input is pinned to a store path baked in at ISO build time and passed as
# --override-input, so nix never consults the lock's github URLs and never
# needs a warm fetcher cache. `--offline` then makes any regression here
# fail loudly instead of silently reaching for the network.
{ pkgs, golemSrc, overrideArgs }:

pkgs.writeShellApplication {
  name = "golem-hw-decide";
  runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.nix ];
  text = ''
    json=false
    facts=""
    src="${golemSrc}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json)  json=true; shift ;;
        --facts) facts="''${2:?--facts needs a file}"; shift 2 ;;
        --src)   src="''${2:?--src needs a directory}"; shift 2 ;;
        -h|--help)
          echo "usage: golem-hw-decide [--json] [--facts FILE] [--src DIR]"; exit 0 ;;
        *) echo "golem-hw-decide: unknown argument '$1'" >&2; exit 2 ;;
      esac
    done

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    # No --facts: measure this machine. Only golem-hardware.nix is wanted,
    # so the probe's stdout form is used — `-o` would also invoke
    # nixos-generate-config, which wants root and a target root and has
    # nothing to say about the DECISION.
    if [[ -z "$facts" ]]; then
      golem-hw-detect > "$work/golem-hardware.nix"
      facts="$work/golem-hardware.nix"
      echo "probed this machine → $(grep -c . "$facts") lines of facts" >&2
    fi
    facts=$(realpath "$facts")

    # --impure: the facts file is a live path outside the store (it was
    # written a second ago). Everything else about this eval is pinned.
    # `path:` is not decoration. Without it nix parses a /nix/store/… ref
    # as a STORE PATH installable, and asking one for an attribute fails
    # with "does not correspond to a Nix language value" — which is exactly
    # how this died on its first live run (VM, 2026-09-04) after working on
    # the dev host, where the same string happened to parse as a flakeref.
    # Spell the scheme; do not rely on inference.
    # Pinning every input necessarily "modifies" the lock, and nix narrates
    # all six substitutions on stderr every run — 25 lines of noise ahead of
    # the answer. Hold stderr back and print it only if the eval actually
    # fails, so a real error is still the loudest thing on screen.
    out="$work/decision.json"
    if ! nix eval --offline --no-write-lock-file --impure --json \
      ${overrideArgs} \
      "path:$src#lib.golem.decide" --apply "f: f (import $facts)" \
      > "$out" 2> "$work/eval.err"; then
      cat "$work/eval.err" >&2
      echo "golem-hw-decide: evaluation failed (facts: $facts)" >&2
      exit 1
    fi

    if [[ "$json" == true ]]; then
      cat "$out"
      exit 0
    fi

    # Dumb on purpose: print the sections in the order decide.nix listed
    # them, with the labels it chose. All ordering and wording decisions
    # live next to the values they describe, so adding a row there needs
    # no change here. The key column is padded to the widest label in
    # THAT section, so narrow sections stay narrow.
    jq -r '
      def pad($n): . + (" " * ($n - length));
      .[]
      | "\(.name)",
        ( (.rows | map(.k | length) | max) as $w
          | .rows[] | "  \(.k | pad($w))   \(.v)" ),
        ""
    ' "$out"
  '';
}
