# Structural-dependence LV truth-matrix ultra-plan

Date: 2026-07-02
Status: plan-only truth-lock; no compute or API widening
Scope: `gllvmTMB` source grammar, R<->Julia bridge capability truth, and
`GLLVM.jl` ordinary/mixed-family bridge boundaries

## Decision

Yes: use an ultra-plan before any more phylo Model A, structural-source, or
non-Gaussian LV work. The next object is not a likelihood change. It is a
truth matrix that makes four adjacent but different things impossible to
conflate:

1. ordinary predictor-informed latent scores, `latent(..., lv = ~ env)`;
2. source-specific predictor-informed score means, for example
   `phylo_latent(..., lv = ~ env)`;
3. structural random-slope grammar, for example
   `phylo_latent(1 + env | species, d = K)`;
4. R<->Julia matrix bridge flags such as `X`, `X_lv`, masks, mixed-family
   vectors, and confidence intervals.

No source-specific `lv` exposure, PR #127 reopen, package API widening,
likelihood change, or Totoro/DRAC compute belongs in this slice.

## Current truth

| Lane | Current status | Evidence / boundary |
| --- | --- | --- |
| Ordinary `latent(..., lv = ~ env)` | Covered as the ordinary score-mean grammar; Julia bridge has ordinary `predictor_informed_lv` point rows for admitted promoted one-part families, while native GLLVM.jl also has shared-cutpoint Ordinal `X_lv` route evidence. | `gllvmTMB` ordinary grammar; `GLLVM.bridge_capabilities()` lists ordinary predictor-informed LV rows for Gaussian, Poisson, Binomial links, NB2, Beta, and Gamma; Ordinal `X_lv` is native shared-cutpoint Julia evidence only and does not promote per-trait ordinal bridge parity. |
| Source-specific `lv = ~ env` on `phylo_latent`, `spatial_latent`, `animal_latent`, `kernel_latent` | Guarded/fail-loud; not support. | `gllvmTMB/R/brms-sugar.R` rejects source-specific `lv`; `test-canonical-keywords.R` covers the structural-source error. |
| Phylo Gaussian Model A source-specific `lv` | Parked for v1; internal evidence frozen only for changed `B_eta_realized`. | Gate 3 DRAC evidence: `2495/2500 = 0.998` for `B_eta_realized`; old population `B_lv` weak cell remains blocked (`591/720 = 0.821`, optimistic `671/800 = 0.839`). |
| Structural random-slope syntax, e.g. `phylo_latent(1 + env | sp, d=K)` and `spatial_latent(1 + env | site, d=K)` | Separate from `lv`; existing R evidence says covered for specific phylo/spatial allowlists. | `docs/design/35-validation-debt-register.md` rows PHY-17 and SPA-09. Must not be used as evidence for source-specific `lv = ~ env`. |
| Animal/kernel structural random-slope lanes | Need exact current-state audit before wording. | Do not infer from phylo/spatial rows; Gate 0 enumerates tests and guards. |
| R bridge mixed-family vector | Complete balanced point/postfit only; no fixed `X`, no `X_lv`, no masks, no CIs. | `gllvm_julia_capabilities()` mixed row and `GJL-GATE-MIXED-CI` / `GJL-GATE-MIXED-COMPONENTS`. |
| Julia mixed-family vector | Point/postfit route exists; CI request returns an empty CI payload with a "not routed" note. | `test/test_bridge_mixed.jl`. Reconcile wording with R gate so this cannot be read as mixed-family CI support. |
| Non-Gaussian source-specific `X_lv` / Model A | New derivation and ADEMP arc only. | No inheritance from Gaussian Gate 3, ordinary bridge `X_lv`, or structural random-slope rows. |

## Council roles

- Ada chairs the arc decision and prevents "support by adjacency".
- Boole owns grammar: ordinary `lv` stays separate from source-specific `lv`
  and from augmented structural random slopes.
- Hopper owns R<->Julia bridge truth: `gllvm_julia_capabilities()` and
  `GLLVM.bridge_capabilities()` must reconcile or name drift explicitly.
- Fisher owns inference boundaries: no bootstrap rescue, no mixed-family CI
  claim, no non-Gaussian/source-specific interval inheritance.
- Curie owns minimal tests: guard probes and capability-row assertions before
  any ADEMP or compute.
- Grace owns compute posture: Totoro diagnostics only after Gate 1; DRAC only
  for predeclared claim denominators.
- Rose owns wording: block "partial support" for source-specific phylo `lv`;
  allow `partial` only as a bridge-ledger status where the row names the gate.
- Shannon owns git hygiene: inspect dirty state, stage explicit filenames only,
  local commit only if Shinichi asks.

## Half-day execution plan

### S0 - Freeze and lane check, 20 minutes

Input: both worktrees:

- `/Users/z3437171/Dropbox/Github Local/gllvmTMB`
- `/private/tmp/gllvmjl-phylo-xlv`

Output: clean current-state note with SHA, dirty files, and off-limits files.

Commands:

```sh
git status --short
git rev-parse --short HEAD
```

Acceptance: no broad staging, no edits to pre-existing dirty
`src/confint_family.jl` or `test/test_phylo_xlv.jl`.

### S1 - Grammar truth matrix, 60 minutes

Owner: Boole with Rose review.

Input: `gllvmTMB/R/brms-sugar.R`,
`gllvmTMB/tests/testthat/test-canonical-keywords.R`, source-keyword tests.

Output: a table with one row per grammar form:

