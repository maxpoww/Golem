# Changes — the Installing ledger

The deferred queue for the next ISO, exactly as preinstall ran it
(archived original: `~/GolemOne/Install/Preinstall/testing/changes.md`).
**The number line is one line:** #1–#61 live in the preinstall archive
and DockMenu's FINDINGS.md; this file continues at **#62**. Round-scoped
surface items are `I<round>-<n>`.

## How to use this file

- While a round runs, a finding's raw experience goes in the machine's
  file; the CHANGE it implies lands here: what / why (which finding,
  which machine) / where (file:location) / size (small · medium ·
  needs-Max). Status rides the header tag.
- Nothing lands in an ISO mid-round. Round closes → work the queue top
  to bottom → `nix flake update` → rebuild → verify the built artifact
  → VM gate → reflash → move applied entries below with their round.
- Waverunner-side fixes ride the launcher → Golem lock → seed pipeline
  and are marked with their launcher rev.
- The live-fix refinement applies: a queued fix may be verified on a
  booted machine as a RAM overlay / seed update, marked
  **[verified live on <machine>]** — the frozen stick still never
  reburns mid-round.

## Queued for the next ISO

*(empty — Installing round I1 has not started finding things yet)*

## Applied

*(moves here at round close, tagged with the round that shipped it)*
