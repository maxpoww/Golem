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
#
# NOT the input method golem-apps.nix also turns on (fcitx5): an IME is its
# own leaf (desktop/ime.nix, still to land, default.nix) and nobody decided to
# ship one here. Imported with the apps on 2026-09-30, it started with every
# session (app-org.fcitx.Fcitx5@autostart), put every keystroke through
# fcitx5 (the MacBook's main keyboard became its virtual keyboard) and sat in
# the Apps grid; the lock screen's password never matched while it ran.
{ lib, ... }:

{
  imports = [ ../../golem-apps.nix ];
  i18n.inputMethod.enable = lib.mkForce false;
}
