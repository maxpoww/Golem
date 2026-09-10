# FINDINGS — dock/menubox findings log

> Dated, append-only. Install-era findings carry their
> `~/Golem/Installer/preinstall/testing/changes.md` number. New findings
> found through THIS project continue the same number line so there is
> one sequence across the lab.

## 2026-09-09 — the install-pipeline day (pre-project, folded in)

- **#37/#40/#41/#42** — stale tile deadlock, GL frame throttle, seed
  permanence, GLES cubemap icons. Fixed + shipped (see FirstInstall.md).
- **#45** — applier read live oneshot builds as dead (`is-active` =
  `activating` → non-zero); foreign-run Done mis-attributed
  (`finished>=since`). False-failed installs at 120 s and reverted the
  list mid-build — the silent xcalc uninstall. Fixed `b2d59f9`.
- **#46** — finished tile stranded "Installing…": apply "done" precedes
  async home-manager activation; the post-fill rescan was one-shot.
  Re-arms every 2 s now. Fixed `bb76739`.
- **#47** — the scan-fingerprint short-circuit returned before
  `resolve_pending_installs`; a scan in the busy/held window froze
  resolution forever (the vlc 13-minute tile; #46's retries armed the
  trap). Fixed `1fa223f`.
- **#48** — installing an already-present app (chromium, the #3 catalog
  overlap) fabricated an icon-less phantom "Command-line tool" tile and
  poisoned `managed.json` gui flags (also brave/darktable/fritzing from
  past sessions). Rescue + heal pass. Fixed `ab44373`; heal verified
  relabeling all four live.
- Post-fix latencies on the ASUS: gimp 1.6 s, signal 1.5 s, spotify
  2.0 s (Done → tile swap).

## 2026-09-09 — project creation audit (the first full-stack pass)

- **#49 (NEW)** — persist reads a corrupt store as empty and the next
  write destroys it. Real-world precedent: the dev box's
  `apps-order.json.bak-20260903-shredded`. Fix: preserve as
  `<name>.corrupt-<date>` + loud log; harden tmp naming. → landing now.
- **#50 (NEW)** — notif history is unbounded by design AND its images
  are never swept (`store_image` writes; nothing deletes). Dev box:
  153 image files after months; year-5 model: thousands of files + a
  startup parse that grows forever. Fix: cap 500 cards + sweep
  unreferenced images on save. → landing now.
- **#51 (CORRECTED after measurement)** — the dictionary hypothesis was
  WRONG: `dict.rs` already lazy-loads on first panel open, and the lean
  image ships NO dictionary files (verified: none on the ASUS). The
  measured RSS story (ASUS, release build, 277 MB / peak 328 MB):
  ~40 MB resident GL driver libs (LLVM+gallium — unavoidable on the GL
  backend, shared pages), ~90–100 MB anon heap. Heap suspects with
  numbers: package index (2.2 MB TSV → per-String structs, est.
  10–20 MB), retained CPU copies of every app icon at multiple sizes
  (needed for GL re-upload after `set_icons` — est. 20–30 MB), glyph
  caches, wgpu staging, and glibc arena retention from the install-churn
  peak. **No lazy-load silver bullet exists; the next step is a real
  profile** (heaptrack/dhat on the ASUS daemon) before touching the
  renderer's icon lifecycle — that is #42-fragile territory. → QUEUED
  as the DockMenu "memory diet" phase, with the profile as its gate.
- **OPEN (queued)** — #3 catalog dedup (don't offer installed apps);
  webapp-chrome disk-cache bound; terminal-emulator assumption of the
  CLI tile path; uninstall-path dogfood; apps-order dead-id policy
  (watch via census).

## 2026-09-09 — #49/#50 landed + drilled live

- Both shipped in launcher `8bb6c72`, Golem lock bumped, ASUS rebuilt
  from seed (daemon `mfzr434j…`).
- **Live corruption drill on the ASUS:** wrote garbage into
  `usage.json`, restarted — the daemon logged the loud rescue, preserved
  the exact bytes as `usage.json.corrupt-1789004889`, started with a
  clean store, and stayed healthy. Real counts restored after the drill.
  Invariant S2 verified end-to-end on metal.
- `aging-check.sh` green on the ASUS post-deploy; zero tmp/corrupt
  leftovers.

## 2026-09-09 evening — uninstall-path dogfood (Max, live)

- **The path WORKS end-to-end:** 5 trash-drags in 12 s (2 webapps + 4
  packages) + installs pushed on top. Instant grid removal (the
  hide-until-reindex hold), strict serialization on the mutation thread,
  each op edits the list at ITS turn, every rebuild landed ok (~40 s
  each), no reverts, no phantoms. First systematic exercise of
  `apply_uninstall` on metal — closes the AUDIT-D "uninstall not yet
  dogfooded" gap.
- **#52 (NEW, optimization)** — N queued drags = N sequential
  nixos-rebuilds. A 5-item batch costs ~3–4 min of serial rebuilds and
  holds a queued install's tile at "installing…" the whole time. The
  mutation worker should COALESCE: drain the request queue, apply ALL
  pending list edits, run ONE rebuild, then send each op its Done. Same
  correctness (the #45 started-based coverage already tolerates a run
  covering several writes), ~N× faster on batches. Care: per-op
  attribution of a batch failure (one bad attr must not fail the whole
  batch — or must fail it honestly). QUEUED — design note here first,
  then implement.

