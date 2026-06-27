# Claude → Claude handover — `latent(..., lv = ~ x)` build-out (2026-06-27)

**You are Claude, picking up the `latent(..., lv = ~ x)` goal mid-flight.** Codex is
on leave, so you are running the live Julia/R toolchain directly. This doc is the
durable record; the chat that produced it is gone. Read it top to bottom before
touching anything.

> **Source of truth.** This is the GLLVM.jl copy of the cross-repo handover. The work
> spans **two** repos — GLLVM.jl (Julia) and gllvmTMB (R). The mission-control table
> in §2 covers both. The companion session-handoff `docs/dev-log/claude-xlv-session-handoff-2026-06-27.md`
> (on the held feature branch) and the after-task reports under
> `docs/dev-log/after-task/2026-06-27-*` carry the per-slice detail — link, don't re-read.

---

## 0. The goal (durable "why")

The maintainer's standing instruction (`/goal`): **finish ALL the work related to
`latent(..., lv = ~ x)` across both R and Julia** — confidence intervals, all
response families, mixed-family, structured sources (phylo/animal/spatial/kernel),
tier expansion (K>1), broad parity, and the public article — **each gated by
recovery/coverage validation**. "I mean really ALL."

`latent(lv = ~ x)` = **predictor-informed latent scores**: the latent ordination
axes are regressed on unit-level covariates `x`. The estimand surfaced to users is
the derived product **`B_lv = Λ · α'`** (loadings × score-effect), which is
**rotation- and sign-stable** — invariant under `Λ → ΛQ, α → αQ` for any orthogonal
`Q` and any K. That invariance is *why* CIs on `B_lv` are well-posed for K ≥ 1 and is
the backbone of the whole subsystem.

**Hard constraints (verbatim, do not violate):**
- **Never** work from `/Users/z3437171/Dropbox/Github Local/gllvmTMB` for package PR
  work. That is the **dirty mission-control tree** — must not be cleaned, reset,
  staged, committed, reverted, or harvested in bulk. Use the `/private/tmp/gllvm*`
  worktrees/clones for all PR work.
- **One open PR at a time.** Land before opening the next.
- **No GPU lane. No DRAC/Totoro power sweeps** until this bridge goal is closed.
- Keep **REML / AI-REML language Gaussian-only**. Do **not** claim broad R↔Julia parity.
- Family / likelihood / inference changes are **HIGH-RISK** → must **not** self-merge
  without maintainer approval (the maintainer gave explicit landing approval for the
  current pile via "go ahead and merge"; that approval does **not** extend to new
  families or new inference surfaces).
- Keep user-facing **advertising / capability-promotion parked** until the
  register/NEWS/article slice.
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
  PR bodies end with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- **Never `git add -A`** (Documenter generates untracked artifacts; stage explicit paths).

---

## 1. Headline finding (the big one)

**A pre-existing, package-wide bug: every non-Gaussian Wald CI in GLLVM.jl was
wrong — now fixed and merged (#119).** `_fd_hessian` wrote `2f0`, which Julia lexes
as the Float32 literal `2.0f0`, **not** `2 * f0`. The observed-information diagonal
therefore dropped the centre value and exploded with the objective's constant,
collapsing `inv(H)` to standard errors ~1e-6. It affected every
`confint(fit, Y; method=:wald)` path (Poisson/Binomial/NB/Beta/Gamma/Tweedie/
two-part/SPDE-latent/structural). Off-diagonals, profile, bootstrap, and the
Gaussian path were unaffected. It survived because the CI tests only checked
structure / `pd_hessian`, never SE magnitude. Fix: `2f0 → 2*f0`, pinned by a new
`test_fd_hessian.jl` against a known analytic Hessian. **Merged as #119.**

---

## 2. Mission control — both repos (the at-a-glance table)

### GLLVM.jl (Julia) — `https://github.com/itchyshin/GLLVM.jl`

`origin/main` = **`88f898b`** and carries: **#118** (Poisson X_lv), **#119** (the
`2f0` Wald-SE fix), **#120** (NB2 X_lv). Full `Pkg.test` on the feature tree: 4834
pass, 1 broken (pre-existing), exit 0.

