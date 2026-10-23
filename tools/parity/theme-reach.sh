#!/usr/bin/env bash
# theme-reach: which installed apps the Golem palette reaches, and how.
# (Max, 2026-10-17: "cover as many apps as possible… there will be more cases".)
#
# For every app in the menus (.desktop files on the data path, NoDisplay and
# Hidden ones left out) it finds the program behind the Exec line — through
# Nix's wrapper scripts to the real binary — tells what it is built with
# (GTK 3/4, Qt 5/6, KDE, Electron, Java, Flatpak, a webapp, a terminal app…)
# and says whether Golem's theme reaches it:
#   covered   — a route writes its colours (GTK/Qt files, kdeglobals, VS Code,
#               JetBrains, Inkscape, foot…)
#   look      — it follows only dark/light (the portal's color-scheme)
#   MISSING   — nothing reaches it; the ROUTE column says what would
# One line an app: STATUS  TOOLKIT  ROUTE  NAME  (program). Bounded and
# tolerant: plain bash + coreutils + grep; a program it cannot read is "?".
set -u

data_dirs="${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Follow wrapper scripts (Nix's makeWrapper, shell launchers) to the binary.
real_program() {
  local p n=0 next
  p=$(command -v "$1" 2>/dev/null) || { echo ""; return; }
  p=$(readlink -f "$p")
  while [ $n -lt 6 ]; do
    # A compiled wrapper (Nix's makeBinaryWrapper) names the program it runs.
    if ! head -c 2 "$p" 2>/dev/null | grep -q '#!'; then
      next=$(grep -aoE '/nix/store/[a-z0-9]{32}-[^/]+/bin/\.[A-Za-z0-9_.+-]+-wrapped' "$p" 2>/dev/null | head -1)
      [ -n "$next" ] && [ -e "$next" ] && [ "$(readlink -f "$next")" != "$p" ] || break
      p=$(readlink -f "$next"); n=$((n + 1)); continue
    fi
    # The last absolute program the script execs (a -wrapped one first).
    next=$(grep -oE '/nix/store/[^ "'"'"']*/\.?[A-Za-z0-9_.+-]+-wrapped' "$p" 2>/dev/null | tail -1)
    [ -z "$next" ] && next=$(grep -E '^\s*exec ' "$p" 2>/dev/null | grep -oE '"?/[^ "]+' | tr -d '"' | tail -1)
    [ -z "$next" ] || [ ! -e "$next" ] && break
    p=$(readlink -f "$next"); n=$((n + 1))
  done
  echo "$p"
}

# What a program is built with.
toolkit() {
  local p=$1 base dir
  base=$(basename "$p"); dir=$(dirname "$p")
  case "$base" in
    java|*.jar) echo java; return;;
    electron*) echo electron; return;;
  esac
  [ -e "$dir/resources/app.asar" ] || [ -e "$dir/../resources/app.asar" ] || [ -e "$dir/../lib/resources/app.asar" ] && { echo electron; return; }
  # A script that runs java (IDEs, many Java apps).
  if head -c 2 "$p" 2>/dev/null | grep -q '#!'; then
    grep -qE '/bin/java|JAVA_HOME|\bjava\b' "$p" 2>/dev/null && { echo java; return; }
    # Python apps: what they import.
    grep -qE "require_version\(['\"]Gtk['\"], *['\"]4" "$p" 2>/dev/null && { echo gtk4; return; }
    grep -qE "require_version\(['\"]Gtk|from gi.repository import Gtk" "$p" 2>/dev/null && { echo gtk3; return; }
    grep -qE "PyQt6|PySide6" "$p" 2>/dev/null && { echo qt6; return; }
    grep -qE "PyQt5|PySide2" "$p" 2>/dev/null && { echo qt5; return; }
    grep -qE "chrome|chromium" "$p" 2>/dev/null && { echo chromium; return; }
    echo script; return
  fi
  [ -r "$p" ] || { echo '?'; return; }
  local libs
  # Everything it links, through its libraries (ldd), else its own names.
  if command -v ldd >/dev/null; then
    libs=$(timeout 5 ldd "$p" 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
  fi
  [ -z "${libs:-}" ] && libs=$(grep -aoE 'lib(gtk-[34]|Qt[56]Core|KF[56]CoreAddons|electron|SDL2|wx_gtk|fltk|webkit2gtk)[A-Za-z0-9_.-]*' "$p" 2>/dev/null | sort -u | tr '\n' ' ')
  case "$libs" in
    *KF6*|*KF5*) echo kde;;
    *Qt6Core*) echo qt6;;
    *Qt5Core*) echo qt5;;
    *gtk-4*) echo gtk4;;
    *gtk-3*|*wx_gtk*) echo gtk3;;
    *libmpv*|*libvlc*) echo media;;
    *libncurses*|*libtinfo*) echo tui;;
    *SDL2*) echo sdl;;
    *fltk*) echo fltk;;
    *)
      # Chromium/Electron builds link none of these by name.
      grep -aqm1 'Electron/' "$p" 2>/dev/null && { echo electron; return; }
      grep -aqm1 'Chrome/' "$p" 2>/dev/null && { echo chromium; return; }
      echo other;;
  esac
}

