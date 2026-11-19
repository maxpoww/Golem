# The app modules' own Lua

A module of programs (system/modules: Gaming, Music Production…) may bring
window rules or keys of its own. They go here as `<name>.lua`, and are loaded
only on a machine that has the module on (`machine.modules`, from
`golem.home.hyprlandModules`), after Golem's own modules and before the
machine's and the owner's. No file is needed for a module with nothing to add.