- `latent(..., lv = ~ env)`;
- `phylo_latent(..., lv = ~ env)`;
- `spatial_latent(..., lv = ~ env)`;
- `animal_latent(..., lv = ~ env)`;
- `kernel_latent(..., lv = ~ env)`;
- `phylo_latent(1 + env | source, d = K)`;
- `spatial_latent(1 + env | source, d = K)`;
- animal/kernel augmented-slope variants if present.

Acceptance: every unsupported source-specific `lv` route has a named
fail-loud probe; no route silently drops `lv`.

### S2 - Structural random-slope evidence audit, 75 minutes

Owner: Boole + Fisher.

Input: validation debt register and tests such as
`test-matrix-slope-phylo-latent.R`,
`test-phylo-latent-slope-gaussian.R`,
`test-matrix-slope-spatial-latent.R`, and source siblings.

Output: source-by-family matrix for augmented structural random slopes,
separate from `lv = ~ env`.

Acceptance: claim wording says "structural random slopes" only where tests and
register rows agree. It never says source-specific `lv`.

### S3 - R<->Julia bridge matrix reconciliation, 75 minutes

Owner: Hopper with Curie.

Input:

- `gllvmTMB/R/julia-bridge.R`
- `gllvmTMB/tests/testthat/test-julia-bridge.R`
- `/private/tmp/gllvmjl-phylo-xlv/src/bridge.jl`
- `/private/tmp/gllvmjl-phylo-xlv/test/test_bridge_capabilities.jl`
- `/private/tmp/gllvmjl-phylo-xlv/test/test_bridge_mixed.jl`

Output: reconciled bridge matrix with columns:

`fit_no_x`, `fixed_effect_X`, `predictor_informed_lv`, `missing_response`,
`cbind_binomial`, `ci_no_x_*`, `ci_mask_*`, `ci_x_*`, postfit payloads, status,
notes, and gate id.

Acceptance:

- mixed-family vector remains complete balanced point/postfit only;
- R bridge errors on mixed-family CI with `GJL-GATE-MIXED-CI`;
- Julia bridge empty-CI "not routed" behavior is either kept as unavailable
  status or changed in a separate implementation slice, but never described as
  support;
- R admitted mixed components remain `gaussian`, `poisson`, `binomial` unless
  a separate parity slice widens them.

### S4 - Minimal guard tests, 60 minutes

Owner: Curie.

Input: S1-S3 matrices.

Output: focused tests only if a missing guard is found.

Candidate checks:

```sh
Rscript -e 'testthat::test_file("tests/testthat/test-canonical-keywords.R")'
Rscript -e 'testthat::test_file("tests/testthat/test-julia-bridge.R")'
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
julia --project=. --startup-file=no test/test_bridge_mixed.jl
```

Acceptance: a missing guard can be fixed; a missing modelling feature is not
implemented in this half-day slice.

### S5 - Mission Control and wording refresh, 45 minutes

Owner: Grace + Rose.

Input: final S1-S3 matrices.

Output: dashboard rows only if the truth matrix changes the visible operating
state.

Allowed wording:

- "source-specific `lv = ~ env` is guarded/fail-loud";
- "structural random-slope syntax is a separate validated lane";
- "mixed-family bridge is point/postfit only";
- "non-Gaussian source-specific LV requires a new derivation and ADEMP gate".

Blocked wording:

- "partial support" for source-specific phylo `lv`;
- "ready to expose";
- "non-Gaussian inherited from Gaussian";
- "mixed-family CI support";
- any pooled Totoro/DRAC denominator unless predeclared.

Validation if dashboard changes:

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
```

### S6 - Next target selection, 30 minutes

Owner: Ada + Fisher.

Output: one next implementation target, or an explicit hold.

Recommended first implementation target after the matrix is locked:

```text
source-specific lv guard matrix + bridge capability reconciliation
```

Only after that should Shinichi choose between:

1. an exposure-design meeting for Gaussian source-specific phylo `lv`;
2. a structural-random-slope documentation/claim cleanup;
3. an ordinary bridge parity slice;
4. a non-Gaussian source-specific derivation/ADEMP plan.

## Gate ladder

- Gate 0: current-state matrix exists and names each grammar/bridge route.
- Gate 1: unsupported `lv`, mixed-family CI, masks, and unsupported bridge
  combinations fail loudly or return an explicit unavailable status.
- Gate 2: R and Julia bridge ledgers reconcile, or every difference has a
  named gate.
- Gate 3: only after Gate 0-2, one narrow canary may be chosen. It must name
  source, family, estimand, host, denominator, and pass/fail rule before any
  Totoro or DRAC run.

For the current half-day goal, Gates 0-2 are the finish line. Gate 3 is a
future decision, not work to start now.

## What not to rerun or reopen

- Do not rerun bootstrap/Wald/t-Wald/percentile/profile as a rescue for the
  old p=80, K=2, lambda=0.5 population `B_lv` weak cell.
- Do not reopen PR #127.
- Do not expose `phylo_latent(..., lv = ~ env)` or any other source-specific
  `lv` grammar.
- Do not infer non-Gaussian source-specific LV from ordinary `X_lv` or from
  structural random-slope tests.
- Do not widen mixed-family bridge components, masks, fixed `X`, `X_lv`, or
  CIs in this slice.
- Do not mix Totoro diagnostic rows with DRAC claim denominators.

## Minimal completion evidence

The arc is ready for execution when these are true:

1. the truth matrix has one row per source/grammar/bridge route;
2. every unsupported route has a guard, unavailable status, or named gate;
3. `gllvmTMB` and `GLLVM.jl` capability rows agree on the public story;
4. Mission Control, if touched, shows no active compute and no source-specific
   `lv` promotion;
5. Rose signs the wording as "guarded/parked/point-only", not "nearly
   supported".
