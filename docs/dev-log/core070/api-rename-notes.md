# API-name-collision renames — `src/re_sd.jl` / `src/diagnostics.jl`

Maintainer decision: docs/dev-log/decisions/2026-09-01-maintainer-decisions-round2-3.md
item #5 — rename Julia functions that shadow R names with **different
semantics**, freeing the name for a future true R-mirror. Source list:
`docs/dev-log/core070/wave7-conversion-batch-contract.json` (`deferred[]`,
38 rows) + `docs/dev-log/core070/wave7-conversion-notes.md`.

## Scope of this pass

Owned files only: `src/re_sd.jl`, `src/diagnostics.jl` (renames only, no
behaviour change), the corresponding export lines in `src/GLLVM.jl`, and
`test/test_se_machinery.jl` / `test/test_diagnostics.jl` call-site updates.

## Rename table (5 confirmed collisions, all in the maintainer's explicit list)

| Old name | New name | File | Reason (from wave7 deferred ledger) |
|---|---|---|---|
| `getREsd` | `latent_score_sd` | `src/re_sd.jl` | R's `getREsd(fit, block=)` covers auxiliary RE blocks (diag_unit, phylo, re_int, ...); Julia's computes latent factor-score conditional SDs instead — the quantity R's `getLV(se=TRUE)` covers. Different quantity entirely. |
| `compare_Sigma_table` | `compare_fits_Sigma_table` | `src/diagnostics.jl` | R's `compare_Sigma_table(x, truth, ...)` compares a fit against a supplied ground-truth matrix; Julia's is a two-fit bridge. Different signature/purpose. |
| `compare_dep_vs_two_psi` | `compare_fits_dep_vs_two_psi` | `src/diagnostics.jl` | R's version takes ONE fitted phylogenetic "two-ψ" model and internally refits an alternative; Julia's is a generic two-fit bridge, no distinct "two-ψ" family implemented. Different model class. |
| `compare_indep_vs_two_psi` | `compare_fits_indep_vs_two_psi` | `src/diagnostics.jl` | Same phylo-specific two-ψ mismatch as `compare_dep_vs_two_psi` (its indep counterpart; a one-line alias in Julia). |
| `diagnostic_table` | `fit_diagnostic_table` | `src/diagnostics.jl` | R's `diagnostic_table(x, table=)` requires `x` to already carry `gllvmTMB_diagnostic` metadata (attached by a prior `predictive_check()`/`residuals()` call); Julia's takes the raw fit and computes everything itself. Different call shape. |

Each rename:
- Renamed the function (all methods, for `getREsd`) and its docstring(s),
  adding a "Renamed from `<old>` (maintainer decision ... #5)" provenance
  note plus the specific R-shape-mismatch reason quoted above.
- Added a deprecated forwarding method for the old name:
  `old(args...; kwargs...) = (Base.depwarn("..."); new(args...; kwargs...))`.
- Kept the old name **exported**, matching its current exported state (both
  `getREsd`/`latent_score_sd` and `diagnostic_table`/`fit_diagnostic_table`
  etc. are exported in `src/GLLVM.jl`) — no export-surface removal, only
  addition of the new name alongside the old.
- Updated call sites in `test/test_se_machinery.jl` (getREsd → latent_score_sd,
  all occurrences) and `test/test_diagnostics.jl` (the four diagnostics.jl
  names).
- Added one test per file asserting the deprecated forwarding actually
  works, via `Test.@test_deprecated` (NOT `@test_logs (:warn, ...)` —
  `Base.depwarn` is silent by default (`--depwarn=no`), so `@test_logs`
  observes nothing and would give a false failure; `@test_deprecated`
  handles this correctly and was verified working in this environment).

## Comment/docstring hygiene note

`src/re_sd.jl`'s module docstring quotes R's own function repeatedly
(`R's getREsd(fit, block=...)`, `.../re-uncertainty.R`) — those references
to **R's actual function name** were left as `getREsd` (not renamed) since
they describe R's surface, not GLLVM.jl's. Only references to *GLLVM.jl's*
function were renamed to `latent_score_sd`. Same care taken in
`src/diagnostics.jl`'s `fit_diagnostic_table` docstring (which now correctly
attributes "Port of R's `diagnostic_table()`" rather than the renamed
Julia name).

## Scanned for other collisions in my files — found, NOT renamed

