# Formula structured-term recognizer — lane implementation notes (core070)

**Status: lane implementation only.** Formula grammar changes are
maintainer-approval-required to merge (AGENTS.md merge authority: "any ...
formula grammar change"). Nothing in this document or the code it describes
is authorized to reach `main` without Shinichi's explicit approval. This
implements docs/dev-log/core070/formula-recognizer-spec.md §2 Steps 0–6 on
the lane branch `codex/core070-aghq-20260830`, worktree
`/private/tmp/GLLVM.jl-core070-aghq-20260830`.

## What was built

All new code lives in `src/formula.jl` (appended after the existing
`gllvm(formula::FormulaTerm, ...)` methods; no existing lines touched), with
tests in `test/test_formula_structured_terms.jl` and one include line added
to `test/runtests.jl`. No other `src/` file was touched, per lane scope.

- `SourceTermSpec` — parsed, not-yet-materialized structured term (`kind`,
  `group`, `common`, `unique`, `name`, `K`, `d`).
- `_recognize_source_term(expr::Expr)` (Step 0) — recognizes one
  `dep/indep/scalar/kernel_*` call from a raw `Expr`, splitting off the bar
  expression for `dep/indep/scalar` and validating literal flags.
- `_assert_no_augmented_lhs`, `_read_literal_flag` (Step 0) — pure gate
  functions named to match the R oracle they port
  (`.assert_no_augmented_lhs` brms-sugar.R:2172-2215; `.read_common_flag`
  brms-sugar.R:2464-2483).
- `_build_source_term_spec` (Steps 1–3, 5–6) — per-kind kwarg parsing for
  `dep`, `indep`, `scalar`, and the five `kernel_*` siblings.
- `_warn_scalar_deprecated_once` (Step 2) — one-shot `@warn`, session-scoped.
- `_check_source_term_exclusions` (Step 4) — the fit-multi.R guard quartet
  (dep+latent, dep+unique, dep+indep, indep+latent), generalized over this
  recognizer's kind vocabulary.
- `_source_term_covariance` (Steps 1, 3, 5, 6) — materializes a
  `SourceCovariance` (src/source_fit.jl, untouched) from a `SourceTermSpec`
  plus a data table (grouping column) and a `kernel_env` (K= resolution).
- `_resolve_kernel` — resolves a `K=` symbol against a caller-supplied
  `NamedTuple`/`Dict` environment (Julia has no calling-environment lookup
  for a raw quoted `Expr`, so the caller supplies one explicitly).
- `_fit_gaussian_structured_sources(Y, data, term_exprs; kernel_env, kwargs...)`
  — the Step 1–6 end-to-end entry point: recognize → exclude → materialize →
  `fit_gaussian_sources`.

None of this is exported; all names are `_`-prefixed and reached via
`GLLVM._...` in tests, matching the existing convention for
`_pervar_formula_design` etc.

## Architectural deviation: not `@formula`-based

The spec's per-step sketches ("formula fit via the formula path... equals a
direct `fit_gaussian_sources` call") could read as implying integration with
`gllvm(formula::FormulaTerm, ...)`. **This is not possible without changing
StatsModels itself**: `@formula(y ~ indep(0 + trait | g))` errors at
**macro-expansion time** (verified against StatsModels 0.7 in this
environment — `|` has no `Term` method, so `parse!` fails before any Julia
code of ours ever runs). This is a hard blocker, not a design choice.

The recognizer therefore operates on **raw, unevaluated Julia `Expr` trees**
(`:(indep(0 + trait | g, common = true))`), assembled by the caller via
`Meta.parse` or `:(...)` quoting, completely independent of `@formula`/
`FormulaTerm`. `_fit_gaussian_structured_sources` takes a `Vector` of such
`Expr`s directly rather than a formula RHS. This keeps the recognizer fully
testable and matches the spec's own framing ("a Julia port implements a
*recognizer* over the formula AST, not the functions") without requiring
engine surgery on StatsModels or a fork of `@formula`. Wiring a `|`-aware
formula front door (a custom macro, or a string-DSL parser) is a separate,
larger grammar decision squarely inside "maintainer-approval-required" and
is explicitly **not** attempted here.

## Second deviation: kernel_* terms have no bar

§1.4's R signature table gives `kernel_latent(unit, K, d=1, name="kernel",
unique=FALSE)` — the first argument is a **bare grouping symbol**, not a bar
formula — confirmed against the R fixtures (`kernel_latent(species,K=A,d=1,
name='a')`, test/parity/fixtures/core070_fit_input.R:22). My first draft
incorrectly assumed all structured terms shared the `lhs | group` bar shape;
this surfaced immediately as a red Step 5 test (`kernel_indep(g, K=K, ...)`
failing the bar-expression check) and was corrected before any commit:
`_recognize_source_term` now branches on `kind in _KERNEL_TERM_KINDS` to
take a bare-symbol first argument for the five `kernel_*` kinds, and a bar
expression for `dep`/`indep`/`scalar` only.

## Step 4 exclusion-gate mapping (generalized, not literal)

The R guard quartet (fit-multi.R:1642-1695) is stated over R's own term
vocabulary (`dep`, `indep`/`diag`, `latent`/`rr`, `unique`). This recognizer
maps:

- `indep`-family = `:indep`, `:scalar`, `:kernel_indep`, `:kernel_scalar`
- `dep`-family = `:dep`, `:kernel_dep`
- `latent` = `:kernel_latent` (the only latent-mode recognizer built in this
  spec's scope — plain `latent(0+trait|g)` non-kernel latent terms are
  **NOT COVERED** here, per spec §4)
- `unique` = `:kernel_unique`, or a `:kernel_latent` spec with
  `unique === true` (the Julia unique-folded analogue)

The four gates (dep+indep, dep+latent, dep+unique, indep+latent) are ported
on this mapping, keyed by shared `group`. This is a **generalization**, not
a byte-for-byte port — R's guards are stated over its own two-term
`unique`-as-separate-source shape, while Julia folds `unique` into the same
`SourceCovariance`. The mapping is documented rather than silently assumed;
flagging it here per instruction, since it's a case where the exact R
semantics don't transfer 1:1.

## Commit granularity deviation

The task instructions ask for "red-first test per the spec's sketch, then
implement, then commit" **per step**. In practice, `_recognize_source_term`,
`_build_source_term_spec`, `_source_term_covariance`, and
`_check_source_term_exclusions` are single functions each handling all
seven `kind`s in one `if`/`elseif` chain — Steps 1/3/5/6 are branches of the
*same* functions, not separable files or even separable function bodies
without artificial revert/reapply churn that would itself risk introducing
bugs between commits. I ran the red tests for each step's sketch (Step 0's
gate tests before the general recognizer existed at all; Step 5's kernel
tests, which caught the bare-symbol-vs-bar bug above, before the kernel
branch was corrected) but landed the implementation in **two** commits
(scaffolding + non-kernel modes covering Steps 0–4; kernel recognizers
covering Steps 5–6) rather than seven. Every step's red-first test sketch
from the spec is present as a distinct `@testset` in
`test/test_formula_structured_terms.jl` and passes; the git history is
coarser than the spec's step numbering, which I'm flagging directly rather
than silently claiming seven discrete step commits.

## Verification

- `test/test_formula_structured_terms.jl` standalone: 58/58 assertions
  pass (`julia --project=. -e 'using GLLVM; include("test/test_formula_structured_terms.jl")'`).
- `using GLLVM` loads cleanly (no new warnings beyond the pre-existing
  `Distributions.Multinomial` name clash).
- Full suite was **not** run locally per task instruction (orchestrator
  runs it consolidated on Totoro).

## Ledger rows converted (case-id-ready)

Per the spec's post-verification correction, the implementable payoff for
§2 is 9 BLOCKED rows. All 9 are now case-id-ready on this recognizer
(pending maintainer approval to merge):

- `namespace/export/indep` (Step 1)
- `namespace/export/scalar` (Step 2)
- `namespace/export/kernel_latent` (Step 6)
- `namespace/export/kernel_indep` (Step 5)
- `namespace/export/kernel_dep` (Step 5)
- `namespace/export/kernel_scalar` (Step 5)
- `namespace/export/kernel_unique` (Step 6, via the documented fold-only
  disposition — `_source_term_covariance` explicitly rejects a standalone
  `kernel_unique` and points at `kernel_latent(..., unique=true)`; whether
  the ledger case wants a literal standalone `kernel_unique` ARgumentError
  contract test or considers the fold itself sufficient is a call for the
  ledger owner, not decided here)
- `covariance/COV-KERNEL-LATENT` (Step 6)
- `covariance/COV-KERNEL-FOLDED-UNIQUE` (Step 6, case STRUCT-KER-SINGLE-PSI
  — single-kernel unique-fold numerics verified against direct
  `fit_gaussian_sources`, not yet against the R fixture's frozen numerics)

`namespace/export/dep` was already paid before this slice (unchanged; Step 3
adds its recognizer as a byproduct of building the shared machinery, feeding
the already-PASS-receipted `covariance/COV-ORD-DEP` per the spec's
post-verification correction).

Steps 7–8 (multi-source bridge lift; named `extract_Sigma` tier) were **not**
attempted — Steps 0–6 consumed the available time; they're next per the
spec, and both explicitly require touching `src/bridge.jl` /
`src/source_fit.jl`, which are outside this lane's file ownership
(read-only, per task instructions: "just modified by sibling slices").

## Explicitly out of scope (unchanged from spec §3)

phylo/animal covariance-vs-precision, spatial SPDE, augmented-slope engines
— not implemented, not stubbed, per task instruction.
