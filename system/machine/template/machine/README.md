# What Golem's tools recorded about this computer

These files are **data**. Golem reads them as text, validates every line and
looks every name up; none of them is ever run as code. They are written by
Golem's own tools (the installer, the dock's installer, the Modules page);
you can edit them by hand too.

| File | What | Written by |
|---|---|---|
| `facts.json` | What the hardware census measured: processor, graphics, memory, firmware, the panel. Golem chooses this computer's hardware modules from it at every build. Safe to regenerate. | the installer (`golem-hw-detect`) |
| `install.json` | The shape chosen at install: `{"profile": "desktop"}`, the name the computer was installed with. | the installer |
| `apps.list` | The programs installed from the dock: one nixpkgs name per line. | the dock |
| `answers.list` | The answers given to Golem's questions after the install (`"question" = "answer";`). | the post-install questions |
| `modules.list` | The app modules switched on in the dock's Modules page: one `<module>` or `<module>.<program>` per line. | the dock |

Which hardware modules the facts lead to, and why each one, is in
`/etc/golem/layout.json` on the running system.
