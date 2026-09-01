# Accessibility research — what a11y means for a layer-shell/wgpu surface

> Investigation for **S11 — Everyone-hardening** (roadmap), the item
> `features.md:139` flags as *"hard on wgpu/layer-shell — research early"*.
> It answers one question: **what would it actually take for a blind person,
> or a person who cannot use a mouse, to use Golem** — and where in the stack
> each answer lives.
>
> **Provenance.** Everything marked *(Golem)* is cited to a file:line in this
> repo and is checkable. Everything else — AT-SPI, AccessKit, Orca, the
> Wayland protocols — is written from knowledge without network access in
> this session, so treat protocol/crate/option names as **"verify before you
> depend on it"**, not as measured. Nothing here was run: there is no `nix`
> and no display in this harness, and the Body's source (waverunner /
> waveview) is outside this tree.
>
> Freeze note: this is Arc-2 prep. Nothing here gets built during Arc 1.
> The one exception worth arguing about is §6.0, which is a habit, not code.

## The short version

Golem has **three renderers**, and each has a completely different
accessibility story:

| Layer | What it draws | A11y today | Cost to fix |
|---|---|---|---|
| GTK4 / libadwaita apps (`system/golem-apps.nix:22-59`) | Nautilus, Text Editor, Papers, the whole CURATE set | **Free — and switched off.** GTK exports an accessibility tree automatically, but nothing in this tree starts the a11y bus | ~1 line of Nix |
| The compositor (Hyprland fork) | windows, borders, the overview, the cursor | Nothing built, but it **owns the hard levers**: zoom, output shaders, key filtering, input-method routing | fork work, mostly small |
| waverunner (wgpu on `wlr-layer-shell`) | dock, topbar, pills, OPTIONS boxes — *the actual Golem UI* | **Nothing, and nothing comes free.** A GPU surface is pixels; there is no tree to read | the real work |

The uncomfortable line: **the parts of Golem that are ours are the parts a
screen reader cannot see at all.** Every stock app we ship is one Nix option
away from being accessible; the shell we built is the inaccessible part.

## 1. Why wgpu + layer-shell is the hard case

A screen reader does not read the screen. It reads a **tree of objects** —
"button, named Install, pressable" — that the application publishes. GTK
builds that tree as a side effect of having widgets. waverunner has no
widgets: it has draw calls into a wgpu surface. From the outside it is one
opaque rectangle of pixels with no name, no children and no actions.

Two separate problems hide inside "hard on wgpu/layer-shell", and they have
different answers:

**1.1 — wgpu (no widget tree).** This is *not* Wayland's fault and is not
protocol work. The accessibility bus on Linux is **AT-SPI2, which is D-Bus,
not Wayland** — `org.a11y.Bus` on the session bus. Any process can publish a
tree on it regardless of how it draws. So a GPU-rendered client is perfectly
able to be accessible; it just has to build and maintain the tree by hand,
because nothing generates one for it.

**1.2 — layer-shell (no toplevel, no focus story).** AT-SPI models an
application with windows that get activated and deactivated. A layer surface
is not a window: it has no `xdg_toplevel`, it never appears in a task
switcher, and the compositor — not the client — decides whether it can even
receive keys, via `zwlr_layer_surface_v1.set_keyboard_interactivity`
(`none` / `exclusive` / `on_demand`). So the questions "which window is
focused" and "where on screen is this object" — both of which a screen
reader needs — have no default answer for our surfaces.

The second one is more tractable than it looks. A layer surface knows its
own anchor, margins and size, and can read output geometry from `wl_output`,
so it **can compute its absolute screen coordinates** for AT-SPI's
`Component` interface. That is arithmetic we control, not a missing
protocol. What we cannot fake is *focus*: only the compositor knows whether
the dock or a window has the keyboard — and we fork the compositor, so that
is a bridge we are allowed to build.

## 2. The answer for the shell: AccessKit

For a Rust GPU application the tool that exists is **AccessKit** — a
cross-platform accessibility abstraction where the app pushes a tree of
nodes (role, name, value, actions, bounds) and per-platform adapters expose
it natively: UIA on Windows, NSAccessibility on macOS, and **AT-SPI over
D-Bus on Linux** (`accesskit_unix`, zbus-based, no toolkit required). It is
the layer egui, Slint, Bevy and the Xilem/Vello stack use for exactly our
situation: pixels on the GPU, no widgets.

