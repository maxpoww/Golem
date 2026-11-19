# The terminal: foot, and the answer to "which terminal opens a
# Terminal=true program".
{ ... }:

{
  # Which terminal a Terminal=true entry (nvim.desktop, …) opens in.
  xdg.configFile."xdg-terminals.list".text = "foot.desktop\n";

  programs.foot = {
    enable = true;
    settings = {
      main = {
        # The colours are the PALETTE's (Controls → Colours): the dock writes
        # both variants there and switches running terminals between them
        # with a signal (waverunner palette.rs). Seeded empty below, so a
        # terminal opened before the dock's first write still starts.
        include = "~/.local/state/golem/theme/foot.ini";
        font = "JetBrainsMono Nerd Font:size=16";
        pad = "12x12";
        box-drawings-uses-font-glyphs = "yes";
      };
      scrollback = {
        multiplier = 10;
      };
      mouse = {
        hide-when-typing = "yes";
      };
      key-bindings = {
        clipboard-paste = "Control+v";
      };
    };
  };
}
