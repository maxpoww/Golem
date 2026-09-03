# Alpha gate — Golem 26 "Uprise"

> The checklist `todo/todo10.md` item 4 asks for: **versioning · known issues
> · feedback channel**. It is the list of what has to be true before a
> download link exists, and the honest inventory of what a first tester will
> hit. It is not the release, and it does not put anything on golem-os.com —
> the site is a separate repo, out of reach from this one (`NOTES.md`,
> todo9 item 7).
>
> **Provenance.** Every claim about Golem's current behaviour cites a
> file:line in this repo. Nothing here describes waverunner or waveview
> internals: both are pinned flake inputs (`flake.nix:43-53`), not readable
> from this tree — where a fact belongs to them it is cited to the log that
> recorded it (`todo/todoSH.md`), not asserted.
>
> **Unbuilt.** Written with no `nix` available in the harness, so every
> statement about what a *build* produces is marked "confirm at build" rather
> than claimed. Written 2026-09-01.

---

## 1. Versioning

### 1.1 What the name means

**Golem 26 "Uprise"** (`Golem.md:3`). Two parts, and they are not the same
kind of thing:

- **26** — the train, and it is not arbitrary: the flake pins nixpkgs
  `26.05` (`flake.nix:33`, `system.stateVersion = "26.05"` at
  `system/configuration.nix:261`). Golem 26 is the Golem built on the 26.05
  channel. Golem 27 is the one built on 27.05.
- **Uprise** — the codename for this train, chosen once and fixed.

`system.stateVersion` is **not** a Golem version and must never be bumped to
express one. It is a nixpkgs compatibility pin — moving it silently changes
defaults of stateful services on an already-installed machine.

### 1.2 What the machine says today

Nothing. The name lives in one markdown line. An installed Golem introduces
itself as NixOS everywhere a person can see:

| Surface | Today | Fed by |
|---|---|---|
| `/etc/os-release` `NAME`/`PRETTY_NAME` | NixOS | `system.nixos.distroName` (default) |
| systemd-boot entry titles | NixOS | same |
| Generation label in the boot menu | the nixpkgs version string | `system.nixos.label` (default) |
| ISO filename / volume | **already Golem** | `hosts/iso.nix:85-86` |

`hosts/iso.nix:87-88` names this gap and assigns it here: *"Full branding —
os-release, the boot menu title, `system.nixos.distroName` — is S10's, and it
belongs to the installed system too, not just here."* It belongs in
`system/configuration.nix` (every Golem machine), not in the ISO module.

- [x] `system.nixos.distroName = "Golem"` in `system/configuration.nix`
      (2026-09-03). Eval-confirmed on all three configs: os-release reads
      `NAME=Golem`, `PRETTY_NAME="Golem 26.05 (Yarara)"` (systemd-boot titles
      derive from the same option). The codename/version half of the string is
      the §1.2 version-string DECIDE below — untouched.
- [ ] A Golem generation label (`system.nixos.label`, or `system.nixos.tags`
      if the nixpkgs revision should stay in the string for diagnostics).
      **Decide which:** a bare `26-Uprise` reads right in the boot menu; the
      default label carries the nixpkgs rev, which is what tells you *which
      build* a broken generation was. `tags` gets both and is the safer
      default for an alpha.
- [ ] **Decide: does `system.nixos.distroId` flip to `golem`?** It is the
      `ID=` field third-party scripts grep to detect NixOS. Flipping it is
      the honest answer and breaks that detection; leaving it is
      `PRETTY_NAME="Golem …"` with `ID=nixos`. Recommended for alpha: leave
      it, and revisit when Golem has enough of its own tooling to be worth
      the break.
- [ ] One version string, used identically in all four places: os-release,
      boot menu, ISO filename, and the site's download link. An alpha that
      names itself three ways cannot have its bug reports triaged.