*(Verify before depending on it: crate status, whether the Unix adapter
still assumes a winit-style toplevel window, and how it wants to be told
about focus. Golem drives raw Wayland with layer surfaces, not winit, so the
adapter's window-association assumptions are the first thing to test.)*

What adopting it costs is not the dependency — it is that **AccessKit needs
a tree, and a tree needs every drawn thing to know its own name, role and
action.** If the surfaces are drawn as immediate-mode paint calls with
geometry computed inline and no retained model of "this rounded rect is the
Install button", then adding accessibility later means re-deriving that
model for every surface. That is the retrofit cost §6.0 is about.

### 2.1 Even a perfect tree is not enough: Orca has to be drivable

This is the finding that matters most and the one most likely to be missed
until a real test.

Orca is itself a client. It needs to (a) read the tree — fine, that is
D-Bus — and (b) **receive its own keystrokes globally**, because a screen
reader is driven by hotkeys that must work no matter which application has
focus. Wayland deliberately does not let a client grab keys globally. On
GNOME this is solved by compositor-specific plumbing between Mutter and
Orca. On a wlroots-derived compositor there is no equivalent, so the usual
outcome is: the tree is readable, and the screen reader is not steerable.

For Golem this is unusually good news. **We fork the compositor.** A
privileged key route from the compositor to a designated AT client is ours
to implement, and it is the thing that turns "waverunner has an AT-SPI tree"
into "a blind person can drive Golem". No amount of work in the Body
substitutes for it. Any plan that budgets for AccessKit and not for this
will produce a demo, not a usable machine.

### 2.2 The horizon: a Wayland-native a11y architecture

There is ongoing work — the prototype usually referred to as **Newton** —
to make the *compositor* the accessibility mediator rather than a session
D-Bus bus: the compositor learns which surface is focused and routes
accessibility traffic, which fixes both the focus problem and the key-grab
problem by construction. As of this writing it is a prototype, not a
standardized `wayland-protocols` extension, and shipping Golem on it would
be betting the "everyone" claim on someone else's unfinished protocol.

**Recommendation: build on AT-SPI via AccessKit, and keep the tree
construction separate from the transport.** If a Wayland-native path
standardizes later, what changes is the adapter, not the model — the same
node tree feeds either one. *(Status must be re-checked with network access;
this section is the most likely to have aged.)*

## 3. The rest of `features.md` §9, by owner

Nine rows in §9 (`features.md:138-148`). Only one of them is the hard
research problem; the rest are ordinary work, and several are nearly free —
which is worth knowing before "accessibility" gets filed as one huge item.

| §9 row | Owner | Reality |
|---|---|---|
| Screen reader | shell + compositor | §2. The hard one. Weeks, not days, and needs a blind tester to mean anything |
| Magnifier / zoom | compositor | Close to free: the config already animates a **`zoomFactor`** leaf (`system/home/hyprland.lua:188`), i.e. the fork already has an output zoom. What is missing is a bind and a step size — verify the dispatcher name in the fork |
| High contrast | split | Apps: a dconf key next to the ones we already write (`home.nix:102-107`). Shell: our own palette, our own work — the amber/`#3c3836` scheme (`hyprland.lua:126-127`) has no high-contrast variant |
| Large text / bold text | split | Apps honour `text-scaling-factor` (dconf). **The shell will not** — it sizes its own glyphs. Two mechanisms, one intent; see §4 |
| Reduce motion / transparency | split (3 places) | §4 — this is todo11's next item and the one with the clearest shape |
| Sticky / slow / bounce keys | compositor | Not free and often assumed to be. These were an X server feature (AccessX); libxkbcommon does not implement them, so on Wayland the compositor must. Ours to write in the fork |
| Mouse keys | compositor | Same place, same story: pointer motion synthesized from the keypad |
| On-screen keyboard | packaging + compositor | Cheapest real win: Hyprland speaks `input-method-v2` + `virtual-keyboard-v1`, so an existing OSK is a package away. **Blocked by our own config:** `system/configuration.nix:247-249` sets `LIBINPUT_IGNORE_DEVICE=1` on every touchscreen, so touch is off system-wide (already noted in NOTES for todo5) |
| Colour-blindness filters | compositor | Hyprland's output shader hook (`decoration:screen_shader`) is exactly this, and would also give invert/high-contrast at the output level — one GLSL file per filter. Verify the hook exists in the fork |

Two things fall out of that table:

- **Most of §9 is compositor work, not shell work.** The instinct is that
  accessibility belongs to the UI layer; here, six of nine rows live in the
  Hyprland fork. That is a scheduling fact worth having before S11 opens.
- **The magnifier, the colour filters and the OSK are each roughly a day.**
  They are not the reason accessibility is scary. The screen reader is.

## 4. Reduce-motion / reduce-transparency (prep for todo11 item 4)

The next item in `todo/todo11.md` is parked on the Body being out of reach,
but its *design* is decidable from here, and it is the template for every
other split setting.

Golem's motion and its glass live in **three** places, not one:

1. **The compositor's animations** — one master switch already exists:
   `hl.animation({ leaf = "global", enabled = true, … })`
   (`system/home/hyprland.lua:172`). Setting that leaf false stops window,
   layer and workspace animation wholesale.
2. **The compositor's transparency** — `decoration.blur.enabled`,
   `active_opacity` / `inactive_opacity` and `dim_inactive`
   (`system/home/hyprland.lua:139-156`).
3. **waverunner's own motion and glass** — the dt-based animation the
   roadmap makes a cross-cutting rule, and the frosted surfaces §9 calls
   "our glass". Nothing in this repo can turn these off; the engine has to
   read a flag. The seam already exists: `xdg.configFile."waverunner/config.toml"`
   (`system/home/home.nix:316-326`) is written from this repo and already
   carries a `[theme]` and an `[options]` section.
4. *(And the apps, which honour `enable-animations` in dconf next to the
   keys `home.nix:102-107` already sets.)*

**The design conclusion: one intent, four consumers.** Whoever implements
this should not add a "reduce motion" toggle to the shell — they should add
*a setting* that writes all four. The failure mode otherwise is the one
Golem is supposed to be immune to: a machine where the dock stops animating
and the windows keep flying.

Order of work: the config.toml key must exist and be read by the engine
*first* (waverunner tree), because the other three are one-line changes in
this repo that are pointless while the shell keeps animating.

## 5. What "no accessibility" actually means today

Stated plainly, so it can be quoted in `release-checklist.md` §2.2, which
currently says only *"No i18n, no keyboard-only path, no accessibility
work"* (`release-checklist.md:137`):

- **There is no accessibility bus.** No `at-spi2-core`, no `orca`, no
  reference to either anywhere in this tree (grepped). GTK apps that would
  otherwise be fully accessible publish nothing, because there is no bus to
  publish to.
- **The shell is invisible to assistive technology** — dock, topbar, pills,
  OPTIONS boxes, notifications, the dictionary panel. Not "partly": there is
  no tree at all.
- **Touch input is disabled system-wide** (`system/configuration.nix:248`),
  which also rules out an on-screen keyboard as a mouse alternative.
- **There is no login screen to make accessible** — greetd auto-starts
  Hyprland as `max` (`system/configuration.nix:158-166`). That is a gap that
  *opens* when the installer starts creating real users: the greeter is the
  first screen, and a screen a blind user cannot pass is a machine they
  cannot boot.
- **The one thing that is genuinely fine:** keyboard control of the
  *compositor*. `system/home/hyprland.lua:263-329` binds focus, movement,
  resize, workspaces, close, the launcher (`SUPER+SPACE`), window cycling
  (`SUPER+TAB`) and the overview (`SUPER+R`, digits jump, Esc closes)
  without a pointer. The keyboard-only gap is in the surfaces, not the
  window manager — which is the useful half of the answer todo11's
  keyboard-audit item was going to look for.

## 6. Cheapest true first steps, in order

**6.0 — The habit to adopt now (free, and the reason to research early).**
Every interactive thing the Body draws should carry a **name, a role and an
action** in its data model at construction time, whether or not anything
reads them yet. This costs nothing today and is the entire difference
between "add AccessKit" being a week and being a rewrite. It is also the
only item here that conflicts with the Arc-1 freeze — and it does not
really, because it adds no surface and no option: it is how new code is
written, not new code to write.

**6.1 — Turn on the accessibility bus.** One option
(`services.gnome.at-spi2-core.enable`, verify the attribute path on 26.05),
plus `orca` in the app set. Effect: every GNOME app we ship becomes screen-
reader usable, immediately, and there is finally a bus for the shell to
publish to later. Do it at the top of S11, not the bottom — it is also the
only way to *test* anything else here.

**6.2 — The free compositor wins.** Magnifier bind, colour/contrast output
shader, the `global` animation switch. Each is small, each is independently
shippable, and together they cover three of the nine §9 rows.

**6.3 — The AccessKit spike.** One surface — the dock is the right one: a
short, flat list of named, activatable things. Publish it, read it with
Orca, and find out how badly the layer-shell focus assumptions bite. That
spike is what turns this document into a plan.

**6.4 — The compositor→AT key route (§2.1).** Only worth starting once 6.3
proves the tree works, but nothing ships without it.

## 7. What must be verified — the checklist for a session that has a machine

None of this could be run here. In rough order of "would change the plan if
false":

1. `at-spi-bus-launcher` running after enabling the option; `orca` starts
   and speaks in a GNOME app under Hyprland.
2. Whether Orca's own hotkeys reach it at all under our compositor (§2.1) —
   test *before* building anything on top.
3. `accesskit_unix`: does it work with a raw-Wayland, layer-shell client, or
   does it assume a winit toplevel?
4. The fork's zoom dispatcher name and whether `decoration:screen_shader`
   survives our patches.
5. Whether GTK apps honour `text-scaling-factor` while the shell does not —
   i.e. how bad the mixed-size desktop looks before it is fixed.
6. Newton's real status, with network.

## 8. The honest answer to "is 'everyone' true?"

`Golem.md:33` says *"Everyone includes languages, includes accessibility"*
and `Golem.md:69` closes with *"For everyone."* Today that is an intention,
not a description: a blind person cannot use Golem at all, and a person who
cannot use a pointer can move windows but cannot reach the shell that is
Golem's whole point.

That is fine for an alpha — the roadmap schedules S11 as the section that
closes last — but it is only fine if the website says so. The claim to
avoid is the one `Golem.md:52` already refuses by name: a feature that
exists on a website. **"Built to be for everyone; not there yet — here is
what is missing"** is true, checkable against this file, and costs nothing
that "for everyone" buys.
