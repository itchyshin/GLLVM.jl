# Post-LV capability cost-control boundary

Date: 2026-07-02
Status: next capability boundary after LV closeout
Scope: generic non-Gaussian family CI bootstrap, row-effect missing-response
test cost, and local worktree hygiene

## Decision

The next goal after the LV closeout is a bounded capability-cleanup slice, not a
new phylo Model A or source-specific `lv` slice.

What changed:

- The redundant empty placeholders under `docs/dev-log/after-task/.gitkeep`
  and `docs/dev-log/decisions/.gitkeep` were removed after both directories had
  real files.
- The ZIB family-CI smoke and row-effect missing-response extra gate were
  already resized so the focused tests and full package suite can complete.
- The current source audit confirms that generic family bootstrap refits still
  use each fitter's default iteration budget.

What must not change in this slice:

- no source-specific `phylo_latent(..., lv = ~ env)` or
  `spatial_latent(..., lv = ~ env)` exposure;
- no PR #127 reopen;
- no new Totoro or DRAC production compute;
- no old population-`B_lv` bootstrap/profile reruns;
- no package API widening without maintainer approval.

## Source audit

The generic family CI route has no public `bootstrap_iterations` keyword:

```text
src/confint_family.jl:1552:function _family_bootstrap(ad::_FamilyCI, sel::Vector{Int}, level::Real,
src/confint_family.jl:1667:function confint(fit::_CIFit, Y::AbstractMatrix;
```

The expensive ZIB bootstrap refit currently calls the default fitter:

```text
src/confint_family.jl:1234:function _family_ci(fit::ZIBFit, Y::AbstractMatrix;
src/confint_family.jl:1260:        fb = try fit_zib_gllvm(Yb; K = K, N = Ntr) catch; return nothing end
src/families/twopart.jl:1082:function fit_zib_gllvm(Y::AbstractMatrix{<:Real}; K::Integer, N::Integer,
```

The existing iteration cap is deliberately limited to LV-effect bootstrap
helpers:

```text
src/confint_family.jl:2014:                            bootstrap_iterations::Union{Nothing, Integer} = nothing)
src/confint_family.jl:2060:                            bootstrap_iterations::Union{Nothing, Integer} = nothing)
src/confint_family.jl:2116:function _lv_boot_kwargs(bootstrap_iterations::Union{Nothing, Integer})
```

Therefore, adding `bootstrap_iterations` to generic
`confint(fit, Y; method = :bootstrap)` would be public API widening. Per
`AGENTS.md`, that needs an explicit API/documentation/test cascade and
maintainer authorization; it should not be slipped in as a cleanup patch.

## Current operating truth

The cost boundaries are no longer blockers to the completed LV arc:

- `test/test_confint_family.jl` is green as a bounded smoke gate:
  `122 pass | 4m17.9s`.
- `test/test_missing_response_extra.jl` is green as a bounded
  missing-response gate: `35 pass | 3m20.4s`.
- The core suite then passed: `4951 pass | 3 broken | 4954 total | 45m28.3s`.
- The full package suite then passed: `4963 pass | 1 broken | 4964 total |
  50m07.1s`.

These are local package-gate facts. They are not calibration evidence for
source-specific phylo `lv`, and they do not revive the old weak-cell route.

## Candidate next defensible target

The next implementation slice, if Shinichi wants to spend engineering time
here, should be:

```text
Design and implement maintainer-approved generic family bootstrap refit-control
for confint(fit, Y; method = :bootstrap), with default behavior unchanged.
```

Minimal evidence gate:

1. Default `confint(fit, Y; method = :bootstrap)` results remain unchanged for
   a fixed seed on at least one one-part and one two-part family.
2. A positive refit-iteration cap is honored by the ZIB bootstrap path.
3. A non-positive cap fails before any bootstrap refits.
4. `test/test_confint_family.jl` remains green.
5. User-facing docs and examples name the new keyword if the API is widened.
6. Rose wording says "cost-control knob", not "coverage improvement".

Until that slice is authorized, keep the current bounded smoke tests as the
practical gate and move project effort to higher-value capability work.

## Rose verdict

Rose verdict: PASS WITH NOTES - the LV arc remains closed, the test-cost
boundary is explicit, and generic family bootstrap refit-control is parked
behind a separate maintainer-approved API slice.
