# The UEFI half of the boot menu.
#
# WHY THIS EXISTS (Max, 2026-09-05, from the lab): "on the acer i just see
# Start at the left top corner, the selection is blue and it's the whole
# screen width. i try the usb on an older pc and it looked as we designed
# it." Both are the same stick — the difference is the FIRMWARE:
#
#   BIOS  → isolinux/syslinux → isoImage.syslinuxTheme (iso.nix) → themed
#   UEFI  → GRUB              → isoImage.grubTheme                → was null
#
# With grubTheme null, iso-image-golem.nix falls through to
# `set color_highlight=white/blue` over a background image, and GRUB draws
# its stock menu: top-left, full width, blue bar. That is exactly what the
# Acer showed. The old comment in iso.nix called it "close enough"; on real
# hardware it is the first thing a stranger sees, and half the machines in
# the lab boot this path.
#
# So: the same design, expressed twice, because two loaders draw it.
# Values here mirror iso.nix's syslinuxTheme deliberately —
#   background      #000000        MENU COLOR SCREEN black
#   unselected      #cccccc        MENU COLOR UNSEL  #FFCCCCCC
#   selected        #000000 on     MENU COLOR SEL    #FF000000 on #FFEEEEEE
#                   #eeeeee bar
# and the menu box is sized to hug the long label ("Install") the way
# syslinux's WIDTH 11 does, then centred.
#
# GRUB quirks worth knowing before editing:
#  - a desktop-image is REQUIRED; a pure desktop-color leaves artefacts
#    (the reference nixos-grub2-theme carries the same note).
#  - a selection BAR needs a pixmap; selected_item_color alone only
#    recolours the text. One centre slice is enough — GRUB stretches it.
#  - the font must be a .pf2, and iso-image-golem.nix loadfont's every
#    .pf2 it finds in this directory.
{ runCommand, imagemagick, binutils, nixos-grub2-theme }:

runCommand "golem-grub-theme" { nativeBuildInputs = [ imagemagick binutils ]; } ''
  mkdir -p $out

  # Reuse the .pf2 nixpkgs already ships rather than running grub-mkfont
  # for a face we are not choosing differently anyway. Its internal name
  # is read back below, never assumed.
  cp ${nixos-grub2-theme}/dejavu.pf2 $out/dejavu.pf2

  # PNG32: is load-bearing. GRUB's png module handles only truecolour
  # RGB/RGBA; a solid-colour image left to ImageMagick's own judgement
  # comes out 1-bit or 4-bit GRAYSCALE, and GRUB then fails the whole
  # theme with "error: png: color type not supported" — silently, behind
  # the "Loading graphical boot menu..." line, falling back to the text
  # menu. That error is only visible if you drop to the GRUB command line
  # and re-run `normal` by hand, which is how it was finally caught.
  magick -size 16x16 xc:'#000000' PNG32:$out/background.png
  magick -size 16x16 xc:'#eeeeee' PNG32:$out/select_c.png

  # Byte 25 of a PNG is the IHDR colour type: 2 = RGB, 6 = RGBA. Anything
  # else is a theme GRUB will refuse, so fail the build here rather than
  # ship an ISO that quietly looks wrong on every UEFI machine.
  for png in $out/background.png $out/select_c.png; do
    ct=$(od -An -tu1 -j25 -N1 "$png" | tr -d ' ')
    case "$ct" in
      2|6) ;;
      *) echo "$png has PNG colour type $ct; GRUB needs 2 (RGB) or 6 (RGBA)" >&2
         exit 1 ;;
    esac
  done

  # theme.txt is deliberately BARE: ASCII only and no comments inside the
  # component block. GRUB's theme parser is not a general config parser —
  # a `#` line between properties, or a stray non-ASCII byte, makes it
  # abandon the theme and silently fall back to the built-in text menu,
  # which looks exactly like having set no theme at all. That is a full
  # ISO rebuild per guess, so keep this file boring; the reasoning lives
  # in the Nix comments above, where it costs nothing.
  #
  # Geometry mirrors iso.nix's syslinuxTheme: left/width centre a box just
  # wide enough for "Install", item_color #cccccc on black, and the
  # selection is black text on the #eeeeee bar drawn by select_c.png.
  # THE FONT NAME MUST BE THE ONE INSIDE THE PF2, EXACTLY. This file is
  # generated with the name read out of the .pf2 at build time rather than
  # typed, because typing it is how this went wrong: "DejaVu Regular"
  # (which nixos-grub2-theme's own theme.txt uses) is NOT what
  # dejavu.pf2 registers - it registers "DejaVu Sans Regular 20". A name
  # GRUB cannot resolve makes it abandon the whole theme and fall back to
  # the built-in text menu, which looks identical to having set no theme,
  # so the failure is completely silent. Two ISO rebuilds were spent on
  # that. Deriving the name here means it cannot drift from the font.
  font_name=$(head -c 300 $out/dejavu.pf2 | strings | sed -n '/^PFF2NAME$/{n;p;}')
  [ -n "$font_name" ] || { echo "could not read the font name out of dejavu.pf2" >&2; exit 1; }
  echo "theme font: $font_name"

  cat > $out/theme.txt <<EOF
  desktop-image: "background.png"
  desktop-color: "#000000"
  title-text: ""

  + boot_menu {
      left = 50%-60
      top = 50%-32
      width = 120
      height = 64
      item_font = "$font_name"
      item_color = "#cccccc"
      item_height = 28
      item_spacing = 0
      item_padding = 2
      item_icon_space = 0
      selected_item_font = "$font_name"
      selected_item_color = "#000000"
      selected_item_pixmap_style = "select_*.png"
      scrollbar = false
  }
  EOF
''
