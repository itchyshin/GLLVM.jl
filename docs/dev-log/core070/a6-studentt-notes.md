# A6 Student-t: boundary-honesty wiring + interior-nu paired fixture

Maintainer round2-3 #11 (`docs/dev-log/decisions/2026-09-01-maintainer-decisions-round2-3.md`):
"A6 Student-t: boundary-diagnosis fixture — paired evidence at interior nu PLUS
wire the nu_boundary flag into converged/health reporting; rerun the harness
cell." This closes the last open item from the adversarial parity panel
(`docs/dev-log/core070/parity-panel-2026-09-01.md`, finding 4): the shared A6
harness cell sat **both** engines on the nu -> infinity Gaussian-limit
boundary. R correctly diagnosed it (`false-convergence(8)`); Julia missed it
(`converged=true` at nu=3.0e31). The panel's repair 3 (commit `efe3d644`) added
`nu_boundary::Bool` to `StudentTFit` as an **additive** flag — documented
explicitly as "converged semantics unchanged" because changing `converged` was
called out as a maintainer-gated public-contract change. Round2-3 #11 is that
maintainer authorization. This leaf spends it.

## Part 1 — wiring the flag into honest health reporting

**File**: `src/families/studentt.jl`, in `fit_studentt_gllvm`.

**Convention chosen**: force `converged = false` when `nu_boundary` is true,
mirroring the existing `_tweedie_verdict` rule (`src/families/tweedie.jl`,
`:power_at_boundary` — a family parameter that has run to the edge of its
admissible domain is treated as non-convergence regardless of what `Optim`
itself reported, because `Optim` cannot distinguish a genuine stationary point
from a flat plateau by gradient alone). This was the option offered in the
task brief that requires **no edit to `diagnostics.jl`** (off-limits for this
leaf): `sanity_multi` / `gllvmTMB_diagnose` already read `fit.converged`
generically (`hasfield(typeof(fit), :converged)`), so forcing the field is
sufficient to make a boundary fit fail the repo's existing, family-agnostic
fit-health gate. The change is a **tightening**, never a weakening — it adds a
new failure mode and touches no pre-existing pass case (verified: the full
`test_studentt*.jl` suite, 8 files, all green after the change).

```julia
loglik, conv, iters = _fit_verdict(res)
conv = conv && !boundary
return StudentTFit(β̂, Λ̂, ν̂, σ̂, link, loglik, conv, iters, hessian,
                   disp_group, estimated, boundary)
```

Considered and rejected: a separate `healthy(fit::StudentTFit)` accessor
living only in `studentt.jl`. That would have worked too (also without
touching `diagnostics.jl`) but would NOT flow through the existing generic
gate that every other fit type already reports through — a caller checking
`sanity_multi(fit).pass` or `gllvmTMB_diagnose(fit).pass` (the repo's actual
"is this fit healthy" surface) would still see a clean pass on a boundary fit.
Forcing `converged` is the smaller, more consistent change, and it is exactly
the convention the repo already uses for this shape of problem (Tweedie).

**Tests** (`test/test_studentt_boundary.jl`, wired into `test/runtests.jl`
immediately after the existing `test_studentt_boundary_honesty.jl`):

- Unit-level: `GLLVM._studentt_nu_boundary` composition (estimated + boundary
  vs. fixed + boundary vs. interior), mirroring the `_tweedie_verdict` unit
  tests in `test/test_tweedie_engine_health.jl`.
- Red-first, fixture-level: the same pure-Gaussian-data construction as
  `test_studentt_boundary_honesty.jl` (guaranteed, on this seed, to walk the
  estimated-nu MLE to the flat boundary) — asserts `fit.converged == false`,
  `sanity_multi(fit).converged == false`, `sanity_multi(fit).pass == false`,
  `gllvmTMB_diagnose(fit).pass == false`. This is the assertion that did NOT
  hold before this change (the additive-only flag left `converged == true`).
- A companion interior-nu case (`nu = 6.0` fixed) confirms the wiring is a
  no-op away from the boundary.

Local result: 14/14 new assertions pass, plus the boundary IS exercised on
this seed (the `@warn` fires), so the red-first path is genuinely tested, not
vacuously skipped by the `if any(>(1e6), νvec)` branch.

## Part 2 — the A6 interior-nu paired fixture

**Files** (all new, this leaf): `tools/core070_a6_studentt_fixture.R`,
`tools/core070_a6_studentt_fixture.jl`,
`docs/dev-log/core070/a6-studentt-contract.json`.

