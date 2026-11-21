# Which program opens each kind of file.
{ lib, ... }:

{
  # ── Default apps (roadmap S5) ─────────────────────────────────────────
  # Every file type opens in the CURATE pick from golem-apps.nix. Without
  # this, "open with" is whatever alphabetical accident the desktop-file
  # scan lands on — the difference between Standard feeling assembled and
  # feeling like a pile of packages.
  #
  # Not wired here: text/html and the http/https schemes. Those ARE the
  # browser decision (todo5 item 1) — wiring them now would settle it by
  # the back door. They land in the same commit that answers it.
  #
  # First rebuild on a machine that already has a hand-written
  # ~/.config/mimeapps.list will stop and say the file is in the way:
  # move it aside, it is being replaced by this.
  xdg.mimeApps =
    let
      # Folders open in Golem Files — the shell's own file manager, whose
      # launcher the dock writes at its first start (launcher `filer.rs`);
      # Nautilus stays installed and is next in line.
      files = [
        "golem-files.desktop"
        "org.gnome.Nautilus.desktop"
      ];
      editor = [ "org.gnome.TextEditor.desktop" ];
      images = [ "org.gnome.Loupe.desktop" ];
      # mpv plays both (zsh.nix ships it with MPRIS); Showtime and Decibels
      # left with the debloat (2026-09-29).
      video = [ "mpv.desktop" ];
      audio = [ "mpv.desktop" ];
      docs = [ "org.gnome.Papers.desktop" ];
      archives = [ "org.gnome.FileRoller.desktop" ];
    in
    {
      enable = true;
      defaultApplications = {
        "inode/directory" = files;

        "text/plain" = editor;
        "text/markdown" = editor;
        "text/csv" = editor;
        "text/x-log" = editor;
        "application/json" = editor;
        "application/xml" = editor;
        "application/x-shellscript" = editor;
        "application/toml" = editor;
        "text/x-python" = editor;
        "text/x-csrc" = editor;
        "text/x-chdr" = editor;
        "text/rust" = editor;
        "text/x-nix" = editor;

        "image/png" = images;
        "image/jpeg" = images;
        "image/gif" = images;
        "image/webp" = images;
        "image/tiff" = images;
        "image/bmp" = images;
        "image/svg+xml" = images;
        "image/heif" = images;
        "image/avif" = images;

        "video/mp4" = video;
        "video/x-matroska" = video;
        "video/webm" = video;
        "video/quicktime" = video;
        "video/x-msvideo" = video;
        "video/mpeg" = video;

        "audio/mpeg" = audio;
        "audio/flac" = audio;
        "audio/ogg" = audio;
        "audio/x-vorbis+ogg" = audio;
        "audio/x-wav" = audio;
        "audio/mp4" = audio;
        "audio/x-opus+ogg" = audio;

        "application/pdf" = docs;
        "application/epub+zip" = docs;

        "application/zip" = archives;
        "application/x-tar" = archives;
        "application/gzip" = archives;
        "application/x-xz" = archives;
        "application/zstd" = archives;
        "application/x-7z-compressed" = archives;
        "application/vnd.rar" = archives;
        "application/x-bzip2" = archives;

        # A disk image opens as the archive it is (File Roller reads ISO
        # 9660). GNOME Disks left with the debloat, and with it Calendar,
        # Contacts and Maps: a calendar file, a contact card and a geo: link
        # have no default here until an app that opens them ships — a default
        # that names an app nobody installed only hides the ones that are.
        # (desktop-matrix: every default here is a desktop file of an app
        # the desktop really installs.)
        "application/x-cd-image" = archives;
      };
    };

  # Standard's defaults sit BELOW the owner's choice (2026-10-13, the control
  # panel's "Default apps"). home-manager writes the table twice: as
  # ~/.config/mimeapps.list, and as ~/.local/share/applications/mimeapps.list.
  # The first is the file `xdg-mime default` and every "always open with" box
  # write to — as a read-only link of ours nobody could ever change a default
  # (the panel's pick failed in silence, so did Nautilus'). So only the
  # second is ours: the lookup reads the owner's file first and falls through
  # to it, type by type.
  xdg.configFile."mimeapps.list".enable = lib.mkForce false;
}
