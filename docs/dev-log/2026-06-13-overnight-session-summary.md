# Overnight autonomous session — summary + open decisions (2026-06-13)

Maintainer away (reachable on mobile); REML held until the drm team finishes
(we borrow theirs). This banks everything done + the calls still waiting on you.

## Banked engine + docs (local commits)

| commit | branch | what |
|---|---|---|
| `6809ee9` | integration (pushed) | EM-FA per-var fast path default — 9–164× faster than L-BFGS, identical ML optimum (Δ logL ≤ 2e-7), 54/54 tests |
| `3786f53` | codex/non-gaussian-fitter-gradients | 340× claim scoped to single-σ²; `fit_phylo_gaussian` marked shipped |
| `86b851f` | codex/… | docs consolidation — 12 files, 12/12 sound agent review |
| `202a960` | codex/… | wire 4 green orphan suites into runtests; triage the rest |
| `9a46880` | codex/… | merge origin (mobile-homepage), kept `getLV(fit,Y)`, check-log unioned |
| `86fd07c` | codex/… | gate em_squarem_safety behind GLLVM_SLOW_TESTS; wire into runtests |
| `055e089` | codex/… | feat: Wald CIs for Poisson GLLVM fits (observed information; FD-verified, 10/10) |
| `9c6dcbf` | codex/… | feat: extend non-Gaussian Wald CIs to Binomial (6/6; Gaussian confint 14/14, no regression) |

Uncommitted (untracked) dev-log notes only: this file, the drm-REML borrow map,
the orphan triage, the gllvmTMB-thread audit notes. No code uncommitted.

## GitHub state (authorized batch — done)

