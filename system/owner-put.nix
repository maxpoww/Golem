# golem-owner-put DEST: stdin into DEST, by a fresh temp file beside it and a
# rename, so a reader never sees half a file. The root helpers
# (waverunner-apply, golem-postinstall-apply) run it AS THE OWNER, with
# runuser, for every write into the owner's folders: root writing there by
# name can be steered by a link the owner swaps in between two of root's
# steps, and as the owner a link leads only to what the owner could already
# touch (18-Nov).
pkgs:
pkgs.writeShellScript "golem-owner-put" ''
  set -eu
  t=$(${pkgs.coreutils}/bin/mktemp --suffix=.tmp "$1.XXXXXX")
  if ${pkgs.coreutils}/bin/cat > "$t" && ${pkgs.coreutils}/bin/chmod 644 "$t" && ${pkgs.coreutils}/bin/mv -f "$t" "$1"; then exit 0; fi
  ${pkgs.coreutils}/bin/rm -f "$t"
  exit 1
''
