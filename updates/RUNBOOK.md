# Updates runbook

What to do, situation by situation. How it works: [README.md](README.md).
`golem-lane` runs on the build machine (the dev box) as the maintainer.

## Every day: nothing

The lane runs at 05:00 (or at the next wake) and notifies when it publishes
or fails. To look:

```sh
golem-lane status                 # the last run, as JSON
ls ~/.local/state/golem-lane/logs # one log per run, kept 30 days
systemctl status golem-lane       # the service and its timer
```

## Publish now (don't wait for 05:00)

```sh
sudo systemctl start golem-lane          # or, in a terminal: golem-lane run
golem-lane run --bump                    # also take this week's NixOS fixes now
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
- After a version reaches the lab: `tools/parity/golem-parity max@<ip>`.

## The next NixOS release (twice a year)

The lane notifies when it is out, and a month before the current one ends
(26.05 ends 2026-12-31).

1. `golem-lane release 26.11 --push`: branch `release-26.11` with both
   inputs moved, the gate built, the errors listed, the branch on GitHub.
2. Fix on `release-26.11` until `golem-lane release` reports every system
   builds. Read NixOS's release notes for renamed or removed options.
   Never touch `system.stateVersion`.
3. Lab round: `GOLEM_LAB_BRANCH=release-26.11` lab-pull on the lab laptops,
   reboot, golem-parity, use them.
4. Merge into `main`. The lane publishes it like any version; installs take
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

- **Back it up** (password manager or an encrypted stick).
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
