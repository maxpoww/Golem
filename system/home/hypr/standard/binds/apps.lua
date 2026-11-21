-- standard/binds/apps.lua: the keys that open a program.
local G = require("standard.lib")
local mainMod, terminal, fileManager = G.mainMod, G.terminal, G.fileManager

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
