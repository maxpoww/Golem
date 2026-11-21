# modules/ai — AI: the assistants (web apps), models on this computer, tools
# that create, tools that code.
#
# No plumbing. PROGRAM SETUP: a local model runs in a SERVICE; the command
# and the windows are its clients.
#   · Ollama's service, the plain build: it runs models on the processor, on
#     every machine, and comes from the cache. NOT the build for a graphics
#     card. NVIDIA's (pkgs.ollama-cuda) is in no cache — CUDA is unfree — so
#     it would COMPILE on the owner's computer: tens of minutes and several
#     GB, at an install or in the middle of a nightly update, and a build
#     that fails there stops every update after it. A faster model is tuning,
#     not what the program needs to work (README, rule 2), until Standard's own
#     cache carries that build. By hand, on a machine that wants it, in its
#     configuration:  services.ollama.package = pkgs.ollama-cuda;
#     (AMD's ROCm supports few cards and the census cannot tell a card from a
#     laptop's built-in graphics; the Vulkan build is still upstream's
#     experiment.)
#   · Open WebUI is a web page served from this computer (127.0.0.1:8080).
# Alpaca, Jan, LM Studio and GPT4All bring their own engine: nothing here.
{ config, lib, ... }:

let
  m = import ./lib.nix { inherit lib; };
  inherit (m.scope config) has;
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
    services.ollama.enable = lib.mkIf (has "ollama") true;

    # Open WebUI is a server and a page: the program alone is neither
    # running nor reachable. Local only (the module's own default host).
    services.open-webui.enable = lib.mkIf (has "open-webui") true;
  };
}
