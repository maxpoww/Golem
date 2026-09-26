# desktop/fonts — stage 1. Ported from the fat system/configuration.nix: the
# OPTIONS bar's glyphs need the JetBrains Mono Nerd Font, and "sans-serif" is
# pinned to DejaVu deliberately (it used to fall back there by fontconfig
# accident). A real Golem UI font is still an open design call (todo7).
#
# CJK / Indic coverage for the global languages (Phase C) is NOT here yet —
# this is the Latin base every desktop needs. The IME + its fonts land with
# desktop/ime.nix.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    dejavu_fonts
  ];
  fonts.fontconfig.defaultFonts.sansSerif = [ "DejaVu Sans" ];
}
