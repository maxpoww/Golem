# golem-postinstall-questions — given this machine's facts, print the list
# of post-install questions Golem will ask once there is a desktop
# (postinstall/postinstall.md, changes.md #33).
#
#   golem-postinstall-questions                 # probe this machine, print JSON
#   golem-postinstall-questions --facts FILE    # replay a committed fixture
#
# Sibling of golem-hw-decide (decide.nix), same reasoning: the eval matrix
# proves the modules react to facts correctly in CI, on fixtures; this runs
# on the metal against facts measured seconds earlier, through the same
# lib.golem.postinstallQuestions the CI matrix would check. golem-install
# calls this once, at install time (there is no boot-audit-time use for
# it — a question about the OWNER's judgement can't be answered before
# there is an owner sitting at a desktop), and drops the result into
# hosts/target/postinstall-questions.json, the fourth dropped file.
#
# Always JSON: unlike golem-hw-decide there is no human reading this
# directly on the console — its only consumer is golem-install (this file)
# and, later, golem-postinstall-ask on the installed system. A --human mode
# can be added the day a person actually wants to eyeball it; until then a
# second renderer is speculative surface.
#
# OFFLINE BY CONSTRUCTION, same --override-input pinning as golem-hw-decide
# — see that file's header for why `--offline --impure path:$src#...` is
# spelled exactly this way.
{ pkgs, golemSrc, overrideArgs }:

pkgs.writeShellApplication {
  name = "golem-postinstall-questions";
  runtimeInputs = [ pkgs.coreutils pkgs.nix ];
  text = ''
    facts=""
    src="${golemSrc}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --facts) facts="''${2:?--facts needs a file}"; shift 2 ;;
        --src)   src="''${2:?--src needs a directory}"; shift 2 ;;
        -h|--help)
          echo "usage: golem-postinstall-questions [--facts FILE] [--src DIR]"; exit 0 ;;
        *) echo "golem-postinstall-questions: unknown argument '$1'" >&2; exit 2 ;;
      esac
    done

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    if [[ -z "$facts" ]]; then
      golem-hw-detect > "$work/golem-hardware.nix"
      facts="$work/golem-hardware.nix"
      echo "probed this machine → $(grep -c . "$facts") lines of facts" >&2
    fi
    facts=$(realpath "$facts")

    # See golem-hw-decide for why --impure + the literal `path:` scheme are
    # both load-bearing, not decoration, here too.
    if ! nix eval --offline --no-write-lock-file --impure --json \
      ${overrideArgs} \
      "path:$src#lib.golem.postinstallQuestions" --apply "f: f (import $facts)" \
      > "$work/questions.json" 2> "$work/eval.err"; then
      cat "$work/eval.err" >&2
      echo "golem-postinstall-questions: evaluation failed (facts: $facts)" >&2
      exit 1
    fi

    cat "$work/questions.json"
  '';
}
