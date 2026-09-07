# Session Handoff: Destination B twin bridge → Codex

Meta: 2026-09-07 · from Cursor · to **Codex** · D-220 · docs-only handoff

You are Codex, picking up the single D-220 coordination lane for both
`GLLVM.jl` and its R twin `gllvmTMB`. This document is the durable input for
the next session. Mission Control was updated before this handoff at the
single twin project id `gllvmTMB`, whose `repos_covered` are both
`gllvmTMB` and `GLLVM.jl`.

## Critical Context

Destination B is the v0.true-parity track against the frozen `gllvmTMB`
0.7.0 reference. It is **not** a 0.7.1 parity claim. The lane is paused at
G0: there is no named no-G0 Julia leaf left to invent or implement.

The Julia side owns engine truth, the bridge harness, and the frozen oracle.
The R side is the read-only oracle unless Shinichi explicitly answers the R
`phylo_rr` S3b G0. Do not modify R/C++ as part of the normal twin-bridge
line.

## Goals → Plans → Current State

### Goals

- Keep the GLLVM.jl ↔ gllvmTMB twin as one D-220 coordination lane.
- Complete only named, authorised Destination B parity work.
- Preserve honest boundaries: frozen R 0.7.0 reference, no 0.7.1 claim,
  no FRK build, and no unnamed capability leaves.

### Plans

1. Remain paused until Shinichi answers the five G0 questions below, or
   take the named authorised Julia bridge line if he gives one.
2. If authorised, work from a clean GLLVM.jl worktree, with `gllvmTMB`
   read-only as the oracle.
3. Use a second worktree for the R bridge-only line only if Shinichi gives
   G0 on R `phylo_rr` S3b. No C++ changes.
4. Run Rose's mandatory cross-file and claim-boundary audit before any
   public parity statement. No auto-merge; no push without explicit
   instruction for any repo-specific protected action.

### Current state

- **Working:** Mission Control is updated and committed in the vault;
  Destination B is paused at G0.
- **Done:** Julia M3-PHY-S3-FIT and M3-PHY-S3-ANIMAL work is diagnostic-only
  and complete for its named cells. There is no named no-G0 Julia leaf left.
- **Done:** Destination B items `#301`, `#297`, `#304`, `#306`, `#308`,
  `#309`, `#307`, `#310`, `#311`, `#312`, and `#313`.
- **Done on the R twin:** `#1274`.
- **Parked:** FRK, issue `#1275`; do not implement now.
- **Closed drafts:** `#303`, `#305`, and `#298`.
- **Open/parked:** gllvmTMB `#1236` remains parked; twin ownership is D-220.
- **Blocked:** further work that would choose a G0 outcome without Shinichi.

## G0 questions — stop here

These are the five remaining decision labels. Do not infer answers from
issue status or from an apparently green diagnostic:

1. **Grouping B1:** should the grouping-B1 line be admitted, narrowed, or
   parked?
2. **R phylo_rr S3b:** should the R bridge-only S3b line proceed?
3. **S4:** is the S4 line authorised, and with what exact scope?
4. **vcv:** is the `vcv` line authorised, and what parity contract is intended?
5. **FRK:** confirm the park. Issue `#1275` is a parking record, not an
   implementation request.

The Julia S3a/FIT/ANIMAL diagnostic work does not silently answer these
questions. M3-PHY-S3-FIT/ANIMAL is diagnostic only.

## Which line should Codex take?

D-220 intends **one coordination lane across both repos**, but Codex usually
works one checkout/worktree at a time. The recommended primary line is:

> **GLLVM.jl Destination B / twin-bridge; gllvmTMB read-only oracle.**

Codex can touch both folders sequentially, or use two worktrees. It is not
correct to claim Codex cannot work across both repos; the safety requirement
is to avoid simultaneous working-tree bleed-through. If Shinichi gives G0
on R `phylo_rr` S3b, Codex may use a second worktree for that **R
bridge-only** slice. That second worktree must not touch C++ and must not
become a second uncoordinated engine lane. If Shinichi wants R-first, wait
for the S3b G0 before taking it.

Do not dual-write gllvmTMB `#1236`. Keep the frozen R reference stable while
the Julia bridge is being worked.

## Key decisions and fences

- Destination B means v0.true-parity against frozen gllvmTMB 0.7.0.
- This handoff does not promote or imply gllvmTMB 0.7.1 parity.
- M3-PHY-S3-FIT/ANIMAL results are diagnostic only.
- FRK is parked under `#1275`; no FRK build.
- No unnamed leaf may be created to fill a roadmap gap.
- gllvmTMB is read-only from the primary Julia line.
- No R C++ work.
- Rose review is mandatory before a public claim.
- No auto-merge. Push only after explicit maintainer instruction where
  repository policy requires it.

