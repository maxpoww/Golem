# golem-parity

Compares a Golem machine's **live** desktop with the reference (the dev box's
live session) and prints every difference that isn't explained.

```sh
tools/parity/golem-parity max@192.168.1.149          # exit 0 = parity, 1 = findings
tools/parity/golem-parity max@192.168.1.149 --save   # also writes work/parity/<host>-<date>.md
```

- `collect.sh`: the snapshot. It runs on the machine as the desktop's owner,
  with plain bash and no dependencies.
  - Every Hyprland option's effective value (batched `getoption`; the
    `descriptions` "current" field is wrong for Lua-set options).
  - Every keybind: submap, mods, key and flags.
  - The deployed `hyprland.lua` (window rules and motion are compared from it).
  - Every `exec_cmd` checked against the session PATH.
  - The session env and `$SHELL`, config errors, failed units.
  - The menubox launchers and whether their program exists.
- `golem-parity`: the comparison, run on the dev box.
- `accepted.toml`: the intended differences, each with a reason.
- `../../work/parity.md`: the ledger of findings (open / fixed).

Adding a check: collect it as a new `===section===` in `collect.sh`, then
compare or verify it in `golem-parity`. Prefer checks a user would feel.