- **GLLVM.jl main → `9406e22`** (merged #89 analytic-gradient default + #90 CLAUDE.md refresh). Local main fast-forwarded.
- **gllvmTMB main → `2305d4c`** (merged #473 — the R→Julia `engine="julia"` bridge).
- **`origin/integration` pushed**; **draft PR #95** (integration→main) open — predates #89, needs reconciliation before merge.
- 8 stale `/private/tmp/gll-*` worktrees pruned (41 remain).

## Verification evidence

- EM-FA vs L-BFGS per-var: identical ML optimum, Δ logL ≤ 2e-7 across p=8/16/32; default fitter 5–16 ms (was 150–900 ms).
- Per-var-touching tests after the EM default: 54/54 (gaussian_pervar 14 · unified_api 22 · aicbic 18).
- Doc examples executed: confint/profile_ci/getLV corrected forms 5/5 run.
- Docs diff reviewed file-by-file: 12/12 sound, every API claim cross-checked vs `src/`.
- Working-branch merge: 0 conflict markers; `getLV(fit, Y)` preserved.

## Findings to action

- **drm REML** (see `2026-06-13-drm-reml-borrow-map.md`): drm's REML is TMB-AD Laplace only; the **Gaussian closed-form REML objective is borrowable** (GLLVM.jl could make it fast via Woodbury), but **analytic-gradient + phylo REML are NOT in drm** — those don't come for free. (drm's live board shows them building Newton/AI-REML now.)
- **Phylo orphan failures** (`2026-06-13-orphan-test-triage.md`): `em_phylo`/`em_squarem` fail an "EM == dense MLE" gate by an identical ~1.99 logLik (EM internally consistent — likely a stale gate comparing unconstrained EM to a σ_phy>0-constrained dense fit); `confint_derived_wald` phylo-signal H² returns 6.5 (out of [0,1]) with NaN CI — possible real bug. Noether is diagnosing; fix-or-park rec to follow, no fix without maintainer OK.
- **`em_squarem_safety`**: passes but takes 38 min — recommend a `GLLVM_SLOW_TESTS` gate before wiring (mechanism doesn't exist yet).

## Open decisions for the maintainer

1. **Per-trait Ψ default flip** — make Gaussian `latent` default to ΛΛᵀ + per-trait Ψ (residual=FALSE opt-out). Speed objection is gone (EM-FA). Routing + claim-scoping, not new math.
2. **Push the working branch** — `codex/non-gaussian-fitter-gradients` is merged + clean, ahead of origin, unpushed. Push it?
3. **Phylo fix-or-park** — once Noether reports.
4. **PR #95 (integration→main)** — reconcile with the merged #89, then merge (currently draft).
5. **REML** — held; revisit when drm finishes (borrow the Gaussian closed-form).

## Slices left to ship both packages (4-agent count, 2026-06-13)

**43 of 59 slices remain** — 16 done · 20 in progress · 23 not started. (Non-Gaussian
Wald CIs now substantially done: **all 5 real-dispersion one-part families** done &
FD-verified — Poisson/Binomial/NB/Beta/Gamma (commits 055e089, 9c6dcbf, 3a4dc59, 72594e0;
41 assertions, every SE matched to a central-FD oracle; Gaussian confint 14/14, no
regression). Remaining: Ordinal (cutpoints) Wald + profile/bootstrap CIs for non-Gaussian.) (Estimate
from the parity "Honest gaps" + both roadmaps/ledgers + the audit, deduped; not a
line-by-line audit. Much of "in progress" lives on `integration`, not yet on main.)

| category | total | note |
|---|---|---|
| functionality | 21 | structured×non-Gaussian, @formula+slopes+Xβ (Laplace), missing-data across families, ZIP/ZINB/Delta-Gamma/Tweedie |
| release | 18 | CRAN mechanics, Julia registry, version bump + [compat], executed-doc tutorials |
| parity | 9 | frozen-value R-parity harness in CI, per-trait Ψ flip, machine-precision evidence |
| inference | 4 | non-Gaussian CIs (Wald/profile/bootstrap) |
| infra | 4 | GLLVM_SLOW_TESTS gate, orphan fix-or-park |
| speed | 3 | REML (held for drm), per-var fallbacks |

Highest-leverage remaining: non-Gaussian CIs · frozen-value parity harness ·
per-trait Ψ flip (gated) · executed-@example tutorials · version bump + ForwardDiff
compat · gllvmTMB --as-cran 3-OS green (maintainer) · slow-tests gate · bridge
structured/phylo/spatial (#33). Full 59-slice list: workflow output for run
`wf_20532ea9-100`.

---

## RESUME HERE — context handoff to a fresh thread (2026-06-13)

**Read first:** this file · `docs/dev-log/2026-06-12-session-handover.md` (broader
twin-project handover) · `docs/dev-log/2026-06-13-drm-reml-borrow-map.md` ·
`docs/dev-log/2026-06-13-orphan-test-triage.md` · `~/.claude/memory/memory_summary.md`.
Rehydrate: `git log --oneline -12`, `git status`, `git worktree list`.

**Branch / GitHub state:**
- On `codex/non-gaussian-fitter-gradients`, tip **`72594e0`**, **10 commits ahead of
  origin, UNPUSHED** (no push without an explicit maintainer instruction). Tracked tree
  is **clean**; untracked = `.claude/` (the dashboard), the dev-log notes, `bench/results/`.
- Merge `9a46880` already reconciled origin (mobile-homepage homepage; my `getLV(fit,Y)`
  fix kept; check-log unioned).
- `integration` pushed → `origin/integration`; **draft PR #95** (integration→main) open,
  needs reconcile vs the just-merged #89.
- Both mains synced after merging PRs: GLLVM.jl main `9406e22` (#89 analytic-grad + #90),
  gllvmTMB main `2305d4c` (#473 R→Julia bridge). 8 stale `/tmp` worktrees pruned.

**The 10 commits:** EM-FA per-var default (`6809ee9`, on `integration`) · 340× scoped to
single-σ² (`3786f53`) · docs consolidation (`86b851f`) · orphan triage (`202a960`) ·
origin merge (`9a46880`) · GLLVM_SLOW_TESTS gate (`86fd07c`) · non-Gaussian Wald CIs
Poisson (`055e089`) / Binomial (`9c6dcbf`) / NB (`3a4dc59`) / Beta+Gamma (`72594e0`).

**Possibly-still-running agent:** `Noether` (read-only phylo root-cause). Check `/workflows`.
It was diagnosing (a) em_phylo/em_squarem "EM == dense MLE" gate failing by ~1.99 logLik —
likely a STALE gate (unconstrained EM vs σ_phy>0-constrained dense fit), not a real bug;
(b) `confint_derived_wald` phylo-signal H²=6.5 with NaN CI — possible REAL bug. **HOLD any
phylo fix for the maintainer** (their explicit instruction).

**Next autonomous slice (was mid-flight at handoff):** **Ordinal Wald CIs** — the 6th
one-part family, to finish `src/confint_nongaussian.jl`. `OrdinalFit` has `Λ` + ordered
cutpoints `τ` (length `C−1`) and **NO β intercept** (unlike the 5 done families). Marginal
is the cumulative-logit `ordinal_*`. CAUTION: cutpoints are ordered (τ₁<…<τ_{C-1}); confirm
the fit's packed parameterisation (the `θ` layout) before building the Hessian, and the CI
back-transform. Verify with the same central-FD-oracle pattern as the others (see
`test/test_confint_nongaussian.jl`). Then: profile + bootstrap CIs for non-Gaussian.

**Non-Gaussian CI capability shipped this session:** Wald CIs via observed information
(ForwardDiff Hessian of the Laplace marginal, FD-oracle-verified) for **Poisson, Binomial,
NB, Beta, Gamma** — see `src/confint_nongaussian.jl` (`_wald_ci_from_nll` generic +
`_wald_ci_dispersion_family` for the log-dispersion families).

**Widget:** `preview_start` config **`status-dashboard`** → port **8770**, serves
`.claude/preview/index.html`. Keep it honest + live (maintainer asked: show agents / who /
how many; the **"Slices left to ship: 43 of 59"** metric).

**Held maintainer decisions:** per-trait Ψ default flip · push the working branch
(merged+clean, local-only) · reconcile+merge PR #95 · phylo fix-or-park · REML (hold until
drm finishes; borrow map banked). **Discipline:** stage by name, one concern per commit,
no push without instruction, verify before claiming.