### Why a genuinely-interior fixture, and why p=5/K=1/n=250/nu_true=6

The panel's A6 cell used **pure Gaussian data**, which is exactly the
construction that pushes the estimated-nu MLE to the boundary — that is a
correct test of the boundary pathology, but it cannot also be the fixture that
demonstrates paired engine agreement, because at the boundary both engines'
"convergence" is unreliable by construction (the gradient of a flat plateau is
exactly zero) and the round2-3 #11 brief explicitly separates the two asks:
"paired evidence at interior nu PLUS wire the flag." This fixture is therefore
deliberately, **genuinely** heavy-tailed (`nu_true = 6`, real t-distributed
noise via `Distributions.TDist`, not a Gaussian dressed up as one) so the
estimated-nu MLE is expected to land well inside `(1, Inf)` on both engines. A
local plumbing check confirmed this: Julia's own fit on the generated data
recovered `nu_hat ≈ 5.89`, `sigma_hat ≈ 0.699` against `nu_true = 6.0`,
`sigma_true = 0.7`, with `converged = true` and `nu_boundary = false` — the
fixture is well-conditioned and estimable at this size (`p=5, K=1, n=250`),
before any live R run.

### House-style conventions followed, and one deliberate departure

The task brief named five conventions: **argv 2, coverage guard, soft-fail,
self-test with >=4 mutations, `reference_commit` pinned to
`b4d5fee64def88bc768dda1f1f77c29b295edd86`, paired tolerance `1e-4`**. All
five are implemented; the departure is structural, not conventional:

- **argv 2**: both `tools/core070_a6_studentt_fixture.R` and
  `tools/core070_a6_studentt_fixture.jl` take exactly two positional
  arguments (`<data_path> <r_output_path>`), matching
  `tools/core070_aghq_frozen_reference.R`'s `stopifnot(length(args)==2L)`
  pattern. `K` (the one other design-relevant number a caller might expect as
  an argument) is a **fixed design constant** embedded in both scripts and
  the contract JSON — this fixture has one frozen shape, not a family of
  shapes, so it does not belong on the command line.
- **Departure — one file pair instead of an R + Julia + Python triad**: the
  ownership for this leaf is exactly
  `tools/core070_a6_studentt_fixture.{R,jl}` +
  `docs/dev-log/core070/a6-studentt-contract.json` — no third
  `tools/core070_..._verify.py` file. The existing house triads
  (`core070_aghq_frozen_run.jl` / `_reference.R` / `_verify.py`, and the
  `core070_wave6_conversion_batch.{R,jl}` / `_verify_wave6_conversion_batch.py`
  pair) put the coverage-guard / soft-fail / self-test machinery in a
  standalone Python verifier. Here that machinery lives inside
  `core070_a6_studentt_fixture.jl` itself, which plays three roles depending
  on invocation state (see below) rather than three files. This keeps the
  ownership list exactly as specified rather than introducing an unowned
  fourth file; the comparison logic (`_a6_compare`) is a pure function over
  plain `Dict`s, so it is unit-testable via `--self-test` exactly the way the
  Python verifiers are, just in Julia rather than Python.
