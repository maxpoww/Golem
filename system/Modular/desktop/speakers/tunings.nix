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
    components = "~.*HDA:10ec0287,17aa387e,.*";
    # The amp loses the first fraction of a second of every sound that starts
    # after the analog output went idle, so the analog PCM (speakers and
    # headphone jack share it) is never suspended on this model. This used to
    # hold EVERY output of EVERY Golem awake (pipewire ~23 wakeups/s forever
    # after the first sound, measured on the 2013 MacBook Air, 2026-11-10).
    # Whether kernel 6.18 still needs it is measured in docs/speakers.md.
    keepAwake = "~alsa_output.*HiFi__(Speaker|Headphones)__sink";
    # v0 — NOT MEASURED YET. A 24 dB/octave high-pass (two 2nd-order
    # sections) so the woofers stop being asked for bass they cannot move.
    # The corner is set by measurement on the machine (the test-tone sweep in
    # docs/speakers.md), then confirmed by ear.
    graph = {
      nodes = [
        { type = "builtin"; name = "hp1"; label = "bq_highpass"; control = { Freq = 120.0; Q = 0.707; }; }
        { type = "builtin"; name = "hp2"; label = "bq_highpass"; control = { Freq = 120.0; Q = 0.707; }; }
      ];
      links = [
        { output = "hp1:Out"; input = "hp2:In"; }
      ];
    };
  }
]
