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
    Music Production — the full studio in one switch: DAWs, synthesizers
    (including a Hammond/tonewheel organ emulator), effect plugins, a
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
      # DAWs — record, edit, produce. Ardour is the open-source flagship;
      # Reaper is the widely-loved proprietary pick with the best plugin/
      # hardware compatibility track record on Linux. Both ship so nothing
      # forces a workflow before the organ's even plugged in.
      ardour
      reaper

      # The organ, specifically: setBfree emulates a tonewheel (Hammond-
      # style) organ + spinning Leslie speaker — the one pick made FOR an
      # electric organ rather than music production in general.
      setbfree

      # Softsynths, spread across synthesis styles (subtractive/analog-
      # modeled, additive, FM, wavetable) so whatever the organ's MIDI out
      # feeds has somewhere useful to go beyond its own voice.
      surge-xt
      zynaddsubfx
      yoshimi
      dexed
      helm

      # Sample/soundfont playback — General MIDI fallback (fluidsynth +
      # a real soundfont) and a full softsampler for sample libraries.
      fluidsynth
      soundfont-fluid
      linuxsampler

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
