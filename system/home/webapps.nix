# Webapps: the catalog the dock's Install section offers (seeded once, then
# the owner's) and the icons bundled for them.
{ lib, ... }:

{
  # The webapps catalog: the dock's Install section offers these, and a webapp
  # runs in Seam (seam -golem-app <slug> <url>, the WEBAPPS module in
  # seam/golem-chrome.js). Seeded once and then the owner's to edit: the dock
  # owns the file after that. (Held back 2026-09-29..30 while webapps still
  # launched through Chrome, which Golem does not ship.)
  home.activation.seedWebappsList = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/webapps.list" ]; then
      $DRY_RUN_CMD install -Dm644 ${./webapps.list} "$HOME/.config/webapps.list"
    fi
  '';

  # Bundled webapp icons
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-claude.svg".source = ./webapp-claude.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-whatsapp.svg".source = ./webapp-whatsapp.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-gemini.svg".source = ./webapp-gemini.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-twitch.svg".source = ./webapp-twitch.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-zoom.svg".source = ./webapp-zoom.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-snapchat.svg".source = ./webapp-snapchat.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-pinterest.svg".source = ./webapp-pinterest.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-ebay.svg".source = ./webapp-ebay.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-chatgpt.svg".source = ./webapp-chatgpt.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-stackoverflow.svg".source = ./webapp-stackoverflow.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-airbnb.svg".source = ./webapp-airbnb.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-cloudflare.svg".source = ./webapp-cloudflare.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-coinbase.svg".source = ./webapp-coinbase.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-messenger.svg".source = ./webapp-messenger.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-asana.svg".source = ./webapp-asana.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-vercel.svg".source = ./webapp-vercel.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-linkedin.svg".source = ./webapp-linkedin.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-canva.svg".source = ./webapp-canva.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-aliexpress.svg".source = ./webapp-aliexpress.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/webapp-booking.svg".source = ./webapp-booking.svg;
}
