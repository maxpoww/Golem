# conditions.md — operating conditions for the ACTIONS research agent

*How the work is done. The constitution decides WHAT survives; this file decides HOW you produce and cut. Where they conflict, the constitution wins.*

## 0. Honesty rules (read first)

- There is no real dataset of "the 1000 most repetitive habits of the average computer user". You are doing disciplined synthesis, not science. NEVER fabricate citations, statistics, percentages, or studies.
- Mark every habit **[observed]** (you found it in a real, checkable source — name the source inline, e.g. `(StatCounter 2025)`) or **[reasoned]** (enumerated from first principles). WebSearch/WebFetch are available and encouraged — browser-usage stats, OS telemetry write-ups, time-use surveys, UX research. When search yields nothing, mark **[reasoned]** and move on. An honest [reasoned] beats a fake [observed], always.
- Ground every sensability claim in the REAL engine: `/home/max/Golem/docs/shell/options/catalog.md` — §0 is the authoritative table of live signals, and its **[live] / [cheap] / [bridge] / [new]** legend is your feasibility vocabulary. Also skim `/home/max/Golem/docs/shell/options/modules.md` and `/home/max/Golem/docs/shell/options/UXRules.md` (§1 The Leader, §2 The Still Bar) once per batch.

## 1. The funnel — one batch = one full run

Wide generation, then five rounds of killing. Survival through explicit criteria — never brainstorm the 40 directly.

- **F1 → `habits-1000.md`** — 1000 numbered habits of computer users, one line each, generated in four chunks of 250 (one chunk per work unit). Sweep at minimum these categories: browsing, communication, media, files, coding/work tools, writing/docs, system/settings, power/battery, audio/devices, health/ergonomics, time-of-day rituals, security/privacy rituals, window/workspace management, search/launch, finance/shopping, learning/reading.
- **F2 → `cut-500.md`** — kill: not roughly daily for the people who have the habit; phone-only; no digital footprint a desktop OS could ever see.
- **F3 → `cut-250.md`** — kill: anything that cannot NAME a sensable trigger on a Linux/Wayland desktop. Every survivor gains a trigger note with a feasibility tag from the catalog ([live]/[cheap]/[bridge]/[new]). Prefer [live] and [cheap]; [bridge]/[new] survive only if the habit is exceptional.
- **F4 → `cut-100.md`** — kill: privacy violators — anything needing content-reading, cloud, or surveillance-feel that cannot be reformulated as gestures-not-content and aggregates-not-diaries (Constitution VI).
- **F5 → `cut-50.md`** — the usefulness bar: would a real user THANK the system for this offer? Kill nags, kill reminders-to-exist, kill anything the user can do faster themselves than reading the sentence, kill imagined helpfulness (Constitution III).
- **F6 → `actions-40.md`** — the utterance economy: the final 40 must collectively feel rare (Constitution IV), span categories (no more than ~5 per category), and contain no near-duplicates. Each becomes a full action block (schema below).

Every cut file: survivors renumbered (keep the original H-id in parens), and it ends with `## Casualties worth noting` — 10–20 removed items, one line each on why. The casualties are how Max audits your judgment.

## 2. Schemas

### habits-1000.md — one line per habit

`H0421 [reasoned] (files) empties the Downloads folder when it gets messy`

Sequential ids across chunks, no duplicates. Category in parens from the F1 list.

### actions-40.md — one block per action

```
### A07 — <name>
- **Type:** moment | habit
- **Trigger & evidence:** the exact sensed signal(s) + threshold. Habit actions: what is counted and how many times before the first offer. Feasibility tag(s) from the catalog: [live]/[cheap]/[bridge]/[new].
- **Sentence:** the ONE sentence, in Golem's voice (Constitution II).
- **Verb(s):** the nested pill label(s) and precisely what each executes (command / API where knowable).
- **Refusal:** what "not now" means for THIS action — when may it re-offer?
- **Gear:** the palm-sized config contents — (a) domain params, (b) trigger conditions, (c) lifecycle. Max ~5 controls.
- **Ladder:** the assisted form and the automatic form it can graduate to.
- **Privacy note:** exactly what is stored at rest (aggregate shape, approx bytes) — Constitution VI.
- **Fires:** honest estimate of how often it would actually speak (e.g. "≤1×/day", "~2×/week during streaks").
```

### implementation.md — exactly 6 paragraphs

Numbered 1–6, ~120–220 words each, prose only (no bullet lists inside paragraphs). Coverage: (1) the concept and why it is not slop; (2) engine architecture — detectors, evidence counters, the persistence layer, no-new-wakeups; (3) surface anatomy and choreography — pill, verbs, gear box, the grow morph; (4) privacy architecture — the five laws made concrete; (5) admission and lifecycle — the funnel as ongoing governance, ladder, refusals, notebook; (6) voice and feel. It must be REWRITTEN FROM SCRATCH (not edited) at least twice per batch: `implementation-draft-1.md` → `implementation-draft-2.md` → final `implementation.md`. Each rewrite starts from a blank page with fresh eyes on everything learned since.

## 3. Adversarial rounds — the slop hunts

Two per batch: after F6 drafts the 40 names, and again after the full action blocks are written. Procedure: re-read the constitution top to bottom, then ATTACK every survivor — actively try to disqualify each on any law (imagined helpfulness? non-daily? unsensable? content-reading? would anyone thank it? does the sentence moralize?). Log every verdict in `slop-hunt.md` (kept/killed + one line why). Replace kills from the cut-50 runner-ups, which then face the same attack. A hunt that kills nothing is suspicious — look harder; if everything genuinely survives, write down why you believe that.

## 4. Batches

- Outputs live in `work/batch-01/`, `work/batch-02/`, …
- **Actions must NEVER repeat across batches.** An action is "the same" if trigger + verb match in substance — rewording is repetition. Before F6 of any batch ≥2, re-read every earlier `actions-40.md`. Habits should avoid repeats where possible; overlap is tolerated in F1, never in F6.
- Later batches: the daily well runs dry — that is exactly where slop creeps in. Quality outranks quota (Constitution VII): deliver fewer than 40 and say so, rather than pad. From batch 3 onward you MAY relax the EVERYDAY law to weekly, but then the batch must be explicitly labelled the **weekly tier** in all its files and in SUMMARY.md.
- After finalizing each batch, update `work/SUMMARY.md` — the entry point Max reads on waking: one section per batch with status, how many actions shipped, the 5 best at a glance (name + sentence), relative links to the batch files, and honest caveats.

## 5. State and units of work

- `work/STATE.md` is your ONLY memory between invocations. Format:

```
batch: 2
phase: P3
next: <one imperative sentence — the single unit the next invocation performs>
done:
- <timestamped one-liners appended as units complete>
```

- One invocation = ONE unit of work: one 250-habit chunk, one funnel cut, one slop hunt, one implementation rewrite, one set of ~10 action blocks. Write output files FIRST, update STATE.md LAST — so a cut-off invocation is always resumable.
- Never modify anything outside `/home/max/Golem/docs/shell/actions/work/`. Read anywhere under `/home/max/Golem/` and `/home/max/launcher/` (read-only) as needed.
