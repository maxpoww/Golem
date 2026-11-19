# Files in the terminal: yazi.
{ ... }:

{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "alphabetical";
      };
      manager = {
        show_hidden = true;
        sort_by = "alphabetical";
      };
    };

    # THE PALETTE: the terminal's colour NAMES, not hex — foot's sixteen are
    # the palette's (the dock's foot.ini), so yazi follows Controls → Colours
    # and dark/light with no file of its own. (Was a fixed gruvbox.)
    theme = {
      mgr = {
        cwd = { fg = "yellow"; bold = true; };
        hovered = { fg = "black"; bg = "yellow"; bold = true; };
        selected = { fg = "black"; bg = "green"; bold = true; };
        border = { fg = "darkgray"; };
      };

      status = {
        mode_normal = { fg = "black"; bg = "blue"; bold = true; };
        mode_select = { fg = "black"; bg = "green"; bold = true; };
        mode_unset = { fg = "black"; bg = "magenta"; bold = true; };
        permissions_t = { fg = "blue"; };
        permissions_r = { fg = "yellow"; };
        permissions_w = { fg = "red"; };
        permissions_x = { fg = "green"; };
      };

      filetype = {
        rules = [
          { mime = "inode/directory"; fg = "yellow"; bold = true; }
          { mime = "image/*"; fg = "cyan"; }
          { mime = "video/*"; fg = "magenta"; }
          { mime = "audio/*"; fg = "magenta"; }
          { mime = "application/archive"; fg = "red"; }
          { mime = "application/zip"; fg = "red"; }
          { mime = "application/pdf"; fg = "yellow"; }
        ];
      };
    };
  };
}
