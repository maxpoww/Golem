# desktop/apps — the app set, stage 1: what opening a file needs.
#
# Golem's CURATE column lives in system/golem-apps.nix (the fat profile imports
# it too); this leaf is that file's place on the Modular desktop, so both
# profiles ship the same core (Nautilus, File Roller, Text Editor, Loupe,
# Papers) and the same system-wide emoji input.
#
# Landed 2026-09-30 (deep debug, parity P9): an installed Golem had NO
# file-opening app at all — every default in the home layer's mimeapps pointed
# at an app that was never shipped, so "open folder" resolved to a dead entry,
# images and PDFs to whatever browser the owner happened to install, and text
# files to nothing.
{ ... }:

{
  imports = [ ../../golem-apps.nix ];
}
