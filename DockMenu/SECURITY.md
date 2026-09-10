# SECURITY — the dock/menubox threat model

> "This one can't be Golem's backdoor." (Max, 2026-09-09.) The dock is
> where a Golem system's trust concentrates: it captures the clipboard
> and notifications, runs a Chrome, fetches network content, and drives
> a ROOT rebuild pipeline. This file is the honest map: what's sound,
> what was fixed, and the one architectural decision only Max can make.

## The privilege boundary (audited SOUND)

The user→root surface is `packages.list` → the root `waverunner-apply`
helper. The design is right:

- The helper parses the user file as **data**, validates every line
  against `^[a-zA-Z0-9][a-zA-Z0-9._-]*$`, and generates the Nix itself.
  No expression injection is possible through the list.
- Installing an attr lands in `home.packages` — user-profile binaries,
  no setuid, nothing a user couldn't get with `nix profile install`
  themselves. The list grants no privilege the user lacks.
- The daemon never runs as root; the control socket lives in the user's
  0700 runtime dir (same-user only).
- The package index is a distro-built, store-pinned TSV — not fetched at
  runtime. No supply-chain surface at the daemon level.

## THE architectural decision (Max's call — the real "backdoor" question)

**The seed flake lives in `$HOME`, owned by the user** — and the root
helper rebuilds the SYSTEM from it on every install. Consequence: any
code running as the user can edit the system configuration and trigger
a root rebuild silently. On a single-user desktop this is close to the
Linux baseline (user compromise is already game-over for the user's
data, and a wheel user with sudo is root-adjacent anyway) — but it
**bypasses the sudo password prompt**: malware as the user can root the
machine without the user ever typing a password. Options, in increasing
order of friction:

1. **Accept + document** (the single-user "owner owns the machine"
   model). Cheapest; weakest.
2. **Integrity gate:** the helper hashes the seed's system config
   (everything except the generated `waverunner-packages.nix`) and
   REFUSES an unattended rebuild when it changed — config changes then
   need one explicit `sudo golem-apply` blessing. Keeps the hackable
   home-dir seed, closes the silent-root path. **Recommended.**
3. **Root-owned seed** (`/etc/golem`), user edits via a sudo-gated tool.
   Strongest; changes Golem's whole "your system is your home dir"
   philosophy.

Not implemented — this reshapes the distro contract, so it's Max's
decision. Recorded as #56.

## Fixed in the first security pass (2026-09-09, #53–#55)

- **#53 — passwords were recorded in plaintext history.** The clipboard
  watcher ignored the de-facto `x-kde-passwordManagerHint` MIME type, so
  KeePassXC/Bitwarden/KDE secret copies landed verbatim in
  `clipboard-history.json`. Now any clip offering the hint type is never
  recorded.
- **#54 — the link unfurler trusted copied URLs.** With
  `link_unfurl = true` (off by default), every copied URL was fetched
  with `curl -sL`: redirects could pivot into the LAN
  (`http://192.168.1.1/…`, cloud metadata addresses), any protocol curl
  supports, unbounded download size. Now: `--proto =http,https` (initial
  AND redirects), `--max-filesize` caps (2M page / 8M image), and a
  literal private/loopback host refusal (v4+v6, tested). Residual,
  documented: DNS-rebinding past the literal check — acceptable for an
  off-by-default share-card.
- **#55 — state dirs were world-readable** (0755/0644 umask defaults):
  clipboard text, notification bodies, and the webapp Chrome profile
  readable by any local account. The daemon now enforces 0700 on both
  state dirs at startup.

## Standing posture (verify on every pass)

- Clipboard + notification stores are owner-only plaintext. Encryption
  at rest is deliberately NOT used: the key would live beside the data
  under the same user, adding complexity without a real boundary. The
  protections that matter: don't record secrets (#53), owner-only dirs
  (#55), bounded retention (#50).
- The webapp Chrome runs with its own profile under the state dir; its
  sandbox is Chrome's own (userns). Extension injection is store-pinned
  via `WAVERUNNER_WEBAPP_EXTENSION`.
- The "try it" builds run inside the nix daemon's build sandbox as
  `nixbld` — trying a package executes nothing outside it until the
  user launches the result.
- All daemon-side parsing of hostile bytes (unfurl HTML, desktop files,
  notification markup) is memory-safe Rust; the HTML "parse" is a
  bounded meta-tag scan, not a browser engine.
- Launch quoting: every user-influenced string routes through
  `shell_quote`; attrs are charset-gated before they ever reach a shell.

## Queue

- **#56** — the seed integrity gate (decision above).
- Bound the webapp Chrome cache (`--disk-cache-size`) — hygiene, minor.
- Consider `CLIPBOARD_STATE`-style hints beyond the KDE one if other
  ecosystems emerge.
- aging-check: add a perms assertion (state dirs 0700) once #55 ships.