- **Coverage guard**: `julia tools/core070_a6_studentt_fixture.jl <data> <r_out>`
  refuses to report a pass while `<r_out>` does not exist yet (prints
  `CORE070_A6_STUDENTT_AWAITING_R` and exits 1) — a missing oracle side is
  never silently treated as agreement, mirroring the wave-5/wave-6
  "loud coverage guard" precedent
  (`docs/dev-log/core070/surface-conversion-notes.md`: "the loud coverage
  guard + Julia soft-fail from Repair 2 both worked as designed").
- **Soft-fail**: `read_r_output` raises on any line it cannot parse as a
  `key\tvalue` or `key\tindex\tvalue` row (never silently drops it), and
  `_a6_compare` checks every required key is present on **both** sides before
  running any numeric comparison, mirroring the `null_oracle_value` soft-fail
  pattern in `tools/core070_wave6_conversion_batch.jl`.
- **Self-test, >=4 mutations**: `julia tools/core070_a6_studentt_fixture.jl --self-test`
  builds a synthetic agreeing `(julia_result, r_result)` pair (no data file,
  no fit, no R), confirms `_a6_compare` accepts it, then mutates it 9
  independent ways (loglik/beta/sigma/nu past tolerance; Julia
  converged=false; Julia nu_boundary=true; R healthy=FALSE; R
  nu_at_boundary=TRUE; a required key dropped) and confirms every mutation is
  rejected — `>= 4` required, `9` delivered. Locally: `julia --project=.
  tools/core070_a6_studentt_fixture.jl --self-test` ->
  `CORE070_A6_STUDENTT_SELF_TEST_OK rejected_mutations=9`.
- **`reference_commit`**: pinned as `REFERENCE_COMMIT` in the Julia script and
  `reference_commit` in the contract JSON; not asserted against a live R
  package version string anywhere in this leaf, because the R stage has not
  been run (see below) — it documents which frozen `gllvmTMB` commit this
  fixture targets, for whoever runs it on Totoro to confirm against their own
  checkout.
- **Paired tolerance `1e-4`**: `PAIRED_TOL = 1e-4` in the Julia script,
  applied to `loglik`, `beta`, `sigma`, `nu`, and the sign-aligned `loading`
  vector.

### The R stage's family call

Per the frozen R readback (`R/families.R:355-381` in the local
`gllvmTMB` checkout): `student(link = "identity")` estimates degrees of
freedom unless `df` is supplied — matching `StudentTFamily()`'s Julia default
exactly. The fit call mirrors the existing paired-fixture shape already used
in this repo (`tools/core070_aghq_gaussian_pair_run.jl`):

```r
gllvmTMB(value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
         data = df, unit = "site", trait = "trait",
         family = student(link = "identity"),
         control = gllvmTMBcontrol(se = FALSE))
```

with an inline `healthy` check (optimizer convergence code 0, finite
objective/parameters/gradient, scaled gradient <= 1e-3, `sigma_student`
finite and positive, `df_student` not past the same `1e6` Gaussian-limit
boundary rule `_studentt_nu_boundary` uses on the Julia side) modelled on
`test/parity/r_health.R`'s `core070_tweedie_health()` shape but specialised to
the student() family's own boundary — written inline in
`core070_a6_studentt_fixture.R` rather than added to `r_health.R` (Tweedie-only,
not owned by this leaf).

## What was and was not run locally

**Run and green locally** (Julia only; `julia --project=.`):

- `test/test_studentt.jl`, `test_studentt_input_validation.jl`,
  `test_studentt_disp_group.jl`, `test_studentt_core070.jl`,
  `test_studentt_boundary_honesty.jl`, `test_studentt_boundary.jl` (new),
  `test_studentt_normalizer_precision.jl`, `test_studentt_retained_precision.jl`
  — all green (see tallies in the after-task report / final message).
- `julia --project=. tools/core070_a6_studentt_fixture.jl --self-test` ->
  `CORE070_A6_STUDENTT_SELF_TEST_OK rejected_mutations=9`.
- End-to-end plumbing of all three Julia-script states (generate, soft-fail
  await, and BOTH the pass and fail branches of the comparison) using a
  **hand-built stand-in `r_out.tsv`** — never a real R fit — to exercise file
  parsing, key coverage, sign-alignment, and tolerance logic before handing
  this to a real R run.

**Not run** (per the task brief: "I will run the batch on Totoro after you
deliver — do NOT try to run R locally"):

- `Rscript --vanilla tools/core070_a6_studentt_fixture.R <data> <r_out>`
  itself, against the live frozen `gllvmTMB` library — this is the actual A6
  paired-evidence run and must happen on Totoro. If the frozen R `student()`
  fit fails its own inline `healthy` check on this interior fixture too, that
  is a recorded finding for the after-task report, not a fudge — the contract
  JSON's `both_engine_health_required` field says this explicitly, and
  neither script silently downgrades a health failure into a pass.

## Totoro run command

```sh
julia --project=. tools/core070_a6_studentt_fixture.jl /path/to/a6-data.tsv /path/to/a6-r-out.tsv
Rscript --vanilla tools/core070_a6_studentt_fixture.R /path/to/a6-data.tsv /path/to/a6-r-out.tsv
julia --project=. tools/core070_a6_studentt_fixture.jl /path/to/a6-data.tsv /path/to/a6-r-out.tsv
```

The first invocation generates `a6-data.tsv` (deterministic, seed
`20260901`) and exits 0 with instructions; the R stage then fits and writes
`a6-r-out.tsv`; the final, repeated Julia invocation performs the paired
comparison and prints `CORE070_A6_STUDENTT_PAIRED_VERIFIED` (exit 0) or
`CORE070_A6_STUDENTT_PAIRED_FAILED` with a per-quantity message list (exit 1).
