# modules/ai — AI: the assistants (web apps), models on this computer, tools
# that create, tools that code.
#
# No plumbing. PROGRAM SETUP: a local model runs in a SERVICE; the command
# and the windows are its clients.
#   · Ollama's service, built for the graphics card where one can run models:
#     NVIDIA's (RTX 20 and newer, the proprietary driver) gets the CUDA build.
#     ⚠ nixpkgs' cache has no CUDA builds (unfree): that one compiles on this
#     computer the first time, several minutes. Every other machine runs the
#     plain build on the processor: AMD's ROCm supports few cards and the
#     census cannot tell a card from a laptop's built-in graphics; the Vulkan
#     build is still upstream's experiment.
#   · Open WebUI is a web page served from this computer (127.0.0.1:8080).
# Alpaca, Jan, LM Studio and GPT4All bring their own engine: nothing here.
{ config, lib, pkgs, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;

  hw = config.golem.hardware;
  nvidia = (hw.gpu or "auto") == "nvidia" || ((hw.gpu2 or "none") == "nvidia" && (hw.gpu2Health or "unknown") != "failing");
  cuda = nvidia && (hw.nvidiaGen or "unknown") == "turing+";
in
{
  imports = [
    (m.mkModule {
      id = "ai";
      description = "AI: the assistants (web apps), models on this computer, tools that create, tools that code.";
    })
  ];

  config = {
    # Ollama's command is a client: the models run in its service.
    services.ollama = lib.mkIf (has "ollama") {
      enable = true;
      package = lib.mkIf cuda (lib.mkDefault pkgs.ollama-cuda);
    };

    # Open WebUI is a server and a page: the program alone is neither
    # running nor reachable. Local only (the module's own default host).
    services.open-webui.enable = lib.mkIf (has "open-webui") true;
  };
}