- [ ] **Tag the git rev the alpha ISO is built from.** The flake carries no
      version attribute; the ISO's only identity is its source revision. A
      bug report that cannot name the build is not actionable, and
      `nix build .#iso` at HEAD is not reproducible after the next commit.
      → HALF DONE (77a8c82): every image now embeds its source rev
      (`system.configurationRevision` from self.rev/dirtyRev; read with
      `nixos-version --configuration-revision`), so any booted Golem can name
      its build. The git TAG at alpha cut remains the release act.

### 1.3 Alpha marker

- [ ] **Decide: is the artifact "Golem 26 Uprise" or "Golem 26 Uprise
      alpha"?** This is the only versioning question with a real consequence:
      the pre-alpha status is stated in `README.md:8`, and a download page
      that drops it is the first dishonest thing the project ships.
      Recommended: the alpha marker is in the version string itself, not only
      in prose next to the link — it survives being re-shared.

---

## 2. Known issues

The list a first tester needs, from this tree only. Grouped by what it costs
them, not by component.

### 2.1 Blocks the Arc-1 exit — there is no alpha until these move

- **The ISO has never been built or booted.** `hosts/iso.nix` +
  `packages.iso` exist and are unexercised (`todo/todo9.md:14-17`, which also
  names the two things to suspect first: systemd initrd on an overlay store,
  and the quiet-boot black screen).
- **No installer.** Which surface does the guided install is undecided
  (`todo/todo9.md:18`); the disk flow behind it is parked on that decision
  (`:20`). Today the way out of the live session is `nixos-install` in a
  terminal — which is the one thing the roadmap's exit criterion forbids
  (`roadmap.md:44`, "no terminal, no Max in the room").
- **No host for a machine that isn't Max's.** `nixosConfigurations.golem`
  carries `hosts/golem/hardware-configuration.nix` (his disk UUIDs) and
  `nvidia.nix`; `golem-vm` is a VM. A stranger's install needs a generic host
  whose `hardware-configuration.nix` is generated at install time
  (`NOTES.md`, todo9 item 3).
- **Nvidia machines land on nouveau.** nvidia is a host choice, not a core
  one (`system/configuration.nix:145-151`) — deliberate, and it means a
  tester with an nvidia GPU gets the open driver until the generic host
  exists.
- **No scan-and-join wifi GUI anywhere in Golem.** The stopgap is
  `networkmanagerapplet` (`system/configuration.nix:213`), whose
  `nm-connection-editor` cannot scan and whose applet is a tray client on a
  desktop with no tray (`todo/todo7.md:207-217`). Audio and bluetooth *are*
  covered; the network third is not. On a laptop with no ethernet this is the
  difference between a working install and a brick.

### 2.2 Ships broken, on purpose — say so on the download page

- **Every Golem user is named `max` — now ONE option, not five files
  (2026-09-03).** `golem.owner` (default `max`) feeds every owner-shaped
  site: the user account, greetd's autologin, the sudo rule, the home
  layer's username/homeDirectory, the ISO's live-user password, the VM
  host's seed/ssh/flakeDir, and — the one with teeth — waverunner-apply's
  watch path. Verified by `extendModules { golem.owner = "anna"; }`: no
  `max` user exists, greetd logs in `anna`, home is `/home/anna`, apply
  watches `/home/anna/.config/waverunner/packages.list`, and at the default
  the evaluated attrs are unchanged. The S9 installer's rename job is now
  setting this option (plus the GECOS full name, left as `"Max"`
  deliberately). Until the installer exists, every image still SHIPS as
  `max` — the download page must still say so.
- **Max's locale and timezone are everyone's.** `time.timeZone =
  "America/La_Paz"` and nine `LC_*` settings pinned to `es_BO`
  (`system/configuration.nix:98-110`) apply to every Golem machine including
  the ISO. A tester in another country gets the wrong clock on first boot.
- **In the live session, dragging an app into Install does nothing.** No
  flake checkout on a read-only medium, by design and documented
  (`hosts/iso.nix:64-70`). It works on an *installed* machine.
- **No i18n, no keyboard-only path, no accessibility work.** That is S11
  (`roadmap.md:81-82`) and it has not opened.

