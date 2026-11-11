# Speaker tunings: one entry per laptop model whose built-in speakers need one.
#
# A tuning is a PipeWire filter graph that WirePlumber loads INTO the speaker
# node itself (node.filter-graph.rules → audioconvert.filter-graph.0), not a
# second sink in front of it. Nothing new appears in the output list, the
# default output and the volume keys stay on the real speakers, and the graph
# comes and goes with the speaker node (a profile switch rebuilds it). The
# filter runs before the node's volume, so the volume keys scale its output.
#
# Rules for an entry:
#   • match the speaker hardware, not a marketing name: the HDA codec and its
#     subsystem id, which is what the vendor keys the amp's firmware on
#     (TAS2XXX387E.bin for 17aa:387e);
#   • builtin filters only (bq_*, linear): they run in the sound card's
#     real-time thread, so no ffmpeg (it allocates) and no LV2 plugin (LSP's
#     limiter alone is 167 MB in every closure);
#   • cut, don't boost. A boost needs the same amount of negative gain in front
#     of it, so the graph never makes a peak louder than what went in;
#   • say where the numbers came from.
#
# The graph is mono; PipeWire runs one copy per channel.
[
  {
    name = "lenovo-slim-pro-9i-16irp8";
    description = "Lenovo Slim Pro 9i 16IRP8 (83C0, \"Yoga S780-16 Pro Quad YC\")";
    # Realtek ALC287 with Lenovo subsystem 387e: the Quad "YC" speaker set the
    # kernel drives through a TAS2781 amp (ALC287_FIXUP_TAS2781_I2C). The
    # 387d sibling ("Quad AAC") has different speakers; it is not matched.
    # A plain piece of the card's alsa.components (WirePlumber's match wraps
    # it in ".*"; the dock's Equalizer finds the tuning by it too).
    components = "HDA:10ec0287,17aa387e,";
    # Chosen by ear by the owner on the machine, 2026-11-10, with the amp
    # reload on (tas2781.nix): stock it "sounds beautiful but saturates".
    #   • below 60 Hz out (12 dB/octave): the woofers cannot move it, and it is
    #     what drives them into saturation first;
    #   • a −6 dB shelf from 180 Hz down: "a bit less bass, not much";
    #   • −1 dB overall: 0 dB still saturated a little, −1.5 dB was "more volume".
    # The internal-mic sweep (40 Hz–10 kHz, -18 dBFS) agrees on the low end:
    # below ~300 Hz these speakers give mostly harmonics, not the tone asked.
    graph = {
      nodes = [
        { type = "builtin"; name = "sub"; label = "bq_highpass"; control = { Freq = 60.0; Q = 0.707; }; }
        { type = "builtin"; name = "bass"; label = "bq_lowshelf"; control = { Freq = 180.0; Q = 0.707; Gain = -6.0; }; }
        { type = "builtin"; name = "vol"; label = "linear"; control = { Mult = 0.891; }; }
      ];
      links = [
        { output = "sub:Out"; input = "bass:In"; }
        { output = "bass:Out"; input = "vol:In"; }
      ];
    };
  }
]
