# CI verdict — run 33622687447 @ df7009b3

Perspective: Gauss. Worktree `/private/tmp/GLLVM.jl-core070-aghq-20260830`
(branch `codex/core070-aghq-20260830`, HEAD `ce9aee48+`); CI ran on `df7009b3`
with the same `src/`/`test/`.

**Job "Julia 1.10 - ubuntu-latest"** (julia 1.10.12,
`Pkg.test(; julia_args=["--check-bounds=yes","--compiled-modules=yes","--depwarn=yes"])`):

> **13360 passed, 7 failed, 0 errored, 6 broken**

Local reference: Totoro, commit `a9e22ef5`, Julia 1.12.6, check-log "suite5
FULLY GREEN" → 13325 pass / 0 fail / 8 broken. "Julia 1 - ubuntu-latest"
(latest 1.x) was `in_progress` when checked, and **still `in_progress`**
at the end of this diagnosis (see last line).

## Class A — six `@test_deprecated` failures

**Mechanism.** `@test_deprecated` is **byte-identical** in Julia 1.10.12
and 1.12.6's `Test` stdlib (`Test/src/logging.jl` ~309-345): it checks
`Base.JLOptions().depwarn` — only runs the real
`@test_logs (:warn, pattern, Ignored(), :depwarn) match_mode=:any` check
when `depwarn==1` (`--depwarn=yes`); with `depwarn==0` (default, no flag)
it just runs the expression **unwrapped by any `@test`** — no pass, no
fail, not exercised. Reproduced on both installed versions:

```
$ julia +1.10.12 --depwarn=yes -e '...; f() = Base.depwarn("x is renamed to y", :f); @test_deprecated f()'
ERROR: There was an error during testing
  Captured Logs: LogRecord(Warn, "x is renamed to y", Main, :depwarn, ...)

$ julia +1.12.6 --depwarn=yes -e '...; f() = Base.depwarn("x is renamed to y", :f); @test_deprecated f()'
ERROR: There was an error during testing
  Captured Logs: LogRecord(Warn, "x is renamed to y", Core, :depwarn, ...)
```

Both versions fail **identically** under `--depwarn=yes` — not a
1.10-vs-1.12 stdlib difference. With no flag, `Base.JLOptions().depwarn`
is `0` on both (confirmed). **Mechanism, one sentence**: CI's `Pkg.test`
explicitly adds `--depwarn=yes`; the local Totoro run behind "suite5
FULLY GREEN" evidently did not, so these six lines ran unchecked there
(silently skipped, not passed) while CI's flag activates the real check
and it fails because none of the six shim messages contain "deprecated".

**The six shim messages** (none contain "deprecated"), each `"<name> is
renamed to <new_name>; the name <name> is reserved for a future
R-mirroring [readiness-registry] surface"`:

- `src/diagnostics.jl:740` `diagnostic_table` → `fit_diagnostic_table`
- `src/diagnostics.jl:748` `compare_Sigma_table` → `compare_fits_Sigma_table`
- `src/diagnostics.jl:755` `compare_dep_vs_two_psi` → `compare_fits_dep_vs_two_psi`
- `src/diagnostics.jl:762` `compare_indep_vs_two_psi` → `compare_fits_indep_vs_two_psi`
- `src/re_sd.jl:332` `getREsd` → `latent_score_sd`
- `src/confint_profile.jl:777` `profile_targets` → `profile_curve_targets`

**Proposed fix (not applied)** — insert "is deprecated:" into each message, e.g.:

```julia
Base.depwarn(
    "diagnostic_table is deprecated: renamed to fit_diagnostic_table; the " *
    "name diagnostic_table is reserved for a future R-mirroring surface",
    :diagnostic_table)
```

applied identically across all six shims. Correct on **both** versions
(macro logic is identical); only the message text needs the word. **No
test change needed** — the six call sites are already correct; they only
need `--depwarn=yes` to be exercised at all. **Risk to numerics: none** —
only the warning string of unused-name forwarding shims changes; return
values (`fit_diagnostic_table(...)` etc.) are untouched.

## Class B — `test_phylo_branch_re.jl:139` numeric mismatch

**Evaluated** (`z_sparse ≈ z_dense`, `rtol=1e-9, atol=1e-8`):

```
[-0.16923876383754013, 0.33042678400661896, -0.43540063641886045,
 0.5643776378944559, -0.012076115502603338, 0.004025368473984262]
≈ [-0.16923876925440495, 0.33042677858704717, -0.4354006569686339,
   0.5643776173436553, -0.01207613988264411, 0.004025359226572586]
```

