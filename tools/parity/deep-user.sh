#!/usr/bin/env bash
# golem deep probe, SESSION half: run it FROM INSIDE the graphical session
# (golem-deep has Hyprland spawn it), so permissions, environment, D-Bus and
# portals are read as an app launched from a keybind would see them. Plain
# bash; every probe is bounded and tolerant: a missing tool prints "n/a".
#
# Sections open with "===<name>===". Pair with deep-root.sh.
set -u
section() { printf '\n===%s===\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

section meta
echo "host=$(hostname) user=$(id -un) uid=$(id -u) date=$(date -Is)"
echo "groups=$(id -Gn)"
echo "session_id=${XDG_SESSION_ID:-unset} desktop=${XDG_CURRENT_DESKTOP:-unset} type=${XDG_SESSION_TYPE:-unset}"
echo "cgroup=$(cat /proc/self/cgroup 2>/dev/null | head -1)"

# The logind session an app belongs to decides what polkit lets it do
# (parity.md P5): Class=greeter or a seatless manager session is refused
# things a Class=user seat session gets for free.
section logind
if have loginctl; then
  for s in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
    loginctl show-session "$s" -p Id -p Class -p Type -p Seat -p Active -p Service -p State -p IdleHint 2>/dev/null | tr '\n' ' '; echo
  done
  echo "self: $(loginctl show-session self -p Id -p Class -p Seat 2>/dev/null | tr '\n' ' ')"
else echo n/a; fi

# What an app in this session may do without a password prompt.
section polkit
if have pkcheck; then
  for a in org.freedesktop.login1.power-off org.freedesktop.login1.reboot org.freedesktop.login1.suspend \
           org.freedesktop.login1.hibernate org.freedesktop.login1.inhibit-block-idle \
           org.freedesktop.udisks2.filesystem-mount org.freedesktop.udisks2.eject-media \
           org.freedesktop.NetworkManager.network-control org.freedesktop.NetworkManager.settings.modify.system \
           org.freedesktop.NetworkManager.enable-disable-wifi org.freedesktop.NetworkManager.wifi.scan \
           org.freedesktop.timedate1.set-timezone org.freedesktop.hostname1.set-hostname; do
    out=$(pkcheck --action-id "$a" --process $$ 2>&1); rc=$?
    case $rc in 0) r=yes;; 1) r=NO;; 2) r="NO(auth needed)";; *) r="rc$rc";; esac
    printf '%-58s %s\n' "$a" "$r"
  done
else echo n/a; fi

section env
for k in SHELL PATH LANG LC_ALL LC_TIME EDITOR VISUAL TERMINAL BROWSER \
         XDG_DATA_DIRS XDG_CONFIG_DIRS XDG_RUNTIME_DIR XDG_SESSION_DESKTOP \
         QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION GDK_BACKEND MOZ_ENABLE_WAYLAND \
         NIXOS_OZONE_WL ELECTRON_OZONE_PLATFORM_HINT SDL_VIDEODRIVER CLUTTER_BACKEND \
         XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE GTK_THEME \
         LIBVA_DRIVER_NAME WLR_NO_HARDWARE_CURSORS __GLX_VENDOR_LIBRARY_NAME; do
  printf '%s=%s\n' "$k" "${!k-<unset>}"
done

section dbus_user
if have busctl; then
  busctl --user list --no-legend 2>/dev/null | awk '{print $1}' | grep -E 'Notifications|portal|ScreenSaver|secrets|PowerManagement|kwalletd|gnome' | sort
  echo "-- notifications server:"
  busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications GetServerInformation 2>&1 | head -2
else echo n/a; fi