| item | branch / PR | tip | state | what it is |
|---|---|---|---|---|
| Poisson X_lv | #118 | merged | ✅ on main | bridge admits Poisson `X_lv` route |
| `2f0` Wald-SE fix | #119 | merged | ✅ on main | package-wide CI repair + `test_fd_hessian.jl` |
| NB2 X_lv | #120 | merged | ✅ on main | bridge admits NB2 `X_lv` route |
| **Gamma X_lv** | **#121** `claude/gamma-xlv-20260626` | open | 🟡 **CI UNSTABLE/pending** | next to land |
| Beta X_lv | `claude/beta-xlv-20260626` | `7d7b29d` | held, **unpushed** | rebase onto main after #121 |
| X_lv recovery bench | `claude/xlv-recovery-20260627` | `47acce4` | held, **unpushed** | correctly-specified multi-seed recovery + checkpoint |
| **X_lv CI subsystem** | `claude/xlv-wald-ci-20260627` | `4a79ab7` | held, **unpushed** | `confint_lv_effects` — Wald + bootstrap, 6 families, K≥1, native + bridge; `test_lv_ci` **106/106** |
| handover (this doc) | `handover/2026-06-27-claude` | new | docs-only PR | this file + AGENTS snapshot |

### gllvmTMB (R) — primary repo

| item | branch | tip | state | what it is |
|---|---|---|---|---|
| R Poisson X_lv | `claude/poisson-xlv-r-20260626` | `1404783` | held, **unpushed** | admit Poisson `X_lv` on `engine='julia'` |
| R NB2/Gamma/Beta X_lv | `claude/nbgammabeta-xlv-r-20260627` | `b940a96` | held, **unpushed** | admit NB2/Gamma/Beta `X_lv` (+ `skip_if_not_installed("glmmTMB")`) |
| **R CI reader** | `claude/xlv-r-ci-reader-20260627` | **dirty (uncommitted)** | ⚠️ **not yet committed** | reads the Julia Wald CI bridge fields into `extract_lv_effects()` — see §5 |

> 🔴 **Every held branch above is LOCAL and UNPUSHED.** A fresh session checks out a
> clean tree and will not see them. They live only in the `/private/tmp/gllvm*`
> worktrees on this machine. **If you resume on a different machine, they are gone.**
> Pushing is the maintainer's call for the family/CI branches (high-risk); say so
> loudly. The handover branch itself is pushed by this doc's PR.

### Landing sequence (one open PR at a time; ~50 min CI per PR × 4 OSes)

1. **#121 Gamma** — merge when green (currently UNSTABLE/pending).
2. **Beta** — `git rebase --onto origin/main 34fb20c claude/beta-xlv-20260626`, PR, land.
3. **Recovery bench** (`47acce4`) — rebase onto main, PR, land (low-risk: tests + bench).
4. **CI subsystem** (`claude/xlv-wald-ci-20260627` @ `4a79ab7`) — the big one. Rebase
   onto main, PR. **HIGH-RISK (new inference surface) → maintainer approval to merge.**
5. **R Poisson** (`1404783`) → **R NB2/Gamma/Beta** (`b940a96`) → **R CI reader** (§5).

---

## 3. What the X_lv CI subsystem actually contains (Julia, held on `claude/xlv-wald-ci-20260627`)

`src/confint_family.jl`:
- `confint_lv_effects(fit, X_lv; method = :wald | :bootstrap, n_boot, seed, level)`
  — GLM Union method + a separate Gaussian/`GllvmFit` method.
