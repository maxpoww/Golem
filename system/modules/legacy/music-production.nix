# Music Production — GolemModules.md §4's first real category. ONE switch,
# not a per-tool checklist yet (Max, 2026-09-08: "check all, one click, add"):
# every package and tweak below rides golem.modules.music-production.enable.
# Splitting it into per-tool toggles is future work once the bundle itself
# is proven on real hardware (Max's electric organ).
{ config, lib, pkgs, ... }:

let
  cfg = config.golem.modules.music-production;
in
{
  options.golem.modules.music-production.enable = lib.mkEnableOption ''
    Music Production — the full studio in one switch: DAWs, a loop/beat
    workstation, synthesizers (including a Hammond/tonewheel organ
    emulator), a live looper, audio-interface control, effect plugins, a
    patchbay, sample/soundfont playback and low-latency audio tuning.
  '';

  config = lib.mkIf cfg.enable {
    # Low-latency tuning. PipeWire's shipped default (1024/48000, ~21ms)
    # favors battery life over responsiveness — fine for playback, but a
    # musician playing an instrument live through a DAW feels every
    # millisecond between key-press and sound. 32/48000 (~0.7ms) is the
    # range JACK-era studio setups target; min/max give PipeWire room to
    # grow the buffer under load instead of glitching outright on a slower
    # machine (this repo's old-hardware fleet included). Confirmed option
    # shape against the NixOS pipewire module source (its own doc example
    # sets default.clock.rate the identical way) — the exact numbers here
    # are the standard recipe, not yet metered against real hardware; if
    # the organ crackles, max-quantum is the first knob to raise.
    services.pipewire.extraConfig.pipewire."92-golem-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };

    # No realtime-kernel toggle here (GolemModules.md originally proposed
    # one): linuxPackages-rt was REMOVED from nixpkgs 2026-03-24 ("lack of
    # maintenance") — offering a switch for a package that no longer
    # builds would break evaluation the moment someone checked it. Not a
    # loss in practice: PipeWire's rtkit-based scheduling (security.rtkit,
    # already on system-wide in audio.nix) is what actually delivers
    # realtime priority to audio threads today; a patched kernel was the
    # pre-PipeWire answer to a problem PipeWire's session model has since
    # absorbed for all but extreme deterministic-latency use cases.

    environment.systemPackages = with pkgs; [
      # DAWs — record, edit, produce, each a different shape of the same
      # job. Ardour is the open-source flagship (full multitrack record/
      # mix/master, and — this IS the mixer answer, see below — a real
      # multi-channel mixing console built in, not bolted on). Reaper is
      # the widely-loved proprietary pick with the best plugin/hardware
      # compatibility track record on Linux. LMMS is the loop/beat
      # workstation — pattern-based, sample-driven, the one to reach for
      # building a track around a riff rather than tracking a live take.
      # Qtractor is a lighter native alternative when Ardour is more than
      # the job needs. None forces a workflow before the organ's even
      # plugged in.
      ardour
      reaper
      lmms
      qtractor

      # Rhythm section. Hydrogen programs drum patterns/full kits; Giada
      # is a loop-based live-performance sampler (trigger clips/loops from
      # a grid, built for playing rather than arranging).
      hydrogen
      giada

      # LIVE LOOPING — the organ-specific case "record, produce, reproduce"
      # implies beyond a DAW: play a phrase, loop it, layer the next one on
      # top, hands free, no mouse. SooperLooper is purpose-built for this.
      sooperlooper

      # The organ, specifically: setBfree emulates a tonewheel (Hammond-
      # style) organ + spinning Leslie speaker — the one pick made FOR an
      # electric organ rather than music production in general.
      setbfree

      # Softsynths, spread across synthesis styles so whatever the organ's
      # MIDI out feeds has somewhere useful to go beyond its own voice:
      # Surge XT and Odin2 (subtractive/wavetable/semi-modular — the two
      # most-reached-for free synths right now), ZynAddSubFX and Yoshimi
      # (additive/subtractive workstation-class engines), Dexed (FM, a
      # DX7 clone), Helm (a lighter subtractive synth), Vital (wavetable —
      # arguably the single most popular free synth today; leaving it out
      # of the first pass was a real gap, not a deliberate cut).
      surge-xt
      odin2
      zynaddsubfx
      yoshimi
      dexed
      helm
      vital

      # Sample/soundfont playback — General MIDI fallback (fluidsynth + a
      # real soundfont) and a full softsampler for sample libraries.
      fluidsynth
      soundfont-fluid
      linuxsampler

      # AUDIO INTERFACE, answered directly: Golem doesn't need to "become"
      # one — PipeWire+ALSA already drive any class-compliant USB Audio
      # interface (which covers the overwhelming majority of consumer
      # gear, most electric organs' USB audio/MIDI included) with zero
      # extra software the moment it's plugged in. alsa-scarlett-gui is
      # the one addition worth naming: it's the control panel for
      # Focusrite Scarlett interfaces specifically — the single most
      # common consumer interface — reaching the onboard DSP mixer/
      # loopback/gain controls Linux otherwise has no UI for at all.
      alsa-scarlett-gui

      # MIXER, answered directly: NOT a separate app bolted onto PipeWire —
      # Ardour's Mixer window (above) is the real multi-channel console
      # (channel strips, EQ, sends, automation) and is where mixing
      # actually happens in this stack. meterbridge adds standalone,
      # always-visible VU/peak meters across a session for the "watch the
      # levels" half of that job. (qjackctl/cadence/non-mixer, the classic
      # standalone JACK mixer apps, are gone from nixpkgs — unmaintained
      # upstream — and would be the wrong tool here anyway: PipeWire IS
      # the JACK-compatible server on this system, nothing needs to start
      # a second one.)
      meterbridge

      # A keyboard when the organ isn't plugged in (testing, triggering a
      # synth on its own, sanity-checking MIDI routing before blaming the
      # hardware).
      vmpk

      # Effect plugins (EQ, compression, reverb, amp/cab sims) — the
      # everyday toolkit a DAW reaches into while mixing.
      calf
      lsp-plugins
      x42-plugins
      guitarix

      # Routing/glue. Carla hosts LV2/VST plugins standalone and patches
      # anything to anything; qpwgraph is the visual PipeWire patchbay for
      # wiring the organ's MIDI/audio into the DAW by hand when PipeWire's
      # auto-routing guesses wrong (a real possibility with class-compliant
      # USB MIDI/audio gear — worth watching on first plug-in).
      carla
      qpwgraph

      # Recording/editing utility and notation, rounding out "record, edit,
      # produce, reproduce."
      audacity
      musescore
    ];
  };
}
