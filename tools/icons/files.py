#!/usr/bin/env python3
"""Golem's FILE and DATA icons (Max, 2026-10-14: "with this model, make the
icons for different formats, files, data… all but apps"): the folders' model —
the dock figures' cast grey, a gloss, a bevel, a ROUND symbol engraved — on a
sheet with its corner folded (mimetypes/) and on a drive's box (devices/).
One file per freedesktop name; the names that mean the same thing are links
to it. Run again after any change."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make import shape, line, W, B, MASK, centred, variant, OUT

HERE = os.path.dirname(os.path.abspath(__file__))

DEFS = """
    <linearGradient id="front" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#eef0f3"/><stop offset="1" stop-color="#c2c6cd"/></linearGradient>
    <linearGradient id="fold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#d9dce1"/><stop offset="1" stop-color="#a7acb5"/></linearGradient>
    <linearGradient id="gloss" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".35"/><stop offset=".55" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <filter id="bevel" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="-.6" stdDeviation="0" flood-color="#fff" flood-opacity=".5"/>
      <feDropShadow dx="0" dy="1.6" stdDeviation="1" flood-color="#000" flood-opacity=".45"/>
    </filter>"""

# A FILE is a SHEET with its corner folded (Max, 2026-10-14: the square tried
# first lost what says "a file" — and in Golem Files a file shows its own
# thumbnail whenever it can, so these are the fallbacks: keep the standard).
# Nearly 1x1, a little taller: 46 x 50, the symbol in the middle of it.
SHEET = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>{defs}{mask}
  </defs>
  <g transform="translate(9 7)">
    <path fill="url(#front)" filter="url(#bevel)" d="M4.5,0H35L46,11V45.5A4.5,4.5 0 0 1 41.5,50H4.5A4.5,4.5 0 0 1 0,45.5V4.5A4.5,4.5 0 0 1 4.5,0Z"/>
    <path fill="url(#gloss)" d="M4.5,0H35L46,11V45.5A4.5,4.5 0 0 1 41.5,50H4.5A4.5,4.5 0 0 1 0,45.5V4.5A4.5,4.5 0 0 1 4.5,0Z"/>
    <path fill="url(#fold)" d="M35,0V8A3,3 0 0 0 38,11H46Z"/>
    <path fill="#000" opacity=".12" d="M38,11H46L44.6,12.4H38.8Z"/>
    <rect fill="#fff" opacity=".55" x="4.5" y="0" width="29.6" height=".7" rx=".35"/>
  </g>{mark}
</svg>
"""
SHEET_MARK = """
  <g transform="translate(12.56 14.56) scale(1.62)">
    <rect x="-3" y="-3" width="30" height="30" fill="#fff" opacity=".6" mask="url(#sym)" transform="translate(0 .75)"/>
    <rect x="-3" y="-3" width="30" height="30" fill="#a1a6af" mask="url(#sym)"/>
  </g>"""

# A DEVICE has the sheets' near-square (Max, 2026-10-14: "a los dispositivos
# hacelos del mismo aspecto"): 46 x 50, no fold, a small green light at its foot.
DRIVE = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <defs>{defs}{mask}
  </defs>
  <g transform="translate(9 7)">
    <rect fill="url(#front)" filter="url(#bevel)" x="0" y="0" width="46" height="50" rx="6"/>
    <rect fill="url(#gloss)" x="0" y="0" width="46" height="50" rx="6"/>
    <rect fill="#fff" opacity=".55" x="6" y="0" width="34" height=".7" rx=".35"/>
    <circle fill="#7fd18b" cx="39" cy="43.5" r="1.5"/>
  </g>{mark}
