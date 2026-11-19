-- test/machine.sample.lua: a plain install's facts, for a run with no
-- generated machine.lua at hand (check.sh's layering run, a rig). The real
-- one is written by system/home/home.nix; what each line means: golem/lib.lua.
return {
    dev = false,
    ctl = "waverunner-ctl",
    plugin = nil,
    dock = nil,
    shell = "/run/current-system/sw/bin/bash",
    keyboard = { layout = "us", variant = "", model = "pc104", options = "" },
    panel_dpi = 0,
    panel_scale = nil,
    bluetooth = false,
    effects = "full",
    lab = false,
    modules = { "demo", "no-file-for-this-one" },
}
