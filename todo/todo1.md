# todo1 — S1 Land & clean

- [x] `nix develop -c cargo clippy --workspace -- -D warnings` on the branch
- [x] `nix develop -c cargo test --workspace` (230+ tests, 0 failed)
- [x] verify-ui the dictionary panel (debug-dict) — screenshot verified live
- [x] Commit the 5 modified files (copy-link pill + webapp CDP + lock self-heal)
- [x] Merge `feat/clipboard-dictionary` → `main` (fast-forward, 0bc01e0)
- [x] Header on `IMPLEMENTATION_PLAN.md`: historical record; living map =
      `~/Golem/roadmap.md`
- [x] Fix `GOLEM.md` dangling refs — point at `~/Golem/` + the animation skill
- [x] Update `options-engine/src/lib.rs` docs (all nine collectors + Mind
      implemented; missing piece = the daemon consuming them)
- [x] Update the memory `dict_data_provisioning` (merged to main 2026-08-29)
- [x] `git init ~/Golem` + first commit — done by Max

**S1 exit check:** main is green (clippy clean, tests pass), nothing
uncommitted, docs point at this roadmap. ✅ **S1 COMPLETE 2026-08-29 — next: S2, todo2.md (the Spine).**