</svg>
"""
DRIVE_MARK = """
  <g transform="translate(12.56 14.06) scale(1.62)">
    <rect x="-3" y="-3" width="30" height="30" fill="#fff" opacity=".6" mask="url(#sym)" transform="translate(0 .75)"/>
    <rect x="-3" y="-3" width="30" height="30" fill="#a1a6af" mask="url(#sym)"/>
  </g>"""

T = 1.7  # the width of a symbol's lines

SYM = {
    "lines": [line(W, f"M5 {y}h{w}", T) for y, w in [(6, 14), (10, 14), (14, 14), (18, 9)]],
    "document": [shape(W, 'rect x="4.4" y="4.4" width="15.2" height="3.6" rx="1.2"', 1)]
        + [line(W, f"M5 {y}h{w}", T) for y, w in [(11.6, 14), (15, 14), (18.4, 9)]],
    "pdf": [line(W, "M3.4 17.6V6.4h3a3 3 0 0 1 0 6h-3", T), line(W, "M10.6 17.6V6.4h1.8a4.6 4.6 0 0 1 0 11.2z", T),
            line(W, "M18.4 17.6V6.4h3.8", T), line(W, "M18.4 11.8h3.2", T)],
    "picture": [shape(W, 'rect x="3.8" y="5" width="16.4" height="14" rx="2.6"'), shape(B, 'rect x="6.2" y="7.4" width="11.6" height="9.2" rx="1.2"', 1),
                shape(W, 'path d="M6.6 16.2 10 12.2l2.8 3 1.6-1.6 3 2.6z"', 1.1), shape(W, 'circle cx="15" cy="10" r="1.2"', 1)],
    "video": [shape(W, 'rect x="3.6" y="5.8" width="16.8" height="12.4" rx="3.2"'), shape(B, 'path d="M10.4 9.4v5.2l4.4-2.6z"', 1.3)],
    "audio": [shape(W, 'circle cx="9.4" cy="17.2" r="2.8"'), line(W, "M12 17V5", 1.7), line(W, "M12 5c1.2 2.6 5 3 5.4 6", 1.7)],
    "archive": [shape(W, f'rect x="{9.4 + (k % 2) * 2.6}" y="{2.4 + k * 2.3}" width="2.6" height="1.6" rx=".6"', .4) for k in range(5)]
        + [shape(W, 'rect x="8.4" y="13.8" width="7.2" height="7.8" rx="2.2"'), shape(B, 'rect x="10.7" y="16.8" width="2.6" height="2.8" rx=".9"', .4)],
    "spreadsheet": [shape(W, 'rect x="4" y="4.6" width="16" height="14.8" rx="2.2"'), shape(B, 'rect x="5.8" y="9.4" width="5" height="3.8" rx=".5"', .4),
                    shape(B, 'rect x="12.6" y="9.4" width="5.6" height="3.8" rx=".5"', .4), shape(B, 'rect x="5.8" y="14.4" width="5" height="3.4" rx=".5"', .4),
                    shape(B, 'rect x="12.6" y="14.4" width="5.6" height="3.4" rx=".5"', .4)],
    "presentation": [shape(W, 'rect x="3.4" y="4" width="17.2" height="11.6" rx="2"'), shape(B, 'rect x="5.6" y="6.2" width="12.8" height="7.2" rx=".8"', .6),
                     shape(W, 'rect x="7.4" y="10.2" width="2" height="2.4" rx=".5"', .3), shape(W, 'rect x="11" y="8.2" width="2" height="4.4" rx=".5"', .3),
                     shape(W, 'rect x="14.6" y="9.2" width="2" height="3.4" rx=".5"', .3), line(W, "M12 15.6v3.4", T), line(W, "M8.6 20.2h6.8", T)],
    "code": [line(W, "M8 7.4 3.6 12 8 16.6", 2), line(W, "M16 7.4l4.4 4.6-4.4 4.6", 2), line(W, "M13.4 5.4l-2.8 13.2", 1.8)],
    "terminal": [line(W, "M5 7.6l4.4 4.4L5 16.4", 2), line(W, "M12.4 17h6.6", 2)],
    "web": [shape(W, 'circle cx="12" cy="12" r="8.4"', .6), shape(B, 'circle cx="12" cy="12" r="6.8"', .4),
            line(W, "M12 4v16", 1.4), line(W, "M4.4 12h15.2", 1.4), line(W, "M12 4.4c-2.6 2.2-3.8 4.8-3.8 7.6s1.2 5.4 3.8 7.6", 1.4),
            line(W, "M12 4.4c2.6 2.2 3.8 4.8 3.8 7.6s-1.2 5.4-3.8 7.6", 1.4)],
    "json": [line(W, "M8.4 4.8c-2 0-2.4 1-2.4 2.6v1.8c0 1.4-.6 2.2-2 2.8 1.4.6 2 1.4 2 2.8v1.8c0 1.6.4 2.6 2.4 2.6", 1.8),
             line(W, "M15.6 4.8c2 0 2.4 1 2.4 2.6v1.8c0 1.4.6 2.2 2 2.8-1.4.6-2 1.4-2 2.8v1.8c0 1.6-.4 2.6-2.4 2.6", 1.8)],
    "markdown": [line(W, "M3.6 17V7l4 5 4-5v10", 1.9), line(W, "M17.6 7v10", 1.9), line(W, "M14.6 14l3 3 3-3", 1.9)],
    "csv": [line(W, f"M4 {y}h16", 1.5) for y in (6.4, 12, 17.6)] + [line(W, f"M{x} 4v16", 1.5) for x in (9.4, 14.6)],
    "font": [line(W, "M2.8 18.6 7.6 5.6l4.8 13", 1.9), line(W, "M4.6 14h6", 1.9), shape(W, 'circle cx="17.2" cy="15.4" r="2.8"', .4),
             shape(B, 'circle cx="17.2" cy="15.4" r="1.3"', .3), line(W, "M20.4 12.2v6.4", 1.7)],
    "disc": [shape(W, 'circle cx="12" cy="12" r="8.6"', .6), shape(B, 'circle cx="12" cy="12" r="2.2"', .4),
             line(B, "M12 5.4a6.6 6.6 0 0 1 6.6 6.6", 1)],
    "book": [shape(W, 'path d="M12 6.6C10 5 7 4.6 3.6 5v13.4c3.4-.4 6.4 0 8.4 1.6z"', 1.2),
             shape(W, 'path d="M12 6.6c2-1.6 5-2 8.4-1.6v13.4c-3.4-.4-6.4 0-8.4 1.6z"', 1.2), line(B, "M12 7v12.6", .9)],
    "calendar": [shape(W, 'rect x="3.8" y="5.2" width="16.4" height="15" rx="2.6"'), shape(B, 'rect x="5.8" y="10" width="12.4" height="8.4" rx="1"', .4),
                 line(W, "M8.2 3.4v3.4", 1.8), line(W, "M15.8 3.4v3.4", 1.8)]
        + [shape(W, f'circle cx="{x}" cy="{y}" r=".9"', .3) for x in (8.4, 12, 15.6) for y in (12.6, 15.8)],
    "contact": [shape(W, 'rect x="3.8" y="4" width="16.4" height="16" rx="2.6"'), shape(B, 'circle cx="12" cy="10" r="2.6"', .4),
                shape(B, 'path d="M7.2 17.6a4.8 4.8 0 0 1 9.6 0z"', .6)],
    "database": [shape(W, 'path d="M5 6.4c0-1.6 3.1-2.8 7-2.8s7 1.2 7 2.8v11.2c0 1.6-3.1 2.8-7 2.8s-7-1.2-7-2.8z"', 1),
                 line(B, "M5.4 10.2c1.2 1.2 3.8 1.9 6.6 1.9s5.4-.7 6.6-1.9", 1), line(B, "M5.4 14.6c1.2 1.2 3.8 1.9 6.6 1.9s5.4-.7 6.6-1.9", 1)],
    "unknown": [line(W, "M8.6 9a3.4 3.4 0 1 1 5 3c-1 .6-1.6 1.4-1.6 2.6v.6", 2.1), shape(W, 'circle cx="12" cy="19" r=".9"', 1.2)],
    "vector": [line(W, "M5 17.4C6.4 10.4 9.6 7 12 7s5.6 3.4 7 10.4", 1.6), line(W, "M5.6 7h12.8", 1),
               shape(W, 'rect x="3" y="15.6" width="4" height="4" rx="1"', .4), shape(W, 'rect x="17" y="15.6" width="4" height="4" rx="1"', .4),
               shape(W, 'rect x="10" y="5" width="4" height="4" rx="1"', .4)],
    "diff": [line(W, "M12 4.6v7", 2), line(W, "M8.4 8.1h7.2", 2), line(W, "M8.4 17.6h7.2", 2)],
    "key": [shape(W, 'circle cx="8" cy="12" r="4.4"', .6), shape(B, 'circle cx="8" cy="12" r="1.6"', .4),
            line(W, "M12.2 12h8.2", 2), line(W, "M17.2 12v3", 2), line(W, "M20.2 12v2.2", 2)],
    "drawing": [shape(W, 'circle cx="9" cy="9.6" r="5.2"', .6), shape(W, 'rect x="10.4" y="10.8" width="9.6" height="9.6" rx="2"', .6),
                shape(B, 'rect x="11.8" y="12.2" width="6.8" height="6.8" rx="1"', .4)],
    "subtitles": [shape(W, 'path d="M6 4.8h12a2.6 2.6 0 0 1 2.6 2.6v7.4A2.6 2.6 0 0 1 18 17.4h-6.4L7.4 20.6v-3.2H6a2.6 2.6 0 0 1-2.6-2.6V7.4A2.6 2.6 0 0 1 6 4.8z"', 1),
                  line(B, "M7.2 10h9.6", 1.4), line(B, "M7.2 13.4h5.6", 1.4)],
    "windows": [shape(W, f'rect x="{x}" y="{y}" width="6.6" height="6.6" rx="1.4"', .6) for x in (4.6, 12.8) for y in (4.6, 12.8)],
    "magnet": [line(W, "M6.4 4.6v7a5.6 5.6 0 0 0 11.2 0v-7", 3), line(B, "M4.6 8h3.6", 1), line(B, "M15.8 8h3.6", 1)],
    "pendrive": [shape(W, 'rect x="9.2" y="2.6" width="5.6" height="5" rx="1"', 1), shape(B, 'rect x="10.4" y="4" width="1.2" height="1.4" rx=".3"', .2),
                 shape(B, 'rect x="12.4" y="4" width="1.2" height="1.4" rx=".3"', .2),
                 shape(W, 'rect x="7.4" y="7.4" width="9.2" height="14" rx="2.6"'), shape(B, 'circle cx="12" cy="17.6" r="1.3"', .4)],
    "phone": [shape(W, 'rect x="5.6" y="3" width="12.8" height="18" rx="3.2"'), shape(B, 'rect x="7.6" y="5.6" width="8.8" height="10.6" rx="1.2"', 1),
              shape(B, 'circle cx="12" cy="18.4" r=".8"', 1)],
    "scanner": [shape(W, 'rect x="3" y="5.4" width="18" height="3.2" rx="1.4"'), shape(W, 'rect x="3" y="10.6" width="18" height="9" rx="2.4"'),
                line(B, "M6.4 14.4h11.2", 1.3), shape(B, 'circle cx="17.4" cy="17.4" r=".7"', .4)],
    "camera": [shape(W, 'rect x="8.4" y="4.2" width="7.2" height="4.4" rx="1.6"'), shape(W, 'rect x="3" y="6.8" width="18" height="13" rx="3"'),
               shape(B, 'circle cx="12" cy="13.3" r="3.9"', .4), shape(W, 'circle cx="12" cy="13.3" r="2"', .3), shape(W, 'circle cx="17.6" cy="9.8" r=".2"', .9)],
    "printer": [shape(W, 'rect x="7" y="3" width="10" height="5.4" rx="1"', 1), shape(W, 'rect x="3" y="8.2" width="18" height="9.4" rx="2.4"'),
                line(B, "M6.2 14.2h11.6", 1.4), shape(W, 'rect x="7.4" y="15" width="9.2" height="6" rx=".8"', .6),
                line(B, "M9.2 17.4h5.6", .8), line(B, "M9.2 19.2h3.6", .8), shape(B, 'circle cx="17.6" cy="11" r=".7"', .4)],
    "sdcard": [shape(W, 'path d="M10 3h6.4A1.6 1.6 0 0 1 18 4.6v14.8a1.6 1.6 0 0 1-1.6 1.6H7.6A1.6 1.6 0 0 1 6 19.4V7.2z"'),
               line(B, "M9.6 5.6v3", .9), line(B, "M12 4.8v3.8", .9), line(B, "M14.4 4.8v3.8", .9)],
    "harddisk": [shape(W, 'rect x="3" y="6.4" width="18" height="11.2" rx="3"'), line(B, "M6.6 12h7.2", 1.4),
                 shape(B, 'circle cx="17.2" cy="12" r="1"', .4)],
    "usb": [line(W, "M12 3.8v15", 1.8), line(W, "M12 15.6 7 12.2V9.6", 1.6), line(W, "M12 13.6l5-3.2V8.2", 1.6),
            shape(W, 'circle cx="7" cy="8.6" r="1.4"', .4), shape(W, 'rect x="15.8" y="6.6" width="2.6" height="2.6" rx=".6"', .4),
            shape(W, 'path d="M12 2.6 14 5.4H10z"', .6), shape(W, 'circle cx="12" cy="19.4" r="1.8"', .4)],
}

# name → (body, symbol, the names that are links to it)
ICONS = {
    "text-x-generic": ("sheet", "lines", ["text-plain", "text-x-log", "application-x-zerosize"]),
    "x-office-document": ("sheet", "document", ["application-msword", "application-rtf", "application-vnd.oasis.opendocument.text",
                          "application-vnd.openxmlformats-officedocument.wordprocessingml.document"]),
    "application-pdf": ("sheet", "pdf", []),
    "image-x-generic": ("sheet", "picture", ["image-png", "image-jpeg", "image-gif", "image-webp", "image-bmp", "image-tiff", "image-heif", "image-avif"]),
    "image-svg+xml": ("sheet", "vector", ["image-x-svg+xml"]),
    "video-x-generic": ("sheet", "video", ["video-mp4", "video-x-matroska", "video-webm", "video-quicktime", "video-x-msvideo"]),
    "audio-x-generic": ("sheet", "audio", ["audio-mpeg", "audio-flac", "audio-ogg", "audio-x-wav", "audio-mp4", "audio-x-opus+ogg"]),
    "package-x-generic": ("sheet", "archive", ["application-x-archive", "application-zip", "application-x-tar", "application-x-compressed-tar",
                          "application-x-7z-compressed", "application-x-rar", "application-vnd.rar", "application-gzip", "application-x-xz",
                          "application-x-bzip", "application-zstd", "application-x-zstd-compressed-tar"]),
    "x-office-spreadsheet": ("sheet", "spreadsheet", ["application-vnd.ms-excel", "application-vnd.oasis.opendocument.spreadsheet",
                             "application-vnd.openxmlformats-officedocument.spreadsheetml.sheet"]),
    "x-office-presentation": ("sheet", "presentation", ["application-vnd.ms-powerpoint", "application-vnd.oasis.opendocument.presentation",
                              "application-vnd.openxmlformats-officedocument.presentationml.presentation"]),
    "x-office-drawing": ("sheet", "drawing", ["application-vnd.oasis.opendocument.graphics"]),
    "text-x-script": ("sheet", "code", ["text-x-csrc", "text-x-chdr", "text-x-c++src", "text-x-python", "text-rust", "text-x-rust", "text-x-go",
                      "application-javascript", "text-javascript", "application-typescript", "text-css", "text-x-lua", "text-x-nix",
                      "application-toml", "application-x-yaml", "application-sql", "text-x-java", "application-xml", "text-xml"]),
    "application-x-shellscript": ("sheet", "terminal", ["text-x-shellscript", "application-x-executable", "application-x-sharedlib"]),
    "text-html": ("sheet", "web", ["application-xhtml+xml"]),
    "application-json": ("sheet", "json", []),
    "text-markdown": ("sheet", "markdown", ["text-x-markdown"]),
    "text-csv": ("sheet", "csv", ["text-x-csv", "text-tab-separated-values"]),
    "font-x-generic": ("sheet", "font", ["font-ttf", "font-otf", "font-woff", "font-woff2", "application-x-font-ttf"]),
    "application-x-cd-image": ("sheet", "disc", ["application-x-iso9660-image", "application-x-raw-disk-image"]),
    "application-epub+zip": ("sheet", "book", ["application-x-mobipocket-ebook", "image-vnd.djvu"]),
    "x-office-calendar": ("sheet", "calendar", ["text-calendar"]),
    "text-vcard": ("sheet", "contact", ["text-x-vcard", "text-directory"]),
    "application-vnd.sqlite3": ("sheet", "database", ["application-x-sqlite3", "x-office-database"]),
    "text-x-patch": ("sheet", "diff", ["text-x-diff"]),
    "application-pgp-keys": ("sheet", "key", ["application-x-pem-key", "application-pkcs12", "application-x-x509-ca-cert"]),
    "application-x-subrip": ("sheet", "subtitles", ["text-vtt", "application-x-subtitle"]),
    "application-x-ms-dos-executable": ("sheet", "windows", ["application-x-msdownload", "application-x-msi"]),
    "application-x-bittorrent": ("sheet", "magnet", []),
    "unknown": ("sheet", "unknown", ["application-octet-stream"]),
    "drive-harddisk": ("drive", "harddisk", ["drive-harddisk-system", "drive-harddisk-solidstate"]),
    "drive-removable-media": ("drive", "usb", ["media-removable"]),
    "drive-optical": ("drive", "disc", ["media-optical"]),
    "drive-removable-media-usb-pendrive": ("drive", "pendrive", ["drive-removable-media-usb", "media-removable-usb"]),
    "media-flash": ("drive", "sdcard", ["media-flash-sd-mmc", "media-flash-memory-stick"]),
    "phone": ("drive", "phone", ["smartphone", "multimedia-player", "phone-android"]),
    "scanner": ("drive", "scanner", []),
    "camera-photo": ("drive", "camera", ["camera", "camera-web", "camera-video"]),
    "printer": ("drive", "printer", ["printer-network"]),
}

def write(path, svg):
    svg = variant(svg)
    with open(path + ".tmp", "w") as f:
        f.write(svg)
    os.replace(path + ".tmp", path)

def link(dirn, alias, target):
    path = os.path.join(dirn, alias + ".svg")
    if os.path.lexists(path):
        os.remove(path)
    os.symlink(target + ".svg", path)

count = 0
for name, (body, sym, aliases) in ICONS.items():
    dirn = os.path.join(OUT, "mimetypes" if body == "sheet" else "devices")
    os.makedirs(dirn, exist_ok=True)
    tmpl, mark = (SHEET, SHEET_MARK) if body == "sheet" else (DRIVE, DRIVE_MARK)
    svg = tmpl.replace("{defs}", DEFS).replace("{mask}", MASK.replace("{shapes}", centred("file:" + sym, SYM[sym]))).replace("{mark}", mark)
    write(os.path.join(dirn, name + ".svg"), svg)
    for a in aliases:
        link(dirn, a, name)
    count += 1 + len(aliases)
print("wrote", len(ICONS), "icons,", count, "names")