~3e-8 relative across the six entries, tripping `rtol=1e-9`.

**What the test compares.** `test/test_phylo_branch_re.jl:100-139` builds
a 4-leaf tree, forms dense `Σ = σ²V + σ²_eps·I`, computes `z_dense` via
plain dense `\` (LAPACK/OpenBLAS). It compares against `z_sparse` from
`branch_blups` (`src/phylo_branch_re.jl:336-360`), a genuinely different
path: **sparse** Cholesky (`cholesky(Symmetric(Λ/λscale))`, CHOLMOD via
`_lambda_chol`, `src/phylo_branch_re.jl:184-190`) on the scaled auxiliary
precision `Λ = diag(1/(σ²ℓ)) + σ_eps⁻²ZᵀZ` via Woodbury.

**Fixture, not conditioning, is the binding constraint.** `y = [1e8,
1e8+0.5, 1e8-0.25, 1e8+0.75]` (line 121); `cond(Σ)` for both `(σ²,σ²_eps)`
pairs is **~5.17 and ~1.00** (computed in this worktree) — Σ is very
well-conditioned, not a near-singular solve. The real constraint is
representational: `eps(1e8) ≈ 1.49e-8` — a value near `1e8` carries only
~8 significant decimal digits, coarser than the 9-digit `rtol=1e-9`
demand on quantities derived from that `y`. Two correct algorithms on the
same double-precision `y` at this scale can legitimately diverge by
~`eps(1e8)`, independent of library version. Library versions differ and
touch exactly these two solve paths:

| | Julia 1.10.12 (CI) | Julia 1.12.6 (Totoro) |
| --- | --- | --- |
| OpenBLAS_jll | 0.3.23+2 | 0.3.29+0 |
| SuiteSparse_jll (CHOLMOD) | 7.2.1+1 | 7.8.3+2 |

`z_dense` depends on OpenBLAS's dense factorization/summation order;
`z_sparse` on CHOLMOD's sparse ordering/factorization — both bumped
between these Julia releases. Either shift can move accumulated rounding
by a few ULPs at a `y`-scale already sitting at the `eps(1e8)` floor.

**Classification: environment drift interacting with a too-tight
tolerance on an ill-scaled (not ill-conditioned) fixture** — not an
engine defect. Dense-LAPACK vs. sparse-CHOLMOD-via-Woodbury are
intentionally different algorithms (that's the point of the cross-check);
both are correct to the precision their `1e8`-scale input can support.

**Fix options (diagnosis-first — no tolerance widening as the default):**
(1) **recenter the fixture** — shift `y` by its mean (production code
already does this internally via `ymean`/`yc`) so compared quantities are
O(1), restoring genuine 1e-9 headroom; (2) **conditioning-aware bound** —
replace flat `rtol=1e-9` with `rtol = κ * eps(maximum(abs, y))`, stating
what precision the inputs can support instead of a fixed digit count;
(3) **split the checks** — keep the dense-vs-sparse cross-check on an
O(1) fixture, move the large-offset case to a same-algorithm repeat.
**Recommendation**: option 1 — smallest, most surgical, fixes the actual
defect (an unnecessarily ill-scaled `y`) without touching what the test
asserts. **No tolerance widening without the maintainer's explicit
sentence** (AGENTS.md "No silent tolerance widening") — if the maintainer
prefers loosening `rtol` instead, that decision belongs in the commit
that makes it.

---

## What this means for PR #277

Not mergeable as-is. Needs one fix commit (Class A wording; Class B
fixture/assertion per maintainer decision) then a **fresh green CI run**
— the current red run cannot be waived. Pushing the fix **cancels the
in-progress "Julia 1" job**, so push once, after "Julia 1 - ubuntu-latest"
has also concluded on this SHA.

## Not the engine
13360 of 13367 executed checks passed on Julia 1.10.12 under the
strictest flags (`--check-bounds=yes`, `--depwarn=yes`), including every
parity/cross-objective/recovery suite; Totoro's Julia 1.12.6 suite is
fully green (0 failures) at a slightly lower total-test count consistent
with the six unchecked `@test_deprecated` lines under default `depwarn=0`.
Both classes localize to test-harness/fixture concerns — a warning-text
wording convention, and a fixture whose `y`-scale outruns Float64's
representable precision at the requested tolerance — not to the
dense/sparse likelihood, gradient, or CI machinery itself.

---

**Julia 1 - ubuntu-latest, final check**: `in_progress` (no conclusion
yet) as of the last poll before this file was written.