section portals
if have busctl; then
  for i in FileChooser Screenshot ScreenCast Settings OpenURI Notification Inhibit; do
    v=$(busctl --user get-property org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.$i version 2>&1 | tail -1)
    printf '%-14s %s\n' "$i" "$v"
  done
  for f in "$HOME/.config/xdg-desktop-portal/"*.conf /etc/xdg/xdg-desktop-portal/*.conf "${XDG_DATA_DIRS//:/ }"; do :; done
  ls "$HOME/.config/xdg-desktop-portal/" /etc/xdg/xdg-desktop-portal/ 2>/dev/null | head
  for f in "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf" /etc/xdg/xdg-desktop-portal/hyprland-portals.conf /etc/xdg/xdg-desktop-portal/portals.conf; do [ -e "$f" ] && { echo "-- $f"; cat "$f"; }; done
  pgrep -a -f 'xdg-desktop-portal' | sed -E 's#/nix/store/[^/]+/#…/#' | cut -c1-100
else echo n/a; fi

section fonts
if have fc-match; then
  for f in sans-serif serif monospace emoji "JetBrainsMono Nerd Font Mono" "JetBrainsMono Nerd Font" "Noto Color Emoji" "DejaVu Sans"; do
    printf '%-30s -> %s\n' "$f" "$(fc-match "$f" 2>/dev/null)"
  done
  echo "families=$(fc-list : family 2>/dev/null | sort -u | wc -l)"
else echo n/a; fi

# Every default handler must point at an entry that exists and runs.
section xdg_defaults
if have xdg-mime; then
  echo "browser=$(xdg-settings get default-web-browser 2>/dev/null)"
  for m in text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/mailto inode/directory \
           text/plain image/png image/jpeg video/mp4 audio/mpeg application/pdf application/zip; do
    id=$(xdg-mime query default "$m" 2>/dev/null)
    st="unset"
    if [ -n "$id" ]; then
      f=""; for d in "$HOME/.local/share" ${XDG_DATA_DIRS//:/ }; do [ -e "$d/applications/$id" ] && { f="$d/applications/$id"; break; }; done
      if [ -z "$f" ]; then st="MISSING entry"
      else
        prog=$(grep -m1 -E '^Exec=' "$f" | sed -E 's/^Exec=//; s/^env( [A-Za-z_]+=[^ ]*)+ //' | awk '{print $1}')
        if [ "${prog#/}" != "$prog" ]; then [ -x "$prog" ] && st=ok || st="DEAD exec $prog"
        else command -v "$prog" >/dev/null 2>&1 && st=ok || st="DEAD exec $prog"; fi
      fi
    fi
    printf '%-30s %-40s %s\n' "$m" "${id:--}" "$st"
  done
  echo "mimeapps: $(ls -la "$HOME/.config/mimeapps.list" 2>&1 | cut -c1-90)"
else echo n/a; fi

section hyprland
if have hyprctl; then
  hyprctl version 2>/dev/null | head -1
  echo "-- devices:"; hyprctl devices 2>/dev/null | grep -E 'Keyboard at|Touchpad|main:|active keymap|rules:' | head -12
  echo "-- clients (xwayland=1 means an X11 app, blurry at fractional scale):"
  hyprctl clients -j 2>/dev/null | grep -oE '"class": "[^"]*"|"xwayland": (true|false)' | paste - - | sort | uniq -c
  echo "-- monitors:"; hyprctl monitors 2>/dev/null | grep -E 'Monitor|@|scale|vrr|dpms'
  echo "-- idle/lock daemons: $(pgrep -a -x hypridle hyprlock swayidle swaylock 2>/dev/null | wc -l)"
else echo n/a; fi

section audio
if have wpctl; then wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' | grep -E '^\s*(├|└|│)?\s*\*?\s*[0-9]+\.|Default|Sinks|Sources' | head -12; else echo n/a; fi

section network
if have nmcli; then
  nmcli -t -f RUNNING,STATE,CONNECTIVITY,WIFI general 2>/dev/null
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | grep -v '^lo'
  nmcli -t -f NAME,TYPE,AUTOCONNECT con 2>/dev/null | head -5
fi
t0=$(date +%s%N); getent hosts nixos.org >/dev/null 2>&1 && echo "dns nixos.org: $(( ($(date +%s%N)-t0)/1000000 ))ms" || echo "dns nixos.org: FAIL"
gw=$(ip route 2>/dev/null | awk '/^default/{print $3; exit}'); [ -n "$gw" ] && echo "gateway $gw: $(ping -c1 -W1 "$gw" 2>/dev/null | grep -oE 'time=[0-9.]+ ms' || echo FAIL)"
have resolvectl && resolvectl status 2>/dev/null | grep -E 'Current DNS|DNS Servers' | head -2

section clipboard
if have wl-paste; then wl-paste -l 2>&1 | head -3; else echo "wl-paste: n/a"; fi

section seam
if have seam; then
  echo "seam=$(readlink -f "$(command -v seam)")"
  echo "running=$(pgrep -fc '[s]eam-[0-9.]+/bin/firefox') main proc(s)"
  echo "default browser: $(xdg-settings get default-web-browser 2>/dev/null)"
  j="$HOME/.local/share/seam/golem-media.json"
  if [ -e "$j" ]; then
    grep -E '"(at|firefox|adapterDescription|hardwareDecode|windowProtocol)"' "$j" | tr -d ' ' | tr '\n' ' '; echo
    grep -A5 '"display"' "$j" | tr -d ' \n' | cut -c1-120; echo
    grep -A4 '"memory"' "$j" | tr -d ' \n' | cut -c1-120; echo
    grep -E '"(blockForStreaming|status|weight)"' "$j" | tr -d ' ' | tr '\n' ' '; echo
  else echo "no golem-media.json"; fi
  du -sh "$HOME/.local/share/seam" 2>/dev/null
else echo "seam: n/a"; fi

section user_units
if have systemctl; then
  systemctl --user --failed --no-legend --plain 2>/dev/null
  for u in waverunner options-notify pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk; do
    printf '%-30s %s restarts=%s\n' "$u" "$(systemctl --user is-active "$u" 2>/dev/null)" "$(systemctl --user show "$u" -p NRestarts --value 2>/dev/null)"
  done
else echo n/a; fi

section user_dirs
for d in DESKTOP DOWNLOAD DOCUMENTS PICTURES; do
  p=$(xdg-user-dir $d 2>/dev/null); printf '%-10s %s %s\n' "$d" "$p" "$([ -d "$p" ] && echo exists || echo MISSING)"
done

section locale_time
locale 2>/dev/null | grep -E '^(LANG|LC_TIME|LC_NUMERIC)='
have timedatectl && timedatectl show -p Timezone -p NTPSynchronized -p NTP 2>/dev/null | tr '\n' ' '; echo

section perf_idle
sample() { awk '{print $14+$15}' "/proc/$1/stat" 2>/dev/null; }
pids="$(pgrep -x Hyprland || pgrep -x .Hyprland-wrapp) $(pgrep -f 'bin/\.?waverunner(-wrapped)?$' | head -1) $(pgrep -f '[s]eam-[0-9.]+/bin/firefox' | head -1)"
declare -A a0; for p in $pids; do [ -n "$p" ] && a0[$p]=$(sample "$p"); done
sleep 3
for p in $pids; do [ -n "$p" ] && printf '%-18s %s%% of a core\n' "$(cat /proc/$p/comm 2>/dev/null)" "$(( ($(sample "$p")-${a0[$p]:-0})*100/300 ))"; done
free -m | awk '/^Mem:/{printf "mem used %d MB of %d, avail %d\n",$3,$2,$7} /^Swap:/{printf "swap used %d MB of %d\n",$3,$2}'
cat /proc/pressure/cpu 2>/dev/null | head -1

# THE COLOURS (Controls → Colours + Dark mode; waverunner palette.rs): what
# the dock wrote for the apps, and whether each consumer can see it from
# INSIDE the session. A MISSING / NO / "No schemas" here is a finding: the
# palette reaches the apps only through these files, keys and variables.
section colours
T=${XDG_STATE_HOME:-$HOME/.local/state}/golem/theme
C=${XDG_CONFIG_HOME:-$HOME/.config}
D=${XDG_DATA_HOME:-$HOME/.local/share}
P=/etc/profiles/per-user/$(id -un)
if [ -d "$T" ]; then
  for f in colors.json foot.ini hyprlock.conf gtk4.css qt.conf qt5.conf nvim.lua; do
    if [ -s "$T/$f" ]; then printf '  %-14s ok %6s B  written %ss ago\n' "$f" "$(stat -c %s "$T/$f")" "$(( $(date +%s) - $(stat -c %Y "$T/$f") ))"
    else printf '  %-14s MISSING\n' "$f"; fi
  done
  echo "  colors.json: $(grep -E '"(name|palette|dark|dynamic|dark_websites|accent|base01)"' "$T/colors.json" 2>/dev/null | tr -d ' \n')"
else echo "  theme dir MISSING: $T"; fi
echo "settings.json colors: $(tr -d ' \n' < "$C/golem/settings.json" 2>/dev/null | grep -o '"colors":{[^}]*}' | head -c 160)"
echo "dconf org/gnome/desktop/interface:"
for k in color-scheme gtk-theme icon-theme accent-color; do printf '  %-13s %s\n' "$k" "$(dconf read /org/gnome/desktop/interface/$k 2>&1 | head -c 60)"; done
echo "gsettings (session schemas): $(gsettings get org.gnome.desktop.interface gtk-theme 2>&1 | head -c 60)"
if have gdbus; then
  for k in color-scheme accent-color; do
    printf 'portal %-12s %s\n' "$k" "$(timeout 4 gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Settings.ReadOne org.freedesktop.appearance $k 2>&1 | head -c 70)"
  done
fi
adw=NO; for d in "$P/share/themes" /run/current-system/sw/share/themes "$D/themes"; do [ -e "$d/adw-gtk3/gtk-3.0/gtk.css" ] && adw="$d"; done
echo "gtk: adw-gtk3=$adw  own themes: $(ls -d "$D"/themes/Golem-* 2>/dev/null | xargs -rn1 basename | tr '\n' ' ')"
for n in Golem-A Golem-B; do [ -d "$D/themes/$n" ] && echo "  $n: gtk-3.0=$( [ -s "$D/themes/$n/gtk-3.0/gtk.css" ] && echo ok || echo MISSING ) gtk-4.0=$( [ -s "$D/themes/$n/gtk-4.0/gtk.css" ] && echo ok || echo MISSING ) base=$(grep -o 'adw-gtk3[-a-z]*' "$D/themes/$n/gtk-3.0/gtk.css" 2>/dev/null | head -1)"; done
echo "  settings.ini: $(grep -E 'theme|dark' "$C/gtk-3.0/settings.ini" 2>/dev/null | tr '\n' ' ')"
echo "  gtk-4.0/gtk.css: $(head -c 110 "$C/gtk-4.0/gtk.css" 2>/dev/null | tr '\n' ' ')"
echo "qt: QT_QPA_PLATFORMTHEME=${QT_QPA_PLATFORMTHEME:-<unset>}"
echo "  qt5ct: $(grep color_scheme_path "$C/qt5ct/qt5ct.conf" 2>/dev/null || echo MISSING)  qt6ct: $(grep color_scheme_path "$C/qt6ct/qt6ct.conf" 2>/dev/null || echo MISSING)"
for f in qt.conf qt5.conf; do [ -f "$T/$f" ] && echo "  $f roles: $(sed -n 2p "$T/$f" | tr ',' '\n' | wc -l)"; done
echo "  platformthemes on QT_PLUGIN_PATH: $(for d in ${QT_PLUGIN_PATH//:/ }; do ls "$d/platformthemes" 2>/dev/null | grep -o 'qt[56]ct'; done | sort -u | tr '\n' ' ')"
echo "foot: $(grep -h '^include' "$C/foot/foot.ini" 2>/dev/null | head -1)  check-config=$(have foot && (foot --check-config >/dev/null 2>&1 && echo ok || echo FAIL) || echo n/a)"
echo "hyprlock: $(grep -h '^source' "$C/hypr/hyprlock.conf" 2>/dev/null | head -1 | cut -c1-80)  theme vars: $(grep -c 'golem_' "$T/hyprlock.conf" 2>/dev/null)"
if have hyprctl; then
  echo "hyprland: active_border=$(hyprctl getoption general:col.active_border 2>/dev/null | head -1 | cut -c1-70)"
  echo "          inactive=$(hyprctl getoption general:col.inactive_border 2>/dev/null | head -1 | cut -c1-40)  background=$(hyprctl getoption misc:background_color 2>/dev/null | head -1 | cut -c1-30)"
fi
echo "btop: $(grep color_theme "$C/btop/btop.conf" 2>/dev/null || echo 'no conf')  theme file: $( [ -s "$C/btop/themes/golem.theme" ] && echo ok || echo MISSING)"
echo "nvim: theme file $( [ -s "$T/nvim.lua" ] && echo ok || echo MISSING )  mini.nvim: $(ls "$P"/share/nvim/site/pack/*/start/ 2>/dev/null | grep -c mini)"
echo "obs: $(grep -A3 '^\[Appearance\]' "$C/obs-studio/user.ini" 2>/dev/null | grep '^Theme' || echo 'no user.ini / no Theme')"
seamdir=$(dirname "$(dirname "$(readlink -f "$(command -v seam 2>/dev/null)" 2>/dev/null)")")
echo "seam: dark reader in profile: $(grep -o '"addon@darkreader.org"' "$D/seam/extensions.json" 2>/dev/null | head -1 || echo NO)  chrome script palette: $(grep -ac 'SEAM PALETTE' "$seamdir"/lib/firefox-bin-*/mozilla.cfg 2>/dev/null | head -1)  userChrome golem-bg: $(grep -c 'golem-bg' "$D/seam/chrome/userChrome.css" 2>/dev/null)"
echo "yazi: hex colours in theme.toml: $(grep -c '"#' "$C/yazi/theme.toml" 2>/dev/null) (0 = the terminal's names)"
echo "icons: $(ls -d "$P"/share/icons/Golem* 2>/dev/null | xargs -rn1 basename | tr '\n' ' ') golem-files dark tone: $(grep -o '#737882' "$P/share/icons/Golem-Dark/scalable/apps/golem-files.svg" 2>/dev/null | head -1 | sed 's/#737882/graphite/')"
echo "dock: $(pgrep -a -x waverunner | head -1 | cut -c1-90)"
pl=$(journalctl --user -u waverunner --no-pager 2>/dev/null | grep 'palette:' | tail -1 | cut -c1-120)
[ -n "$pl" ] || pl=$(grep 'palette:' "$HOME/.local/state/waverunner/daemon.log" 2>/dev/null | tail -1 | cut -c1-120)
echo "dock log: ${pl:-no palette line}"