- **Wald (delta method):** `Cov(B_lv) = J Σ Jᵀ`, `Σ = inv(H)`, `J = ∂vec(B_lv)/∂θ` by
  finite difference. GLM path uses `_fd_hessian` (Laplace objective is not
  AD-friendly); Gaussian path uses exact `ForwardDiff.hessian`.
- **Bootstrap:** percentiles of derived `B_lv` over `simulate(fit; X_lv)` + refit,
  sign-aligned. Six family closures in `_lv_boot_fns`.
- **Packed-θ layouts** (do not confuse these):
  - GLM: `[β(p); vec(α_lv)(q_lv·K); pack_lambda(Λ)(rr); optional log-disp]`.
  - Gaussian (`gaussian_lv_nll_packed`, q=0): `[vec(α_lv)(q_lv·K); log_σ(1);
    pack_lambda(Λ)(rr)]` — **α FIRST, no β**.
- **K ≥ 1 guard** with the rotation-invariance comment (was K==1; relaxed because
  `B_lv` is rotation-invariant).

`src/bridge.jl`: `_bridge_lv_ci_fields(ci, q_lv)` emits
`lv_effects_lower/upper/se/ci_level/ci_method/ci_pd` (reshaped p×q_lv); the 6 X_lv
routes merge `ci_extra`; gate is `ci_method in ("none","wald")`.

`test/test_lv_ci.jl`: **106/106** (Gaussian K=2 bootstrap guard, per-family bootstrap
smokes, q_lv=2, bridge==native, level=0.90, gate-rejection).

**Validation gate already closed:** all 8 K=1 routes recover `B_lv` ~unbiased with
RMSE ~1/√n; K=1 coverage 0.915–0.955 (80/80 PD); K=2 coverage 0.925–0.964 (60/60 PD).

---

## 4. Gotchas / failed approaches (do not repeat)

- **The `2f0` lexing trap.** `2f0` is a Float32 literal, not `2*f0`. If you ever
  hand-write finite-difference stencils in Julia, never juxtapose an integer with a
  variable named `f…`. This bug cost the most.
- **Gaussian bootstrap transpose.** `_lv_boot_fns(::GllvmFit)` originally computed the
  score mean as `X_lv * alpha_lv'`. `alpha_lv` is **q_lv×K**, `X_lv` is **n×q_lv**, so
  the mean must be `X_lv * alpha_lv` (→ n×K). The transpose `DimensionMismatch`es for
  q_lv≠K (silently swallowed → `n_converged=0` → all-NaN) and draws from the wrong mean
  for q_lv==K>1. **Hid because every Gaussian fixture was q_lv==K==1** (transpose =
  no-op). Found by the multi-agent audit; fixed; guarded by the Gaussian K=2 bootstrap
  test (asserts `n_converged ≥ 25`).
- **`gen_poisson` comprehension bug (recurred twice).** A Poisson data generator
  called the η-builder *inside* the per-cell array comprehension, redrawing the shared
  innovation per cell → mis-specified data → spurious Poisson under-coverage (0.46,
  later 0.611 in the K=2 sweep). **The engine was never wrong.** Fix: hoist the
  RNG-consuming `eta` out of the comprehension (→ 0.917 / 0.961). Lesson: hoist RNG
  setup out of comprehensions; cross-check any anomalous coverage against a dedicated
  correct run before suspecting the engine.
- **Escaped quotes inside `$(...)` interpolation** break the Julia parser. Write
  `"$(join(_BRIDGE_XLV_FAMILIES, ", "))."` — **not** `\", \"`. Caught by a load check.
- **New worktrees:** `Manifest.toml` is gitignored → run `Pkg.instantiate()` before
  the first `julia` run in a fresh `/private/tmp/gllvm*` clone.
- **`gh pr merge` transient "unexpected EOF":** just retry; it succeeds.

---

## 5. ⚠️ The R CI reader is BUILT but UNCOMMITTED — your first concrete task