## Landing State

Mission Control was landed separately in the local vault before this
handover:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| Mission Control `live/status/gllvmTMB.json` | yes, `1fd9167` | local vault | none | LANDED |
| `cursor/codex-handover-20260907` | pending in this handoff | no | draft to open | CARRIED-OVER until commit/PR |
| GLLVM.jl shared checkout pre-existing scaffolding | no change by this lane | no | none | PROTECTED / not ours |
| gllvmTMB `#1236` | yes on its own branch | n/a | open/parked | PROTECTED / do not touch |

FINDINGS-OF-RECORD: none. The handoff findings are recorded in this
committed document and the Mission Control status; no branch-only scientific
finding is being carried.

## Files created or modified by this handoff

- `GLLVM.jl/docs/dev-log/handover/2026-09-07-codex-handover.md` — this
  durable handoff.
- Mission Control vault
  `Shinichi/Dashboards/mission-control/live/status/gllvmTMB.json` — updated
  and committed separately as `1fd9167`.

No gllvmTMB working-tree file is modified by this handoff. No engine,
likelihood, test, or capability file is modified.

## Next immediate steps

1. Re-run lane preflight for both repos and inspect current git state.
2. Read the Mission Control `gllvmTMB` status and this handoff.
3. Classify each item `OWED`, `DONE`, `RETRACTED`, or `PROTECTED`; execute
   only `OWED`.
4. Wait for Shinichi's G0 answers, unless he has already named an authorised
   Julia Destination B bridge line.
5. If authorised, create/use a clean GLLVM.jl worktree, keep the R twin
   read-only, run the live verification, and request Rose review.

## Environment and rehydration

### GLLVM.jl

Repository: `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`

Julia launcher:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"
export JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
```

Safe core check:

```sh
julia --project=. test/runtests.jl
```

Canonical full check:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

### gllvmTMB read-only oracle

Repository: `/Users/z3437171/Dropbox/Github Local/gllvmTMB`

Live R toolchain:

```sh
export NOT_CRAN=true
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
```

Use a separate worktree for any authorised R bridge-only work. Do not use
the shared checkout, do not edit C++, and do not run a campaign without its
own G0 and pre-registration.

### Required rehydration order

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
sh "$HOME/shinichi-brain/tools/lane_preflight.sh" .
sh "$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
git status --short --branch
git log --all --oneline --since="6 hours ago"
```

Then read `AGENTS.md`, this handoff, and the Mission Control status. Rose
is the required review lens; Codex owns live Julia/R compilation, fits,
tests, and rendering when a G0 authorises them.

## Blockers / open questions

The blocker is human authorization, not a failed test: the five G0 labels
above remain unanswered. The current preflight also reports unrelated live
lanes in both repositories. Do not absorb or overwrite them; if a requested
slice overlaps one, surface the collision to Shinichi.

## Gotchas and failed approaches

- Do not treat a diagnostic green result as a parity admission.
- Do not rebuild FRK from `#1275`.
- Do not invent an unnamed Julia leaf.
- Do not dual-write `#1236`.
- Do not claim 0.7.1 parity.
- Do not run Codex simultaneously in the shared checkouts; use sequential
  checkouts or explicitly separated worktrees.
- Mission Control's canonical cockpit is the single `gllvmTMB` id covering
  both twin repos; do not create a duplicate GLLVM.jl cockpit id.

## How to resume

Paste this in a fresh Codex session from the GLLVM.jl checkout:

```text
Rehydrate from docs/dev-log/handover/2026-09-07-codex-handover.md and the AGENTS.md snapshot. Read Mission Control's gllvmTMB status, run lane preflight for both GLLVM.jl and gllvmTMB, classify the listed work OWED/DONE/RETRACTED/PROTECTED, and stop at the five G0 questions unless Shinichi has explicitly authorised a named Julia Destination B/twin-bridge line. Keep gllvmTMB read-only, do not build FRK, do not invent leaves, do not dual-write #1236, do not touch R C++, and do not claim 0.7.1 parity.
```

## Mission Control summary

| Repository | Lane / state | What shipped | Next safe action |
|---|---|---|---|
| GLLVM.jl | Destination B paused at G0 | Julia phylo S3a/FIT/ANIMAL diagnostic work; listed parity items done | Shinichi answers G0, or Codex takes a named authorised Julia bridge line |
| gllvmTMB | Frozen 0.7.0 read-only oracle; #1236 parked | R `#1274`; FRK `#1275` parked | R `phylo_rr` S3b only after explicit G0 |

