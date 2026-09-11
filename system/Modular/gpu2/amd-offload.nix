# gpu2/amd-offload — a SECOND amd GPU that passed the wake test. Chosen
# when gpu2=amd, gpu2Health=working. mesa's radeonsi handles offload on
# the default open stack — there is genuinely nothing to configure (the
# gpu-second.nix header's "AMD healthy offload rides the default mesa
# stack, nothing to do"). The leaf exists so the pointer list NAMES the
# working second GPU rather than silently omitting it (reveal honesty).
{ ... }:

{
}
