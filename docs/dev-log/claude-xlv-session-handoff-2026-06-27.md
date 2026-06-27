# Claude session handoff — `latent(..., lv = ~ x)` build-out (2026-06-27)

Authoritative reference for the work done this session (Codex on leave; Claude ran
the live Julia/R toolchain directly). Nothing is pushed — all branches are local.

## 1. Headline

**A pre-existing, package-wide bug: every non-Gaussian Wald CI in GLLVM.jl was
wrong.** `_fd_hessian` wrote `2f0` (the Float32 literal `2.0f0`, not `2 * f0`), so
the observed-information diagonal dropped the centre value and exploded with the
objective's constant, collapsing `inv(H)` to standard errors ~1e-6. Affects
`confint(fit, Y; method=:wald)` / `_family_wald` for Poisson/Binomial/NB/Beta/
Gamma/Tweedie/two-part/SPDE-latent/structural CIs. Off-diagonals, profile,
bootstrap, and the Gaussian path were unaffected. The CI tests only checked
structure / `pd_hessian`, never SE magnitude — which is why it survived.

## 2. What shipped (all committed, none pushed)

### GLLVM.jl (Julia)
| branch | base | commits | content |
|---|---|---|---|
| `claude/fd-hessian-wald-fix-20260627` | **main** | `c7db1ae` | the `2f0→2*f0` fix + `test_fd_hessian.jl` (pins the Hessian to a known analytic value) |
| `claude/xlv-recovery-20260627` | Beta tip | `47acce4` | correctly-specified multi-seed recovery bench + checkpoint (8 routes + n-scaling) |
| `claude/xlv-wald-ci-20260627` | Beta tip | `3a8995e`,`e2a6620`,`fcf4925`,`fb47e37`,`a4d1b96`,`2bda27a` | `confint_lv_effects` (all 6 families, native + **bridge** `ci_method="wald"`) + coverage + **K>1** |

### gllvmTMB (R)
| branch | base | commit | content |
|---|---|---|---|
| `claude/nbgammabeta-xlv-r-20260627` | R-Poisson | `67158e9` | admit NB2/Gamma/Beta `X_lv` on `engine='julia'` (static-validated; see env note) |

Prior held pile (unchanged): GLLVM.jl #118 (Poisson, open), NB2/Gamma/Beta Julia
(stacked, unpushed), R-Poisson (`claude/poisson-xlv-r-20260626`), gllvmTMB #564.

## 3. Validation evidence

- **`_fd_hessian` fix:** `test_fd_hessian` 5/5; `test_confint_family` 122/122,
  `test_structural_confint` 45/45, `test_confint_profile` 4/4, `test_bridge_ci`
  64/64 — all green with the fix; existing non-Gaussian Wald SE `3e-6 → ~0.05`.
- **Recovery (point):** all 8 K=1 routes recover `B_lv` essentially unbiased
  (mean bias ≤0.004), n=160/320/640 sweep → RMSE ~1/√n, bias→0.
- **Coverage (interval):** all 8 K=1 routes 0.915–0.965 (80/80 PD).
- **K>1 (tier expansion):** `B_lv=Λα'` rotation-invariant → guard relaxed to K≥1;
  K=2 validated (recovery + coverage ~0.94 per family).
- **Tests:** `test_lv_ci` 73/73; `test_bridge_lv_predictor` 207/207.

## 4. The X_lv Wald-CI subsystem is now complete on the Julia side

All six families × K=1 and K>1 × native (`confint_lv_effects`) and bridge
(`ci_method="wald"` → `lv_effects_lower/upper/se`) × recovery and coverage
validated. Plus the package-wide Wald-SE repair.

## 5. 🔴 Needs maintainer

1. **Push the `_fd_hessian` fix** (off main, independent of #118) — repairs every
   non-Gaussian Wald CI package-wide. Highest-value, landable now.
2. **Merge #118** → unblocks the held NB2/Gamma/Beta Julia + their R admissions.
3. **Repair the local R env** — `assertthat`/`devtools`/`roxygen2` missing and no
   network to CRAN, so the R slices are static-validated only (parse + family-
   mapping + ledger-order verified) and cannot be `devtools::test()`-run here.

## 6. Remaining roadmap (and why each is not autonomously closeable now)

- **R reads the bridge CI fields** (the last R↔Julia CI link) — needs a working R
  env; depends on the bridge wiring + #118 merging.
- **Profile / bootstrap CIs for `X_lv`** — incremental; Wald is already
  coverage-calibrated, so low marginal value. Bounded if wanted.
- **Mixed-family `X_lv`; structured sources (phylo/animal/spatial/kernel) ×
  `X_lv`** — substantial NEW modeling (the X_lv fitters currently reject these
  combinations); each its own recovery/coverage gate. Warrant a design decision.
- **Broader K>1 recovery/coverage across families** — cheap confirmatory sweep.
- **Public article** — deliberately not drafted; the guards say don't advertise
  un-promoted capability until the register/NEWS/article slice.

## 7. Process notes

- Two repeats of one bench bug: a Poisson generator that called the η-builder
  *inside* the per-cell comprehension, redrawing the shared innovation per cell
  (mis-specified data → spurious under-coverage). The engine was never affected;
  caught both times by cross-checking against a dedicated correct run. Lesson
  recorded: hoist RNG-consuming setup out of array comprehensions.
- All per-slice after-task reports are in `docs/dev-log/after-task/2026-06-27-*`.
