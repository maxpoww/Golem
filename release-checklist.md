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

- [ ] `system.nixos.distroName = "Golem"` in `system/configuration.nix`.
      Confirm at build: os-release `NAME`/`PRETTY_NAME` and the systemd-boot
      entry titles both follow it.
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

- **Every Golem user is named `max`.** The name is baked into five places
  (`system/configuration.nix:112,163,254`, `system/home/home.nix:16-17`,
  `system/waverunner-apply.nix:31`), and the last has teeth: the apply
  service watches `/home/max/…`, so on any other account **installing an app
  silently does nothing**. Renaming is the installer's job and the installer
  does not exist yet.
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

This is the largest and least comfortable group: `todo/todoSH.md` leaves
seven items open where the fix is written and built but no human has looked
at the result. For an alpha they are *unknown*, not *fixed*:

- overview opens with no pointer (`todoSH.md:59`, fix in waveview `92913d3`)
- overview motion leaking to the workspace underneath (`:109`, `b095aa7`)
- dock hidden / topbar aware during overview (`:116`)
- overview gap inconsistency (`:128`, `4a5e0e4`)
- empty frames reading bigger than full ones (`:141`, `6f6b517`)
- floating mode (`:238`) — cause found and removed, marked verified
  end-to-end, item still open
- **the float leak** (`:514-556`) — round 19 closed with Max's *"no more
  leaks for now"*. "For now" is not a clean bill; the diagnostic watch is
  still armed.

SH's own exit gates are both open: **one week of daily driving with a notes
file** (`:285`) and **the exit review, "zero known brokenness"** (`:287`).
The roadmap makes SH's exit a week of daily use with zero surprises
(`roadmap.md:29`). No alpha should go out ahead of it.

### 2.4 Open design calls (not bugs — unfinished decisions)

- **Overview design** (`todoSH.md:164`): too compact, empty frames read
  bigger. Mockup built, numbers not chosen. Max's call.
- **The Golem UI font** (`system/configuration.nix:168-177`): DejaVu Sans is
  a deliberate default standing in for a real choice (todo7).

### 2.5 Upstream, guarded, not fixed

Two null-dereference SEGVs in the compositor that took the session down
during development, both worked around in the plugin, neither fixed in the
pinned nixpkgs: the Hyprland `dragEnd` null-target crash, and the fork's
`resizeTarget`/`setTargetGeom` unchecked `target->space()`
(`todoSH.md:583-598`, `:599-606`; upstream state at `:490-496`). The guards
hold. A tester on a different Hyprland will not have them.

### 2.6 Silent seams worth one look before shipping

- `system/home/home.nix:302-314` rewrites three homedir paths out of
  `hyprland.lua` with `builtins.replaceStrings`, which **never errors on a
  miss**. All three needles currently match (`hyprland.lua:31,33,270`), so it
  works today — but if that file is edited without updating the needles, a
  stranger's machine tries to load the plugin from `/home/max/waveview` and
  the desktop comes up without the overview, silently.
- **Rollback depth is the smaller of two limits.** `configurationLimit = 15`
  (`system/configuration.nix:39`) keeps 15 boot entries, while the daily gc
  runs `--delete-older-than 7d` (`:241-245`) against the profiles. Confirm at
  build which one bites first: a tester who breaks their machine and does not
  notice for eight days may have nothing left to roll back to — on the
  feature the project wants to headline (§3).
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
      brokenness (`todoSH.md:285-287`) — including eyes on all seven of §2.3.
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
