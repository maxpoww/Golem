# StandardOS

**StandardOS 26 — "Uprise"**

---

## Three names

- **StandardOS** — *Standard*, said short — is the system: what is installed,
  what has a version, what the boot screen says. The standard: the starting
  point that already works.
- **OPTIONS** is how Standard offers things: the right tool at the right
  moment, and nothing else in the way.
- **Golem** is the being that works inside it. It installs, updates,
  repairs, goes back when something went wrong, connects the phone.
  Everything a person did not have to do, Golem did.

OPTIONS offers. You choose. Golem does. Standard is what remains.

## What Standard is

A Linux distribution with a soul. Not a theme, not a desktop environment,
not a pile of apps — an operating system built around one idea: **OPTIONS**.

## The idea

All friction between a person and their intention is a design failure.
You should not operate a computer; you should *use* it. Standard's job is to
notice what you're doing, offer exactly what helps, and get out of the way.

## The philosophy

Game designers solved the problem desktop designers never did: teaching
complete novices to master complex systems — no manual, no training, no
fear. They did it with dynamic, diegetic, context-aware design that surfaces
the right tool at the right moment and removes the rest. **OPTIONS is that
philosophy applied to an OS.** Help scales to your skill: scaffolding for
the novice, silence for the expert, safety for both.

## Who it's for

**Everyone.** Not "anyone could" — *everyone can*. Take a Standard PC, get
things done. The shell meets each person where they come from: the dock and
topbar welcome the Mac user, the openbox welcomes the Windows user, the
substrate welcomes the Linux user — and OPTIONS fills every gap between
intention and action. Everyone includes languages, includes accessibility,
includes the person who has never installed anything in their life.

## How it's built

- **The Brain** (`options-engine`) senses your context — windows, media,
  git, phone, battery — and decides what is logical to offer.
- **The Body** (`waverunner`) is the one living surface you see: dock,
  openbox, the OPTIONS boxes. GPU-rendered, animated with intent, idle at rest.
- **The Ground** (NixOS) makes everything declarative and reproducible:
  installs are intent written to a file; updates are atomic; *any* change
  can be rolled back. The system cannot rot. No mainstream OS can say that.
- **The Reach** (Golem for Android) fuses your phone into the same Brain —
  the open answer to the Mac+iPhone ecosystem, on the seat Google and Apple
  left empty.

**What Standard does not build itself.** The Brain senses and decides; it does
not reimplement what a mature daemon already does. Power, thermals, network,
bluetooth, audio are each decades of hardware-specific edge cases, and a
desktop shell has no business relitigating them. Standard runs the proven daemon
underneath — TLP, UPower, thermald, NetworkManager, BlueZ, PipeWire — and
connects it to the Brain. The intelligence lives in the *offer*: the right
control, at the right moment, in Standard's own surface. Never in the plumbing.

Three things this law is not:

- Not a licence to add dependencies by reflex. Every backend is a real system
  dependency with a cost, chosen per module and written into the flake.
  `system-landscape.md` makes exactly this call for UPower: the shipped
  battery module senses via sysfs, and adopting UPower to get `TimeToEmpty`
  is *adding a dependency*, not collecting a free upgrade.
- Not a licence to ship someone else's UI. The daemon is a backend. The
  surface is always Standard's. A module is not done because a GUI for it exists
  — that is what the stopgap kit is, and every stopgap is scheduled to die.
- Not a licence to bind to a vendor. Prefer the **interface** over the
  implementation: talk to `org.freedesktop.UPower.PowerProfiles` on D-Bus,
  which either power-profiles-daemon or TLP's `services.tlp.pd` shim can
  provide — they conflict precisely because they answer the same interface
  (nixpkgs asserts on it). Bind to the contract and the backend stays
  swappable; bind to `tlp-stat` and it does not.

## Golem

**One Golem.** Each computer has its Standard; the same Golem lives in all
of them, and in the app on the phone. There is never "the laptop's Golem":
there is Golem, and the places where it is. A phone is not paired with a
computer, it joins Golem; a second computer on the network does not bring a
second one. (What makes two devices the same Golem is not decided yet.)

**Neither a helper nor a genie.** A helper talks, suggests, turns up with
advice: that would break the first pillar, *the environment is the
assistant*. A genie interprets wishes, and wishes have traps. Golem is a
golem, as in the legend: made of the clay of the house (it lives in your
machines, not in someone's cloud), brought to life by a word, at work while
you sleep, a guard, silent, and stopped by its maker whenever the maker
likes. Unix calls the programs that work in the background *daemons*,
spirits: Golem is all of them, as one being with one name.

**The word** that brings it to life is `/etc/nixos`. What is written there
is what the machine is. Change the word and Golem changes the machine.

**Its laws** — each one already true in the code:

1. It works only for you. Nothing leaves your machines.
2. It does what the word says, no more and no less.
3. It never breaks what works: it builds aside, changes over when that
   worked, and goes back by itself when it did not.
4. It does not interrupt: it waits for a quiet moment.
5. It does not talk, it tells: short notes, in your language, signed Golem.
6. It never chooses for you.
7. You can do more than it can: its files are yours, you can stop it and
   undo what it did.

**Where a person meets it.** In the notices ("Golem could not update",
"Golem kept your edits aside"). In the installer ("Golem is going to install
StandardOS on this disk"). In the terminal: `golem-update`, `golem-status`,
`golem-recover` are ways of speaking to it. On the phone: the app is Golem,
not "Standard for Android" — Standard is the computer; what reaches the
phone is Golem.

**In the code** the rule is the same: what the system IS is called
`standard` (its options, `standard.owner`; its folder, `/etc/nixos/standard`;
its name on the boot menu and the medium); what DOES things is called
`golem` (its commands and services, its memory in `/var/lib/golem`, what it
knows about this machine in `/etc/golem`).

## What Standard refuses

Configuration as a hobby. Terminals as a requirement. Ads, telemetry,
upsells inside the OS. Features that exist to be lists on a website.
Interruptions dressed as help. An update that can break your machine.

## Direction

Two arcs. **First, reach metal**: perfect what exists and put it on an ISO
a stranger can install without us in the room. **Then, grow the soul**:
wire the Brain to the Body, build out the OPTIONS modules, complete the
everyday OS, reach the phone (roadmap.md — Arc 1: SH→S7→S9; Arc 2: the rest).
OPTIONS is a living layer — modules will keep changing, growing, multiplying;
the ISO doesn't wait for them.

**Uprise** is the first climb: from a daily-driven prototype to an OS other
people wake up to.

---

*One surface. One Brain. Zero friction. For everyone.*
