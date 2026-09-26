{ ... }:

# Beam — Golem's browser, as ONE module. Import this directory:
#   Golem flake: golemModules (desktop composition)
#   dev box:     /etc/nixos/configuration.nix
# The per-user half (prefs, look, profile) is ./home.nix, imported by the home layer.
#   ./browser.nix   Firefox build (Mozilla's, pinned) + policies + chrome script
#   ./lane.nix      security update lane: beam-update.timer, beam-update, beam-selftest
# See ./README.md.
{
  imports = [ ./browser.nix ./lane.nix ];
}