Per the task's "collisions in files you don't own get LISTED... not
edited" instruction, and because the maintainer's round2-3 decision #5
explicitly enumerated only the 5 rows above (verified against
`wave7-conversion-notes.md`'s own gap table, which the maintainer reviewed
before writing decision #5) — the following are same-name-shadow
collisions **living in `src/diagnostics.jl`** per the wave7 deferred
ledger, but were **not** renamed here because the maintainer's explicit
list did not include them (their `reason` strings describe RNG-decoupling
or return-shape mismatches, not the "different quantity/model entirely"
character of the 5 confirmed rows) and unilaterally renaming an exported
public API beyond an explicit maintainer instruction is out of scope for a
"renames only" task:

| Name | Deferred ledger source_id | Reason summary |
|---|---|---|
| `gllvmTMB_check_consistency` | `namespace/export/gllvmTMB_check_consistency` | Same conceptual MC consistency check on both sides, but RNG streams are independently seeded — only structural comparison possible, not a different-quantity collision. |
| `gllvmTMB_diagnose` | `namespace/export/gllvmTMB_diagnose`, `postfit/POSTFIT-SURFACE-gllvmTMB_diagnose` | R returns a rich report list (ICC, communality per tier); Julia returns `(pass, sanity, boundary_flags, messages)` — shape gap, not renamed by maintainer. |
| `check_gllvmTMB` | `postfit/POSTFIT-SURFACE-check_gllvmTMB` | R returns a data.frame of named checks with PASS/WARN/FAIL/INFO status; Julia aggregates to one `pass::Bool`. |
| `predictive_check` | `namespace/export/predictive_check`, `postfit/POSTFIT-SURFACE-predictive_check` | Same conceptual simulate-and-summarise check on both sides; RNG-decoupled, structural comparison only. |
| `diagnose_kernel_separability` | `postfit/POSTFIT-SURFACE-diagnose_kernel_separability` | R's kernel-keyword machinery scopes to a different structured-covariance mechanism than Julia's K_W-tier check; no shared fixture exercises both. |
| `confint_inspect` | `postfit/POSTFIT-SURFACE-confint_inspect` | Genuinely comparable in shape on both sides; blocked only by the live-paired-run cost of per-term profile CIs on both engines, not a semantic mismatch. |

**Recommendation for maintainer follow-up**: if any of these six are later
confirmed as "different semantics" (not just RNG/shape gaps), they can be
renamed with the same forwarding-shim pattern used here.

## Leftover: confirmed-collision name living OUTSIDE my two files

`profile_targets` → `profile_curve_targets` was named in the task brief as
a confirmed collision "in your files," but it actually lives in
**`src/confint_profile.jl`** (not `src/re_sd.jl` or `src/diagnostics.jl`),
which this task's file-ownership boundary excludes me from editing. Per
the wave7 ledger (`namespace/export/profile_targets`): R's `profile_targets()`
is a READINESS REGISTRY (which parameters could be profiled, without
running anything — cheap and reversible because `TMB::tmbprofile()` needs
the fit's live tmb_obj checkpoint); Julia's `profile_targets(fit, targets)`
instead RUNS every target's curve directly (no comparable checkpoint step
exists in GLLVM.jl). Genuine "different operation" collision, same
character as the 5 confirmed renames above — **flagged for the agent/task
that owns `src/confint_profile.jl` to rename to `profile_curve_targets`**
with the same forwarding-shim pattern. `test/test_se_machinery.jl` still
calls `profile_targets(fit, ...)` (3 call sites, lines ~286-289) — those
were left untouched since the function itself is out of scope for this
pass.

## Verification

- `julia --project=. test/test_se_machinery.jl` — standalone green
  (1096/1096 pass) after the rename, including the new
  `getREsd: deprecated forwarding to latent_score_sd` testset.
- `julia --project=. test/test_diagnostics.jl` — standalone green
  (65/65 pass) after the rename, including the new
  `deprecated names forward to their renamed target (maintainer decision
  round2-3 #5)` testset.
- `julia --project=. -e 'using GLLVM'` — clean load; both old and new
  names resolve for all 5 renamed functions (verified via a one-off
  `println` of each symbol).

## Tallies

- Functions renamed: 5 (1 in `src/re_sd.jl`, 4 in `src/diagnostics.jl`).
- Deprecated forwarding shims added: 5.
- Docstrings updated with rename provenance: 5.
- Export-line additions in `src/GLLVM.jl`: 5 new names added alongside
  their still-exported old names (no removals).
- Test call sites updated: 16 in `test/test_se_machinery.jl` (all
  `getREsd` → `latent_score_sd`) + 8 in `test/test_diagnostics.jl` (the
  four diagnostics.jl names) = 24.
- New forwarding-assertion tests added: 2 testsets (1 per file, covering
  all 5 renamed functions between them).
- Other same-name collisions found in my files but left unrenamed
  (maintainer list did not confirm): 6, listed above for follow-up.
- Confirmed-collision leftover outside my files: 1 (`profile_targets`,
  lives in `src/confint_profile.jl`), listed above for follow-up.

## Commits

1. `refactor(re_sd): rename getREsd -> latent_score_sd, deprecated forwarding shim (round2-3 #5)`
   — `src/re_sd.jl`, `src/GLLVM.jl` (export line + include comment).
2. `refactor(diagnostics): rename 4 collision functions, deprecated forwarding shims (round2-3 #5)`
   — `src/diagnostics.jl`, `src/GLLVM.jl` (export line).
3. `test(se-machinery,diagnostics): update call sites to renamed names + forwarding-shim tests`
   — `test/test_se_machinery.jl`, `test/test_diagnostics.jl`.
4. `docs(core070): api-rename-notes for re_sd/diagnostics collision renames`
   — `docs/dev-log/core070/api-rename-notes.md` (this file).
