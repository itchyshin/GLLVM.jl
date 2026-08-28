# FINDING — a documented phylogenetic subsystem is not in the module (2026-08-28)

**Severity: this is a claim-vs-code gap, not a bug.** Nothing computes a wrong
answer. But `AGENTS.md` and `CLAUDE.md` describe capabilities that a user
cannot reach, and seven test files that would have caught this never run.

**Status: FINDING ONLY — nothing changed.** The remedy touches `AGENTS.md` /
`CLAUDE.md` (merge-authority fence) and/or the module's public surface (an
API change), so it needs a maintainer decision.

## Verified facts

Five source files exist in `src/` and are included **nowhere**:

| file | in `src/`? | `include(...)` in `src/GLLVM.jl`? |
|---|---|---|
| `edge_incidence.jl` | yes | **0** |
| `em_phylo.jl` | yes | **0** |
| `em_squarem.jl` | yes | **0** |
| `phylo_contrasts.jl` | yes | **0** |
| `relaxed_clock.jl` | yes | **0** |
| `likelihood_contrasts.jl` | — | **0** |
| `likelihood_edge_incidence.jl` | — | **0** |

Confirmed at runtime — `using GLLVM` then `isdefined`:
`fit_em_phylo` **NOT DEFINED** · `fit_phylo_squarem` **NOT DEFINED** ·
`fit_relaxed_clock` **NOT DEFINED** · `fit_branch_re` **NOT DEFINED`.

Their seven test files are all orphaned (present in `test/`, absent from
`runtests.jl`): `test_edge_incidence.jl`, `test_em_phylo.jl`,
`test_em_squarem.jl`, `test_em_squarem_safety.jl`, `test_phylo_branch_re.jl`,
`test_phylo_contrasts.jl`, `test_relaxed_clock.jl`. (An eighth orphan,
`test_quality_jet.jl`, is a separate question — quality tooling, not this
subsystem.) These are the ONLY orphans: 8 of 185 test files, so the older
"14 orphaned test files" figure is stale — and the phylo-`X_lv` family tests
that earlier notes listed as orphans are all wired now (verified).

## Why it matters

`CLAUDE.md:49-56` lists these files under "Phylogenetic representations" and
"Fitting at scale" as though they ship. `AGENTS.md:16` states *"Phylogenetic
representations: sparse (CHOLMOD), contrasts, edge-incidence"* — and adds that
all representations *"return identical log-likelihoods to machine precision"*.

Two of those three representations are not loadable, and the identity claim
between them is **not exercised by any run of the test suite**. A reader of the
instruction files — human or agent — will believe the capability is present.
This is the same class as today's other two ledger findings (curvature table
overstated; L47 row understated), and it is the largest of the three.

## Options

1. **Install the subsystem**: add the `include`s, export what should be
   public, wire the seven tests into `runtests.jl`, and fix whatever they
   surface. Highest value — it makes the documented capability real and puts
   the machine-precision identity claim under CI. Cost: unknown until the
   tests run; the code has been out of the module long enough to have drifted
   from the current engine (compare the AGHQ Slice 0 precedent, where parked
   code had silently diverged from the curvature contract).
2. **Annotate honestly**: mark these in `CLAUDE.md`/`AGENTS.md` as
   *prototype / not in the module*, and mark the tests as intentionally
   dormant. Cheap and immediately honest; leaves the capability unavailable.
3. Remove them. Not recommended — the contrasts and edge-incidence
   representations are cited design work with references.

Recommendation: **(1) if the tests pass or nearly pass, else (2) now and (1)
as its own arc.** Cheap first probe: wire the tests in a scratch branch and
run them; the result decides the option.

## Provenance note

The edge-incidence representation carries a private-provenance constraint (see
`AGENTS.md`) — it cites Bolker's `phylog.rmd` only. Any promotion must keep
that citation discipline.