### 2.3 Fixed in code, never verified by eye

*(Re-cut 2026-09-01. The first pass counted seven, but it was reading
checkboxes, not verdicts: four of the seven carried Max's own ✅ in
`todoSH.md` and were merely still unticked, and a fifth was verified
end-to-end in the session that fixed it. Those five are now closed there,
each with the verification it rests on written under it. What is left is the
genuine article, and it is three.)*

Fixes written and built where no human has confirmed the result. For an
alpha these are *unknown*, not *fixed*:

- overview motion leaking to the workspace underneath (`todoSH.md:122`, fix
  in waveview `b095aa7`) — the only overview item with no verdict at all.
  Indirect evidence is good (every drag/resize round after it ran with
  motion swallowed and the leak was never re-reported), but one deliberate
  sweep of the pointer over the windows underneath settles it in a minute.
- overview opens with no pointer (`:69`, `92913d3`) — different shape: the
  fix is understood and the cause named, but the bug is *intermittent*, so
  it closes on a week without recurrence, not on one look.
- **the float leak** (`:573-615`) — round 19 closed with Max's *"no more
  leaks for now"*. "For now" is not a clean bill; the diagnostic watch is
  still armed and a leak still prints `FLOAT-LEAK +Nms` to
  `/tmp/waveview-trace.log`.

Note what the three have in common: all of them are answered by the same
week of daily driving, not by separate work.

SH's own exit gates are both open: **one week of daily driving with a notes
file** (`:333`) and **the exit review, "zero known brokenness"** (`:340`).
The roadmap makes SH's exit a week of daily use with zero surprises
(`roadmap.md:29`). No alpha should go out ahead of it.

### 2.4 Open design calls (not bugs — unfinished decisions)

- ~~**Overview design**~~ — *settled 2026-08-30, no longer open.* The call
  was made by live iteration rather than on the mockup (which is retired for
  this surface): gap 20 / outer 35 / top 12 / frame r28 / window r20 / seam
  2.8%, and the "empty frames read bigger" complaint turned out to be a bug,
  not a taste question — windows were mapped against the full monitor
  including the bar's reserved strip (`todoSH.md:201`, waveview round 5).
- **The Golem UI font** (`system/configuration.nix:168-177`): DejaVu Sans is
  a deliberate default standing in for a real choice (todo7).

### 2.5 Upstream, guarded, not fixed

Two null-dereference SEGVs in the compositor that took the session down
during development, both worked around in the plugin, neither fixed in the
pinned nixpkgs: the Hyprland `dragEnd` null-target crash, and the fork's
`resizeTarget`/`setTargetGeom` unchecked `target->space()`
(`todoSH.md:642-657`, `:658-665`; upstream state at `:549-555`). The guards
hold. A tester on a different Hyprland will not have them.

### 2.6 Silent seams worth one look before shipping

- ~~`system/home/home.nix` replaceStrings silent-miss~~ — **CLOSED
  (2026-09-03).** A missed needle is now an eval failure, not a silent ship:
  the rewrite asserts every needle occurs in `hyprland.lua` before replacing
  (`lib.assertMsg`, names the missing needle). Verified both directions: the
  golem config evals with the rewrites applied, and a deliberately broken
  needle fails eval with the message.
- ~~**Rollback depth is the smaller of two limits.**~~ — **CONFIRMED AND
  FIXED (2026-09-03).** Confirmed which bites: the daily
  `nix-collect-garbage --delete-older-than 7d` deleted system-profile
  generations by AGE (all but current, `nix-collect-garbage(1)`), so an
  8-days-idle machine lost every rollback while systemd-boot still showed 15
  menu entries whose store paths were gone — dangling entries are worse than
  none, on the §3 headline feature. Fixed count-based: the gc now runs
  `nix-env --delete-generations +15` on the system profile (exactly matching
  `configurationLimit = 15`, so every menu entry stays bootable) followed by
  a plain store gc, and iso-smoke static check 8 gates the regression class
  (retention must be count-based, gc must carry no age-based deletion).
  `+15` semantics verified against the real nix-env on a synthetic
  20-generation profile (removes 1–5, keeps 15).
