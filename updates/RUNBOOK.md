# Updates runbook

What to do, situation by situation. How it works: [README.md](README.md).
`golem-lane` runs on the build machine (the dev box) as the maintainer.

## Every day: nothing

The lane runs at 05:00 (or at the next wake). Once a week it publishes;
the other days it only builds and boots `main` when `main` moved. It
notifies when it publishes or fails. To look:

```sh
golem-lane status                 # the last run, as JSON
ls ~/.local/state/golem-lane/logs # one log per run, kept 30 days
systemctl status golem-lane       # the service and its timer
```

## Publish now (an urgent fix: don't wait for the week)

```sh
golem-lane run --now                     # publish main today
golem-lane run --bump                    # also take this week's NixOS fixes now
sudo systemctl start golem-lane          # the scheduled run, now (publishes only if the week is up)
```

## The lane says the gate failed

Nothing was published; every machine stays on the current `stable`.

1. Read the log it names: `grep -E '^error:' ~/.local/state/golem-lane/logs/<run>.log`.
2. A NixOS bump that broke something: fix on `main` (or wait for NixOS's
   fix: the next weekly bump retries). A commit of ours that broke: fix it.
3. `golem-lane run` again, or wait for tomorrow.

## A bad version got out

Machines whose desktop crashes roll back by themselves and hold that
version. For everything else:

1. **Stop the spread** (only machines whose wave has not come yet are
   saved): put `stable` back by hand, the only time it moves backwards:
   `git push --force origin <last good commit>:stable`. The lane never does
   this. Machines already on the bad version stay there until stable passes
   them.
2. **Fix forward**: commit the fix on `main` (a descendant of the bad
   version) and `golem-lane run`. Every machine fast-forwards to the fix.

## One machine, right now

```sh
sudo touch /run/golem-update-now && sudo systemctl start golem-autoupdate   # skip its wave
journalctl -u golem-autoupdate -n 50                                         # what it did
golem-update-wave                                                            # its wave
```

## The lab

- Lab machines are wave 0: they take each version the night it is out.
- Try `main` on a lab machine before the lane publishes it:
  `ssh root@<ip> 'GOLEM_LAB_BRANCH=main sh -s' < tools/deploy/lab-pull.sh`.
  Its nightly update moves it back to `stable` and waits there until
  `stable` has caught up.
- A long deploy (a NixOS move, a slow machine) must not hang on the SSH
  session: a dropped connection kills the rebuild with it (MacBook,
  2026-10-27: 25 min in, saturated wifi, no keepalive answer). Run it
  detached on the machine and follow its journal:

  ```sh
  scp tools/deploy/lab-pull.sh root@<ip>:/run/golem-lab-pull.sh
  ssh root@<ip> 'systemd-run --unit=golem-lab-pull --collect --setenv=PATH=/run/wrappers/bin:/run/current-system/sw/bin --setenv=GOLEM_LAB_BRANCH=main sh /run/golem-lab-pull.sh'
  ssh root@<ip> 'journalctl -fu golem-lab-pull'
  ```
- After a version reaches the lab: `tools/parity/golem-parity max@<ip>`.

## The next NixOS release (twice a year)

Nothing to do when it goes well: the lane makes the jump by itself on the
first weekly publish 28 days after the release branch appeared (or sooner
when the current release ends within 14 days; 26.05 ends 2026-12-31), if
every system builds and boots on it, and notifies "Golem moved to NixOS
YY.MM". Watch the lab laptops that night.

When it says **"NixOS YY.MM not ready yet"**, Golem stays on the current
release and the lane tries again every week. To fix:

1. `golem-lane release 26.11 --push`: branch `release-26.11` with both
   inputs moved, the gate built, the errors listed, the branch on GitHub.
2. Fix on `release-26.11` until `golem-lane release` reports every system
   builds. Read NixOS's release notes for renamed or removed options.
   Never touch `system.stateVersion`.
3. Lab round: `GOLEM_LAB_BRANCH=release-26.11` lab-pull on the lab laptops,
   reboot, golem-parity, use them.
4. Merge into `main` (or land just the fixes on `main` when they work on
   both releases). The lane publishes it like any version; installs take
   it over a week.

The May release usually brings a new LTS kernel series. Check the
out-of-tree drivers first: nvidia (open and legacy), facetimehd,
broadcom-sta. They broke on 7.2/7.3 (2026-10-27, `strncpy`). If one does not
build and nixpkgs has no fix yet, carry a patch the way
`system/Modular/quirks/facetimehd.nix` does, on `linuxPackages`.

## The signing key

`~/.local/share/golem-lane/cache-key.sec` on the build machine (mode 600).
Its public half is in `client.nix` (`golem.update.cache.publicKeys`) and in
golem-cache's README.

- **The backup** is the private repo github.com/maxpoww/golem-keys
  (`golem-cache-1.sec`; its README says how to restore it). Anyone who
  controls that GitHub account can already push `stable`, so the copy adds
  no new risk. Never make that repo public.
- **Rotate** (lost, or as hygiene): `nix key generate-secret --key-name
  golem-cache-2 > …/cache-key.sec`, add the new public key to
  `publicKeys` next to the old one, publish. When every machine runs that
  version, remove the old key.
- **Leaked**: remove the old key from `publicKeys` at once, and publish
  with the new one. Machines compile that one update, then use the cache.

## A new build machine

1. Its NixOS configuration imports `<Golem>/updates/builder.nix` and sets
   `golem.lane = { enable = true; user = "<maintainer>"; };`.
2. Copy the key to `~/.local/share/golem-lane/cache-key.sec` (600).
3. `gh auth login` as that user (push to Golem and golem-cache).
4. `golem-lane run --no-publish` once and read `golem-lane status`.

## First run ever (bootstrap)

`stable` and the first cache come from a version that is not on GitHub yet:

```sh
GOLEM_LANE_LOCAL=/home/max/Golem golem-lane run --base local/updates --no-publish   # build, test, cache
GOLEM_LANE_LOCAL=/home/max/Golem golem-lane run --base local/updates                # + publish main, stable
```

## Moving the cache off GitHub

Change the release URL in `client.nix` (`golem-cache-args`) and the upload
in `golem-lane.sh` (`cache()`), keep the key, publish. Machines on older
versions keep using GitHub until they update.

## Disk on the build machine

The gate's gc root (`~/.local/state/golem-lane/gcroots/gate`) keeps the last
published version's closure, so the next build reuses it. Logs go after 30
days. `export/` holds the last upload and is replaced each run.