# The apps with a route of their own (checked before the toolkit's).
special() {
  case "$1" in
    seam*|firefox*) echo "covered|Seam's chrome + Dark Reader";;
    code|codium|code-oss|vscodium) echo "covered|VS Code colorCustomizations";;
    studio*|idea*|pycharm*|clion*|goland*|webstorm*|rider*|android-studio*) echo "covered|JetBrains theme plugin (restart)";;
    inkscape*) echo "covered|fixed GTK theme Golem (restart)";;
    foot*) echo "covered|foot.ini + live colour sequences";;
    nvim*) echo "covered|nvim.lua";;
    soffice*|libreoffice*) echo "covered|Golem's GTK theme (VCL gtk3; the page stays white)";;
    gimp*) echo "covered|its System theme on Golem's GTK, gimp.css spin scales (restart)";;
    blender*) echo "MISSING|Blender userpref theme XML";;
    krita*) echo "covered|Golem colour scheme (fit: kritarc [theme] Theme=Golem)";;
    shotcut*) echo "covered|its system theme on Golem's Qt palette (fit: Shotcut.conf theme=system)";;
    darktable*) echo "n/a|neutral greys by design (a photo editor judges colour)";;
    thunderbird*) echo "look|its own dark/light from the portal (legible; checked 2026-10-23)";;
    obsidian*) echo "MISSING|Obsidian CSS snippet";;
    discord*|vesktop*|slack*|signal*|element*|teams*) echo "look|Electron: dark/light only (no theme file of its own)";;
    kitty*) echo "MISSING|kitty include file";;
    alacritty*) echo "MISSING|Alacritty import file";;
    wezterm*) echo "MISSING|WezTerm colour scheme file";;
    ghostty*) echo "MISSING|Ghostty theme file";;
    konsole*) echo "covered|KDE colour scheme (Konsole profile: MISSING)";;
    steam*) echo "look|Steam: its own skin";;
    waverunner*) echo "covered|Golem's own (the dock's colours)";;
    btop*) echo "covered|btop golem.theme";;
    yazi*) echo "covered|yazi theme.toml";;
    lf) echo "covered|in the terminal (foot's colours)";;
    xterm*|.xterm*) echo "n/a|old X program (not themed by design)";;
    blueman*|..blueman*|thunar*|.thunar*) echo "covered|GTK 3 theme (Golem-A/B)";;
    lsp-plugins*) echo "MISSING|draws itself (its own skin)";;
    launch-arch-vm*|qemu*) echo "n/a|a virtual machine's own screen";;
    nvidia-settings*|.nvidia-settings*) echo "covered|GTK 3 theme (Golem-A/B)";;
    mpv*) echo "look|a player: draws its own controls";;
    scrcpy*|bash) echo "n/a|the phone's own screen";;
    *.html) echo "covered|opens in Seam";;
    google-chrome*|chromium*) echo "n/a|a browser: only Seam is coloured";;
    brave*) echo "n/a|a browser: only Seam is coloured";;
    vlc*|.vlc*) echo "covered|Qt interface (qt5ct/qt6ct)";;
    *) return 1;;
  esac
}

# What the toolkit's route gives.
route() {
  case "$1" in
    gtk3) echo "covered|GTK 3 theme (Golem-A/B)";;
    gtk4) echo "covered|GTK 4 libadwaita colours";;
    qt5|qt6) echo "covered|qt5ct/qt6ct colours";;
    kde) echo "covered|kdeglobals colour scheme";;
    electron|chromium) echo "look|Electron/Chromium: dark/light only";;
    java) echo "MISSING|Java: GTK look and feel (_JAVA_OPTIONS)";;
    sdl|fltk) echo "MISSING|draws itself (no route)";;
    tui) echo "covered|in the terminal (foot's colours)";;
    media) echo "look|a player: draws its own controls";;
    script) echo "?|a script (could not see the program)";;
    *) echo "?|unknown toolkit";;
  esac
}

declare -A seen
IFS=:
for d in $data_dirs; do
  for f in "$d"/applications/*.desktop; do
    [ -f "$f" ] || continue
    id=$(basename "$f")
    [ -n "${seen[$id]:-}" ] && continue
    seen[$id]=1
    grep -qiE '^(NoDisplay|Hidden)=true' "$f" && continue
    name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
    term=$(grep -m1 '^Terminal=' "$f" | cut -d= -f2-)
    unset IFS
    # The program: past env, flatpak, a seam webapp.
    set -- $exec
    while [ $# -gt 0 ] && { [ "$1" = env ] || [[ "$1" == *=* ]]; }; do shift; done
    prog=${1:-}
    case "$exec" in
      *"flatpak run"*|*/flatpak\ run*) printf '%-8s %-9s %-52s %s\n' "check" flatpak "Flatpak: needs the themes shared (override)" "$name"; IFS=:; continue;;
      *"-golem-app"*) printf '%-8s %-9s %-52s %s\n' covered webapp "Seam webapp (Seam's colours)" "$name"; IFS=:; continue;;
    esac
    real=$(real_program "$prog")
    base=$(basename "${real:-$prog}")
    if r=$(special "$(basename "$prog")") || r=$(special "$base"); then
      tk=$(toolkit "$real" 2>/dev/null)
    else
      tk=$(toolkit "$real"); r=$(route "$tk")
    fi
    [ -z "$real" ] && { tk='?'; r="?|program not found ($prog)"; }
    # (A terminal app wears the terminal's colours unless it has its own.)
    [ "$term" = true ] && [ "${r%%|*}" = '?' ] && { tk=tui; r="covered|in the terminal (foot's colours)"; }
    printf '%-8s %-9s %-52s %s  (%s)\n' "${r%%|*}" "$tk" "${r#*|}" "$name" "$base"
    IFS=:
  done
done | sort -k1,1 -k2,2
unset IFS
