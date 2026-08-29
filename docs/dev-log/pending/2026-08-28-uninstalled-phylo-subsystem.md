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

## PROBE RESULT (run 2026-08-28 — this answers the "unknown cost" question)

A scratch session (`Base.include(GLLVM, …)`, module untouched) loaded all
seven files against the CURRENT engine:

**All 7/7 load cleanly. There is no compile drift.** That is the good news and
it removes the main risk this note originally flagged (the AGHQ precedent,
where parked code had silently diverged). These files are stale in *wiring*,
not in *code*.

Two concrete, small integration items the probe surfaced:

1. **`em_phylo.jl:65` carries its own `include(joinpath(@__DIR__,
   "takahashi_selinv.jl"))`** — a file the module already includes. Installing
   it as-is double-includes that file (observed: "Replacing docs for
   `GLLVM.takahashi_selinv`" warnings). Fix: drop that line at install time.
   It is a self-contained-file artifact, NOT a competing definition —
   `em_phylo.jl` defines no `takahashi_*` function of its own (verified:
   `grep -c "^function takahashi_selinv" src/em_phylo.jl` → 0). An earlier
   draft of this note called it a "duplicate with drift"; that was wrong, from
   a `diff` of an empty extraction, and is corrected here.
2. **Test-referenced names do not all exist.** After loading, only
   `fit_relaxed_clock` becomes defined; `fit_em_phylo`, `fit_phylo_squarem`
   and `fit_branch_re` remain missing. The files define
   `em_fit_phylo_squarem`, `blup_phylo_sparse`, `felsenstein_contrasts`,
   `edge_phy`, `Q_perbranch`, etc. So the orphaned tests were written against
   an older naming, and wiring them needs a name-reconciliation pass — the
   real cost of option (1), and it is bounded and mechanical.

**Revised recommendation:** option (1) is cheaper than this note first
assumed — the code compiles, so the work is one include-line fix plus a
naming pass, then let the seven tests report. Still a maintainer call because
it changes the public surface and the instruction files.

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

Recommendation (updated by the probe above): **(1)** — the compile risk is
gone; what remains is an include-line fix and a name-reconciliation pass
before the seven tests can report.

## Provenance note

The edge-incidence representation carries a private-provenance constraint (see
`AGENTS.md`) — it cites Bolker's `phylog.rmd` only. Any promotion must keep
that citation discipline.