A multi-agent workflow built the R-side reader on `claude/xlv-r-ci-reader-20260627`
(worktree `/private/tmp/gllvmtmb-xlv-r-ci-reader-20260627`). **The workflow's
`.output` capture file is empty (0 bytes) — the real artifact is the dirty working
tree**, which is coherent and high-quality on inspection:

- `extract_lv_effects()` now surfaces `std.error` / `lower` / `upper` from the Julia
  payload's `lv_effects_se` / `lv_effects_lower` / `lv_effects_upper` (with a
  dimension-match guard and `uncertainty_status = "julia_bridge_wald_delta_method"`),
  instead of hardcoding `std.error = NA`.
- Gate `GJL-GATE-XLV-CI` relaxed from `ci_method != "none"` to
  `!ci_method %in% c("none", "wald")` in both `gllvm_julia_fit` and the summary path.
- CI payload reshaping (`lv_effects_*` → p×q_lv with dimnames; `ci_level`/`ci_method`/
  `ci_pd` scalarised).
- Docstrings + capability notes updated to "Wald X_lv CIs are routed; profile/bootstrap
  remain gated."

`git diff --stat`: `R/julia-bridge.R` +101, `tests/testthat/test-julia-bridge.R` +187.

The build+audit workflow's overall verdict was **PASS** (gate correctly admits only
`ci_method="wald"`; profile/bootstrap, X+X_lv, mask+X_lv stay gated; `ci_method`
threaded through; the self-contradicting `test-julia-bridge.R:1881-1884` gate-raises
assertion *was* updated), **with one MAJOR blocker the maintainer must resolve:**

> 🔴 **The absent-CI path is not schema-preserving.** `.gllvm_julia_extract_lv_effects`
> now **always** adds `lower` and `upper` columns to the returned frame — even on the
> `ci_method="none"` point-estimate path (filled `NA_real_`). The *values* are correct,
> but the **column set changed**: the TMB engine path (`R/extractors.R:603-612`) still
> emits **no** `lower`/`upper`, and the documented `@return` contract
> (`R/extractors.R:535-538`) lists only `{level, trait, predictor, estimate,
> std.error, uncertainty_status, validation_row}`. So the two engines now return
> structurally different frames for the same call, and any downstream
> `rbind`/`identical`/`expect_named` comparison breaks. **Decision for the maintainer:**
> (a) add `lower`/`upper` to the `@return` roxygen *and* the TMB path for parity, or
> (b) only add `lower`/`upper` when `have_ci` is TRUE. This is an API decision — do not
> self-merge it. **(b) is the smaller, lower-risk change** and keeps the point-estimate
> schema byte-stable; lean that way unless the maintainer wants cross-engine CI parity.

**Before committing it:** (a) re-read the diff with fresh eyes; (b) confirm `%||%` is
available in that file's namespace; (c) `Rscript -e 'parse("R/julia-bridge.R")'`
parse-check both files; (d) **resolve the schema blocker above** (likely option (b));
(e) commit on `claude/xlv-r-ci-reader-20260627` with the trailer. **It cannot be
`devtools::test()`-run here — the local R env is broken (§6).** It is the last R↔Julia
CI link and depends on the bridge fields landing (the CI-subsystem branch) first.

---

## 6. Blockers

1. **CI-bound landing.** Each GLLVM.jl PR runs full `Pkg.test` × 4 OSes (~50 min
   each). The 5–6-PR serial landing spans hours. This is the rate limiter, not the work.
2. **Local R env is broken.** `library(gllvmTMB)` aborts (missing
   `assertthat`/`devtools`/`roxygen2`); `install.packages` fails (no network to CRAN).
   **All R slices are parse-validated + statically audited only — never `devtools::test()`-run
   on this machine.** A working R env (or Codex returning to run the live R toolchain)
   is required to actually exercise the R reader.
3. **Held branches unpushed** (see §2 warning).

---