## 2026-09-09 late — the security pass (#53–#56) + uninstall residue (#57)

- **#53 (FIXED, staged)** — password-manager copies were recorded in the
  plaintext clipboard history: the watcher ignored the de-facto
  `x-kde-passwordManagerHint` MIME. Any clip offering it is now never
  recorded. (Code staged in ~/launcher; ships when Max's in-flight
  plate refactor compiles.)
- **#54 (FIXED, staged)** — link unfurl (off by default) fetched copied
  URLs with `curl -sL`: redirect pivots into the LAN/metadata addresses,
  any protocol, unbounded size. Now: `--proto =http,https` initial+
  redirect, `--max-filesize` 2M/8M, literal private/loopback host
  refusal (v4+v6, tested). Residual documented: DNS rebinding.
- **#55 (FIXED, staged)** — state dirs were 0755: clipboard text, notif
  bodies, and the whole webapp Chrome profile readable by any local
  account. The daemon now enforces 0700 on both dirs at startup.
- **#56 (DECISION — Max)** — the seed-in-$HOME escalation: user-level
  code can edit the system flake and trigger a silent root rebuild (no
  sudo prompt ever). Options + recommendation (helper-side integrity
  gate on the non-generated config) in SECURITY.md.
- **#57 (LOW)** — after the 4-package uninstall batch, all four attrs
  stayed in managed.json for the rest of the session (`managed.remove`
  at uninstall-Done demonstrably didn't fire — mechanism unclear, needs
  instrumentation). A STARTUP prune reconciles managed against the
  package list, so it self-heals on restart and the feared per-boot
  forced-rebuild loop does NOT exist (verified live: restart → entries
  gone, no drift sweep fired). Root-cause when the tree settles.
- Observation (AUDIT row updated): dead pin ids persist (android-studio
  still pinned, app long gone) — filtered at render, harmless; census
  watches pins.json size.
- Memory-ledger addendum: the allocator was ALREADY arena-tuned
  (2026-09-02, `tune_allocator()` — 2 arenas + eager trim, "the single
  biggest RAM lever for the 4 GB target"). Today's 277 MB is
  post-tuning, strengthening the profile-first stance for the diet.

## 2026-09-09/10 night — #56 IMPLEMENTED + drilled live; #58 found on the way

- **#56 (LANDED · Golem `fa4d1a3`+`332920f`)** — the seed blessing gate
  is LIVE on the ASUS. Acceptance drill on metal:
  1. TOFU: first helper run sealed the seed (221 files →
     `/var/lib/golem/seed.manifest`, root 0700/0600).
  2. Tamper (user-level "malware" edit to configuration.nix): the next
     apply REFUSED in 76 ms — "changed since the last blessing … sudo
     golem-bless" — no root rebuild happened.
  3. Legit change: `golem-bless` showed exactly the one changed path,
     re-sealed; the next apply passed the gate and rebuilt clean.
  App installs never prompt (the two validated DATA channels are exempt
  by design). The silent user→root path is closed.
- **#58 (NEW → FIXED same commits)** — the apply helper could not
  survive applying a change to ITS OWN unit: switch-to-configuration
  stopped the running oneshot and (via systemd-run --pipe) the dying
  helper killed the in-flight switch — two half-activated generations
  observed live during the seal deploy; recovered by an external root
  switch. Fixed: `restartIfChanged = false` on both apply services.
  Distro rule: a unit that DRIVES the switch is never restart-on-change.
- Deploy-loop change: seed syncs now require `ssh root@asus golem-bless`
  before the next apply — the gate doing its job.

## 2026-09-10 — #53-#55 SHIPPED (launcher f31f75f, atop Max's plate refactor)

Deployed to both map machines and verified live:
- dev box: dock restarted on the build; state dirs flipped 0755 → 0700
  on startup (#55 observed directly).
- ASUS: seed lock bumped → `golem-bless` caught + blessed the lock
  change (the #56 gate's first REAL deploy-loop exercise) → apply passed
  the gate (40 s) → daemon `k0d97syv`, dirs 0700, aging-check fully
  green including the new perms assertion.
- #53 (sensitive clips) and #54 (unfurl hardening) ride the same build:
  #54's private-host refusal is unit-tested; #53 is compile-verified
  (a true end-to-end test needs a real password-manager copy — worth a
  manual KeePassXC copy check next dogfood).

## 2026-09-10 — #59 (OPEN, renderer): the loop can block FOREVER on a GPU fence

Caught live on the dev box (Vulkan/Iris Xe, the plate-refactor build):
the main thread blocked in `drm_syncobj_array_wait_timeout` — a fence
wait that never signaled — freezing the single-threaded loop: IPC dead
(ctl → EAGAIN), install Done unprocessed, tile stuck "installing…"
while the package was in fact installed. No i915 GPU-hang/reset in
dmesg → likely a wait on a semaphore/fence whose submission never
happened (plate-era pipeline suspect), not a true hardware hang.
OPTIONS flagged system.high_cpu at 15:34:34; frozen right after.
Recovery: TERM + restart; #37 dropped the stale tile cleanly.

INVARIANT to add when fixed (I8): the render loop must never wait
unbounded on GPU sync — every fence/acquire wait needs a timeout +
device-lost path that keeps IPC/installs alive on a wedged GPU (the #40
lesson, Vulkan edition). Renderer territory — Max's plate WIP; evidence
preserved here.