- **`nix flake check` has never been run**, and this repo has no test suite
  of its own. The gate below is the first time anything here is mechanically
  checked.

---

## 3. The one feature to lead with, and the honest version of it

`todo/todo10.md` item 3 wants the Ground superpower headlined: atomic updates
plus a "roll back" button. Half of that is real today and half is not, and
the difference has to be settled *before* the copy is written — shipping the
other half as a headline is the exact thing `Golem.md:52` refuses ("Features
that exist to be lists on a website").

- **Real:** updates are atomic, every change is a generation, and any
  generation can be booted (`system/configuration.nix:34-42`).
- **Not real:** the button. `features.md:129-134` lists the friendly UI and
  the "roll back" button as *needed*, and no surface in this tree provides
  one. Today rolling back means: reboot, catch a **3-second** menu
  (`:35 timeout = 3`) on a machine that boots deliberately silent
  (`:60-75`), and pick an older entry.

- [ ] **Decide the alpha claim.** Either headline what exists — "reboot, pick
      yesterday, you're back" — or ship the button first. Recommended:
      headline the *capability* and show the boot menu honestly; the button
      is an Arc-2 module (S4/S6) and the capability is already the true part
      no mainstream OS matches.

---

## 4. Feedback channel — **open, Max's call**

The alpha's whole purpose is the reports, so this is the one item here that
cannot be defaulted quietly. Three shapes:

| | Barrier to the tester | Trail | Cost to Max |
|---|---|---|---|
| GitHub Issues on `maxpoww/Golem` | needs an account | public, searchable, dedupes itself | triage only |
| Email | none | none — every report is private and re-answered | inbox |
| Matrix / Discord | account + app | chat, not a queue; reports scroll away | constant |

Two constraints the choice has to satisfy, both from this tree:

1. **Bugs arrive from three repos.** Golem (this one), waverunner and
   waveview (`flake.nix:43-53`). A tester cannot be asked to know which one
   broke. Whatever is picked must be **one front door** that Max triages
   outward.
2. **The channel must be reachable from another machine.** §2.1's wifi hole
   means a tester's Golem box may have no network at all — the first bug
   report is the one that says "it can't get online". So the channel must be
   printed on the download page, not only inside the OS.

- [ ] **Pick it.** Recommended: GitHub Issues on `maxpoww/Golem` as the
      single front door (satisfies both constraints, zero setup, and the repo
      is already public), with an email address on the download page for
      people without an account.
- [ ] Whatever is picked, an issue template that asks for the version string
      from §1.2 — otherwise reports cannot be tied to a build.

---

## 5. The gate

In order. Nothing below starts until everything above it is true.

- [ ] SH closes: a week of daily driving, then the exit review at zero known
      brokenness (`todoSH.md:333`, `:340`) — including eyes on all three of
      §2.3, all of which the same week answers.
- [ ] `nix flake check`, and `nix build .#iso` produces an image (§2.6).
- [ ] The ISO boots on real metal (`todo/todo9.md:39`).
- [ ] An installer exists and a stranger reaches a working desktop through it
      without a terminal (`todo/todo9.md:18-20` — the Arc-1 exit).
- [ ] Wifi works during install *or* the install is offline-capable, so the
      network hole moves to first boot instead of blocking the install
      (`NOTES.md`, todo9 item 5).
- [ ] §1 lands: branding in `system/configuration.nix`, one version string,
      the git rev tagged.
- [ ] §4 lands: the channel is picked and printed on the download page.
- [ ] The known-issues list from §2 is published **with** the download, not
      after it. Section 2.2 in particular — a tester who discovers the
      hardcoded `max` on their own is a tester who stops.
- [ ] Install on a machine that isn't Max's, watched, silently
      (`roadmap.md:44`).