## 7. Remaining roadmap (post-landing; why each is not autonomously closeable now)

- **Profile-likelihood CIs for `X_lv`.** Wald + bootstrap are done and
  coverage-calibrated; profile for the derived product `B_lv` needs a constrained
  re-optimisation — harder, low marginal value.
- **Mixed-family `X_lv`; structured sources (phylo/animal/spatial/kernel) × `X_lv`.**
  Substantial NEW modeling — the X_lv fitters currently *reject* these combinations.
  Each warrants its own design decision + recovery/coverage gate.
- **Broader K>1 / non-Poisson direct recovery+coverage.** Cheap confirmatory sweep.
- **Public article.** Deliberately not drafted — guards say don't advertise
  un-promoted capability until the register/NEWS/article slice.

---

## 8. How to resume (TARGET = Claude)

1. Read `~/.claude/memory/memory_summary.md` (gllvmTMB repo rules) and this doc.
2. `cd` into the relevant `/private/tmp/gllvm*` worktree — **never** the Dropbox
   mission-control tree. Map the live state:
   ```bash
   cd /private/tmp/gllvmjl-xlv-wald-ci-20260627 && git fetch origin
   git log -1 --format='%h %s' origin/main      # expect 88f898b until #121 lands
   gh pr list --state open                       # expect #121 Gamma until it lands
   ```
3. **Continue the landing sequence in §2** (merge #121 → Beta → recovery → CI
   subsystem → R branches → R reader). HIGH-RISK PRs (#4, family/CI) need maintainer
   approval before self-merge.
4. **Commit the R CI reader (§5)** once you've re-reviewed + parse-checked it.
5. Live R toolchain is **Codex's** lane (when back). Claude plans/refactors/writes
   prose + runs Julia + logic/CI checks. Spawn the repo's review lens (Rose) before any
   public capability claim.
6. After each slice: narrow tests → after-task report under
   `docs/dev-log/after-task/` → surface PR links + report paths + 🔴 blockers in chat
   (the maintainer does not browse PRs).

---

## 9. Files created / modified this session

**GLLVM.jl — `claude/xlv-wald-ci-20260627` (held):** `src/confint_family.jl`
(`confint_lv_effects` + helpers + `2f0` fix carried), `src/bridge.jl`
(`_bridge_lv_ci_fields` + 6 route merges + gate), `test/test_lv_ci.jl` (→106),
`CHANGELOG.md` (Unreleased Fixed+Added), `docs/dev-log/claude-xlv-session-handoff-2026-06-27.md`,
`docs/dev-log/after-task/2026-06-27-*.md`, `docs/dev-log/recovery-checkpoints/2026-06-27-*.md`,
`bench/lv_coverage.jl`.

**GLLVM.jl — `claude/fd-hessian-wald-fix-20260627` (merged as #119):**
`src/confint_family.jl` (`2f0→2*f0`), `test/test_fd_hessian.jl`.

**GLLVM.jl — `claude/xlv-recovery-20260627` (held):** `bench/lv_recovery.jl`,
recovery checkpoint.

**GLLVM.jl — `claude/beta-xlv-20260626` (held):** Beta X_lv route in `src/bridge.jl`.

**gllvmTMB — `claude/poisson-xlv-r-20260626` / `claude/nbgammabeta-xlv-r-20260627`
(held):** `R/julia-bridge.R` (`.GLLVM_JULIA_XLV_FAMILIES`, family admission),
`tests/testthat/test-julia-bridge.R`.

**gllvmTMB — `claude/xlv-r-ci-reader-20260627` (dirty, §5):** `R/julia-bridge.R`
(+101), `tests/testthat/test-julia-bridge.R` (+187).

**This handover:** `docs/dev-log/handover/2026-06-27-claude-handover.md` (this file) +
`AGENTS.md` Phase-state snapshot bullet — both on `handover/2026-06-27-claude`.
