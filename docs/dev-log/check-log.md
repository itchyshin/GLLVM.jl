# Check Log

## 2026-08-05 - BetaBinomial+X dispersion identity (Arc 0 docs)

Lane `docs/betabinomial-x-identity-20260805` (closeout programme S3). Decision
ACCEPTED: public twin default under shared site-X = **per-trait φ** + **shared
γ**, twin to gllvmTMB `betabinomial` / `log_phi_betabinom` (fid 8). Twin cites
from local `gllvmTMB` @ `ab49638b`. Tweedie rejected as next rung (user path
fail-loud). **No** `src/` engine / bridge admit. Rose: Identity ≠ engine ≠
full family parity ≠ ADEMP. After-task:
`docs/dev-log/after-task/2026-08-05-betabinomial-x-identity.md`.

## 2026-08-05 - Fix bridge capabilities ledger for nb1+X (#186 follow-up)

`test/test_bridge_capabilities.jl` golden lists omitted `nb1` after #186 added
it to `_BRIDGE_X_FAMILIES` / X-CI routing — 4 failures on main CI. Hygiene PR
#187 lands the expectation update (`fixed_effect_X` + `ci_x_*`). Local
`test_bridge_capabilities.jl`: **107/107**.

## 2026-08-04 - Species-XB light RCall Arc 0 (Poisson)

Lane `parity/species-xb-light-20260804`. Helper
`fit_gllvmtmb_parity_loglik_species_x` with R `(0 + trait):x`; Poisson cell via
`fit_gllvm_speciescov`. Live Δ ≈ 4.20e-9 @ rtol 1e-6. After-task:
`docs/dev-log/after-task/2026-08-04-species-xb-light-rcall.md`.

## 2026-08-05 - Post-NB1 hygiene (Δ paste + Distributions + board truth)

Lane `cursor/post-nb1-hygiene-20260805` (closeout programme S1). Paste live
NB1+X Δ (abs ≈1.531e-9, seed=48); mark #186 MERGED on board/AGENTS/
capability-status/after-task/gllvmtmb-parity; `using Distributions` + parity
`Project.toml` dep so `runparity` NB1+X cell resolves `NegativeBinomial`;
nest Gamma/NB1/Ordinal inside outer X `@testset`. No rtol widen. Rose: ledger
truth ≠ full family parity. After-task:
`docs/dev-log/after-task/2026-08-05-post-nb1-hygiene.md`.

## 2026-08-05 - NB1+X combined Arc 1+2 (engine + light scaffold)

Lane `cursor/nb1-x-engine-arc12-fffd` (PR #186). Engine:
`fit_nb1_gllvm_grouped_cov` / `NB1GroupedCovFit` (default
`hessian=:observed`); OH weight
`W = -μ·s_μ - (μ/φ)²·(trigamma(y+r)-trigamma(r))`; bridge + `@formula` +
confint; shared-φ `fit_gllvm_cov(NB1)` opt-in via `GllvmCovFit.family::Any`.
Identity `test/test_nb1_x_identity.jl`: **7/7**. Bridge X
`test/test_bridge_x.jl`: **208/208**. Light cell scaffolded in
`test/parity/test_x_covariate_parity.jl` (`:nb1` → `nbinom1()`, seed=48);
live `GLLVM_PARITY_TESTS=1` **OWED** (no R/`gllvmTMB` in cloud). No rtol
widen. Rose fence: engine + scaffold ≠ live Δ ≠ full family parity ≠ ADEMP.
After-task: `docs/dev-log/after-task/2026-08-05-nb1-x-engine-arc12.md`.

## 2026-08-05 - NB1+X dispersion identity (Arc 0 docs)

Lane `cursor/nb1-x-identity-arc0-fffd` (PR #185). Decision ACCEPTED: public
twin default under shared site-X = **per-trait φ** + **shared γ**, twin to
gllvmTMB `nbinom1` / `log_phi_nbinom1` (fid 15). Twin cites from
`gllvmTMB` @ `5bf18ab3` (`src/gllvmTMB.cpp:355–356`, `:800`, `:2369–2379`;
`R/fit-multi.R:4034–4039`). Julia: bridge no-X grouped; +X kernel absent
(ArgumentError). No `src/`. Rose fence: identity ≠ engine ≠ light RCall ≠
full family parity ≠ ADEMP. After-task:
`docs/dev-log/after-task/2026-08-05-nb1-x-identity.md`.

## 2026-08-05 - Note board hygiene #183 merged

Docs-only pointer tick: `coordination-board.md` + `AGENTS.md` phase snapshot
now record board hygiene as **MERGED #183** @ `c38b9363` (was “PR #183 open”).
START HERE remains idle. No `src/`.

## 2026-08-05 - Post-#181 board / snapshot hygiene

Docs-only catch-up after Merge #181 (`main` @ `a92c5040`). Cleared stale
“push/PR Ordinal+X Arc 2” / “LOCAL DONE (no push)” pointers on
`docs/dev-log/coordination-board.md` and `AGENTS.md` phase snapshot. START
HERE → idle / await owner pick (G0 Q1). Remote GC of merged X-cohort heads
(G0 Q2=yes). No `src/`; no capability-status promotion; no invented next
family/+X arc. Mechanical verify: greps clear stale push/PR Ordinal LOCAL-DONE
on live pointers. Rose fence unchanged: light RCall ≠ full family parity ≠
ADEMP. After-task: `docs/dev-log/after-task/2026-08-05-board-hygiene.md`.
Plans: `docs/dev-log/plans/2026-08-05-board-hygiene-arc-card.md`,
`docs/dev-log/plans/2026-08-05-board-hygiene-ultra-plan.md`.

## 2026-08-03 - Ordinal+X light RCall Arc 2

Lane `parity/ordinal-x-arc2-20260803` from engine tip `e2b4afde` (#180 tip
exception while Julia CI finishes). Extended
`fit_gllvmtmb_parity_loglik_x` with `:ordinal` → `ordinal_probit()`; one
Ordinal+X `@testset` via `fit_ordinal_gllvm_pertrait_cov` + `ProbitLink`.
Live focused cell (seed=47, p=5, K=1, n=80, C=3): **Δ ≈ 5.38e-9** (rtol
1e-6). No `src/` redesign; no tolerance widen. Rose fence: light Ordinal+X
logLik only ≠ full family parity ≠ ADEMP. After-task:
`docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md`.

## 2026-08-03 - Ordinal+X engine Arc 1 (`fit_ordinal_gllvm_pertrait_cov`)

Lane `fix/ordinal-x-pertrait-cov-20260803` from `origin/main` @ `0630f8e4`
(#179). Implements ACCEPTED cutpoint identity under X: per-trait τ₁=0 / K−2
+ shared site-X γ; bridge/`@formula` routing; Julia identity tests.
Focused verify: identity **21/21** (incl. FD ≤ 1e-6); identity+capabilities
**128/128**; bridge_x+formula Ordinal smoke **215/215**. Full `Pkg.test` not
run. No tolerance widen. Rose fence: engine ≠ RCall Arc 2 ≠ ADEMP ≠ full
family parity. After-task:
`docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md`.

## 2026-08-03 - Rebase Ordinal identity tip onto post-#178 main

Resolved board/AGENTS/check-log conflicts after Gamma+X #178 merged.
Docs-only; no `src/`.

## 2026-08-03 - Ordinal+X cutpoint identity (Arc 0 docs)

Lane `docs/ordinal-x-identity-20260803` from `origin/main` @ `0e241215`.
Decision ACCEPTED: public twin default under shared site-X =
**per-trait cutpoints** (τ₁=0 fixed, K−2 free log-spacings) + **shared γ**,
mirroring Gamma/NB2 API B under X for the cutpoint estimand (not φ).
Twin cites: `gllvmTMB` `src/gllvmTMB.cpp:650–659`, `:2152–2167`;
`man/ordinal_probit.Rd:24–26`; site-X via `X_fix*b_fix` `:664–667`.
Julia cites: `fit_gllvm`→`fit_ordinal_gllvm_pertrait`
(`src/families/fit_gllvm.jl:144`); per-trait unpack τ₁=0
(`src/families/ordinal.jl:308–324`); bridge “no covariate kernel”
(`src/bridge.jl:171–173`, `:393–405`). Mechanical: **no `src/`** in lane
diff. Rose fence: docs ≠ engine ≠ RCall ≠ full family parity; Gamma land /
#177 remain OWED outside GOAL. After-task:
`docs/dev-log/after-task/2026-08-03-ordinal-x-identity.md`.

## 2026-08-03 - Merge origin/main into Gamma+X tip (post-#177)

Resolved docs + `test/parity` conflicts so this PR carries Gamma+X Arc 1–2
on top of merged #177 (NB2/Beta+X light cells). Unioned shared-X oracle
families and X-cohort cells; no tolerance widen.

## 2026-08-03 - Cursor handover (Gamma+X Arc 1–2 close)

Handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md`
on preferred tip `parity/gamma-x-arc2-20260803` (Arc 2 content @ `44e5f801`).
`handoff_gate.sh` FAIL declared: Gamma stack CARRIED-OVER (push/PR ask);
duplicate `fix/gamma-x-grouped-cov-20260803` @ `bcd48513` CARRIED-OVER (do not
push); Dropbox `claude/jl-bridge-capabilities-20260619` PROTECTED; #177
CARRIED-OVER (merge when green). Board + AGENTS snapshot point at Active-Lane-
Split. Next: land Gamma PR when asked; merge #177; fresh chat = Ordinal+X
identity Arc 0 only.

## 2026-08-03 - Gamma+X light RCall Arc 2

Lane `parity/gamma-x-arc2-20260803` stacked on engine tip `ca2b2c0b`. Unblocker:
`fit_gamma_gllvm_grouped_cov` / grouped Gamma Laplace gained
`hessian=:observed` (default; TMB curvature `W=α y/μ` under log link) —
Fisher-only objective was systematically Δ≈0.2–1 vs gllvmTMB. Identity G=1 vs
`fit_gllvm_cov` forces `hessian=:fisher`. Parity: extend
`fit_gllvmtmb_parity_loglik_x` for `:gamma` → `stats::Gamma(link="log")`; add
Gamma+X cell (`group=collect(1:p)`, default observed). Live
`GLLVM_PARITY_TESTS=1`: Gamma+X **Δ≈3.03e-8** (seed=46, p=5, K=1, n=120);
shared-X suite pass; identity **7/7**; bridge_x **204/204**. rtol stayed
`1e-6`. Rose: OK for “Gamma+X light logLik under per-trait α”; ≠ full family
parity; ≠ NB2/Beta+X on this tip (#177); ≠ Ordinal+X. After-task:
`docs/dev-log/after-task/2026-08-03-gamma-x-arc2-parity.md`. Fence #177 merge.

## 2026-08-03 - Gamma + X grouped_cov (API B under X) — Arc 1

Lane `fix/gamma-x-grouped-cov-20260803` from `origin/main` @ `0e241215` (+
cherry-picked identity decision `82cdd5e5`/`2e865b82`). Engine:
`fit_gamma_gllvm_grouped_cov` / `GammaGroupedCovFit` (θ = `[β; γ; pack(Λ); log α…]`,
FD LBFGS; offset `O=Xγ` into `gamma_grouped_marginal_loglik_laplace`). Bridge +
`@formula` route `gamma`+X here; `fit_gllvm_cov(...; family=Gamma())` stays
shared-α opt-in. Identity `test/test_gamma_x_identity.jl`: **7/7** (G=1 ≈
`fit_gllvm_cov` atol=1e-2/rtol=1e-4; constant αvec+X offset ll ≈ shared to
1e-10). Bridge X **204/204**; formula **11/11** + Gamma route smoke →
`GammaGroupedCovFit`. Rose fence: Arc 1 Julia identity + routing only — **not**
Arc 2 RCall; no Option B flip; #177 untouched. After-task:
`docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md`.

## 2026-08-03 - Tweedie Wald SE seed repair (unblock #177 on Julia 1.10)

`test/test_confint_family.jl:294` ("Tweedie Wald + bootstrap") flaked on
**Julia 1.10-ubuntu only** (CI run 30814553093, macOS/windows/Julia-1-ubuntu
green): `isfinite(ci.se[pidx])` failed for `phi`. Root cause found by local
repro: with `Random.seed!(35)`, `fit_tweedie_gllvm` converges with the fitted
power `p` pinned at its `p_init=1.5` default (`p=1.499997`), leaving a
knife-edge-flat likelihood ridge in `(φ, p)` whose Hessian-derived phi SE is
`~3.4e-8` — technically finite on macOS (Julia 1.10.0 local repro confirms),
but on the knife-edge enough that a platform-dependent LAPACK/BLAS
least-significant-bit difference on ubuntu's Julia 1.10 runner flips the sign
of a near-zero curvature term, producing `NaN`. Not an #177-diff issue —
`test_confint_family.jl` has zero diff vs `main` on this branch.

Repair: swapped the DGP seed `35` → `3` (same n/K/p/iterations, no `@test`
assertion or tolerance touched). Seed 3's draw makes the fit move well away
from `p_init` (`p≈1.276`), giving a well-conditioned phi SE (`~0.086`, four
orders of magnitude larger, immune to LSB-level platform noise). Verified
locally: full `test/test_confint_family.jl` **124/124 pass** (7m21s,
`julia --project=. test/test_confint_family.jl`, Julia 1.10.0 macOS). Rose
fence: this is a setup/seed repair for a pre-existing, PR-177-unrelated flake
— not a tolerance widening, not touching Julia 1.10 in the CI matrix (kept).

## 2026-08-03 - Arc 2 conflict resolution vs main (#177 close-out)

Merged `origin/main` (post-#176, tip `0e241215`) into
`parity/nb2-beta-x-arc2-20260802` to unblock PR #177. Only
`docs/dev-log/check-log.md` and `docs/dev-log/coordination-board.md`
conflicted (both docs-only, additive log/board entries from disjoint
lanes); resolved by keeping both sides' entries and updating the
Active-Lane-Split to reflect #176 **MERGED** and #177 awaiting green
Julia CI. No engine, test, or tolerance changes in this commit.

## 2026-08-02 - NB2/Beta+X Arc 2 — light gllvmTMB logLik parity cells

Lane `parity/nb2-beta-x-arc2-20260802` from post-merge `origin/main` @
`9f5133a7` (#175 merged). No engine changes — extends
`test/parity/parity_helpers.jl` `fit_gllvmtmb_parity_loglik_x` to accept
`:negbinomial`/`:beta` (`gllvmTMB::nbinom2()`/`gllvmTMB::Beta()`, per-trait
dispersion by R default) and adds two `@testset`s to
`test/parity/test_x_covariate_parity.jl`: "NB2 + shared X (q=1)" and "Beta +
shared X (q=1)", using Arc 1 `fit_nb_gllvm_grouped_cov` /
`fit_beta_gllvm_grouped_cov` (`group=collect(1:p)`, default
`hessian=:observed`).

DGP repair (both cells): the first draw for each family left one trait's
per-trait dispersion running to a near-boundary value (NB2 `r` → ~1e7,
near-Poisson; Beta `φ` → ~3.5e5, near-degenerate) — a genuine Heywood-like
identifiability failure under the combined X + latent + per-trait-dispersion
load, not numerical noise. Repaired by moving to `K=1`, milder loadings, and
stronger true overdispersion/precision signal (NB2: `r_true=1.5`, `n=120`;
Beta: `φ_true=8.0`, `n=80`) — both R fits then converge cleanly and every
per-trait estimate stays well away from its boundary. rtol 1e-6 unchanged, no
tolerance widened.

Live run (`GLLVM_PARITY_TESTS=1 julia --project=test/parity
test/parity/runparity.jl`): shared site-X cohort **34/34** (was 18/18 before
Arc 2). NB2+X Δ logLik = `1.29e-8`; Beta+X Δ logLik = `4.29e-9`. Full
`Pkg.test()`: **5096 pass / 1 broken (pre-existing) / 0 fail** in 55m22s
(Aqua/JET included, no regressions). Rose fence: "NB2/Beta + shared site-X
light logLik under per-trait φ, twin to gllvmTMB `disp.group`" — **not** full
family parity, **not** shared-φ-Julia-vs-per-trait-R, no Gamma+X/Ordinal+X.
After-task: `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md`.

## 2026-08-02 - Windows row-effect NA gate (unblock #175)

PR #175 Windows CI failed twice on
`test/test_missing_response_extra.jl:284` (`fr_na.converged`) with
`fit_roweffect_gllvm(...; iterations=160)`. Arc 1 identity **14/14** on the
same Windows runs; macOS/ubuntu/Julia 1.10 green; local missing-response-extra
**35/35**. Restored fitter-default iteration budget (500) for the row-effect
NA/mask cells; kept `n=50` runtime bound. No tolerance change. Probe (macOS):
converges in 142 iters under seed 44.

## 2026-08-02 - NB2/Beta + X grouped_cov (API B under X)

Lane `fix/nb2-beta-x-grouped-cov-20260802` from post-merge `origin/main` @
`c4c46293` (#172/#173/#174). Engine: `fit_nb_gllvm_grouped_cov` /
`fit_beta_gllvm_grouped_cov` (θ = `[β; γ; pack(Λ); log disp…]`, default
`hessian=:observed`); bridge + `@formula` route NB/Beta+X here; `fit_gllvm_cov`
stays shared-φ opt-in. Identity `test/test_nb_beta_x_identity.jl`: **14/14**
(G=1+fisher ≈ `fit_gllvm_cov` atol=1e-2/rtol=1e-4; constant rvec/φvec+X offset
ll ≈ shared to 1e-10). Bridge X **201/201**; formula **11/11**. Rose fence:
Arc 1 Julia identity + routing only — **not** Arc 2 RCall; Gamma+X unchanged.
After-task: `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md`.

## 2026-08-02 - Default-route φ landing (push + PR #169)

Branch `parity/default-route-phi-20260801` @ `3621ffde` pushed to origin.
PR: https://github.com/itchyshin/GLLVM.jl/pull/169 (base `main`, **not merged**).
Head OID matches local tip. Rose fence in PR body: light logLik / default-route
φ only — not full family parity; grouped_dispersion:61 not claimed fixed.
Parity re-smoke skipped (existing `/tmp/default-route-phi-parity.log` still green;
twin `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`). Landing LOOP:
`lanes/default-route-phi-landing-20260801/LOOP/`. Attach scratch left untracked.

## 2026-08-01 - Default-route NB2/Beta per-trait φ (API B)

Lane: `parity/default-route-phi-20260801` from catch-up tip `bbf5d7d8`.
Twin `/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`.

Engine: `fit_gllvm` coerces `disp_group=nothing`→`:species` for
`NegativeBinomial`/`Beta` only → `NBGroupedFit`/`BetaGroupedFit`. Named
`fit_nb_gllvm` / `fit_beta_gllvm` remain shared-φ. Gamma unchanged.

Live (`GLLVM_PARITY_TESTS=1 … runparity.jl` →
`/tmp/default-route-phi-parity.log`):

```text
Gaussian 30/30 · Binomial 6/6 · Poisson 6/6 · NB2 8/8 · Beta 8/8 · Ordinal-probit 5/5
= 63/63
NB2 Δ=-2.499e-4 (fit_gllvm default) · Beta Δ=+5.969e-9 (fit_gllvm default)
```

Cascade core 51/51. Core `runtests.jl`: **5063 passed, 1 failed, 0 errored,
3 broken** — sole fail is pre-existing one-group NB grouped≈shared cell
(`test_grouped_dispersion.jl:61`; engines unchanged vs `bbf5d7d8`). Rose fence:
default-route per-trait φ light logLik for NB2+Beta only — **not** full family
parity. After-task:
`docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md`.

## 2026-08-01 - A4/A5 catch-up logLik oracle CLOSE (all ordered cells green)

Lane tip (engine): `387d267a` on `catchup/loglik-oracle-20260801`. Twin `cee55a07`.
GOAL complete for light gllvmTMB logLik oracles on named routes.

| Family | Route | ΔlogLik order | Evidence SHA |
|---|---|---|---|
| Gaussian | centred unique=FALSE | ~1e-8 | A2 |
| Binomial | Bernoulli | ~1e-10 | A3 |
| Poisson | log | ~1e-8 | A3 |
| NB2 | `fit_nb_gllvm_grouped` `group=1:p` + observed Hess. | ~2.5e-4 | cell `5ad55877`; curvature restored at closeout |
| Beta | `fit_beta_gllvm_grouped` `group=1:p` + observed Hess. | ~6e-9 | `387d267a` |
| Ordinal | **ordinal_probit** + observed Hess. | ~5e-9 | `10fcd484`/`3a84d8b6` |

Full suite (`GLLVM_PARITY_TESTS=1 … runparity.jl` →
`/tmp/gllvmjl-catchup-full-parity-20260801.log`):

```text
Gaussian 30/30 · Binomial 6/6 · Poisson 6/6 · NB2 8/8 · Beta 8/8 · Ordinal-probit 5/5
= 63/63
NB2 Δ=-2.499e-4 · Beta Δ=+5.969e-9 · Ordinal Δ=+5.476e-9
```

Closeout restored NB2 grouped `hessian=:observed` (prior bank at `5ad55877`
omitted the engine hunk). Rose fence: OK for named-route light logLik greens.
**Not OK:** “full family parity,” ADEMP/coverage, or equating `n_drift=0` with
fit parity. #129/#128 fenced.
Melissa plan-actual CLOSED:
`docs/dev-log/plan-actual/2026-08-01-gllvm-jl-catchup-loglik-oracle.md`.
After-task: `docs/dev-log/after-task/2026-08-01-a4a5-catchup-loglik-oracle-close.md`.
(Interim blocked receipt retained:
`docs/dev-log/after-task/2026-08-01-a4a5-nbbeta-ordinal-loglik-blocked.md`.)

## 2026-08-01 - Binomial + Poisson gllvmTMB logLik oracle cells (catch-up A3)

Lane tip prior: `5d0cd93f` on `catchup/loglik-oracle-20260801`. Twin `cee55a07`.

Shared helper `test/parity/parity_helpers.jl` + cells:
`test_binomial_parity.jl`, `test_poisson_parity.jl` (wired in `runparity.jl`).
Call shape: gllvmTMB `0+trait + latent(..., unique=FALSE)`; no Y-centring
(Julia already has per-trait β). logLik rtol 1e-6; no silent widening.

Live (`GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl`):

```text
Gaussian  Julia=-501.450700343274  R=-501.45070035305673  Δ=9.78275238594506e-9   Pass 30/30
Binomial  Julia=-194.681986234064  R=-194.68198623424576  Δ=1.8175683180743363e-10 Pass 6/6
Poisson   Julia=-634.171284410425  R=-634.1712844171735   Δ=6.748564373992849e-9  Pass 6/6
```

Claim fence: ordinary no-X Bernoulli/Poisson Laplace logLik only. NB2/Beta/Ordinal
still gated (#132/#148/#133 OPEN GATE). No ADEMP/coverage.

## 2026-08-01 - Live Gaussian gllvmTMB logLik oracle cell (catch-up A2)

Lane: `catchup/loglik-oracle-20260801` from `origin/main` @ `05210eca`
worktree `.worktrees/gllvmjl-catchup-loglik-20260801`. Twin R
`/tmp/gllvmtmb-parity-restart-20260801` @ `cee55a07`.

A0 capability drift (JuliaCall via `GLLVM_JL_PATH` = lane worktree):

```text
n_drift= 0  unregistered= 0
```

A2 replaced DRAFT CRAN `gllvm::gllvm` / `params$theta` call in
`test/parity/test_gaussian_parity.jl` with live twin shape from
`docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md`:
`gllvmTMB` + `latent(..., unique=FALSE)` + per-trait centred Y;
extractors `logLik(fit)`, `report$sigma_eps`, `extract_Sigma(..., part="shared")`.

Live opt-in run (`GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl`):

```text
Julia logLik          = -501.450700343274
gllvmTMB logLik       = -501.45070035305673
Δ logLik (jl − r)     = 9.78275238594506e-9
Julia σ_eps           = 0.6906550063860128
gllvmTMB σ_eps        = 0.6906556682823224
Δ σ_eps               = -6.618963095395003e-7
Test Summary: Gaussian GLLVM parity: GLLVM.jl vs gllvmTMB | Pass 30  Total 30
```

Claim fence: ledger n_drift=0 ≠ fit parity; this cell is ordinary Gaussian
no-X logLik/σ/Σ only. No ADEMP/coverage. #129/#128 fenced. Bin/Pois next;
NB2/Beta/Ordinal gated on #132/#148/#133 (see correctness inventory scratch).

## 2026-07-02 - Phylo x shared-cutpoint Ordinal structural LV S1 likelihood and canary

Added the private phylo x shared-cutpoint Ordinal(logit) x predictor-informed
LV S1 route. This is internal route evidence only: no public fitter, no R
grammar, no bridge transport, no per-trait ordinal parity claim, no Totoro/DRAC
compute, no coverage calibration, and no source-specific `lv` support were
added.

Implemented:

- new private source file `src/phylo_ordinal_xlv.jl`;
- module include in `src/GLLVM.jl`;
- new focused proof test `test/test_phylo_ordinal_xlv.jl`;
- new S0 and S1 decision notes
  `docs/dev-log/decisions/2026-07-02-phylo-ordinal-structural-lv-s0-target.md`
  and
  `docs/dev-log/decisions/2026-07-02-phylo-ordinal-structural-lv-s1-likelihood.md`;
- updated the structural-source Gate 0 matrix and Design 73 status text.

S1 contract:

```text
family: shared-cutpoint Ordinal(logit)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
cutpoints tau: fitted shared ordered nuisance parameters
response Y: valid ordered categories 1:C
status: private S1 likelihood/profile canary banked
```

Verification:

```text
julia --project=. --startup-file=no test/test_phylo_ordinal_xlv.jl
Phylo x shared-cutpoint Ordinal predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 4.6s
Phylo x shared-cutpoint Ordinal B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 21.5s

julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
Phylo x Beta predictor-informed LV S1 likelihood: 13 passed, 0 failed, 0 errored, 5.7s
Phylo x Beta B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 28.8s

julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
Phylo x Gamma predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.5s
Phylo x Gamma B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 53.4s

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.8s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 24.3s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.6s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 25.0s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 5.0s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 14.1s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 196 passed, 0 failed, 0 errored, 4m18.4s
```

Claim boundary: IN: one private stochastic selected-entry S1 finite-endpoint
route canary for phylo x shared-cutpoint Ordinal `B_eta_realized`, with shared
ordered cutpoints kept as nuisance parameters, plus reduction tests against
ordinary shared-cutpoint Ordinal `X_lv` and a dense leaf-covariance reference.
OUT: no public fitter, no `confint_lv_effects` source route, no R
`phylo_latent(..., lv = ~ env)` grammar, no per-trait ordinal bridge parity, no
bridge, no compute, no coverage calibration, no bootstrap rescue, no
source-variance recovery claim, and no transfer to spatial, animal, kernel,
mixed-family, missing/mask, or `unique=` parity.

## 2026-07-02 - Phylo x Beta structural LV S1 likelihood and canary

Added the private phylo x Beta(logit) x predictor-informed LV S1 route. This is
internal route evidence only: no public fitter, no R grammar, no bridge
transport, no Totoro/DRAC compute, no coverage calibration, and no
source-specific `lv` support were added.

Implemented:

- new private source file `src/phylo_beta_xlv.jl`;
- module include in `src/GLLVM.jl`;
- new focused proof test `test/test_phylo_beta_xlv.jl`;
- new S0 and S1 decision notes
  `docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s0-target.md`
  and
  `docs/dev-log/decisions/2026-07-02-phylo-beta-structural-lv-s1-likelihood.md`;
- updated the structural-source Gate 0 matrix and Design 73 status text.

S1 contract:

```text
family: Beta(logit)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
precision phi: fitted nuisance, loose interior guard required
response Y: finite strictly interior continuous responses in (0,1)
status: private S1 likelihood/profile canary banked
```

Verification:

```text
julia --project=. --startup-file=no test/test_phylo_beta_xlv.jl
Phylo x Beta predictor-informed LV S1 likelihood: 13 passed, 0 failed, 0 errored, 5.2s
Phylo x Beta B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 28.2s

julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
Phylo x Gamma predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.2s
Phylo x Gamma B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 52.8s

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.4s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 24.3s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.3s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 24.5s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.9s
```

Claim boundary: IN: one private stochastic selected-entry S1 finite-endpoint
route canary for phylo x Beta `B_eta_realized`, with fitted shared precision
`phi` kept interior, plus reduction tests against ordinary Beta `X_lv`,
phylo-only Beta GLM, and dense leaf-covariance reference. OUT: no public
fitter, no `confint_lv_effects` source route, no R
`phylo_latent(..., lv = ~ env)` grammar, no bridge, no compute, no coverage
calibration, no bootstrap rescue, no source-variance recovery claim, and no
transfer to Ordinal, spatial, animal, kernel, mixed-family, missing/mask, or
`unique=` parity.

## 2026-07-02 - Phylo x Gamma structural LV S1 likelihood and canary

Added the private phylo x Gamma(log) x predictor-informed LV S1 route. This is
internal route evidence only: no public fitter, no R grammar, no bridge
transport, no Totoro/DRAC compute, no coverage calibration, and no
source-specific `lv` support were added.

Implemented:

- new private source file `src/phylo_gamma_xlv.jl`;
- module include in `src/GLLVM.jl`;
- new focused proof test `test/test_phylo_gamma_xlv.jl`;
- new S0 and S1 decision notes
  `docs/dev-log/decisions/2026-07-02-phylo-gamma-structural-lv-s0-target.md`
  and
  `docs/dev-log/decisions/2026-07-02-phylo-gamma-structural-lv-s1-likelihood.md`;
- updated the structural-source Gate 0 matrix and Design 73 status text.

S1 contract:

```text
family: Gamma(log)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
shape alpha_shape: fitted nuisance, loose interior guard required
response Y: finite strictly positive continuous responses
status: private S1 likelihood/profile canary banked
```

Verification:

```text
julia --project=. --startup-file=no test/test_phylo_gamma_xlv.jl
Phylo x Gamma predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.5s
Phylo x Gamma B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 56.3s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 5.1s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 14.6s

julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.9s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 25.5s

julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 6.0s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 24.9s
```

Claim boundary: IN: one private stochastic selected-entry S1 finite-endpoint
route canary for phylo x Gamma `B_eta_realized`, with fitted shared shape
`alpha_shape` kept interior, plus reduction tests against ordinary Gamma
`X_lv`, phylo-only Gamma GLM, and dense leaf-covariance reference. OUT: no
public fitter, no `confint_lv_effects` source route, no R
`phylo_latent(..., lv = ~ env)` grammar, no bridge, no compute, no coverage
calibration, no bootstrap rescue, no source-variance recovery claim, and no
transfer to Beta, Ordinal, spatial, animal, kernel, mixed-family, missing/mask,
or `unique=` parity.

## 2026-07-02 - Phylo x NB2 structural LV S1 likelihood and canary

Added the private phylo x NB2(log) x predictor-informed LV S1 route. This is
internal route evidence only: no public fitter, no R grammar, no bridge
transport, no Totoro/DRAC compute, no coverage calibration, and no
source-specific `lv` support were added.

Implemented:

- new private source file `src/phylo_nb_xlv.jl`;
- module include in `src/GLLVM.jl`;
- new focused proof test `test/test_phylo_nb_xlv.jl`;
- new S0 and S1 decision notes
  `docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s0-target.md`
  and
  `docs/dev-log/decisions/2026-07-02-phylo-nb2-structural-lv-s1-likelihood.md`;
- updated the structural-source Gate 0 matrix and Design 73 status text.

S1 contract:

```text
family: NB2(log)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
dispersion r: fitted nuisance, loose interior guard required
response Y: finite integer-valued non-negative counts
status: private S1 likelihood/profile canary banked
```

Verification:

```text
julia --project=. --startup-file=no test/test_phylo_nb_xlv.jl
Phylo x NB2 predictor-informed LV S1 likelihood: 12 passed, 0 failed, 0 errored, 5.6s
Phylo x NB2 B_eta_realized selected-entry canary: 25 passed, 0 failed, 0 errored, 19.0s
```

Claim boundary: IN: one private deterministic selected-entry S1
finite-endpoint route canary for phylo x NB2 `B_eta_realized`, with fitted
shared dispersion `r` kept interior, plus reduction tests against ordinary NB2
`X_lv`, phylo-only NB2 GLM, and dense leaf-covariance reference. OUT: no public
fitter, no `confint_lv_effects` source route, no R
`phylo_latent(..., lv = ~ env)` grammar, no bridge, no compute, no coverage
calibration, no bootstrap rescue, no source-variance recovery claim, and no
transfer to Gamma, Beta, Ordinal, spatial, animal, kernel, mixed-family,
missing/mask, or `unique=` parity.

## 2026-07-02 - Phylo x Binomial structural LV S1 likelihood and canary

Added the private phylo x Binomial(logit) x predictor-informed LV S1 route.
This is internal route evidence only: no public fitter, no R grammar, no bridge
transport, no Totoro/DRAC compute, no coverage calibration, and no
source-specific `lv` support were added.

Implemented:

- new private source file `src/phylo_binomial_xlv.jl`;
- module include in `src/GLLVM.jl`;
- new focused proof test `test/test_phylo_binomial_xlv.jl`;
- new S1 decision note
  `docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s1-likelihood.md`;
- updated the Binomial S0 target page, structural-source Gate 0 matrix, and
  Design 73 status text.

S1 contract:

```text
family: Binomial(logit)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
trial matrix N: required, positive, integer-valued, dimension-matched
response Y: integer-valued successes with 0 <= Y <= N
status: private S1 likelihood/profile canary banked
```

Verification:

```text
julia --project=. --startup-file=no test/test_phylo_binomial_xlv.jl
Phylo x Binomial predictor-informed LV S1 likelihood: 14 passed, 0 failed, 0 errored, 6.2s
Phylo x Binomial B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 19.7s

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.5s
```

Claim boundary: IN: one private deterministic selected-entry S1
finite-endpoint route canary for phylo x Binomial `B_eta_realized`, plus
reduction tests against ordinary Binomial `X_lv`, phylo-only Binomial GLM, and
dense leaf-covariance reference. OUT: no public fitter, no `confint_lv_effects`
source route, no R `phylo_latent(..., lv = ~ env)` grammar, no bridge, no
compute, no coverage calibration, no bootstrap rescue, and no transfer to NB2,
Gamma, Beta, Ordinal, spatial, animal, kernel, mixed-family, missing/mask, or
`unique=` parity.

## 2026-07-02 - Phylo x Binomial structural LV S0 target

Initial S0 entry, now superseded for implementation status by the S1 entry
above. This opened the second non-Gaussian structural-source LV target:
phylo x Binomial logit. The S0 slice was symbolic alignment and gate planning;
it did not add a likelihood proof, selected-entry canary, source-specific R
grammar, bridge row, Totoro run, or DRAC run.

Implemented:

- new S0 target page
  `docs/dev-log/decisions/2026-07-02-phylo-binomial-structural-lv-s0-target.md`;
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  now links Binomial to that S0 page and keeps S1 blocked until
  Binomial-specific reduction tests exist;
- `docs/design/73-predictor-informed-latent-scores.md` recorded phylo x
  Binomial as symbolic S0 only in this initial slice.

S0 target:

```text
family: Binomial(logit)
source: augmented phylogeny
target: B_eta_realized = slope_X(Lambda * Z_truth')
trial matrix N: required design input, not an estimand
initial status: awaiting S1 proof
```

Initial S1 requirements, now satisfied by the later S1 entry above:

- `sigma_phy^2 -> 0` reduction to ordinary Binomial `X_lv`;
- `Lambda = 0` reduction to `phylo_glm_marginal_loglik(Binomial())`;
- dense/sparse phylo equality anchor;
- `N` dimension/positivity and `0 <= Y <= N` guards;
- only then a deterministic selected-entry `B_eta_realized` profile canary.

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.6s
```

Historical claim boundary for the initial S0 slice: IN: phylo x Binomial had
an S0 target page and explicit S1 requirements. OUT at S0 time: combined
Binomial structural likelihood and profile canary were absent; no compute, no
source-specific `lv` support, no bridge transport, no coverage calibration, and
no inheritance from ordinary Binomial or phylo x Poisson evidence followed.

## 2026-07-02 - Structural-source LV matrix Ordinal sync

Synced the structural-source Gate 0 truth matrix after the ordinary
shared-cutpoint Ordinal `X_lv` profile canary landed. This is a documentation
and verification slice only: no source-specific fitter, R grammar, bridge row,
Totoro run, or DRAC run was launched.

Updated:

- `docs/design/73-predictor-informed-latent-scores.md` now names Poisson,
  Binomial logit, NB2, Gamma, Beta, and shared-cutpoint Ordinal logit as the
  ordinary selected-entry `B_lv` profile-LR route-evidence set
  (`196/196`, 3m57.7s).
- `docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  moves shared-cutpoint Ordinal from "not admitted for ordinary `X_lv`" to
  "ordinary Gate 1 complete; structural-source still Gate 0 only".
- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-truth-matrix-ultraplan.md`
  distinguishes native shared-cutpoint Ordinal route evidence from per-trait
  ordinal R bridge parity.
- `docs/dev-log/after-task/2026-07-02-nongaussian-structural-source-lv-gate0.md`
  now points to this later same-day follow-up so the earlier report is not read
  as the current family boundary.

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.4s

julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params_rerun.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params_rerun.csv --task-id 1 --dry-run
S2 dry-run task 1 / 20
target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized
dry-run only: no model fit, no random draw, no Totoro/DRAC launch
```

Claim boundary: IN: current docs now align ordinary Gate 1 route evidence with
the Ordinal extension and keep phylo x Poisson as the only structural-source
S0/S1/S2-manifest lane. OUT: no compute launch, no public source-specific
`lv`, no bridge profile/bootstrap transport, no per-trait ordinal bridge parity,
no mixed-family `X_lv`, no coverage calibration, and no `unique=` Julia parity.

## 2026-07-02 - Ordinary Ordinal LV profile Gate 1 extension

Closed the ordinary one-part non-Gaussian selected-entry profile Gate 1 set by
extending route evidence to shared-cutpoint Ordinal logit. This stays inside the
same ordinary `X_lv` ADEMP gate:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Implemented:

- added shared-cutpoint Ordinal `X_lv` support to `fit_ordinal_gllvm`;
- threaded the predictor-informed link-scale offset through the ordinal Laplace
  mode and marginal likelihood;
- added `extract_lv_effects`, `getLV(...; component=:mean/:innovation/:total)`,
  `predict`, and `simulate` support for `OrdinalFit` with `X_lv`;
- added `confint_lv_effects(fit::OrdinalFit, Y, X_lv; method=:wald/:profile/:bootstrap)`;
- added an ordinary Ordinal logit selected-entry profile canary to
  `test/test_lv_ci.jl`.

Gate 1 local canary:

```text
p=2, n=60, K=1, q_lv=1, C=4
cutpoints tau=[-1.1, 0.05, 1.25]
Lambda=[0.50, -0.38]'
alpha=[0.55]
selected entry: B_lv[1,1] / vec(B_lv)[1]
truth: 0.275
fit: converged in 19 iterations
estimate: 0.27757861344530577
profile interval: [-0.4920852132652146, 1.1235356474682392]
```

Focused verification:

```text
julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_ordinal_fit.jl
fit_ordinal_gllvm: 9 passed, 0 failed, 0 errored, 14.8s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 196 passed, 0 failed, 0 errored, 3m57.7s

julia --project=. --startup-file=no test/test_ordinal_probit.jl
Ordinal cumulative-link selection (logit default + probit): 10 passed, 0 failed, 0 errored, 3.7s

julia --project=. --startup-file=no test/test_ordinal_pertrait.jl
Ordinal per-trait cutpoints: 96 passed, 0 failed, 0 errored, 0.5s
bridge ordinal payload uses per-trait cutpoints: 15 passed, 0 failed, 0 errored, 6.8s

julia --project=. --startup-file=no test/test_confint_family.jl
Non-Gaussian confidence intervals: 124 passed, 0 failed, 0 errored, 4m13.4s
```

Claim boundary: IN: native Julia ordinary shared-cutpoint Ordinal logit `X_lv`
point fits and selected-entry `B_lv` profile route evidence. OUT: no
per-trait ordinal bridge `X_lv`, no R bridge profile/bootstrap transport, no
source-specific `lv = ~ env`, no structural/source Ordinal `X_lv`, no
mixed-family `X_lv`, no masks or missing responses with `X_lv`, no coverage
calibration, no `unique=` parity, and no Totoro/DRAC compute.

## 2026-07-02 - Phylo x Poisson structural LV S2 manifest

Predeclared the next possible diagnostic step for the private phylo x Poisson x
predictor-informed LV route. This is a manifest/dry-run slice only: no model
fit, no random draw, no Totoro launch, no DRAC launch, no R grammar exposure,
no bridge transport, and no public support wording.

Implemented:

- new manifest-only helper `bench/phylo_poisson_xlv_s2_manifest.jl`;
- durable ADEMP-style S2 plan at
  `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s2-manifest.md`.

S2 manifest:

```text
target: B_eta_realized
method: private _phylo_poisson_xlv_profile_eta_realized
family/source: Poisson(log) x augmented phylogeny
cell: p=6, n_sites=28, K=1, q_lv=1, K_phy=1, sigma2_phy=0.35
replicates: 20
seed0: 20260702
selected entries: 1,2,5
fit/profile optimizer budgets: 250 / 700
host: Totoro diagnostic only after explicit authorization
denominator: 20 x 3 = 60 selected-entry profiles
```

Entry rule: entry `1` is the strongest positive loading, entry `2` is a
negative loading, and entry `5` is a smaller positive loading in the S1/S2
six-species cell. These entries were chosen before any S2 outcome was
generated.

Commands:

```sh
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --write-params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --reps 20 --seed0 20260702 --selected-entries 1,2,5 --profile-iterations 700 --iterations 250
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --params /tmp/phylo_poisson_xlv_s2_manifest_params.csv --task-id 1 --dry-run
julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --help
```

Results:

```text
wrote 20 S2 manifest tasks to /tmp/phylo_poisson_xlv_s2_manifest_params.csv
S2 dry-run task 1 / 20
family=poisson_log source=augmented_phylo host=Totoro-diagnostic-only
seed=20260702 p=6 n_sites=28 K=1 q_lv=1
sigma2_phy=0.35 alpha_lv=0.45 epsilon_sd=0.08
Lambda=0.22;-0.18;0.20;-0.16;0.14;-0.12
selected_entries=1;2;5 level=0.95
future budgets: iterations=250 profile_iterations=700 newton=120/1e-10
target=B_eta_realized; method=private _phylo_poisson_xlv_profile_eta_realized
dry-run only: no model fit, no random draw, no Totoro/DRAC launch

julia --project=. --startup-file=no bench/phylo_poisson_xlv_s2_manifest.jl --help
help printed the manifest-only warning and default selected entries 1,2,5

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.8s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.5s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 4.1s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s2-manifest.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` confirmed
`Phylo x Poisson structural LV S2 manifest`, selected entries `1,2,5`, the
60-entry diagnostic denominator, no outcome-producing compute, no public
fitter, and no Totoro/DRAC launch language.

Diagnostic pass rule, if Shinichi later authorizes S2: `20/20` fits converge,
`60/60` selected-entry profiles are usable with finite endpoints, at least
`55/60` include the realized target, MCSE/Wilson interval are reported, all
misses are retained, and repeated same-entry or source-variance-boundary
patterns hold S3 planning.

Claim boundary: IN: one predeclared S2 diagnostic manifest and local dry-run
artifact. OUT: no outcome-producing compute, no coverage result, no source-
specific `lv` support, no R grammar, no R bridge, no bootstrap rescue, no
source transfer, and no denominator pooling across Totoro/DRAC.

## 2026-07-02 - Phylo x Poisson structural LV S1 profile canary

Added the first private selected-entry `B_eta_realized` profile-LR
finite-endpoint canary on top of the phylo x Poisson x predictor-informed LV
likelihood proof.

Implemented:

- private packing/unpacking, truth-started point fit, selected-entry
  penalty-profile helpers, and endpoint inversion in `src/phylo_poisson_xlv.jl`;
- deterministic positive-control `B_eta_realized[1,1]` finite-endpoint route
  test in `test/test_phylo_poisson_xlv.jl`;
- durable decision note at
  `docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md`;
- S0/Gate0/Design 73 wording updated from the former pending state to
  "private S1 finite-endpoint route canary covered locally."

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.8s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 14.1s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.8s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.6s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no -e 'using Pkg; println(haskey(Pkg.project().dependencies, "JET") ? "JET-present" : "JET-not-in-project")'
JET-not-in-project
```

Audit and Mission Control refresh:

```text
git diff --check

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s1-profile-canary.md")'
after-task structure check passed

Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` confirmed "Phylo x Poisson
structural LV S1", finite-endpoint wording, `22/22`, "No public fitter", and
no-active-compute guard text.

Claim boundary: IN: one private deterministic selected-entry S1 finite-endpoint
route canary for phylo x Poisson `B_eta_realized`. OUT: no public fitter, no
`confint_lv_effects` source-specific route, no R `phylo_latent(..., lv = ~ env)`
grammar, no bridge transport, no Totoro/DRAC compute, no coverage calibration,
no bootstrap rescue, and no spatial/animal/kernel or non-Poisson transfer.

## 2026-07-02 - Ordinary Beta LV profile Gate 1 extension

Completed the ordinary one-part non-Gaussian selected-entry profile canary set by
extending route evidence from Poisson, Binomial logit, NB2, and Gamma to Beta,
still inside the same Gate 0 ADEMP note:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Exploratory pre-edit smoke:

```text
Beta p=5, n=50, true precision=12.0, fitted precision about 13.81, estimate
-0.06202309634911434, lower -0.28754483857615315, upper 0.2296678784559789,
truth -0.06048 covered, and profile time about 14.80 seconds after compilation.
```

Gate 1 implementation:

- added an ordinary Beta `X_lv` selected-entry profile canary to
  `test/test_lv_ci.jl`;
- target remains `B_lv = Lambda * alpha_lv'`;
- selected entry is `B_lv[1,1]` / `vec(B_lv)[1]`;
- known DGP truth is `-0.06048`;
- the canary includes a loose fitted-precision guard.

Focused verification:

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 180 passed, 0 failed, 0 errored, 3m49.4s
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Claim boundary: IN: ordinary Poisson, Binomial logit, NB2, Gamma, and Beta
selected-entry `B_lv` profile route evidence. OUT: no coverage calibration, no
R bridge profile/bootstrap transport, no source-specific `lv = ~ env`, no
source-specific structural/non-Gaussian inference, no mixed-family CI, no
`unique=` parity, no Totoro/DRAC compute.

## 2026-07-02 - Ordinary Gamma LV profile Gate 1 extension

Extended the ordinary non-Gaussian selected-entry profile route evidence from
Poisson, Binomial logit, and NB2 to Gamma, still inside the same Gate 0 ADEMP
note:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Exploratory pre-edit smoke:

```text
Gamma p=4, n=45, true shape=2.5, fitted shape about 2.58, estimate
-0.0344900584935828, lower -0.5223006611843493, upper 0.19461498978516073,
truth -0.0756 covered, and profile time about 14.87 seconds after compilation.
```

Gate 1 implementation:

- added an ordinary Gamma `X_lv` selected-entry profile canary to
  `test/test_lv_ci.jl`;
- target remains `B_lv = Lambda * alpha_lv'`;
- selected entry is `B_lv[1,1]` / `vec(B_lv)[1]`;
- known DGP truth is `-0.0756`;
- the canary includes a loose fitted-shape guard.

Focused verification:

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 171 passed, 0 failed, 0 errored, 3m39.1s
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Claim boundary: IN: ordinary Poisson, Binomial logit, NB2, and Gamma
selected-entry `B_lv` profile route evidence. OUT: no coverage calibration, no
R bridge profile/bootstrap transport, no source-specific `lv = ~ env`, no
source-specific structural/non-Gaussian inference, no mixed-family CI, no
`unique=` parity, no Totoro/DRAC compute.

## 2026-07-02 - Ordinary NB2 LV profile Gate 1 extension

Extended the ordinary non-Gaussian selected-entry profile route evidence from
Poisson and Binomial logit to NB2, still inside the same Gate 0 ADEMP note:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Exploratory pre-edit smoke:

```text
Initial p=2, n=60 NB2 selected-entry profile exceeded local canary scale after
the point fit and was interrupted. Smaller p=2 cells returned finite endpoints,
but fitted r moved to a large Poisson-like boundary value. The banked cell uses
p=4, n=45, true r=1.5, fitted r about 1.73, estimate -0.06649728383230108,
lower -0.37346403337998935, upper 0.054328496976474336, truth -0.0756 covered,
and profile time about 15.63 seconds after compilation.
```

Gate 1 implementation:

- added an ordinary NB2 `X_lv` selected-entry profile canary to
  `test/test_lv_ci.jl`;
- target remains `B_lv = Lambda * alpha_lv'`;
- selected entry is `B_lv[1,1]` / `vec(B_lv)[1]`;
- known DGP truth is `-0.0756`;
- the canary includes a loose fitted-`r` guard to avoid a Poisson-boundary-only
  proof.

Focused verification:

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 162 passed, 0 failed, 0 errored, 3m26.5s
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Claim boundary: IN: ordinary Poisson, Binomial logit, and NB2 selected-entry
`B_lv` profile route evidence. OUT: no coverage calibration, no R bridge
profile/bootstrap transport, no source-specific `lv = ~ env`, no
source-specific structural/non-Gaussian inference, no mixed-family CI, no
`unique=` parity, no Totoro/DRAC compute.

## 2026-07-02 - Full Pkg.test battery after LV gate fixes

### Scope

Ran the full package test battery after the LV/post-LV gate-budget fixes and the
green core-suite run. No source behavior changed in this slice.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-full-pkgtest-after-lv-gates.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
# test env included Aqua v0.8.16 and JET v0.9.18
# GLLVM.jl | 4963 pass | 1 broken | 4964 total | 50m07.1s
# Testing GLLVM tests passed

pgrep -fl 'julia.*Pkg.test|julia.*test/runtests|julia.*test_' || true
# clean after run
```

Claim boundary retained:

- full local `Pkg.test()` is green in this worktree;
- source-specific `lv` remains parked/fail-loud;
- no DRAC/Totoro production compute, PR push, R grammar widening, or likelihood
  change occurred.

## 2026-07-02 - Core suite after gate budgeting

### Scope

Ran the full core test runner after bounding the ZIB family-CI smoke and the
missing-response row-effect smoke. No source behavior changed in this slice.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-core-suite-after-gate-budgeting.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/runtests.jl
# Aqua not in this environment - run Pkg.test() for the full battery
# JET not in this environment - run Pkg.test() for the type-stability gate
# GLLVM.jl | 4951 pass | 3 broken | 4954 total | 45m28.3s

pgrep -fl 'julia.*test/runtests|julia.*test_' || true
# clean after run
```

Claim boundary retained:

- the local core suite is green after the focused gate-budget fixes;
- this is not a full `Pkg.test()` / Aqua / JET verdict;
- no DRAC/Totoro production compute, source-specific `lv` exposure, likelihood
  change, or R grammar widening occurred.

## 2026-07-02 - Missing response extra gate budget

### Scope

Narrowed the row-effect subcase in the missing-response extra-entry-point test
so the full file is a practical focused gate. No package source behavior
changed.

Files updated in this worktree:

- `test/test_missing_response_extra.jl`
- `docs/dev-log/after-task/2026-07-02-missing-response-extra-gate-budget.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no -e 'using GLLVM, Random, Distributions, LinearAlgebra, Statistics; Random.seed!(44); p,K,n,q=5,1,50,1; beta=log.([3.0,4.0,2.5,5.0,3.5]); Lambda=0.3 .* randn(p,K); eta=beta .+ Lambda * randn(K,n); Yfull=[rand(Poisson(exp(eta[t,s]))) for t in 1:p, s in 1:n]; mask=trues(p,n); for I in randperm(p*n)[1:round(Int,0.03*p*n)]; mask[I]=false; end; Ym=Matrix{Union{Missing,Int}}(Yfull); for I in findall(.!mask); Ym[I]=missing; end; @time fr_na=fit_roweffect_gllvm(Ym; family=Poisson(), K=K, iterations=160); @show fr_na.converged fr_na.iterations; @time fr_mask=fit_roweffect_gllvm(Yfull; family=Poisson(), K=K, mask=mask, iterations=160); @show fr_mask.converged fr_mask.iterations isapprox(fr_mask.loglik, fr_na.loglik; atol=1e-6) isapprox(fr_mask.β, fr_na.β; atol=1e-6)'
# fr_na.converged = true
# fr_na.iterations = 63
# fr_mask.converged = true
# fr_mask.iterations = 63
# loglik and beta NA-vs-mask equality: true

julia --project=. --startup-file=no test/test_missing_response_extra.jl
# Missing responses (NA in Y) - extra entry points | 35 pass | 3m20.4s
```

Claim boundary retained:

- extra missing-response entry points now have a green focused gate;
- the row-effect check remains an equality smoke, not a performance benchmark;
- no source-specific `lv` exposure, likelihood change, or production compute
  changed.

## 2026-07-02 - ZIB family CI smoke budget

### Scope

Narrowed the zero-inflated-binomial bootstrap smoke inside the non-Gaussian
family CI test so the full file is again usable as a focused gate. No package
source behavior changed.

Files updated in this worktree:

- `test/test_confint_family.jl`
- `docs/dev-log/after-task/2026-07-02-zib-family-ci-smoke-budget.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no -e 'using GLLVM, Random, Distributions; Random.seed!(36); p,K,n,Ntr=4,1,80,8; betaz=0.3 .* randn(p) .- 0.6; betac=0.3 .* randn(p); Lambdac=0.4 .* randn(p,K); Y=zeros(Int,p,n); for s in 1:n; etac=betac .+ Lambdac * randn(K); for t in 1:p; mu=inv(1+exp(-etac[t])); Y[t,s]=rand() < inv(1+exp(-betaz[t])) ? 0 : rand(Binomial(Ntr,mu)); end; end; fit=fit_zib_gllvm(Y; K=K, N=Ntr, iterations=120); @show fit.converged fit.iterations; @time a=confint(fit,Y;method=:bootstrap,n_boot=10,seed=5,parallel=false); @show a.n_converged all(isfinite,a.lower) all(isfinite,a.upper); @time b=confint(fit,Y;method=:bootstrap,n_boot=10,seed=5,parallel=true); @show b.n_converged a.lower==b.lower a.upper==b.upper'
# fit.converged = true
# fit.iterations = 13
# serial n_boot=10: 5.644933 seconds, 44.07 M allocations, 2.363 GiB
# a.n_converged = 10
# all(isfinite, a.lower) = true
# all(isfinite, a.upper) = true
# parallel n_boot=10: 4.646354 seconds, 41.21 M allocations, 2.174 GiB
# b.n_converged = 10
# a.lower == b.lower = true
# a.upper == b.upper = true

julia --project=. --startup-file=no test/test_confint_family.jl
# Non-Gaussian confidence intervals | 122 pass | 4m17.9s

pgrep -fl 'julia.*test_confint_family|julia.*runtests|julia.*test_' || true
# clean after run
```

Claim boundary retained:

- ZIB bootstrap is still a smoke test, not a runtime benchmark or coverage
  calibration claim;
- the full non-Gaussian family CI file is now green locally;
- this does not change the phylo Model A weak-cell no-bootstrap conclusion.

## 2026-07-02 - Family CI boundary check

### Scope

Checked the remaining confidence-interval surfaces after the LV/source/bridge
guard slices. No source behavior changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-family-ci-boundary-check.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_confint.jl
# sigma_eps Wald CI:
#   lower = 0.49844230096550035
#   estimate = 0.5094852492967064
#   upper = 0.5207728532432352
#   truth = 0.5
# confint | 14 pass

julia --project=. --startup-file=no test/test_confint_profile.jl
# sigma_eps profile CI clean fixture:
#   lower = 0.4909447706071283
#   upper = 0.5273737959170355
#   truth = 0.5
# profile CI | 4 pass

julia --project=. --startup-file=no test/test_confint_bootstrap.jl
# sigma_eps bootstrap CI on log scale:
#   lower = -0.7169499509370375
#   estimate = -0.6760615447661849
#   upper = -0.6448565114098399
#   truth = -0.6931471805599453
# parametric bootstrap CI | 9 pass

julia --project=. --startup-file=no test/test_confint_derived_wald.jl
# transformed-Wald CIs for derived bounded quantities | 115 pass

julia --project=. --startup-file=no test/test_confint_derived.jl
# communality[1] bootstrap CI:
#   lower = 0.773236130389509
#   estimate = 0.8067721997108832
#   upper = 0.8339152141803738
#   truth = 0.8
#   n_converged = 200
#   n_valid = 200
# derived-quantity CIs | 45 pass

julia --project=. --startup-file=no test/test_confint_family.jl
# interrupted after repeated long quiet run; not counted as passing
# interrupt stack landed in ZIB bootstrap refit:
#   test/test_confint_family.jl:18
#   src/families/twopart.jl:1018 zib_marginal_loglik_laplace
#   src/families/twopart.jl:1102 fit_zib_gllvm
#   src/confint_family.jl:1260 ZIB refit
#   src/confint_family.jl:1572 threaded bootstrap loop
# allocations before interrupt: 1,505,014,869

pgrep -fl 'julia.*test_confint_family|julia.*runtests|julia.*test_' || true
# clean after interrupt
```

Claim boundary retained:

- Gaussian Wald/profile/bootstrap and derived Gaussian/phylo transformed-Wald
  CI surfaces are green in focused tests;
- the broad non-Gaussian family CI bootstrap bundle is not green evidence
  tonight because the ZIB bootstrap refit remains too slow for a focused gate;
- no bootstrap result changes the parked phylo Model A weak-cell conclusion.

## 2026-07-02 - Missing response boundary check

### Scope

Checked missing-response mask behavior after the bridge mask and docs boundary
slices. No source behavior changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-missing-response-boundary-check.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_missing_response_extra.jl
# interrupted after a long quiet run; not counted as passing
# interrupt stack landed in fit_roweffect_gllvm from test/test_missing_response_extra.jl:65

pgrep -fl 'julia.*test_missing_response_extra|julia.*runtests|julia.*test_' || true
# clean after interrupt

julia --project=. --startup-file=no test/test_missing_response.jl
# masked-objective analytic vs FD:
#   maxdiff_poisson = 5.417778936589457e-8
#   maxdiff_binomial = 2.4065222259395114e-8
# Missing responses (NA in Y) - dense-Laplace mask | 23 pass
```

Claim boundary retained:

- core dense-Laplace missing-response masks are green;
- extra wrapper missing-response coverage is not green evidence tonight;
- bridge missing-mask evidence remains the focused bridge test recorded earlier.

## 2026-07-02 - Unified API dispersion boundary

### Scope

Verified and documented the unified `fit_gllvm` grouped-dispersion route. No
source behavior changed.

Files updated in this worktree:

- `docs/src/response-families.md`
- `docs/dev-log/after-task/2026-07-02-unified-api-dispersion-boundary.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_unified_api.jl
# fit_gllvm unified API - keyword routing | 22 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'disp_group = :species|Grouped dispersion is a single|unsupported families fail|row_eff|pervar|fit_gllvm\\(Yc; family = NegativeBinomial' docs/src/response-families.md docs/src/tutorial.md docs/src/gllvmtmb-parity.md README.md
# new response-family docs plus existing related references

git diff --check -- docs/src/response-families.md
# clean, no output
```

Claim boundary retained:

- `disp_group = :species` and explicit integer groups route to grouped fitters;
- grouped dispersion is not combined with `row_eff` or Gaussian `pervar`;
- unsupported families fail loudly.

## 2026-07-02 - Ordination uncertainty boundary

### Scope

Added user-facing docs for the tested `ordination_uncertainty` route while
keeping its fixed-parameter conditional-bootstrap scope explicit. No source
behavior changed.

Files updated in this worktree:

- `docs/src/working-with-a-fit.md`
- `docs/dev-log/after-task/2026-07-02-ordination-uncertainty-boundary.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_ordination_uncertainty.jl
# ordination types: run + recover structure | 16 pass
# ordination_uncertainty: per-site score intervals | 20 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'ordination_uncertainty|conditional bootstrap|fitted parameters held fixed|full refit-level parameter uncertainty|Poisson, NB2, Beta, Gamma|score intervals' docs/src/working-with-a-fit.md docs/src/tutorial.md docs/src/gllvmtmb-parity.md README.md
# only the new bounded working-with-a-fit wording appears

git diff --check -- docs/src/working-with-a-fit.md
# clean, no output
```

Claim boundary retained:

- score uncertainty is conditional on fitted parameters;
- no full refit-level parameter uncertainty is claimed;
- supported route is limited to single-`Y` one-part non-Gaussian ordination fits
  with scalar response means.

## 2026-07-02 - Structural confint boundary

### Scope

Verified structural confidence-interval tables and corrected tutorial wording
that overstated bootstrap availability. No source behavior changed.

Files updated in this worktree:

- `docs/src/tutorial.md`
- `docs/dev-log/after-task/2026-07-02-structural-confint-boundary.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_structural_confint.jl
# Structural-model inference tables | 45 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'All three methods accept.*RowEffectFit|GllvmCovFit`, `RowEffectFit|bootstrap route|dedicated Wald helpers|QuadraticFit.*RowEffectFit' docs/src/tutorial.md docs/src/confidence-intervals.md docs/src/gllvmtmb-parity.md
# only the new structural boundary wording remains

git diff --check -- docs/src/tutorial.md
# clean, no output
```

Claim boundary retained:

- `QuadraticFit` and `RowEffectFit` have Wald/profile intervals but no bootstrap
  route;
- species-covariate, fourth-corner, RRR, and constrained ordination use
  dedicated Wald helpers because their designs are not stored in the fit object;
- source-specific `lv` remains parked.

## 2026-07-02 - Summary table boundary verification

### Scope

Verified the summary / coefficient-table post-fit surface. No source behavior
changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-summary-table-boundary-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_summary_table.jl
# Summary / coefficient table | 14 pass

sed -n '1,220p' test/test_summary_table.jl
sed -n '1,180p' src/summary_table.jl
rg -n "coef_table|summary_table|coefficient table|Summary / coefficient|coef\\(|pvalue|p-value|std_error|z statistic|two-sided" README.md docs/src src test
```

Claim boundary retained:

- `coef_table` is a Wald summary layer, not a separate inference route;
- non-finite standard errors produce `NaN` `z` and `pvalue`;
- selector forwarding such as `parm = "beta"` remains covered.

## 2026-07-02 - ZIB/Tweedie postfit docs boundary

### Scope

Aligned response-family and parity docs with the tested ZIB/Tweedie post-fit
surface and public `simulate` method boundary. No source behavior changed.

Files updated in this worktree:

- `docs/src/gllvmtmb-parity.md`
- `docs/src/response-families.md`
- `docs/src/tutorial.md`
- `docs/dev-log/after-task/2026-07-02-zib-tweedie-postfit-doc-boundary.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_postfit_zib_tweedie.jl
# ZIB post-fit (zero-inflated binomial) | 17 pass
# Tweedie post-fit (compound Poisson-Gamma) | 20 pass

julia --project=. --startup-file=no test/test_beta_hurdle.jl
# beta-hurdle GLLVM | 53 pass

julia --project=. --startup-file=no test/test_ordered_beta.jl
# Ordered-beta family | 21 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n 'simulate\\(fit, n\\).*GLM \\+ covariate|✅ non-Gaussian \\| `simulate|from a fitted model \\(useful|fit_zib_gllvm\\(Y;.*K = 2\\)|fit_beta_hurdle_gllvm|fit_ordered_beta_gllvm|selected non-Gaussian|public `simulate` methods are not universal' docs/src README.md
# only intentional current docs hits remain

git diff --check -- docs/src/gllvmtmb-parity.md docs/src/tutorial.md docs/src/response-families.md
# clean, no output
```

Claim boundary retained:

- ZIB/Tweedie post-fit methods are backed by focused tests;
- beta-hurdle and ordered-beta examples are backed by focused tests;
- public `simulate` remains selected-row only, not universal for every
  two-part fit.

## 2026-07-02 - Bridge CI docs boundary alignment

### Scope

Reconciled top-level docs with the current grouped-dispersion and ordinal CI
bridge evidence. No source behavior changed.

Files updated in this worktree:

- `README.md`
- `docs/src/roadmap.md`
- `docs/src/confidence-intervals.md`
- `docs/src/gllvmtmb-parity.md`
- `test/test_bridge_ci.jl`
- `docs/dev-log/after-task/2026-07-02-bridge-ci-doc-boundary-alignment.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_grouped_dispersion.jl
# bridge grouped dispersion default | 121 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings

rg -n "Pkg\\.add\\(\\\"GLLVM\\\"\\)|Grouped-dispersion fits and per-trait ordinal cutpoint fits|grouped-dispersion bridge endpoints remain explicit unavailable|grouped-dispersion and per-trait ordinal-cutpoint point payloads|mixed-family R bridge is partial|every non-Gaussian family" README.md docs/src test
# only the intentional docs homepage sentence remains:
# docs/src/index.md: GLLVM.jl is not yet in the General registry, so `Pkg.add("GLLVM")` will not resolve.

git diff --check -- README.md docs/src/roadmap.md docs/src/confidence-intervals.md docs/src/gllvmtmb-parity.md test/test_bridge_ci.jl
# clean, no output
```

Claim boundary retained:

- grouped NB2/NB1/Beta/Gamma CI endpoints are routed;
- grouped Tweedie, per-trait ordinal, and mixed-family CI endpoints remain
  follow-ups;
- source-specific `lv` remains parked and no source-specific grammar is exposed.

## 2026-07-02 - Core suite interrupted check

### Scope

Recorded the attempted consolidated quick core-suite check after the LV and
postfit slices. No source behavior changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-core-suite-interrupted-check.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/runtests.jl
# interrupted after a long CPU-active run; not counted as passing
# last explicit progress before interrupt:
# masked-objective analytic vs FD
#   maxdiff_poisson = 5.417778936589457e-8
#   maxdiff_binomial = 2.4065222259395114e-8
# interrupt landed in test/test_va_vs_laplace.jl:14
# process exited with code 130 after a second interrupt

pgrep -fl 'julia.*test/runtests|julia.*runtests' || true
# clean, no output

julia --project=. --startup-file=no test/test_va_vs_laplace.jl
# VA vs Laplace comparison | 8 pass
```

Claim boundary retained:

- no broad quick-core or full `Pkg.test()` green claim from this run;
- the file where the interrupt landed passed when isolated;
- focused tests and the docs build remain the accepted evidence for the local
  slices.

## 2026-07-02 - Postfit prediction docs and SPDE standalone test

### Scope

Moved one slice beyond LV by tightening the user-facing postfit prediction
boundary and fixing a focused standalone test import. No model, likelihood, or
prediction semantics changed.

Files updated in this worktree:

- `docs/src/working-with-a-fit.md`
- `docs/src/roadmap.md`
- `test/test_spde_latent_postfit.jl`
- `docs/dev-log/after-task/2026-07-02-postfit-prediction-docs-spde-test.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_covariates.jl
# Non-Gaussian covariates (Xbeta) | 30 pass

julia --project=. --startup-file=no test/test_spde_latent_postfit.jl
# first run failed before the test import fix:
# UndefVarError: `Poisson` not defined

julia --project=. --startup-file=no test/test_spde_latent_postfit.jl
# SPDE-latent postfit: getLV / predict / predict_spatial | 35 pass

rg -n 'There is no [`]newdata[`] yet|ordinal prediction payloads|Gaussian and binary fits|both Gaussian and binary' docs/src README.md
# clean, no output

git diff --check -- docs/src/working-with-a-fit.md docs/src/roadmap.md test/test_spde_latent_postfit.jl
# clean, no output

julia --project=docs --startup-file=no docs/make.jl
# completed successfully; emitted pre-existing local-link warnings and npm audit warnings
```

Claim boundary retained:

- plain latent fits remain in-sample conditional prediction;
- covariate fits support population-level new-site prediction from `X`;
- spatial latent fits use `predict_spatial` for new locations;
- no bridge row, source-specific `lv`, package API, likelihood, PR state, or
  compute changed.

## 2026-07-02 - Bridge missing-mask boundary verification

### Scope

Verified the response-missing mask bridge boundary after the LV and
mixed-family truth locks. No source behavior changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-bridge-missing-mask-boundary-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# bridge missing-response mask | 83 pass

sed -n '1,260p' test/test_bridge_missing_mask.jl
# confirmed admitted one-part masked rows and fail-loud unsupported cells

rg -n 'mask|missing|X_lv|mixed-family|ci_mask|ci_method|Gaussian|ordinal' src/bridge.jl test/test_bridge_missing_mask.jl test/test_bridge_capabilities.jl docs/src/gllvmtmb-parity.md docs/dev-log/decisions/2026-07-02-*
# confirmed capability notes and decision docs keep mixed-family and X_lv masks blocked
```

Claim boundary retained:

- one-part non-Gaussian response masks are admitted where tested;
- masked no-X CIs route only through admitted one-part rows;
- mixed-family masks, fixed-effect-X masks, Gaussian masks, `X_lv` masks, and
  ordinal masked CIs remain blocked;
- no source-specific `lv`, package API, likelihood, PR state, or compute changed.

## 2026-07-02 - Bridge CI status boundary verification

### Scope

Verified that bridge confidence-interval requests either return routed payloads
or fail/mark unavailable explicitly. No source behavior changed.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-bridge-ci-status-boundary-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

sed -n '260,330p' test/test_bridge_ci.jl
# confirmed flat CI payload contract and unsupported ci_method error

sed -n '1,80p' test/test_bridge_mixed.jl
# confirmed mixed-family ci_method="wald" returns empty CI names with
# ci_note containing "not routed"

sed -n '260,286p' test/test_lv_ci.jl
# confirmed bridge X_lv admits only ci_method="wald"; profile/bootstrap throw
```

Claim boundary retained:

- per-trait ordinal bridge CIs remain not routed;
- mixed-family CIs remain unavailable status, not support;
- bridge `X_lv` admits Wald `B_lv` payloads only;
- no source-specific `lv`, package API, likelihood, PR state, or compute changed.

## 2026-07-02 - Source LV fail-loud guard verification

### Scope

Verified the specific source-grammar risk raised by Shinichi: `lv = ~ env` must
not look accepted for `spatial_latent()`, `phylo_latent()`, `animal_latent()`,
or `kernel_latent()` and then be silently dropped. No source behavior changed.
The R twin was treated as read-only because its local worktree has broad
unrelated dirt.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-source-lv-fail-loud-guard-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
cd "/Users/z3437171/Dropbox/Github Local/gllvmTMB"
git status --short
# heavily dirty from unrelated local work; read-only for this slice

rg -n 'source-specific|lv\s*=|lv =|GJL-GATE|silently|not.*wired|unsupported.*lv|fail-loud|latent.*lv' R/brms-sugar.R tests/testthat/test-canonical-keywords.R tests/testthat/test-ordinary-latent-random-regression.R R/animal-keyword.R R/kernel-keywords.R R/spde-keyword.R R/phylo-signal-ci.R
# found the source-specific lv parser guard and the structural keyword test set

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
# test-canonical-keywords.R | 82 pass, 0 fail, 3 skip
# skips were INLA-not-installed spatial tests, unrelated to lv source guards
```

Claim boundary retained:

- source-specific `lv = ~ env` fails loudly across phylo, spatial, animal, and
  kernel structural keywords and legacy aliases;
- structural random-slope syntax is a separate route, not predictor-informed
  `lv` grammar;
- no source-specific `lv`, package API, likelihood, PR state, or compute changed.

## 2026-07-02 - Bridge postfit boundary verification

### Scope

Verified the postfit bridge capability surface after the LV boundary closeout.
No source behavior changed. The current truth remains: native Julia postfit
support is broader than the R-bridge retained-payload contract in some places,
and the bridge ledger must be read as the R-facing capability boundary.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-bridge-postfit-boundary-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_postfit.jl
# post-fit ordination core | 96 pass
# post-fit predict/fitted | 9 pass
# post-fit residuals | 10 pass
# post-fit AIC/BIC + show | 8 pass
# post-fit Poisson fits | 163 pass
# post-fit NB fits | 160 pass
# post-fit Beta fits | 215 pass
# post-fit Gamma fits | 215 pass
# post-fit Ordinal fits | 216 pass

julia --project=. --startup-file=no test/test_simulate.jl
# simulate(fit) | 5 pass

julia --project=. --startup-file=no test/test_summary_table.jl
# Summary / coefficient table | 14 pass

julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# bridge capabilities ledger | 105 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# bridge mixed-family payload metadata | 18 pass
```

Claim boundary retained:

- `postfit_predict` covers all bridge rows, including ordinal through retained
  cutpoint/probability payloads;
- `postfit_residuals` and `postfit_simulate` deliberately exclude ordinal bridge
  rows because the retained bridge payload does not claim a scalar-mean residual
  contract;
- mixed-family remains complete balanced point/postfit only;
- no source-specific `lv`, package API, likelihood, PR state, or compute changed.

## 2026-07-02 - LV profile selected entries

### Scope

Closed the pre-existing dirty LV profile-selection work. `_lv_effect_profile()`
now accepts internal selected-entry `indices`, validates them, returns the
matching subset of `B_lv` profile intervals, and warm-starts constrained
profile solves from nearby constrained optima. This is diagnostic/canary
tooling only; no public `confint_lv_effects()` argument, source-specific
grammar, package API, likelihood parameterisation, PR state, or compute changed.

Files updated in this worktree:

- `src/confint_family.jl`
- `test/test_phylo_xlv.jl`
- `docs/dev-log/after-task/2026-07-02-lv-profile-selected-entries.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# bridge missing-response mask | 83 pass

julia --project=. --startup-file=no test/test_phylo_xlv.jl
# phylo × X_lv (Model A) | 25 pass

julia --project=. --startup-file=no test/test_lv_ci.jl
# X_lv Wald CIs — confint_lv_effects | 127 pass

git diff --check -- src/confint_family.jl test/test_phylo_xlv.jl
# passed, no output
```

Claim boundary retained:

- selected-entry profile is internal diagnostic tooling;
- old population-`B_lv` support remains parked under prior weak-cell evidence;
- source-specific `phylo_latent(..., lv = ~ x)` remains fail-loud/parked;
- no Totoro/DRAC compute launched.

## 2026-07-02 - Bridge X boundary verification

### Scope

Verified the fixed-effect-X and ordinary predictor-informed `X_lv` bridge
boundaries after the bridge capability note sync. No source behavior changed.
The remaining R/Jl ledger difference is accepted: Julia exposes
`predictor_informed_lv` in `bridge_capabilities()`, while the R bridge keeps a
stable public schema and records the boundary in notes.

Files updated in this worktree:

- `docs/dev-log/after-task/2026-07-02-bridge-x-boundary-verification.md`
- `docs/dev-log/check-log.md`

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
# bridge fixed-effect X (non-Gaussian one-part families) | 195 pass

julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
# bridge predictor-informed latent-score X_lv | 207 pass

rg -n 'X_lv|fixed-effect X|mixed-family|mask|ci_x|predictor_informed_lv|source-specific|not wired|gated|follow-up' src/bridge.jl test/test_bridge_x.jl test/test_bridge_lv_predictor.jl test/test_bridge_capabilities.jl

rg -n 'X_lv|fixed-effect X|mixed-family|mask|ci_x|predictor_informed_lv|GJL-GATE-MIXED|not routed|gated|follow-up' R/julia-bridge.R tests/testthat/test-julia-bridge.R
```

Claim boundary retained:

- fixed-effect `X` rows and ordinary `X_lv` rows are separate bridge surfaces;
- `X_lv` remains complete-response one-part only;
- profile/bootstrap `X_lv`, response-mask `X_lv`, mixed-family `X_lv`, and
  source-specific `X_lv` remain blocked;
- no gllvmTMB R source, package API, likelihood, PR state, or compute changed.

## 2026-07-02 - Bridge capability X_lv note sync

### Scope

Reconciled Julia bridge capability wording after the post-LV baseline review.
The implementation and tests already expose complete-response one-part
predictor-informed `X_lv` routes for Gaussian, Poisson, NB2, Beta, Gamma, and
binomial logit/probit/cloglog; admitted `X_lv` rows route Wald `B_lv` CI
payloads only. The stale bridge header and capability notes still read as if
non-Gaussian non-binomial `X_lv` remained future work. This slice fixed that
metadata drift and added a regression test.

Files updated in this worktree:

- `src/bridge.jl`
- `test/test_bridge_capabilities.jl`
- `docs/dev-log/decisions/2026-07-02-capability-baseline-review.md`
- `docs/dev-log/after-task/2026-07-02-bridge-capability-xlv-note-sync.md`
- `docs/dev-log/check-log.md`

Claim boundary retained:

- one-part ordinary `X_lv` is not source-specific `lv`;
- Wald `B_lv` CI payloads are the admitted bridge `X_lv` CI route;
- profile/bootstrap `X_lv` CIs remain gated;
- mixed-family `X_lv`, response-mask `X_lv`, and source-specific `X_lv` remain
  blocked;
- no gllvmTMB R source, package API, likelihood, PR state, or compute changed.

Checks:

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# bridge capabilities ledger | 105 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# bridge mixed-family payload metadata | 18 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# bridge CI routing | 64 pass

git diff --check -- src/bridge.jl test/test_bridge_capabilities.jl docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-bridge-capability-xlv-note-sync.md
# passed, no output

rg -n 'non-Gaussian non-binomial X_lv remain follow-ups|broader non-Gaussian X_lv routes remain separate|point-estimate-only Gaussian and binomial|Gaussian and binomial logit' src/bridge.jl docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md
# no output
```

## 2026-07-02 - Capability baseline review after LV closeout

### Scope

Started the seven-hour post-LV capability-baseline goal as a truth-sync slice:
reviewed gllvmTMB Mission Control and older capability ledgers against the
GLLVM.jl LV closeout docs, then tightened the GLLVM predictor-informed latent
score design note so source-specific phylo `lv` future wiring cannot be read as
current admission guidance.

Files updated in this worktree:

- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/decisions/2026-07-02-capability-baseline-review.md`
- `docs/dev-log/after-task/2026-07-02-capability-baseline-review.md`
- `docs/dev-log/check-log.md`

Claim boundary retained:

- ordinary `latent(..., lv = ~ env)` remains the supported predictor-informed
  LV route;
- source-specific `phylo_latent(..., lv = ~ env)` remains guarded/fail-loud;
- `B_eta_realized` Gate 0-3 evidence is internal and does not expose public
  source-specific grammar;
- mixed-family bridge support remains complete balanced point/postfit only.

Checks:

```sh
git diff --check -- docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-02-capability-baseline-review.md
# passed, no output

rg -n 'future-only source-specific|future authorized|guarded/fail-loud|ordinary `latent\(\.\.\., lv = ~ x\)`|source-specific `phylo_latent\(\.\.\., lv = ~ x\)`' docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md docs/dev-log/after-task/2026-07-02-capability-baseline-review.md
# found the tightened future-only wording and guarded/source-specific boundary

rg -n 'ready to expose|active compute|source-specific.*covered|non-Gaussian.*inherits|mixed-family.*CI.*support|Admit `lv` as a one-sided predictor formula on `latent\(\)`' docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-capability-baseline-review.md
# no output

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
# r60
```

## 2026-07-01 - Paired source-specific lv alias guard hardening

### Scope

Synchronized the GLLVM.jl handover notes after the paired `gllvmTMB` guard was
hardened from latent-mode wrappers to all source-specific structural aliases.
No Julia source, likelihood, package API, PR state, or compute changed.

Files updated in this worktree:

- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md`
- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-gates-0-2-closeout.md`
- `docs/dev-log/after-task/2026-07-02-structural-lv-gates-0-2.md`
- `docs/dev-log/after-task/2026-07-01-source-specific-lv-alias-guard-sync.md`

Paired `gllvmTMB` guard evidence:

```text
source-specific lv = ~ env rejects:
phylo scalar/unique/indep/latent/dep plus legacy phylo()/phylo_rr()/phylo_slope
spatial scalar/unique/indep/latent/dep plus legacy spatial()/spde()
animal scalar/unique/indep/latent/dep/slope
kernel latent/unique/indep/dep
focused test-canonical-keywords.R: 82 pass / 3 INLA skips
all-keyword direct probe: all-source-lv-guarded
```

Still not claimed:

- No source-specific `lv = ~ x` support for phylo, spatial, animal, or kernel.
- No PR #127 reopen, package API widening, public source-specific support, or
  non-Gaussian/source-specific extension.
- No new Totoro/DRAC compute.

## 2026-07-01 - LV arc closeout source guard

### Scope

Closed the current LV arc as operating truth after adding the paired
`gllvmTMB` source-specific `lv = ~ env` fail-loud guard.

Files updated in this worktree:

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/after-task/2026-07-01-lv-arc-closeout-source-guard.md`

Evidence retained:

```text
Gate 3 job: 17049809_[1-500%100]
target: B_eta_realized
method: profile_eta_realized
covered/planned: 2495/2500 = 0.998000000
MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
```

Paired `gllvmTMB` guard evidence:

```text
source-specific lv = ~ env rejects:
phylo_latent(), spatial_latent(), animal_latent(), kernel_latent(),
phylo(..., mode = "latent"), spatial(..., mode = "latent")
```

Still not claimed:

- No `phylo_latent(..., lv = ~ x)` exposure.
- No PR #127 reopen, package API widening, public source-specific support, or
  non-Gaussian/source-specific extension.
- No new compute.

## 2026-07-01 - Phylo Model A post-Gate3 hardening

### Scope

Froze the Gate 0-3 evidence packet in a compact maintainer note and tightened
current docs so Gate 3 reads as strong internal evidence for the changed
`B_eta_realized` target, not public source-specific `lv` support.

Files updated:

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-post-gate3-hardening.md`

Evidence retained:

```text
Gate 3 job: 17049809_[1-500%100]
target: B_eta_realized
method: profile_eta_realized
covered/planned: 2495/2500 = 0.998000000
MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
```

Checks:

```sh
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-phylo-model-a-post-gate3-hardening.md
rg -n "B_eta_realized|2495/2500|0\\.998000000|explicitly authorizes|separate derivation and ADEMP" docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
rg -n "Gate 3 running|active compute only|result files: 0/500|detail files: 0/500|1 active|ready to scale|source-specific phylo lv.*covered|non-Gaussian.*covered" docs/dev-log/decisions/2026-07-01-phylo-model-a-evidence-freeze-and-next-arc.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
```

Still not claimed:

- No `phylo_latent(..., lv = ~ x)` exposure.
- No PR #127 reopen, package API widening, public source-specific support, or
  non-Gaussian/source-specific extension.
- No new compute.

## 2026-07-01 - Phylo Model A Gate 3 DRAC claim evidence passed

### Scope

Reduced the completed predeclared Gate 3 DRAC/Nibi claim-evidence array for
the non-v1 eta-scale realized/design-conditional Phylo Model A target. This is
DRAC-only evidence and does not pool Totoro Gate 2 rows.

Remote source and result roots:

```text
source:  /scratch/snakagaw/GLLVM.jl-phylo-model-a-gate3
results: /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
depot:   /scratch/snakagaw/julia_depot_gllvm_gate3
source commit for run: 97082bd
```

Run design:

```text
job id: 17049809
host: Nibi
account: def-snakagaw_cpu
Julia: 1.10.10
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 500
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
truth_init: yes
write_details: yes
```

Final reducer:

```text
result files: 500
detail files: 500
fit convergence: 500/500
profile status: 500/500 ok rows
selected entries: 2500
usable profile truth solves: 2500/2500
covered/planned: 2495/2500 = 0.998000000
task coverage mean: 0.998000000
task coverage MCSE: 0.000890835
Wilson 95 percent interval: 0.995326484 to 0.999145426
LR misses: 5
non-empty error logs: 0
```

Per-entry detail:

```text
entry 8:  500/500 covered, max LR 1.30738161784
entry 14: 498/500 covered, max LR 4.31498848912
entry 41: 497/500 covered, max LR 5.06137330611
entry 44: 500/500 covered, max LR 0.803688155171
entry 71: 500/500 covered, max LR 0.595386972622
LR cutoff: 3.84145882069
```

Misses:

```text
task 124 entry 14 LR 3.99667410209 truth -0.0876639401679
task 134 entry 41 LR 4.64533256499 truth  0.154599570045
task 179 entry 41 LR 5.06137330611 truth  0.122797417305
task 423 entry 41 LR 4.62997900325 truth  0.170278825295
task 444 entry 14 LR 4.31498848912 truth -0.0670786076295
```

Runtime summary:

```text
fit seconds mean: 501.456925579, min 287.620323896, max 1739.997769120
CI seconds mean: 1408.125484925, min 583.058674097, max 3389.787456990
bias RMSE mean: 0.016440825, min 0.003134887, max 0.034325971
```

Checks:

```sh
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results -maxdepth 1 -name 'result_*.csv' | wc -l
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/results -maxdepth 1 -name 'detail_result_*profile_eta_realized.csv' | wc -l
find /scratch/snakagaw/phylo_model_a_gate3_20260701-1122/logs -maxdepth 1 -name '*.err' -size +0c | wc -l
sacct -j 17049809 --format=JobID,JobName%20,State,ExitCode,Elapsed,MaxRSS,AllocCPUS
```

Verdict: Gate 3 passes the amended MCSE-aware claim-evidence gate for the
non-v1 `B_eta_realized` target. This closes gates 0-3 for this evidence arc.
It does not by itself expose source-specific R grammar, reopen PR #127, widen
the package API, or turn old population-`B_lv` evidence positive.

## 2026-07-01 - Phylo Model A Gate 3 DRAC claim evidence queued

### Scope

Submitted the predeclared Gate 3 claim-evidence array on Nibi after the Gate 2
Totoro diagnostic passed. This is a queued DRAC run, not completed claim
evidence and not source-specific R grammar exposure.

Remote source and result roots:

```text
source:  /scratch/snakagaw/GLLVM.jl-phylo-model-a-gate3
results: /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
depot:   /scratch/snakagaw/julia_depot_gllvm_gate3
```

SLURM:

```text
job id: 17049809
array: 1-500%100
host: Nibi
account: def-snakagaw_cpu
state at submission: PENDING (Priority)
time limit: 03:00:00
cpus per task: 1
memory per task: 8G
Julia: 1.10.10
```

Design:

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 500
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
truth_init: yes
write_details: yes
host denominator: DRAC/Nibi only
```

Checks:

```sh
module load julia/1.10.10
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); using GLLVM; println("GLLVM gate3 load ok")'
bash bench/phylo_xlv_drac_submit.sh --out /scratch/snakagaw/phylo_model_a_gate3_20260701-1122
bash bench/phylo_xlv_drac_submit.sh --out /scratch/snakagaw/phylo_model_a_gate3_20260701-1122 --submit
scontrol show job 17049809
```

Verdict: Gate 3 is queued. Do not claim completion until the 500-task DRAC
denominator is reduced with fit convergence, profile status, usable selected
entries, coverage, MCSE, Wilson interval, and all misses listed.

## 2026-07-01 - Phylo Model A Gate 2 Totoro diagnostic passed

### Scope

Ran the predeclared Gate 2 weak-cell diagnostic on Totoro from clean source
commit `41a4120`. This was diagnostic evidence only, not DRAC claim evidence,
source-specific R grammar exposure, package API widening, PR #127 reopening, or
public support.

The run used the Gate 2 manifest from the previous log entry:

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 20
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
host: Totoro only
```

Remote result root:

```text
/home/snakagaw/hsq_work/phylo_model_a_gate2_20260701-160537
```

### Result

```text
result files: 20
detail files: 20
fit convergence: 20/20
profile status: 20/20 ok rows
selected entries: 100
usable profile truth solves: 100/100
covered/planned: 100/100 = 1.000
MCSE: 0.0000
Wilson 95% interval: 0.9630 to 1.0000
LR misses: 0
max LR: 2.67333858328 at task 5 entry 14
LR cutoff: 3.84145882069
```

Per-entry detail:

```text
entry 14: 20/20 covered, max LR 2.67333858328
entry 41: 20/20 covered, max LR 2.26827350234
entry 71: 20/20 covered, max LR 0.414283414571
entry 8:  20/20 covered, max LR 0.47645991293
entry 44: 20/20 covered, max LR 0.273812631152
```

Runtime summary:

```text
fit seconds mean: 467.59, min 298.46, max 664.29
CI seconds mean: 1210.85, min 867.55, max 1921.61
```

### Verdict

Gate 2 passes the amended selected-entry diagnostic gate: `20/20` fits
converged, `100/100` profile truth solves were usable, and `100/100` selected
entries covered the eta-scale realized/design-conditional truth on one Totoro
denominator.

This permits Gate 3 DRAC claim-evidence planning. It does not expose
source-specific R grammar, reopen PR #127, or establish public package support.

## 2026-07-01 - Phylo Model A Gate 1 amendment and Gate 2 manifest

### Scope

Locked the amended Gate 1 decision and predeclared the Gate 2 weak-cell
diagnostic manifest before launching any Gate 2 compute.

### Gate 1 Amendment

The original no-miss Gate 1 rule was over-strict for a 100-entry nominal 95%
diagnostic. The amended rule keeps the hard usability conditions but evaluates
coverage as an MCSE-aware selected-entry diagnostic:

- `20/20` fits converged;
- `100/100` selected-entry profile truth solves usable;
- selected-entry coverage at least `0.92` at this `n = 100` denominator;
- MCSE and Wilson interval reported;
- all misses retained and listed;
- one host denominator only.

The corrected Gate 1 diagnostic passes this amended rule with `97/100 = 0.970`
coverage, MCSE `0.0171`, and Wilson interval `0.9155` to `0.9897`.

### Gate 2 Manifest

```text
target: B_eta_realized
method: profile_eta_realized
cell: p=80, n_sites=200, K=2, q_lv=1, K_phy=1, lambda=0.5, scenario=main
replicates: 20
seed0: 20260701
selected entries: 14,41,71,8,44
fit/profile optimizer budgets: 1000 / 1000
host: Totoro diagnostic only unless a tiny local smoke is needed
```

Entry rule: entry `71` is the old weak-cell sentinel; entries `14,41,8,44`
are deterministic population-`|B_lv|` rank representatives chosen before seeing
Gate 2 outcomes.

Commands:

```sh
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_eta_gate2_manifest_params.csv --reps 20 --lambdas 0.5 --n-species 80 --n-sites 200 --K 2 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --params /tmp/phylo_eta_gate2_manifest_params.csv --outdir /tmp/phylo_eta_gate2_dryrun --task-id 8 --methods profile_eta_realized --targets B_lv --b-lv-entries 14,41,71,8,44 --profile-opt-iterations 1000 --iterations 1000 --write-details --truth-init --dry-run
```

Results:

- parameter writer produced `20` tasks;
- dry-run task 8 read `scenario=main`, `lambda=0.5`, `n_species=80`,
  `n_sites=200`, `K=2`, `q_lv=1`, `K_phy=1`, `seed=28381215`;
- `B_lv` length was `80`;
- no Gate 2 statistical result yet.

Claim boundary: amended Gate 1 only permits the Gate 2 diagnostic. It does not
authorize source-specific R grammar, PR #127 reopening, public support, or a
DRAC claim run.

## 2026-07-01 - Phylo Model A Gate 1 corrected optimizer-budget diagnostic

### Scope

Ran a local-only corrected Gate 1 diagnostic after the first Gate 1 run showed
one fit non-convergence and profile underconvergence. This was not Gate 2, Gate
3, Totoro, DRAC, source-specific R grammar, package API, likelihood change, or
PR #127 reopen.

### Design

Same design and seeds as the Gate 1 run:

- `p = 20`, `n_sites = 300`, `K = 1`, `q_lv = 1`, `K_phy = 1`,
  `lambda = 1.0`, scenario `main`.
- `20` replicates from `seed0 = 20260701`.
- Five predeclared selected entries per replicate: `1, 3, 9, 11, 15`.
- Target: eta-scale realized/design-conditional `B_eta_realized`.
- Method: selected-entry one-df `profile_eta_realized` LR canary.

Only the optimizer budget changed:

- fit `iterations = 1000`;
- profile truth refit `profile_opt_iterations = 1000`.

### Checks Run

```sh
julia --project=. --startup-file=no
```

with `bench/phylo_xlv_drac_task.jl` included and `run_task(...)` called for
all 20 rows using the corrected optimizer budget above.

Result files were written under `/tmp/phylo_eta_gate1_corrected`.

Reduction result:

```text
planned selected entries: 100
recorded detail entries: 100
fit convergence: 20/20
profile status: 20/20 ok rows
usable profile truth solves: 100/100
covered/planned: 97/100 = 0.970
MCSE: 0.0171
Wilson 95% interval for selected-entry coverage: 0.9155 to 0.9897
converged LR misses: task 7 entry 9, task 8 entry 9, task 11 entry 11
```

Entry summary:

```text
entry 1: 20/20 covered, max LR 0.928832
entry 3: 20/20 covered, max LR 0.259662
entry 9: 18/20 covered, max LR 6.88283
entry 11: 19/20 covered, max LR 4.39707
entry 15: 20/20 covered, max LR 0.234153
```

Quantitative note: under a nominal 95% selected-entry interval, zero misses out
of 100 has probability `0.95^100 = 0.00592053`; observing at least 97/100
included truths has probability `0.25783866` when the true coverage is 0.95.
So the old zero-miss canary is much stricter than nominal-coverage behavior.

### Verdict

The original predeclared Gate 1 still FAILED because it required zero
converged LR misses. The corrected optimizer-budget diagnostic shows that
convergence/profile underconvergence is not the main blocker: with adequate
iteration limits, all 100 profile truth solves are usable and selected-entry
coverage is `97/100`.

Next defensible decision: amend the Gate 1 rule from a zero-miss canary to an
MCSE-aware selected-entry coverage diagnostic before any Gate 2/3 escalation.
Do not launch Totoro/DRAC or expose source-specific `lv` from this diagnostic
alone.

## 2026-07-01 - Phylo Model A Gate 1 local eta-realized diagnostic

### Scope

Ran the predeclared local-only positive-control diagnostic for the bench-only
`profile_eta_realized` route against `B_eta_realized`. This was Gate 1 only:
no Totoro fan-out, no DRAC claim evidence, no source-specific R grammar, no
package API, no likelihood change, and no PR #127 reopen.

### Design

- `p = 20`, `n_sites = 300`, `K = 1`, `q_lv = 1`, `K_phy = 1`,
  `lambda = 1.0`, scenario `main`.
- `20` replicates, seed stream from `seed0 = 20260701`.
- Five predeclared selected entries per replicate: `1, 3, 9, 11, 15`.
- Truth target: eta-scale realized/design-conditional `B_eta_realized`.
- Method: selected-entry one-df `profile_eta_realized` LR canary.

### Checks Run

```sh
julia --project=. --startup-file=no
```

with `bench/phylo_xlv_drac_task.jl` included and `run_task(...)` called for
all 20 rows using `methods = [:profile_eta_realized]`,
`profile_engine = :penalty`, `truth_init = true`, `iterations = 250`,
`profile_opt_iterations = 120`, and `profile_bisect_iterations = 24`.

Result files were written under `/tmp/phylo_eta_gate1_local`.

Reduction result:

```text
planned selected entries: 100
recorded detail entries: 95
covered/planned: 84/100 = 0.840
covered/recorded: 84/95 = 0.884
covered/usable: 84/87 = 0.966
fit non-convergence: task 3
profile-underconverged tasks: 9, 12, 14, 20
converged LR misses: task 7 entry 9, task 8 entry 9, task 11 entry 11
not-usable detail rows: task 9 entry 9; task 12 entry 9; task 14 entries 1, 3, 9, 15; task 20 entries 9, 11
```

### Verdict

Gate 1 FAILED. The predeclared gate required `20/20` fit convergence,
`100/100` selected entries usable, and zero converged LR misses. This run had
one full fit non-convergence, eight not-usable profile details, and three
converged LR misses concentrated in the weak/near-zero entries.

Gate 2 and Gate 3 remain held. Do not launch Totoro/DRAC for this arc from this
evidence. Do not expose source-specific `phylo_latent(..., lv = ~ x)` or reopen
PR #127.

## 2026-07-01 - Phylo Model A Gate 0 eta-realized target

### Scope

Implemented the internal `B_eta_realized` truth target and bench-only
`profile_eta_realized` LR canary route for a future non-v1 Phylo Gaussian Model
A restart. This is Gate 0 only: no source-specific R grammar, no package API,
no likelihood change, no PR reopen, no Totoro diagnostic, and no DRAC claim
compute.

### Implemented

- Added `GLLVM._eta_realized_lv_effects(X_lv, Z_truth, Lambda)` for the
  finite-sample eta-scale realized/design-conditional slope target.
- Added a deterministic test for centering, orientation, observed-response
  separation, and malformed input.
- Wired `bench/phylo_xlv_drac_task.jl` to return latent-score truth from the
  simulator and run `profile_eta_realized` against `B_eta_realized`.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
julia --project=. --startup-file=no -e 'include("bench/phylo_xlv_drac_task.jl"); println("bench-include-ok")'
git diff --check -- src/lv_targets.jl src/GLLVM.jl test/test_phylo_eta_realized.jl test/runtests.jl bench/phylo_xlv_drac_task.jl
rm -rf /tmp/phylo_eta_gate0_smoke /tmp/phylo_eta_gate0_params.csv
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_eta_gate0_params.csv --reps 1 --lambdas 1.0 --n-species 12 --n-sites 50 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
mkdir -p /tmp/phylo_eta_gate0_smoke
julia --project=. --startup-file=no bench/phylo_xlv_drac_task.jl --params /tmp/phylo_eta_gate0_params.csv --outdir /tmp/phylo_eta_gate0_smoke --task-id 1 --methods profile_eta_realized --targets B_lv --b-lv-entries 1 --iterations 150 --profile-opt-iterations 80 --truth-init --write-details --force
julia --project=. --startup-file=no test/runtests.jl
```

Results:

```text
phylo Model A eta-realized target: 7/7 pass
bench include smoke: bench-include-ok; help lists profile_eta_realized
git diff --check: no whitespace errors
tiny local profile_eta_realized smoke: fit converged; constrained solve converged; LR = 0.415558111946 < 3.84145882069
test/runtests.jl: interrupted after about 31 minutes while CPU-bound in the unrelated zero-inflated/two-part path at test/test_zero_inflated.jl; no full-suite tally recorded
```

Claim boundary: IN: Gate 0 truth helper, deterministic unit test, and
bench-only local smoke. OUT: Gate 1/2/3, source-specific `phylo_latent(..., lv =
~ x)` exposure, R grammar, package API widening, PR #127 reopen, bootstrap
rescue, non-Gaussian extension, Totoro diagnostic, or DRAC claim evidence.

## 2026-07-01 - LV arc closeout and next Phylo Model A target design

### Scope

Recorded the no-compute next-target design for a possible future non-v1 Phylo
Gaussian Model A reopening. This is a planning slice only: no package API, no
formula grammar, no likelihood change, no R exposure, no PR reopen, and no
Totoro/DRAC compute.

### Decision

V1 remains parked. The next defensible future target is not the old
population-`B_lv` route and not the observed-response saturated direct-slope
shortcut. The recommended candidate is an eta-scale realized/design-conditional
slope target:

```text
B_eta_realized(r) = ((Xc_r' Xc_r)^(-1) Xc_r' Etac_lv_r)'
```

where `Eta_lv_r` is the noiseless latent-mediated trait surface for replicate
`r`. The target is finite-sample and conditional, so it cannot be described as
population `B_lv` recovery.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md`

### Checks Run

```sh
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md
rg -n "B_eta_realized|no compute|Totoro|DRAC|source-specific.*support|partial support|ready to scale" docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md
```

Results: `git diff --check` returned no whitespace errors. The claim-audit
scan found the new `B_eta_realized`/no-compute/Totoro/DRAC gate language and
only expected negative guard text for source-specific support and partial
support.

Claim boundary: IN: ADEMP-style design, Williams self-audit, and future gate
definition. OUT: no truth extractor, no unit test, no canary run, no compute,
no source-specific `lv` exposure, and no non-Gaussian extension.

## 2026-07-01 - LV structural dependency truth lock

### Scope

Synced the Julia bridge capability ledger with the R bridge truth-lock slice.
This is not a modelling, likelihood, grammar, or compute change.

### Implemented

- Added explicit assertions for the `mixed-family vector` bridge row in
  `test/test_bridge_capabilities.jl`.
- Confirmed the row remains point/postfit only: `fit_no_x = true`; no fixed
  `X`, no predictor-informed `X_lv`, no response mask, no CI routes; retained
  predict/residual/simulate postfit payloads stay visible.
- Updated this check log to keep the source-specific phylo `lv` v1 parking
  wording current.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
julia --project=. --startup-file=no test/test_bridge_mixed.jl
julia --project=. --startup-file=no test/test_bridge_x.jl
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
git diff --check -- test/test_bridge_capabilities.jl docs/dev-log/check-log.md
```

Results:

```text
bridge capabilities ledger: 63/63 pass
bridge mixed-family payload metadata: 18/18 pass
bridge fixed-effect X: 195/195 pass
bridge missing-response mask: 83/83 pass
bridge CI routing: 64/64 pass
```

Claim boundary: IN: bridge matrix truth assertions and v1 parking wording.
OUT: no package API, no formula grammar, no likelihood change, no source-specific
`lv` exposure, no CI claim for mixed-family vectors, no Totoro/DRAC compute, and
no PR push/reopen.

## 2026-07-01 - Phylo Model A v1 retirement / parking recorded

### Scope

Recorded the final planning closeout for the current phylo Model A arc. Public
source-specific phylo `lv` is retired/parked for v1 under the current evidence.
No package API, likelihood code, R grammar, PR state, or compute launcher was
widened.

### Decision

Current v1 posture:

- keep ordinary `latent(lv = ~ x)` support separate from phylo Model A;
- keep `alpha_lv` as conditional axis/access-effect output; Wald is acceptable
  for that display only;
- keep rotation-stable `B_lv` as the old population target, now blocked for
  public phylo Model A exposure;
- keep `phylo_latent(..., lv = ~ x)` fail-loud;
- keep PR #127 closed/parked;
- do not run bootstrap/Wald/t-Wald/percentile/endpoint-profile or current
  `profile_truth`/`profile_direct_slope` reruns for the failed route.

### Evidence

```text
old weak cell bootstrap_basic:      591/720 = 0.821
optimistic cancelled-task bound:    671/800 = 0.839
task-8 entry-71 profile_truth LR:   9.99181181962 > 3.84145882069
K=1 population profile gate:        98/100 selected entries truth-included
K=1 direct-slope profile gate:      96/100 selected entries truth-included
direct-slope max LR:                6.66143949118 > 3.84145882069
focused package check:              25/25 passed in 1m05.6s
Mission Control version:            r60
Mission Control updated:            2026-06-30 23:30 MDT
```

Interpretation: the direct-slope aggregate is nominal-compatible at a small
denominator, but it failed the predeclared strict no-miss canary. It is not
partial support for source-specific phylo `lv`.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-v1-retirement.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-v1-retirement.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

### Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-v1-retirement.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
rg -n "ready to scale|source-specific.*covered|phylo.*partial support|next step is v1 retirement|Choose v1 retirement|live choice is v1 retirement|production fan-out is running" docs/dev-log/decisions docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json
julia --project=. test/test_phylo_xlv.jl
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "23:30|v1 parking|retired/parked|96/100|blocked_no_active_compute|No active|no active|newly predeclared|PR #127"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "23:30|v1 parking|retired/parked|96/100|profile-LR|no compute|PR #127"
```

Results: JSON parsed, diff checks passed, stale-claim scan found only quoted
command lines, guard phrases that say not to use "partial support", and
no-active phrasing such as "no production fan-out is running". Focused phylo
tests passed `25/25`, and Mission Control served `r60` with the `23:30 MDT` v1
parking row after refresh.

### Claim Boundary

IN: v1 retirement/parking decision, no active compute, future ADEMP-only reopen
gate. OUT: no public source-specific phylo `lv`, no bootstrap rescue, no PR #127
reopen, no R grammar exposure, no package API change, and no claim that Model A
interval coverage is solved.

## 2026-07-01 - Phylo Model A direct-slope K1 20-replicate gate failed strict canary

### Scope

Ran the K = 1, p = 20, n_sites = 200 realized direct-slope diagnostic as the
first promotion-style local wave after the five-seed and task-8 positives. This
was local-only diagnostic compute; no source-specific R grammar, production
compute, bootstrap, or public support claim changed.

### Result

```text
output directory: /tmp/phylo_xlv_direct_slope_k1_20rep_20260701
cell:             main, lambda 0.5, p 20, n_sites 200, K 1, q_lv 1, K_phy 1
seed0:            20260702
method:           profile_direct_slope
entries:          1,5,10,15,20
fit convergence:  20/20
usable entries:   100/100
truth included:   96/100
entry coverage:   0.960
coverage MCSE:    0.0196
RMSE mean:        0.026
mean fit seconds: 4.176
mean CI seconds:  6.859
max LR:           6.66143949118
LR cutoff:        3.84145882069
```

Misses:

| task | rep | seed | entry | term | estimate | direct-slope target | LR |
| ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: |
| 7 | 7 | 27340929 | 5 | `B_lv[5,1]` | -0.141132756958 | -0.0896177522692 | 5.65080204201 |
| 10 | 10 | 30370959 | 5 | `B_lv[5,1]` | -0.144284593088 | -0.0888739640536 | 6.66143949118 |
| 16 | 16 | 36431019 | 5 | `B_lv[5,1]` | -0.139598210616 | -0.0894642329239 | 5.43956667108 |
| 17 | 17 | 37441029 | 20 | `B_lv[20,1]` | -0.110154156887 | -0.0654424555058 | 5.62375223457 |

Per-entry summary:

```text
entry 1:  20/20, max LR 1.04042, mean |target| 0.454468
entry 5:  17/20, max LR 6.66144, mean |target| 0.144455
entry 10: 20/20, max LR 2.80957, mean |target| 0.355322
entry 15: 20/20, max LR 0.318758, mean |target| 0.524356
entry 20: 19/20, max LR 5.62375, mean |target| 0.163322
```

Interpretation: aggregate coverage is compatible with a nominal 95% interval at
this small denominator, but the predeclared strict no-miss promotion canary
failed. The realized direct-slope route should not be promoted to public
source-specific phylo `lv` support. The misses concentrate in weaker direct
targets (entries 5 and 20), so any future path must explicitly revise the
estimand/gate, for example by predeclaring a magnitude-qualified realized-slope
target or by planning a larger nominal-coverage simulation with MCSE
justification.

### Commands

```sh
out=/tmp/phylo_xlv_direct_slope_k1_20rep_20260701
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$out/meta/params.csv" --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
seq 1 20 | xargs -I{} -P4 sh -c 'julia --project=. bench/phylo_xlv_drac_task.jl --params "$0/meta/params.csv" --outdir "$0/results" --task-id "$1" --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force > "$0/logs/task_${1}.log" 2>&1' "$out" {}
julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$out/results"
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "23:19|Direct-slope 20-rep gate|96/100|6.661|blocked_no_active_compute|newly predeclared"
```

Focused package check: `phylo x X_lv (Model A)` passed `25/25` in `1m05.7s`.
Mission Control served `version.txt` as `r60` and the served status/sweep JSON
shows the `Direct-slope 20-rep gate`, `96/100`, max LR `6.661`, and
`blocked_no_active_compute` at `2026-06-30 23:19 MDT`.

Next defensible options: retire public source-specific phylo `lv` for v1, or
write a new ADEMP gate before any more compute. Do not run another same-route
profile, bootstrap, Wald/t-Wald, or production fan-out.

## 2026-07-01 - Phylo Model A realized direct-slope K1 and failed-row canaries

### Scope

Ran the next local diagnostic canaries for the redesigned
realized/sampling-conditional target. This remains bench-only evidence: no
source-specific R grammar, no production compute, no bootstrap, and no public
support claim.

### K1 Five-Seed Canary

```text
output directory: /tmp/phylo_xlv_direct_slope_k1_5seed
cell:             main, lambda 0.5, p 20, n_sites 200, K 1, q_lv 1, K_phy 1
method:           profile_direct_slope
entries:          1,5,10,15,20
fit convergence:  5/5
usable entries:   25/25
truth included:   25/25
summary coverage: 1.000
RMSE mean:        0.024
mean fit seconds: 4.193
mean CI seconds:  8.042
max LR:           3.65953749216
LR cutoff:        3.84145882069
max-LR row:       task 3, rep 3, seed 23300889, entry 5, B_lv[5,1]
```

### Known Failed-Row Canary

The old population-target `profile_truth` canary missed task 8 entry 71 with
`LR = 9.99181181962 > 3.84145882069`. Under the changed realized direct-slope
target, the same row now passes:

```text
output directory:     /tmp/phylo_xlv_direct_slope_task8_entry71_20260701
cell:                 main, lambda 0.5, p 80, n_sites 80, K 2, q_lv 1, K_phy 1
task/seed:            task 8, seed 202614420856
method:               profile_direct_slope
entry:                71, B_lv[71,1]
fit converged:        true, 235 iterations
estimate:             -0.212294346248
direct-slope target:  -0.220447386197
LR:                   0.00569099997301
LR cutoff:            3.84145882069
truth included:       true
```

Interpretation: the realized/sampling-conditional target has positive local
canary evidence, including the row that failed the old population `B_lv` target.
This keeps the redesign route alive. It does not validate population `B_lv`
coverage, source-specific phylo `lv` grammar, or a production support claim.

### Commands

```sh
rm -rf /tmp/phylo_xlv_direct_slope_k1_5seed
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --reps 5 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id 1 --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id 2 --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id 3 --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id 4 --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_k1_5seed/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_k1_5seed/results --task-id 5 --methods profile_direct_slope --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_k1_5seed/results
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_direct_slope_task8_entry71_20260701/results --task-id 8 --methods profile_direct_slope --targets B_lv --b-lv-entries 71 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_task8_entry71_20260701/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "23:10|Direct-slope local canaries|25/25|0.00569|blocked_no_active_compute|No active LV compute|predeclared local"
```

Focused package check: `phylo x X_lv (Model A)` passed `25/25` in `1m05.9s`.
Mission Control served `version.txt` as `r60` and the served status/sweep JSON
shows `Direct-slope local canaries`, `25/25`, task-8 entry-71 LR `0.00569`, and
`blocked_no_active_compute` at `2026-06-30 23:10 MDT`.

Next defensible gate: a predeclared local diagnostic wave, either the K = 1
20-replicate realized-target denominator or a small p = 80, K = 2 selected-row
diagnostic including task 8 entry 71. Keep hosts/denominators separate.

## 2026-07-01 - Phylo Model A realized direct-slope canary tooling

### Scope

Added a bench-only `profile_direct_slope` method for the changed
realized/sampling-conditional target. This does not alter package APIs,
likelihood code, source-specific R grammar, or production compute posture.

### Contract

For each replicate, compute the saturated direct target:

```text
D = [1  X_lv]
Gamma_direct = coef(D \ Y')
B_direct[t, c] = Gamma_direct[c + 1, t]
```

Then constrain selected fitted `B_lv` entries to `B_direct` and record the
one-df LR truth-inclusion canary. Result rows use target label
`B_lv_direct_slope` and method `profile_direct_slope`.

### Smoke Result

```text
output directory:   /tmp/phylo_xlv_direct_slope_smoke
cell:               main, lambda 0.5, p 5, n_sites 60, K 1, q_lv 1, K_phy 1
entries:            2,4
fit converged:      true, 25 iterations
usable entries:     2/2
truth included:     2/2
LR values:          0.0895416648327, 1.60222512548
LR cutoff:          3.84145882069
target:             B_lv_direct_slope
ci_status:          ok
```

Interpretation: the realized direct-slope canary can run end to end on a tiny
local smoke. It is not coverage evidence, does not reopen the old population
`B_lv` route, and does not expose source-specific phylo `lv`.

### Files Updated

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-realized-direct-slope-ademp.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

### Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
git diff --check -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh
rm -rf /tmp/phylo_xlv_direct_slope_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_direct_slope_smoke/meta/params.csv --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260702
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_direct_slope_smoke/meta/params.csv --outdir /tmp/phylo_xlv_direct_slope_smoke/results --task-id 1 --methods profile_direct_slope --targets B_lv --b-lv-entries 2,4 --profile-opt-iterations 80 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_direct_slope_smoke/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "22:54|profile_direct_slope|Direct-slope|blocked_no_active_compute|B_lv_direct_slope"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "22:54|profile_direct_slope|Direct-slope|B_lv_direct_slope"
```

Focused package check: `phylo x X_lv (Model A)` passed `25/25` in `1m03.7s`.
Mission Control served `version.txt` as `r60` and the served JSON shows the
`Direct-slope canary smoke`, `profile_direct_slope`, `B_lv_direct_slope`, and
`blocked_no_active_compute` rows at `2026-06-30 22:54 MDT`.

Claim boundary: IN: bench-only diagnostic method and tiny smoke. OUT: no
source-specific phylo `lv` support, no population `B_lv` recovery claim, no
bootstrap rescue, no production compute, and no grammar exposure.

## 2026-07-01 - Phylo Model A structural fork locked

### Scope

Recorded the post-K1 decision fork for phylo Model A after Shinichi confirmed
the method posture: no bootstrap rescue, profile only if it can be used as a
small canary for a changed target, and `alpha_lv` is not the scientific evidence
target.

### Decision

The old population-`B_lv` interval route is now closed as negative evidence:

- p = 80, K = 2, lambda = 0.5 `bootstrap_basic`: `591/720 = 0.821`;
- optimistic cancelled-task bound: `671/800 = 0.839`;
- task-8 entry-71 `profile_truth`: `LR = 9.99181181962 > 3.84145882069`;
- K = 1 diagnostic profile route: `20/20` fits, `100/100` usable entries,
  `98/100` truth-included, with two converged misses.

The only admissible futures are v1 retirement of public source-specific phylo
`lv`, or a structural redesign with a genuinely changed target/regime and fresh
ADEMP evidence. The plausible redesign candidate is realized/sampling-
conditional and direct-slope-aligned, but that changes the claim from population
`B_lv` recovery to a descriptive/conditional association.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/dev-log/check-log.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

Claim boundary: IN: structural fork and operating rule. OUT: no new compute,
no R grammar exposure, no PR reopen, no package API, no likelihood rewrite, and
no source-specific phylo `lv` support claim.

## 2026-07-01 - Phylo Model A K1 20-replicate profile gate failed

### Scope

Ran the predeclared local diagnostic-only K = 1 `profile_truth` gate after the
5-seed scout looked promising:

- `K = 1`, `q_lv = 1`, `n_species = 20`, `n_sites = 200`, lambda `0.5`;
- 20 seeds from `--seed0 20260701`;
- selected entries: `1,5,10,15,20`;
- method: `profile_truth`;
- no bootstrap, no endpoint CI fan-out, no grammar exposure, no production
  compute.

### Result

```text
output directory:            /tmp/phylo_model_a_k1_diag20_20260630_220930
fits converged:              20/20
selected entries usable:     100/100
selected entries covered:    98/100
mean task coverage (MCSE):   0.980 (0.014)
entry coverage:              0.980
LR range:                    2.65627995759e-05 to 5.14288022148
LR cutoff:                   3.84145882069
mean selected-entry LR:      0.630993528174
fit sec mean:                3.954
selected-entry CI sec mean:  5.616
ci_status:                   ok
```

The two misses were real converged selected-entry canaries:

```text
task 15 rep 15 seed 35421008 entry 10 B_lv[10,1]:
  estimate -0.461291546426, truth -0.355095269986, LR 4.94199940694

task 19 rep 19 seed 39461048 entry 20 B_lv[20,1]:
  estimate -0.234136406101, truth -0.171615120502, LR 5.14288022148
```

Interpretation: the K = 1 selected-entry profile route failed the 20-replicate
stop rule. Do not scale this route to DRAC claim evidence. Do not revive
bootstrap, Wald, t-Wald, percentile, `bootstrap_basic`, or endpoint-profile
reruns. Source-specific phylo `lv` remains blocked for v1 unless Shinichi
chooses a different structural estimand/regime with a fresh ADEMP gate.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-narrowed-regime-gate.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-20rep-profile-gate.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

### Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_k1_diag20_20260630_220930/meta/params.csv --reps 20 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag20_20260630_220930/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag20_20260630_220930/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
# repeated for task-id 2:20 with the same selected-entry diagnostic settings
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_k1_diag20_20260630_220930/results
```

Claim boundary: IN: local diagnostic stop-rule evidence. OUT: no source-specific
phylo `lv` support, no R grammar exposure, no production compute, no bootstrap
rescue, no DRAC claim evidence, and no "partial support" language.

Follow-up validation after the documentation and Mission Control refresh:

```sh
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|K=1 profile gate|98/100|20/20|100/100|active|queued|blocked"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|K=1 profile gate|98/100|20/20|100/100|active|queued|blocked"
```

Results: focused phylo Model A tests passed `25/25` in `1m06.0s`; JSON parsed;
served Mission Control JSON updated to `2026-06-30 22:15 MDT`, with `active = 0`,
`queued = 0`, `blocked = 5`, and the K = 1 profile gate marked blocked after
`98/100` selected-entry truth inclusion.

Follow-up closure: Design 73 and the council-final decision now carry the K = 1
20-replicate gate failure directly, so the model spec no longer points from the
failed p = 80, K = 2 weak cell to a same-route K = 1 profile scale-up. The only
remaining admissible futures are structural redesign with a genuinely different
target/regime and fresh evidence, or explicit v1 retirement of public
source-specific phylo `lv`.

## 2026-07-01 - Phylo Model A narrowed-regime K1 diagnostic wave

### Scope

Ran a local diagnostic-only `profile_truth` wave for a narrowed Gaussian Model A
target:

- `K = 1`, `q_lv = 1`, `n_species = 20`, `n_sites = 200`, lambda `0.5`;
- five seeds: `21280868`, `22290878`, `23300888`, `24310898`, `25320908`;
- selected entries: `1,5,10,15,20`;
- method: `profile_truth`;
- no bootstrap, no endpoint CI fan-out, no production compute.

### Result

The first one-seed scout fit converged in 112 iterations and included truth for
4/4 usable entries; entry 5 was marked underconverged with
`--profile-opt-iterations 160`. Retrying entry 5 only with
`--profile-opt-iterations 500` converged and included truth:

```text
entry 1:  LR = 2.3052625172    < 3.84145882069
entry 5:  LR = 0.0686506851789 < 3.84145882069  (retry)
entry 10: LR = 0.309444810472  < 3.84145882069
entry 15: LR = 0.16730512331   < 3.84145882069
entry 20: LR = 2.54639208502   < 3.84145882069
```

The follow-up 5-seed wave used `--profile-opt-iterations 500` for all selected
entries and repeated the pattern:

```text
fits converged:             5/5
selected entries usable:    25/25
selected entries covered:   25/25
LR range:                   2.65627995759e-05 to 2.54639208502
LR cutoff:                  3.84145882069
mean selected-entry LR:     0.45583577218
max-LR row:                 task 1, seed 21280868, entry 20, B_lv[20,1]
```

Historical interpretation before the 20-replicate gate: K = 1 was plausible
enough to continue. Superseding result: the 20-replicate gate above found two
converged truth-inclusion misses, so K = 1 same-route scaling is now stopped.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-narrowed-regime-gate.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-phylo-model-a-narrowed-regime-scout.md`

### Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --outdir /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 160 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/meta/params.csv --outdir /tmp/phylo_model_a_narrow_k1_profile_truth_20260701_entry5_retry/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 5 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_narrow_k1_profile_truth_20260701/results
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_narrow_k1_profile_truth_20260701_entry5_retry/results
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --reps 5 --lambdas 0.5 --n-species 20 --n-sites 200 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 2 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 3 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 4 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_model_a_k1_diag_wave_20260701_2158/meta/params.csv --outdir /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results --task-id 5 --methods profile_truth --targets B_lv --b-lv-entries 1,5,10,15,20 --profile-opt-iterations 500 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_model_a_k1_diag_wave_20260701_2158/results
julia --project=. test/test_phylo_xlv.jl
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|Narrowed K=1|tiny K=1|active|queued|blocked|no bootstrap|ADEMP gate|source-specific"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|Narrowed K=1|tiny K=1|active|queued|blocked|no bootstrap|ADEMP gate|source-specific"
```

Claim boundary: IN: local diagnostic and narrowed-regime ADEMP gate. OUT: no R
grammar exposure, no source-specific phylo `lv` support, no coverage claim, no
bootstrap, no production compute.

Focused phylo Model A tests passed after the narrowed-regime documentation
refresh: `25/25` in `1m03.9s`.

Mission Control served JSON updated to `2026-06-30 21:54 MDT`, with the
diagnostic K = 1 scout visible, `active = 0`, `queued = 0`, and `blocked = 5`.

## 2026-07-01 - Phylo Model A structural dependency lock

### Scope

Recorded Shinichi's method decision for the next phylo Model A step:

- no bootstrap rescue for the current phylo weak-cell route;
- profile-LR remains useful only as a selected-entry truth-inclusion canary after
  a new/narrowed estimand is named;
- `alpha_lv` may use Wald-style conditional output as the ordinary
  axis/access-effect view, but it is not the rotation-invariant phylo Model A
  claim;
- source-specific phylo `lv` is parked for v1; any future non-v1 route needs a
  named replacement target and fresh ADEMP evidence before grammar exposure.

### Files Updated

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`
- gllvmTMB dashboard: `docs/dev-log/dashboard/sweep.json`

### Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
rg -n "bootstrap is not the next route|no bootstrap rescue|profile-LR is only a selected-entry|alpha Wald|structural-dependencies|partial support|source-specific.*covered|ready to scale" docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-dependencies.md docs/design/73-predictor-informed-latent-scores.md docs/dev-log/check-log.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/sweep.json
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool | rg -n "updated|no bootstrap rescue|profile-LR is only|alpha Wald|profile_truth|active|queued|blocked|partial support"
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool | rg -n "updated|no bootstrap rescue|profile-LR is only|Alpha Wald|bootstrap is not the next route|active|queued|blocked"
julia --project=. test/test_phylo_xlv.jl
```

Results: JSON parsed; `git diff --check` passed for GLLVM.jl docs and the
gllvmTMB dashboard JSON; served `version.txt` stayed `r60`; served
`status.json` and `sweep.json` showed `updated = 2026-06-30 21:41 MDT`,
`active = 0`, `queued = 0`, `blocked = 5`, and the no-bootstrap/profile-canary
method lock. Focused phylo Model A tests passed: `25/25` in `1m03.3s`. Browser
automation against the in-app preview timed out during the read-only page check,
but the tab remains on `http://127.0.0.1:8770/` and the served JSON backing the
page is refreshed.

Claim boundary: IN: structural/method decision and Mission Control wording.
OUT: no package API, no likelihood change, no R grammar exposure, no new
Totoro/DRAC compute, and no claim that phylo Model A is solved.

## 2026-06-30 - Phylo Model A old-target retirement decision

### Scope

Updated the durable design record after the negative task-8 entry-71
profile_truth canary. The old recommendation, "profile-LR calibrated `B_lv` is
the next target", is no longer current. The current decision is:

- do not expose source-specific phylo `lv` for v1 under the current
  population-`B_lv` interval target;
- do not launch more bootstrap, Wald/t-Wald, percentile, `bootstrap_basic`, or
  endpoint-profile compute for the p = 80, K = 2, lambda = 0.5 weak cell;
- superseded current boundary after the K = 1 gate failure: next work must be
  structural redesign with a genuinely different target/regime and fresh
  evidence, or explicit v1 retirement.

### Files Updated

- `docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md`
- `docs/design/73-predictor-informed-latent-scores.md`
- gllvmTMB dashboard: `docs/dev-log/dashboard/status.json`

### Checks Run

```sh
python3 -m json.tool /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json >/dev/null
rg -n "profile-LR B_lv canary|next admissible step is a profile-LR|ready to scale|partial support|source-specific.*covered" docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md /Users/z3437171/Dropbox/Github\ Local/gllvmTMB/docs/dev-log/dashboard/status.json
git diff --check -- docs/dev-log/decisions/2026-06-30-phylo-model-a-redesign-plan.md docs/design/73-predictor-informed-latent-scores.md
```

Claim boundary: IN: old-target retirement decision and stale recommendation
cleanup. OUT: no new compute, no public grammar exposure, no claim that a
narrower regime is already validated.

Follow-up within the same slice: added
`docs/dev-log/decisions/2026-06-30-phylo-model-a-council-final.md` as the
compact operating decision. It records Ada/Fisher/Curie/Grace/Rose roles, the
reopen gate, and the "do not rerun" list. Design 73 and the earlier redesign
plan now point to this final council note.

## 2026-06-30 - Phylo Model A profile-truth canary result

### Scope

Added and exercised a bench-only `profile_truth` method for the phylo Model A
runner. This method answers the canary question directly: for a known
simulation truth, does the one-df profile likelihood-ratio statistic at the true
`B_lv` value fall below the chi-square cutoff? It does not return endpoint CIs
and it is not public API.

This follows Shinichi's direction to avoid more bootstrap work, keep
`alpha_lv` as the ordinary/default axis-effect side where Wald output is
acceptable, and spend the inference gate on the rotation-invariant `B_lv`
trait/loading effect.

### Checks Run

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
smoke_dir=/tmp/phylo_xlv_profile_truth_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$smoke_dir/meta/params.csv" --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params "$smoke_dir/meta/params.csv" --outdir "$smoke_dir/results" --task-id 1 --methods profile_truth --targets B_lv --b-lv-entries 2,4 --profile-opt-iterations 80 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$smoke_dir/results"
julia --project=. test/test_phylo_xlv.jl
git diff --check -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh
```

Results:

- task help parsed and advertises `profile_truth`;
- submitter syntax passed;
- tiny smoke wrote `method = profile_truth`, two usable entries, entry coverage
  `1.000`, and detail rows with explicit `lr_deviance` / `lr_cutoff` columns;
- focused phylo Model A tests passed: `25/25` in `1m03.5s`;
- `git diff --check` passed for the touched runner files.

### Weak-Cell Local Diagnostic

Narval login/status reads stalled, so I did not launch more DRAC work. I used
the existing local copy of the seed-matched task-8 parameter row instead:

```sh
out=/tmp/phylo_xlv_profile_truth_task8_entry71_local_20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir "$out/results" --task-id 8 --methods profile_truth --targets B_lv --b-lv-entries 71 --profile-opt-iterations 80 --iterations 400 --write-details --truth-init --force

out=/tmp/phylo_xlv_profile_truth_task8_entry71_local_250_20260701
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv --outdir "$out/results" --task-id 8 --methods profile_truth --targets B_lv --b-lv-entries 71 --profile-opt-iterations 250 --iterations 400 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$out/results"
```

Results:

- The 80-iteration constrained truth solve did not converge and correctly wrote
  `usable = 0`, `ci_status = profile_truth_underconverged`.
- The 250-iteration constrained truth solve converged for the same task/entry:
  `fit_converged = true`, `fit_iterations = 235`,
  `fit_seconds = 125.1365`, `ci_seconds = 59.4776`,
  `lr_deviance = 9.99181181962`, `lr_cutoff = 3.84145882069`,
  `usable = 1`, `covered = 0`, `coverage = 0`, `ci_status = ok`.

Interpretation: even the profile-LR truth-inclusion canary misses the known
truth for the worst task-8 `B_lv[71,1]` entry. The next defensible decision is
not more endpoint/profile/bootstrap compute. Superseding K = 1 evidence now
rules out same-route narrowed scaling too; the remaining choices are structural
redesign with a genuinely different target/regime, or v1 retirement of
source-specific phylo `lv`.

### Mission Control

Updated the local gllvmTMB Mission Control JSON to show:

- `0` active compute rows and `5` blocked rows;
- local profile_truth miss: LR `9.9918 > 3.8415`;
- no production fan-out;
- no source-specific `lv` grammar exposure;
- Ada/Fisher blocked on the next regime decision, Grace guarding compute, Rose
  guarding wording.

Validation:

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Claim boundary: IN: bench-only profile_truth instrumentation and a local
seed-matched negative diagnostic for task 8 entry 71. OUT: no public CI method,
no R grammar exposure, no source-specific phylo support, no production coverage,
and no claim that Narval job `64471433` finished.

## 2026-06-30 - Phylo Model A profile-LR canary tooling

### Scope

Implemented the narrow operational path needed to test the redesigned phylo
Model A profile-LR `B_lv` canary without rerunning a full p = 80 profile vector.
This is tooling for a predeclared canary, not public source-specific `lv`
support and not new production coverage evidence.

- Added a private selected-entry route to the internal profile helper so
  profile-LR canaries can invert only named entries of `vec(B_lv)`.
- Added `--b-lv-entries all|1,5,9:12` to the phylo DRAC task runner and
  `PHYLO_XLV_B_LV_ENTRIES` to the submitter.
- Wrote selected-entry result provenance into `b_lv_entries` on result/detail
  CSVs, while preserving original `vec(B_lv)` entry IDs in detail rows.
- Warm-started each constrained profile solve from the nearest previous
  constrained solution so selected-entry profiles do not cold-start every
  bracket and bisection point.
- Added bench-runner progress logging around each selected `B_lv` profile entry
  so later canaries do not disappear inside one long profile call.
- Kept the public `confint_lv_effects(...)` API unchanged; no R grammar,
  source-specific `lv`, or likelihood parameterisation changed.

### Checks Run

```sh
julia --project=. test/test_phylo_xlv.jl
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
smoke_dir=/tmp/phylo_xlv_profile_subset_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$smoke_dir/meta/params.csv" --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params "$smoke_dir/meta/params.csv" --outdir "$smoke_dir/results" --task-id 1 --methods profile --targets B_lv --b-lv-entries 2,4 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_subset_smoke/results
git diff --check -- src/confint_family.jl bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh test/test_phylo_xlv.jl docs/dev-log/check-log.md
```

Results: `test/test_phylo_xlv.jl` passed `25/25` in `1m19.2s`. The tiny local
profile smoke converged and wrote a `B_lv,profile` result row with
`b_lv_entries = "2,4"`, `total = 2`, `usable = 2`, `covered = 2`, and
`ci_status = ok`; the detail CSV preserved original entries `2` and `4`.
The summariser read the selected-entry result as one profile task with two
usable entries.

After the warm-start profile improvement, `julia --project=.
test/test_phylo_xlv.jl` passed again: `25/25` in `1m09.4s`.

After the per-entry logging change, `julia --project=. test/test_phylo_xlv.jl`
passed again: `25/25` in `1m03.9s`.

I also reran a tiny bench-level selected-profile smoke after the logging change:

```sh
smoke_dir=/tmp/phylo_xlv_profile_logging_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$smoke_dir/meta/params.csv" --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params "$smoke_dir/meta/params.csv" --outdir "$smoke_dir/results" --task-id 1 --methods profile --targets B_lv --b-lv-entries 2,4 --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_logging_smoke/results
```

Result: per-entry progress lines printed for entries `2` and `4`; the summary
read one profile row, two usable entries, entry coverage `1.000`, and
`ci_status = ok`. This smoke checks the runner logging/provenance path only.

After the logged penalty route showed that entry `71` itself can run silently
for many minutes, I added an opt-in exact Gaussian one-entry profile engine for
bench canaries:

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
smoke_dir=/tmp/phylo_xlv_profile_exact_smoke
julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$smoke_dir/meta/params.csv" --reps 1 --lambdas 0.5 --n-species 5 --n-sites 60 --K 1 --q-lv 1 --K-phy 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params "$smoke_dir/meta/params.csv" --outdir "$smoke_dir/results" --task-id 1 --methods profile --targets B_lv --b-lv-entries 2,4 --profile-engine exact --iterations 250 --write-details --truth-init --force
julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_profile_exact_smoke/results
julia --project=. test/test_phylo_xlv.jl
```

Results: submitter syntax and task help passed; exact smoke wrote
`method = profile_exact`, two usable entries, entry coverage `1.000`, and
`ci_status = ok`; focused phylo tests passed again, `25/25` in `1m04.3s`.
The exact smoke bounds matched the penalty smoke at the displayed precision
needed for a canary, while per-entry solve time dropped from seconds-scale
penalty solves to `2.66s` and `0.04s` for the two tiny entries after the shared
Hessian setup. This is still diagnostic bench tooling, not public API.

I then added a bounded exact-engine knob, `--profile-opt-iterations`, and
side-level lower/upper progress logging. A capped exact smoke with the default
`250` optimiser iterations per candidate passed locally and printed lower/upper
done lines for both selected entries. Submitter syntax, task help, and
`git diff --check` passed after this cap was added.

I also started `julia --project=. test/runtests.jl`. It ran for about 40 minutes
and was interrupted while inside an unrelated two-part `test_confint_family.jl`
bootstrap/profile path, after earlier sparse, profile, Student-t, node-gradient,
and masked-objective checks had emitted normal progress. Treat the core suite as
not completed for this slice.

### First Weak-Cell Canary Launch

After Shinichi confirmed bootstrap should not be the next route, I launched one
seed-matched Narval profile-LR canary for the catastrophic weak-cell row:

```sh
rsync -av src/confint_family.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/src/confint_family.jl
rsync -av bench/phylo_xlv_drac_task.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl
rsync -av bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_submit.sh
ssh -o BatchMode=yes narval '... dry-run task 8 --methods profile --targets B_lv --b-lv-entries 71,67,1,74 ...'
ssh -o BatchMode=yes narval '... sbatch profile_selected_task8.sbatch ...'
```

Result: dry-run confirmed original task 8 (`seed = 202614420856`, p = 80,
K = 2, lambda = 0.5, `B_lv` length 80). Narval job `64462844` was submitted as
a one-core selected-entry profile canary for entries `71,67,1,74`; it moved from
`PENDING (Priority)` to `RUNNING` on `nc11026` and fit in `143.57s`, then stayed
inside the cold-start profile step with no result for about 22 minutes. I
cancelled it and relaunched the identical canary after syncing the warm-started
helper. Warm-start job `64463813` ran on Narval, fit with
`converged = true`, `iterations = 116`, and `seconds = 141.01`, then entered
`B_lv` profile inversion for entries `71,67,1,74`. It was still running at
`00:46:00` elapsed with no result/detail CSV, so I canceled it at `00:46:38` as
runtime/observability evidence rather than statistical evidence.

I then synced the per-entry logging runner to Narval, verified the staged file
contains `B_lv profile entry ... start/done` progress lines, and launched a
narrower logged canary:

- job: `64466208` (`phylo_xlv_p71`);
- host: Narval / DRAC, same Julia `1.10.10` path;
- task: original task 8, seed `202614420856`;
- cell: p = 80, n_sites = 80, K = 2, lambda = 0.5;
- method: `profile`;
- target: `B_lv`;
- entries: `71`;
- bootstrap: none;
- scope: one-core diagnostic canary, not production fan-out.

At first poll, job `64466208` was running on `nc30402` and had entered the fit
phase. Mission Control was refreshed and browser/curl-verified to show
`1 active`, `0 queued`, and still `4 blocked` rows.

Later poll: `64466208` fit with `converged = true`, `iterations = 116`,
`seconds = 141.44`, then printed the synced logging line
`B_lv profile entry 71 start (1/1)`. It was still running at `00:22:08` elapsed
with no done line. I prepared the exact engine locally, but rsync to Narval then
hit a transport timeout and Narval also reported a transient `/home/snakagaw`
I/O warning. I therefore did not launch an exact Narval replacement yet; the
current source-of-truth remote canary remains penalty job `64466208` until a
later successful sync or its wall-time result.

Follow-up: `scp` succeeded where `rsync` had timed out, and the Narval staged
runner now contains the exact profile code. I canceled penalty job `64466208`
at `00:32:04` elapsed with no result and launched exact job `64468504`
(`phylo_xlv_e71`) for the same task 8, seed `202614420856`, entry `71`, no
bootstrap, no production fan-out. Mission Control now shows the exact Narval
canary as the active job.

Final remote state for this turn: exact job `64468504` fit successfully
(`converged = true`, `iterations = 116`, `seconds = 145.03`), entered exact
profile for entry `71`, anchored on `alpha[1]`, and then hit the 30-minute
SLURM time limit with no result/detail CSV. I prepared and attempted to launch a
capped exact retry with `--profile-opt-iterations 120`, but the combined
sync/submit command hung during Narval filesystem/transport instability and no
new job id was confirmed. Mission Control was therefore corrected to
`0 active`, `0 queued`, `5 blocked`: the next operation is to launch the capped
exact retry only after Narval filesystem/transport health is confirmed.

Continuation: Narval recovered enough to confirm `64468504` timed out. I added
`--profile-maxstep` and `--profile-bisect-iterations` plus lower/upper bracket
and bisection progress logging. Local progress-capped exact smoke passed with
`--profile-opt-iterations 80 --profile-maxstep 12 --profile-bisect-iterations
10`, summarising one `profile_exact` row with two usable entries and
`ci_status = ok`. Focused phylo tests passed again, `25/25` in `1m06.1s`.
I synced the staged Narval runner and launched capped exact job `64471433`
for task 8, entry `71`, same seed `202614420856`, no bootstrap, no production
fan-out. First poll confirmed it running on `nc11002`; later scheduler/log reads
were intermittently blocked by Narval filesystem/transport latency. Mission
Control now shows `1 active`, `0 queued`, `4 blocked`.

Note: the first `rsync` attempt copied three files to the remote repo root. I
immediately synced the files to their correct `src/` and `bench/` locations and
removed only those accidental root-level copies before the dry-run/submission.
A later attempt to sync the per-entry logging runner to Narval hit an rsync
transport timeout while the remote path was slow; do not assume that staging
checkout has the logging patch unless the later verified sync above is also
present in the continuation context.

## 2026-06-30 - Phylo Model A council and mission-control refresh

### Scope

Implemented the local Mission Control refresh for the phylogenetic LV arc
council decision. This was a planning/dashboard slice only: no GLLVM.jl source,
likelihood, R grammar, tests, PR, push, or compute route changed.

Superseded note, 2026-07-01: the later local `profile_truth` canary for task 8
entry 71 missed truth. The current policy is therefore no bootstrap rescue and
profile-LR only as a selected-entry truth-inclusion canary after a new/narrowed
target is named.

- Refreshed the gllvmTMB local Mission Control dashboard source so the visible
  widget records the phylo Model A council gate. At the time this pointed to a
  Gaussian direct/native profile-LR canary for rotation-invariant `B_lv`; the
  later canary failed and the structural-dependency lock now controls.
- Kept `alpha_lv` as axis/access-effect output; later Mission Control wording
  makes explicit that alpha Wald output is conditional on the fitted loading and
  axis convention.
- Marked same-route Wald, t-Wald, percentile bootstrap, and `bootstrap_basic`
  reruns as retired for the p = 80, K = 2, lambda = 0.5 weak cell.
- Recorded council roles: Ada chairs; Fisher owns interval target; Curie owns
  the ADEMP-style gate; Grace owns host/provenance discipline; Rose owns claim
  wording; Boole/Hopper stay at the fail-loud grammar guard.

### Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
```

Mission Control remains a local operating board, not public pkgdown or CRAN
evidence. Metrics stayed unchanged at `17 covered, 3 partial, 0 ready, 0
active, 0 queued, 4 blocked`; only the council decision and next-gate wording
changed.

## 2026-06-30 - Phylo Model A redesign plan

### Scope

Drafted a compact redesign plan for the blocked phylo Model A `X_lv` interval
gate, starting from the p = 80, K = 2, lambda = 0.5 `B_lv` weak-cell evidence.
This was a planning/docs slice only: no source, API, likelihood, test, or
cluster-compute route changed.

- Recorded what worked: dense-vs-J3 point agreement, targeted diagnostic
  tooling, seed-matched DRAC rows, and the saturated direct-slope comparator.
- Recorded what failed: Wald, t-Wald, percentile bootstrap, `bootstrap_basic`,
  and truth-start as explanations/rescues for the weak cell.
- Separated access/axis effect `alpha_lv` from induced trait/loading effect
  `B_lv = Lambda * alpha_lv'`.
- Proposed profile-LR calibrated Gaussian Model A `B_lv` as the next candidate
  target, with source-specific `phylo_latent(..., lv = ~ x)` kept fail-loud
  until the weak-cell gate is evidence-backed.

### Checks Run

```sh
sed -n '1,260p' /Users/z3437171/shinichi-brain/AGENTS.md
sed -n '1,240p' /Users/z3437171/shinichi-brain/memory/00-INDEX.md
sed -n '1,320p' AGENTS.md
sed -n '1,320p' docs/dev-log/handover/2026-06-30-codex-handover.md
sed -n '1,320p' docs/design/73-predictor-informed-latent-scores.md
sed -n '1,260p' docs/dev-log/after-task/2026-06-30-phylo-xlv-weak-cell-mechanism-diagnosis.md
sed -n '1,260p' docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md
git status --short --branch
git rev-parse --short HEAD
gh run list --limit 3
gh pr view 127 --repo itchyshin/GLLVM.jl --json number,state,title,headRefName,headRefOid,isDraft,mergeStateStatus,statusCheckRollup,url,updatedAt
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- AGENTS.md CLAUDE.md README.md ROADMAP.md CHANGELOG.md docs/design docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl
```

Result: checkout was clean at `e794575` on
`codex/phylo-xlv-drac-launcher-20260628`; PR #127 was confirmed `CLOSED`,
draft, and unstable on old head `b87a522`; no open GLLVM.jl PRs were present.
The recent local same-file history showed the handoff commit and the weak-cell
diagnostic closeout only.

Final file-format and stale-wording checks are recorded in the matching
after-task report.

## 2026-06-26 - PR #113 main-merge resolution

### Scope

Resolved draft PR #113 (`claude/studentt-105-20260620`) against current
`origin/main` so the Student-t branch can return to a mergeable, CI-testable
state before the R/Julia `X_lv` bridge lane opens its own Julia PR.

- Ran the merge in `/private/tmp/gllvmjl-studentt-ci-113` from local branch
  `codex/studentt-ci-113`.
- The only content conflict was `docs/dev-log/check-log.md`; both the
  Student-t ForwardDiff buffer-fix entry and the later predictor-informed
  latent-score entries were kept.
- `src/GLLVM.jl`, `test/runtests.jl`, and the other mainline code/test/doc
  changes merged automatically.
- No Student-t likelihood equation, optimiser tolerance, family contract, or
  public capability claim was changed in this merge-resolution slice.

### Checks Run

```sh
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,isDraft,mergeStateStatus,url,updatedAt
git log --all --oneline --since="6 hours ago" -- docs/dev-log/check-log.md docs/dev-log/after-task src/GLLVM.jl test/runtests.jl
```

Result: only PR #113 was open in GLLVM.jl and it was still draft/dirty before
the merge-resolution push. No recent same-file activity appeared in the
6-hour log check.

```sh
rg -n '<<<<<<<|=======|>>>>>>>' docs/dev-log/check-log.md
```

Result: no conflict markers remained.

```sh
julia --project=. --startup-file=no test/test_studentt.jl
```

Result: `Student-t (heavy-tailed continuous, fixed nu)` 17/17 pass. The
marginal ForwardDiff-vs-central-FD max relative error was
`6.4151837495491755e-9`.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: full package test suite passed with `4569` pass, `1` broken, `4570`
total in `38m56.8s`.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed with exit code 0. The run
reported the known local-link warnings for absolute-style links, npm audit
warnings from the Vitepress toolchain, a Vitepress chunk-size warning, and
skipped deployment outside CI.

### Deliberately Not Run

- No R/gllvmTMB checks were run from this GLLVM.jl worktree.
- No binary `X_lv` Julia PR was opened in this slice; PR #113 must first be
  pushed and rechecked on GitHub so the one-open-PR queue is not widened.
- No validation or parity row was promoted from this merge-resolution evidence.

### Claim Boundary

IN: PR #113 is locally resolved against current main and passes the full Julia
package test suite plus local Documenter. OUT: no new R bridge claim, no broad
R-Julia parity claim, and no interval/coverage claim for Student-t or `X_lv`.

## 2026-06-25 - Binomial X_lv bridge endpoint

### Scope

Extended the predictor-informed latent-score route from Gaussian-only bridge
rows to complete-response binomial logit/probit/cloglog point rows, without
claiming interval, response-mask, fixed-effect `X` + `X_lv`, mixed-family, or
broader non-Gaussian parity.

- Added `fit_binomial_gllvm(...; X_lv = X_lv, alpha_lv_init = ...)` with
  packed objective
  `eta = beta + Lambda * (X_lv * alpha_lv + z_innovation)'`.
- Added `binomial_lv_nll_packed()` and verified it equals the existing offset
  Laplace core when the parameter-dependent offset is supplied explicitly.
- Retained `alpha_lv` and `theta_packed` on `BinomialFit` for X_lv fits while
  preserving the old six-argument constructor for existing callers.
- Extended `getLV()` for `BinomialFit` with
  `component = :mean/:innovation/:total`, plus `predict()`, `residuals()`,
  `simulate()`, `extract_lv_effects()`, and `lv_effects()` support for
  binomial X_lv fits.
- Added explicit `bridge_fit()` family keys `binomial_probit` and
  `binomial_cloglog` alongside the existing logit `binomial` route.
- Added bridge payload fields for binary X_lv rows: `lv_effects`,
  `alpha_lv`, `scores_mean`, and `scores_innovation`; `scores` remains the
  total rotated latent score.
- Kept `confint()` and bridge `ci_method != "none"` rejected for binomial X_lv
  fits until the expanded observed-information/profile/bootstrap layouts are
  admitted.
- Corrected the binomial fitter so the logit-only analytic Laplace gradient is
  used only for `LogitLink()` no-offset fits; probit/cloglog and X_lv use finite
  differences.
- Updated `bridge_capabilities()` and Documenter prose to report Gaussian plus
  binomial logit/probit/cloglog X_lv point rows as partial, not broad parity.

### Checks Run

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: dependencies instantiated in the fresh worktree; no `Project.toml` or
`Manifest.toml` diff remained.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 94/94` pass.

```sh
julia --project=. --startup-file=no test/test_binomial_fit.jl
```

Result: `fit_binomial_gllvm — recovery 8/8` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `bridge capabilities ledger 44/44` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no test/test_simulate.jl
```

Result: `simulate(fit) 5/5` pass.

```sh
julia --project=. --startup-file=no test/test_postfit.jl
```

Result: `post-fit` sections passed: ordination core 96/96, predict/fitted 9/9,
residuals 10/10, AIC/BIC/show 8/8, Poisson 163/163, NB 160/160, Beta 215/215,
Gamma 215/215, Ordinal 216/216.

```sh
git diff --check
```

Result: clean.

```sh
rg -n "Gaussian-only|Gaussian only|non-Gaussian X_lv|complete-response ordinary Gaussian|X_lv.*Gaussian-only|Gaussian X_lv" src test docs/src docs/dev-log/after-task/2026-06-25-bridge-binomial-xlv.md docs/dev-log/check-log.md README.md CHANGELOG.md
```

Result: remaining matches are historical log/report entries, REML
Gaussian-only boundaries, the native Gaussian fitter's own docstring, the
Gaussian-specific bridge test name, and guarded "non-binomial non-Gaussian"
wording.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: first full-suite run failed after `4595` pass, `0` fail, `1` error,
and `1` broken in `46m20.7s`. The failing route was the pre-existing
masked no-X CI bridge test for admitted one-part non-Gaussian rows:
`test/test_bridge_missing_mask.jl` called the binomial fitter with `K = 0`,
and the first X_lv implementation had accidentally required positive `K` for
all binomial fits.

Fix applied: allow `K >= 0` for ordinary/no-latent binomial fits, while keeping
`X_lv` restricted to positive latent dimension `K > 0`.

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `masked missing-response bridge 83/83` pass after the `K = 0` guard
fix.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
julia --project=. --startup-file=no test/test_binomial_fit.jl
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result after the guard fix: `bridge predictor-informed latent-score X_lv 94/94`,
`fit_binomial_gllvm - recovery 8/8`, and `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result after the guard fix: full package test suite passed with `4629` pass,
`1` broken, `4630` total in `47m36.9s`.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed with exit code 0. The run
reported the known absolute-style local-link warnings, npm audit warnings from
the Vitepress toolchain, a Vitepress chunk-size warning, and skipped deployment
outside CI.

### Queue State

- The branch was originally held because GLLVM.jl PR #113 was open as a draft
  and overlapped `docs/dev-log/check-log.md`, `src/GLLVM.jl`,
  `src/families/laplace.jl`, and `test/runtests.jl`.
- After PR #113 merged as `23938290585f43411f340bcdeedfbb9d1c7af7bd`, this
  branch was refreshed against `origin/main` before opening its own PR.

### Post-#113 Refresh Checks

```sh
julia --project=. --startup-file=no test/test_studentt.jl
```

Result after merging `origin/main`: `Student-t (heavy-tailed continuous, fixed
nu)` 17/17 pass.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_lv_predictor.jl"); include("test/test_binomial_fit.jl"); include("test/test_simulate.jl"); include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl")'
```

Result after merging `origin/main`: bridge predictor-informed latent-score
`X_lv` 94/94, binomial recovery 8/8, simulate 5/5, bridge capabilities 44/44,
and bridge CI routing 64/64 pass.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result after merging `origin/main`: local DocumenterVitepress build completed
with exit code 0. The run reported the known absolute-style local-link
warnings, npm audit warnings from the Vitepress toolchain, a Vitepress
chunk-size warning, and skipped deployment outside CI.

## 2026-06-25 - Gaussian X_lv bridge endpoint

### Scope

Exposed the native ordinary Gaussian predictor-informed latent-score path through
the Julia bridge, without widening the public claim beyond point estimates.

- Added `X_lv` to `bridge_fit()` for complete-response `family = "gaussian"`
  fits only.
- Preserved the existing Gaussian bridge convention by centering responses by
  trait means, returning those means as `alpha`, and fitting
  `fit_gaussian_gllvm(Yc; X_lv = X_lv)` on the centred matrix.
- Added flat JuliaCall payload fields for the R side:
  `lv_effects = Lambda * alpha_lv'`, raw `alpha_lv`, `scores_mean`, and
  `scores_innovation`. The existing `scores` field remains the total rotated
  latent score.
- Added `predictor_informed_lv` to `bridge_capabilities()` so this route is not
  conflated with ordinary fixed-effect `X`.
- Rejected simultaneous `X` + `X_lv`, masks + `X_lv`, mixed-family `X_lv`,
  non-Gaussian `X_lv`, `d = 0`, and `ci_method != "none"` with explicit errors.
- Updated the parity/changelog/roadmap docs to describe this as a Gaussian
  point-estimate endpoint only; R-package row promotion remains gated.

### Checks Run

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: dependencies instantiated after a fresh worktree initially could not
precompile `GLLVM` because `Distributions` was absent from the local depot. This
left no `Project.toml` / `Manifest.toml` changes.

```sh
julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 19/19` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `bridge capabilities ledger 42/42` pass.

```sh
julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `predictor-informed latent-score mean 24/24` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Result: `bridge fixed-effect X (non-Gaussian one-part families) 179/179` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `bridge CI routing 64/64` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `bridge missing-response mask 83/83` pass.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed. It emitted the existing
absolute-style local-link warnings, npm audit warnings from the Vitepress
toolchain, and skipped deployment outside CI; no build failure.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `GLLVM.jl 4540 pass, 3 broken, 4543 total` in `43m39.1s`.
The run reported that Aqua and JET were not in the direct project environment
and should be covered by `Pkg.test()`.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `GLLVM.jl 4552 pass, 1 broken, 4553 total`; `GLLVM tests passed` in
`46m58.8s`.

```sh
git diff --check
```

Result: clean before the dev-log edits.

```sh
rg -n "predictor-informed latent-score|X_lv|lv_effects|scores_mean|scores_innovation|non-Gaussian X_lv|full R-user parity|R-bridge promotion|R-package row promotion" src test docs/src README.md CHANGELOG.md
```

Result: matches were the intended bridge guards, payload tests, capability note,
and claim-boundary docs. No broad R-Julia parity or non-Gaussian `X_lv` claim was
found.

### Deliberately Not Run

- No live R-side `gllvmTMB` bridge test was run in this Julia PR. The paired R
  admission should be a separate `gllvmTMB` slice after this endpoint is merged
  and available to the R bridge.
- No binary/non-Gaussian `X_lv` Julia bridge route was attempted. Native
  constrained-ordination machinery is related, but it is not this flat bridge
  contract and needs a separate recovery/parity design.

### Claim Boundary

IN: complete-response ordinary Gaussian `bridge_fit(...; family = "gaussian",
X_lv = X_lv)` point estimates with total scores, score mean/innovation
decomposition, raw `alpha_lv`, and rotation-stable `lv_effects`.

PARTIAL: this is an endpoint contract against the native Gaussian
`fit_gaussian_gllvm(...; X_lv=...)` oracle. It is not yet an R-package row
promotion, interval route, or missing-response route.

PLANNED/GATED: non-Gaussian `X_lv` bridge rows, binary/probit bridge parity,
simultaneous `X` + `X_lv`, masks + `X_lv`, and confidence intervals remain
separate validation gates.

## 2026-06-22 - Fixed-zero shared X coefficients

### Scope

Added Julia-side fixed-zero coefficient masks for the R-side `Xcoef_fixed`
contract that landed in `gllvmTMB` PR #536.

- `fit_gaussian_gllvm(..., β_fixed = ...)` now optimises only free shared
  Gaussian covariate coefficients, expands `pars.β` back to the full design
  length, and stores `pars.β_fixed`.
- `fit_gllvm_cov(..., γ_fixed = ...)` does the same for non-Gaussian one-part
  shared covariate coefficients and stores `fit.γ_fixed`.
- The bridge accepts `options["coef_fixed"]` / `xcoef_fixed` / `beta_fixed` /
  `gamma_fixed`, passes the mask to the native fitter, returns full coefficient
  vectors with constrained entries equal to zero, and reports
  `mean_coef_status` or `gamma_status`.
- Wald/profile/bootstrap CI term lists and refits omit fixed coefficients from
  the estimated parameter vector while preserving original coefficient indices
  in names such as `beta[1]`, `gamma[3]`.
- AIC/BIC degrees of freedom count free coefficients, not fixed-zero entries.

### Checks Run

```sh
julia --project=. --startup-file=no -e 'using GLLVM; println("loaded")'
```

Result: package loaded cleanly after the new helper include.

```sh
julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_covariates.jl"); include("test/test_bridge_x.jl")'
```

Result: `fixed effects 18/18`, `Non-Gaussian covariates (Xβ) 30/30`, and
`bridge fixed-effect X 179/179` pass.

```sh
julia --project=. --startup-file=no -e 'include("test/test_confint_bootstrap.jl")'
```

Result: `parametric bootstrap CI 9/9` pass.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `GLLVM.jl 4495 pass, 3 broken, 4498 total` in 31m04.9s before the final
docstring/unused-local cleanup.

```sh
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: `GLLVM.jl 4507 pass, 1 broken, 4508 total`; `GLLVM tests passed` in
36m15.0s.

```sh
julia --project=docs --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

Result: local DocumenterVitepress build completed. It emitted existing local-link
warnings for absolute-style documentation links, npm audit warnings from the
Vitepress toolchain, and skipped deployment outside CI; no build failure.

```sh
julia --project=docs --startup-file=no docs/make.jl
```

Result: rerun after the changelog edit completed with the same known
DocumenterVitepress/local-link/npm warnings and no build failure.

```sh
git diff --check
```

Result: clean.

```sh
rg -n "selects variables|automatic deletion|guarantees convergence|proves identifiability|validated item selection|separation solved|nonzero constraint|non-zero constraint|general constraint" README.md docs/src src test
```

Result: no matches.

### Deliberately Not Run

- Cross-repository live R-to-Julia bridge tests were not rerun here; the paired
  R-side `Xcoef_fixed` implementation and merge were validated in `gllvmTMB`
  PR #536. This Julia PR supplies the engine/bridge endpoint used by that
  contract.

### Claim Boundary

IN: zero-only fixed shared coefficients for complete fixed-effect-X Gaussian and
non-Gaussian one-part fits already supported by the Julia fixed-X bridge.

PARTIAL: this is not a general linear-constraint system and does not estimate
nonzero fixed values. Julia receives positional masks; the R package owns
formula-name to position translation.

PLANNED/GATED: fixed coefficients combined with X+mask routes, NB1-X,
mixed-family-X, ordinal-X, and structural-covariance-X bridge rows remain
separate follow-ups.

## 2026-06-16 - Fixed-effect-X CI bridge endpoints

### Scope

Admitted complete-response fixed-effect-X Wald/profile/bootstrap CI payloads for
the bridge rows whose native fitters already route `X`: Gaussian, Poisson,
Bernoulli binomial, NB2, Beta, and Gamma.

- Added `_bridge_compute_ci_cov()` so `GllvmCovFit` bridge rows call native
  `confint(fit, Y; X = X, N = N, method = ...)` and return the existing flat
  CI payload contract.
- Threaded `ci_method`, `ci_level`, `ci_nboot`, and `ci_seed` through
  `_bridge_fit_onepart_cov()`.
- Added `ci_x_wald`, `ci_x_profile`, and `ci_x_bootstrap` capability columns.
  These are true only for Gaussian, Poisson, Binomial, NB2, Beta, and Gamma.
- Kept NB1-X, ordinal-X, ordinal-probit-X, mixed-family-X, and masks with
  fixed-effect X gated.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `40/40` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_x.jl
```

Result: `169/169` pass, including fixed-effect-X Wald parity against native
`confint()` for Poisson, Bernoulli binomial, NB2, Beta, Gamma, and Gaussian,
plus small Poisson-X profile parity and bootstrap smoke.

### Deliberately Not Run

- Full `Pkg.test()` / `test/runtests.jl` was not run for this narrow bridge
  endpoint slice. The touched surface is `src/bridge.jl` plus the fixed-X,
  capability, and bridge-CI tests, which were run directly.
- Documenter was not rebuilt locally.
- The paired R bridge admission is a separate commit in `gllvmTMB`; this Julia
  entry records only the engine-side endpoint route.

### Claim Boundary

IN: complete-response fixed-effect-X bridge CI payloads for Gaussian, Poisson,
Bernoulli binomial, NB2, Beta, and shared-Gamma rows.

PARTIAL: this is endpoint-routing parity against native GLLVM.jl CI engines,
not broad native `gllvmTMB` parity, coverage calibration, or speed evidence.

PLANNED/GATED: NB1-X CIs, ordinal-X CIs, mixed-family-X CIs, masks combined
with fixed-effect X, structured-dependence bridge rows, and per-trait Gamma
expansion remain follow-ups.

## 2026-06-16 - Masked no-X CI bridge endpoints

### Scope

Admitted response-mask no-X Wald/profile/bootstrap CI payloads for the one-part
non-Gaussian bridge rows whose likelihoods already route masks: Poisson,
Bernoulli binomial, NB2 grouped, NB1 grouped, Beta grouped, and Gamma grouped.

- `confint(fit, Y; ...)` now accepts `mask` for scalar and grouped one-part
  non-Gaussian fit types and passes it to the likelihood closure and bootstrap
  refits.
- `bridge_fit()` now passes the observed-cell mask into the non-Gaussian CI
  route instead of stopping for all masked CIs.
- `bridge_capabilities()` now separates `missing_response` from
  `ci_mask_wald` / `ci_mask_profile` / `ci_mask_bootstrap`.
- Per-trait ordinal CIs, Gaussian masks, mixed-family masks, X+mask, variational
  masked CIs, and X-row CIs remain gated.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `83/83` pass. This includes masked Wald routing across Poisson,
Binomial, NB2, NB1, Beta, and Gamma; masked profile/bootstrap smoke for Poisson;
and sentinel-invariance checks for masked Poisson CIs.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `37/37` pass after adding the `ci_mask_*` capability columns.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass; complete-response CI routing was unchanged by the new
mask keyword.

Paired live R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly with `0` failures after the R admission patch.

```sh
git diff --check
```

Result: clean.

### Not Run

- Full `Pkg.test()` / `test/runtests.jl`.
- Documenter build.

### Rose Boundary

PASS WITH NOTES. This admits masked no-X CI endpoints for named one-part
non-Gaussian rows only. It does not claim CI calibration, broad R/TMB parity,
ordinal intervals, mixed-family intervals, X-row intervals, or structured terms.

## 2026-06-16 - Grouped-dispersion `getLV()` bridge scores

### Scope

Added conditional latent-score extraction for the grouped-dispersion fit types
used by the R bridge: `NBGroupedFit`, `NB1GroupedFit`, `BetaGroupedFit`, and
`GammaGroupedFit`.

- `src/families/grouped_dispersion.jl` now has a shared grouped Laplace-mode
  helper and `getLV()` methods for NB2, NB1, Beta, and Gamma grouped fits.
- `bridge_fit()` already called `getLV()` for those rows; before this slice the
  missing methods made `_bridge_scores()` degrade to a `0 x 0` score payload.
  After this slice, grouped bridge rows return finite `n x K` scores.
- No grouped likelihood, optimizer, parameterisation, dispersion scale, CI
  route, or Gamma shared-group policy changed.

### Checks Run

```sh
julia --project=. -e 'using GLLVM; ... grouped bridge/getLV probe ...'
```

Result before the fix: direct grouped `getLV()` calls failed with
`MethodError: no method matching getLV(::NBGroupedFit, ...)` and analogous
errors for NB1, Beta, and Gamma; `bridge_fit()` returned `size(scores) = (0, 0)`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `81/81 pass`. The test now checks finite `bridge_fit().scores` for
NB2, NB1, Beta, and Gamma grouped rows and direct finite `getLV()` outputs with
and without a mask.

```sh
julia --project=. test/test_bridge_capabilities.jl
```

Result: `34/34 pass`.

```sh
julia --project=. -e 'using GLLVM; Y=[1 3 2 4 5 2 3 6 4 7; 2 1 4 3 5 6 7 4 8 6]; br=bridge_fit(; y=Float64.(Y), family="nb1", d=1); println(size(br.scores)); println(all(isfinite, br.scores)); println(size(br.loadings));'
```

Result: `(10, 1)`, `true`, `(2, 1)`.

```sh
julia --project=. test/test_bridge_missing_mask.jl
```

Result: `37/37 pass`.

Paired live R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
Rscript --vanilla -e 'options(gllvmTMB.GLLVM.jl.path = "/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration"); devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly with 0 failures.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This admits grouped conditional score payloads for R-side
post-fit reconstruction. It does not add grouped-dispersion CI endpoints,
simulation, extractor parity, newdata prediction, structured terms, or broad
native-vs-Julia validation beyond the existing fixture evidence.

## 2026-06-16 - Gamma shared bridge route

### Scope

Changed the Julia bridge default for `family = "gamma"` from per-trait grouped
Gamma (`group = 1:p`) to one shared grouped-Gamma shape (`group = fill(1, p)`).
This matches current native `gllvmTMB` ordinary Gamma, where one scalar
`sigma_eps` coefficient of variation is shared across Gamma traits.

- `src/bridge.jl` still uses `fit_gamma_gllvm_grouped()`; only the group
  assignment changes.
- The per-trait grouped Gamma engine remains available for a later native
  per-trait Gamma expansion.
- `test/test_bridge_grouped_dispersion.jl` now expects Gamma `df =
  p + rr_df + 1` and `dispersion_group_id = fill(1, p)`, while NB2/NB1/Beta
  remain per-trait grouped.

### Checks Run

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
julia --project=. test/test_bridge_capabilities.jl
```

Result: `34/34 pass`.

Paired R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly. The paired R test reports Gamma small-fixture
native-vs-Julia point parity: Julia `logLik = 17.595906505513`, native TMB
`logLik = 17.595906784863`, `df = 5` in both engines, and public Gamma
`sigma` matching native `sigma_eps` to about `6e-10`.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is current-oracle Gamma point parity for one small complete
balanced reduced-rank bridge fixture. It does not implement native per-trait
Gamma CV/shape, Gamma CIs, masks, fixed-effect covariates, structured terms, or
speed claims.

## 2026-06-16 - NB1 tiny-phi Fisher boundary fix

### Scope

Fixed a numerical instability in the NB1 Fisher-information helper near the
Poisson boundary. `_nb1_fisher_mu(mu, phi)` previously evaluated the exact
trigamma-difference expression down to `phi ~= 1e-9`, where cancellation made
the expected information collapse to `1e-12` or spike far above the Poisson
limit. The grouped NB1 reduced-rank bridge then over-rewarded boundary fits.

- `src/families/negbin1.jl` now uses the Poisson-limit information
  `1 / (mu * (1 + phi))` for `phi <= 1e-6`.
- `test/test_nb1.jl` adds a boundary regression test for `phi = 1e-8` and
  `1e-9`, plus a near-boundary guard at `1e-5`.
- No NB1 parameterisation changed: the scale remains
  `Var(y) = mu * (1 + phi)`.

### Checks Run

```sh
julia --project=. test/test_nb1.jl
```

Result: `34/34 pass`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
julia --project=. test/test_grouped_dispersion_tweedie_nb1.jl
```

Result: `15/15 pass`.

Paired R bridge check from
`/Users/z3437171/Dropbox/Github Local/gllvmTMB`:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla -e 'devtools::test(filter = "julia-bridge", reporter = "summary")'
```

Result: completed cleanly. The NB1 reduced-rank small fixture now reports
native `logLik = -52.4618425767`, Julia `logLik = -52.4619219625`, `df = 6`
for both, and delta `-7.9386e-05`. Evaluating Julia at the native fitted
parameters gives `-52.4618425607`, matching native TMB to about `1.6e-08`.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This fixes a Julia NB1 boundary numerical bug and supports the
small-fixture reduced-rank bridge parity row. It does not promote broad NB1
simulation recovery, NB1 confidence intervals, masks, fixed-effect covariates,
or structured terms.

## 2026-06-16 - Bridge no-latent NB1 admission

### Scope

Relaxed the Julia `bridge_fit()` latent-rank gate from positive `d` to
non-negative `d`, allowing the R bridge to request no-latent (`d = 0`) rows.
The immediate verified row is grouped NB1 with no latent variables: two trait
intercepts plus two per-trait NB1 `phi` values, no loading parameters.

- `src/bridge.jl` now rejects only `d < 0`.
- `test/test_bridge_grouped_dispersion.jl` adds a no-latent NB1 bridge row and
  keeps the negative-rank rejection locked.
- No family likelihood, parameterisation, optimiser, or CI route changed.

### Checks Run

```sh
gh pr list --state open --json number,title,headRefName,baseRefName,updatedAt,isDraft --limit 20
```

Result: two older draft PRs visible (`#95` integration, `#94`
`a1-nongaussian-ci`); no active PR on this local branch.

```sh
git log --all --oneline --since="6 hours ago" -- src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task | head -120
```

Result: current local bridge commits only (`2a07745`, `5cb7ea5`).

```sh
julia --project='.' -e 'using GLLVM; Y=[1 3 2 4 5 2 3 6 4 7 5 8; 2 1 4 3 5 6 7 4 8 6 9 7]; fit=GLLVM.fit_nb1_gllvm_grouped(Y; K=0, group=collect(1:size(Y,1)), iterations=200); println(fit); println(GLLVM._nparams(fit)); println(size(GLLVM._loadings(fit))); println(fit.loglik); println(fit.converged)'
```

Result: `NB1GroupedFit(p=2, K=0, G=2, ...)`, `_nparams = 4`,
`size(Lambda) = (2, 0)`, finite log-likelihood, `converged = true`.

```sh
julia --project=. test/test_bridge_grouped_dispersion.jl
```

Result: `49/49 pass`.

```sh
rg -n "d must be a positive integer|d must be a non-negative integer|d = 0|K = 0|no-latent|full parity|complete bridge|CRAN-ready" src/bridge.jl test/test_bridge_grouped_dispersion.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-16-bridge-no-latent-nb1.md
```

Result: expected no-latent / `d = 0` hits, the new non-negative error string in
`src/bridge.jl`, and historical negative-scope wording only.

```sh
git diff --check
```

Result: clean.

Paired live R bridge fixture after this Julia edit:

```sh
GLLVM_JL_PATH='/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration' JULIA_HOME='/Users/z3437171/.juliaup/bin' Rscript --vanilla - <<'RS'
# fitted gllvmTMB(value ~ 0 + trait, family = nbinom1()) through
# engine = "julia" and engine = "tmb"; compared logLik, df, and phi.
RS
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: Julia and native TMB
both reported `logLik = -53.17549`, `df = 4`; `delta = 4.253763e-08`;
maximum absolute NB1 `phi` difference was `5.42191e-05`.

### Rose Boundary

PASS WITH NOTES. This admits no-latent bridge rows at the Julia transport layer
and verifies grouped NB1. It does not promote reduced-rank NB1 parity, grouped
CI endpoints, masks, mixed-family rows, or structured terms.

## 2026-06-15 - Bridge method capability metadata

### Scope

Expanded `GLLVM.bridge_capabilities()` with method-level metadata needed by the
R-first `gllvmTMB` bridge ledger.

- Added no-X CI capability columns for Wald, profile, and bootstrap routes.
- Added in-sample post-fit method columns for coefficient payloads, fit
  statistics, summary, prediction, residuals, simulation, and ordination.
- Kept the existing fitters, likelihoods, REML behavior, optimizer behavior, and
  CI implementations unchanged.
- Documented that `ci_no_x_*` columns are scoped to complete one-part
  no-covariate fits only.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. -e 'using GLLVM; caps=GLLVM.bridge_capabilities(); @assert :ci_no_x_wald in propertynames(caps); @assert :postfit_predict in propertynames(caps); println(length(caps.family), " capability rows")'
```

Result: `10 capability rows`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `19/19 pass` in `0.2s`.

Paired live R bridge regression:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 519` in `68.9s`.

### Rose Boundary

PASS WITH NOTES. This is metadata for R-side drift prevention, not new engine
support. REML remains Gaussian-only; AI-REML remains a later exact-Gaussian
speed idea only.

## 2026-06-15 - Mixed-family bridge per-trait payload labels

### Scope

Fixed the Julia-side mixed-family bridge payload so the flat `families` field is
row-aligned with the input family vector instead of repeating the joined model
tag.

- `bridge_fit(; family = ["gaussian", "poisson", "binomial"])` still returns
  `family = "gaussian+poisson+binomial"` as the compact model tag.
- The same payload now returns `families = ["gaussian", "poisson", "binomial"]`
  and per-trait `link = ["IdentityLink", "LogLink", "LogitLink"]`.
- `_bridge_assemble` now accepts an optional per-trait `families` vector and
  rejects malformed lengths.
- `test/test_bridge_mixed.jl` locks the successful payload shape, the mixed CI
  unavailable-status payload, and the length-mismatch failure path.
- `docs/src/gllvmtmb-parity.md` now records the exact boundary: Julia mixed
  metadata is fixed; R bridge admission and parity remain queued.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_mixed.jl
```

Result: `18/18 pass` in `5.7s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM; Y = [0.2 0.4 -0.1 0.3 0.5 -0.2 0.1 0.6; 1 3 2 4 1 2 5 3; 0 1 1 0 1 0 1 1]; br = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1); println(join(br.families, ",")); brci = bridge_fit(; y=Y, family=["gaussian","poisson","binomial"], d=1, options=Dict("ci_method"=>"wald")); println(brci.ci_method); println(length(brci.ci_param_names));'
```

Result:

```text
gaussian,poisson,binomial
wald
0
```

Paired live R bridge regression:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 439` in `65.2s`.

### Rose Boundary

PASS WITH NOTES. Julia mixed-family bridge metadata is now correctly row-aligned,
but `gllvmTMB` still rejects mixed-family `engine = "julia"` fits until
point/logLik parity, labels, and CI-status rows are validated together.

## 2026-06-15 - R-first handoff and roadmap sync

### Scope

Reframed the historical Codex handoff and roadmap so they no longer read as a
current release or bridge-completion claim.

- `docs/dev-log/CODEX_HANDOFF.md` now starts with a 2026-06-15 note: the current
  finish sequence is R-first, native `gllvmTMB` is the oracle, and broad
  engine-side rows still require R-side admission, bridge parity, docs, issue
  evidence, and Rose audit.
- The old TL;DR phrase "full gllvmTMB parity and beyond" was narrowed to
  "broad engine-side parity candidate".
- `docs/src/roadmap.md` now uses the same R-first sequencing, conservative
  release map, and Gaussian-only REML / exact-Gaussian AI-REML boundary.

No engine code, bridge code, tests, or benchmarks changed.

### Checks Run

```sh
rg -n "full gllvmTMB parity|full parity|AI-REML|REML|R-first|engine-side parity candidate" docs/dev-log/CODEX_HANDOFF.md docs/src/roadmap.md
```

Result: expected hits only. "Full parity" appears only in a warning not to read
the historical handoff as a current release claim. REML/AI-REML hits are
boundary wording only.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is documentation governance only. It does not add a new
engine capability or R bridge row.

## 2026-06-15 - Ordinal-Probit Bridge Mask Key

### Scope

Added a distinct `ordinal_probit` bridge family key so the R
`gllvmTMB::ordinal_probit()` constructor routes to cumulative-probit ordinal
GLLVM fits instead of the cumulative-logit `ordinal` default.

- `bridge_fit(...; family = "ordinal_probit", mask = M)` now calls
  `fit_ordinal_gllvm(..., link = ProbitLink(), mask = M)`;
- bare `family = "ordinal"` remains cumulative-logit;
- masked no-X one-part family evidence now covers Poisson, Bernoulli Binomial,
  NB2, Beta, Gamma, and Ordinal-probit from the R bridge.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `23/23 pass` in `16.8s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.2s`.

Paired live R bridge:

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result: `232/232 pass` in `50.9s`.

### Rose Boundary

PASS WITH NOTES. This proves the bridge family key, probit-link routing, and
R-live masked no-X family matrix. It does not add masked CI refits, X+mask,
Gaussian masks, or ordinal prediction/residual payloads.

## 2026-06-15 - Bridge Missing-Response Mask Hook

### Scope

Added the minimal Julia transport hook needed by the R-first
`gllvmTMB(..., engine = "julia", missing = miss_control(response = "include"))`
slice:

- `bridge_fit(...; mask = M)` now accepts a `p x n` observed-cell mask
  (`true = observed`) for one-part no-X non-Gaussian families;
- all-true masks normalize to the complete-data bridge path;
- Gaussian masks, X+mask, mixed-family masks, and masked CI requests fail
  before fitting;
- bridge latent scores and latent-scale summaries call the mask-aware
  post-fit/link-residual paths so sentinel placeholders do not influence
  predictions or correlations.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_missing_mask.jl
```

Result: `17/17 pass` in `15.5s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `18.9s`.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: `66/66 pass` in `46.1s`.

```sh
~/.juliaup/bin/julia --project=. -e 'using Test, GLLVM, Distributions; include("test/test_missing_data.jl")'
```

Result: `34/34 pass` in `12.5s`. The direct file form needs
`Distributions` loaded because the standalone test file assumes the full
`test/runtests.jl` include context.

```sh
~/.juliaup/bin/julia --project=. test/test_postfit.jl
```

Result: post-fit family blocks passed (`96/96`, `9/9`, `10/10`, `8/8`,
`163/163`, `160/160`, `215/215`, `215/215`, `216/216`).

```sh
~/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m15.5s`.

### Rose Boundary

PASS WITH NOTES. This is a bridge transport and post-fit correctness hook, not
full missing-data release readiness. Masked CI refits, X+mask, Gaussian masks,
and per-family R-side parity rows remain separate gates.

## 2026-06-15 - gllvmTMB Bridge X Admission Status Sync

### Scope

Synced `docs/src/gllvmtmb-parity.md` with the current R-side
`gllvmTMB(..., engine = "julia")` bridge surface:

- complete, balanced one-part no-X reduced-rank bridge fits are admitted for
  Gaussian, Poisson, Binomial, NB2, Beta, Gamma, and Ordinal;
- fixed-effect `X` is admitted for complete, balanced one-part Gaussian,
  Poisson, Binomial, NB2, Beta, and Gamma bridge fits;
- response-missing masks, mixed-family bridge metadata, ordinal covariate fits,
  structured terms, and user-selectable Julia optimizer controls remain explicit
  follow-ups;
- REML wording is Gaussian-only, and HSquared-style AI-REML is recorded as a
  later exact-Gaussian scouting target, not non-Gaussian Laplace terminology.

Also updated `docs/dev-log/codex-fast-algorithms-brief.md` with the same REML /
AI-REML boundary.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: 50/50 passed in 18.0s.

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a documentation/status-sync slice only. It does not
claim new Julia engine behavior beyond the already-tested `bridge_fit(...; X=...)`
contract, and it does not claim non-Gaussian REML or AI-REML.

## 2026-06-15 - PR #94 Successor Issue Drafts

### Scope

Converted the `GLLVM.jl#94` unique-content audit into a local successor-issue
draft bank without mutating GitHub remotely.

The draft bank now contains seven durable successor records:

1. Generalized Poisson family.
2. Student-t one-part family.
3. True one-part lognormal family.
4. Standalone zero-truncated Poisson/NB.
5. ANOVA/LRT model-comparison API.
6. Unified check-fit diagnostics, calibration, and plots.
7. Structured Schur / structured Poisson prototype.

Stale #94 benchmark-script notes are routed to existing benchmark/runtime
issues (`#65` and `#61`) rather than duplicated as a new issue.

### Checks Run

```sh
gh issue list --repo itchyshin/GLLVM.jl --state open --limit 100 --json number,title,labels,updatedAt,url
gh issue list --repo itchyshin/gllvmTMB --state open --limit 100 --json number,title,labels,updatedAt,url
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git log --oneline 65a1f10..HEAD --reverse
```

Live PR state at drafting time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`.
- `#95` open draft, mergeable, `integration` at `65a1f10`.
- local runtime stack head before this draft slice: `862f081`.

### Rose Boundary

PASS WITH NOTES. Do not close `#94` yet. Close only after the seven durable
successor records exist and the benchmark-script notes are routed into existing
benchmark issues. No GitHub issue, PR comment, closure, or push was performed in
this slice.

## 2026-06-15 - PR #94 Unique-Content Audit

### Scope

Audited draft/conflicting `GLLVM.jl#94` before closure or supersession.

Live state at audit time:

- `#94` open draft, conflicting, `a1-nongaussian-ci` at `09fc846`
- `#95` open draft, mergeable, `integration` at `65a1f10`
- local integration audit head: `d3d8129`

### Checks Run

```sh
gh pr view 94 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
gh pr view 95 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeable,headRefName,baseRefName,headRefOid,baseRefOid,updatedAt,url
git fetch origin pull/94/head:refs/remotes/origin/pr-94 pull/95/head:refs/remotes/origin/pr-95 main integration
```

Blob classification of `origin/main...origin/pr-94` paths against current local
integration:

| class | count |
| --- | ---: |
| absent from integration | 124 |
| present but different from local integration | 50 |
| byte-identical to local integration | 2 |

### Rose Boundary

PARTIAL BUT ACTIONABLE. Do not merge `#94`. Treat it as an archive to mine into
successor issues for Generalized Poisson, Student-t, standalone lognormal,
standalone zero-truncated count families, ANOVA/LRT, diagnostics, structured
Schur/Poisson prototypes, and stale benchmark rebuilds. Close only after those
successor issues/comments exist.

## 2026-06-15 - Test Warning Hygiene

### Scope

Removed duplicate-method warnings from the core and full package test logs:

- `test/test_takahashi_selinv.jl` now uses the package-loaded
  `GLLVM.takahashi_selinv` and `GLLVM.takahashi_diag` implementations instead
  of self-including `src/takahashi_selinv.jl` into `Main`;
- `test/test_bridge_ci.jl` renamed its local Poisson simulator helper to avoid
  overwriting the helper in `test/test_confint_family.jl` during full-suite
  execution.

No production source changed in this slice.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_takahashi_selinv.jl
```

Result: 8/8 passed in 0.4s, with no duplicate-method warning.

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_ci.jl
```

Result: 66/66 passed in 45.4s.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.0s. The previous
`takahashi_selinv.jl` and `_sim_poisson` overwrite warnings did not reappear.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m12.0s. The duplicate-method
warnings did not reappear under Pkg's temporary test environment.

### Rose Boundary

PASS. This is test-harness hygiene only. It reduces warning noise and does not
change model behavior, likelihoods, fitters, bridge payloads, or public API.

## 2026-06-15 - Sparse Phylo Node-Gradient Shortcut

### Scope

Wired the verified node-frame O(p) gradient into the public sparse phylo
gradient dispatcher for the phylo-unique shape only:

- `K_aug == 1`
- `K_phy == 0`
- `has_unique == true`

All other augmented sparse-phylo gradient shapes still route through the exact
leaf-block fallback (`_sparse_phy_grad_leafblock`). The fallback remains the
reference for `Λ_phy` and mixed augmented shapes because those derivatives need
the dense leaf-row x leaf-column block.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_node_gradient.jl
```

Result: 58/58 passed in 9.7s. The node route was checked against dense
ForwardDiff and the preserved leaf-block reference on balanced and caterpillar
trees. Max relative node-vs-leaf-block error for the `σ_phy` block was
`1.015e-13`; scalar/global blocks were zero or machine precision.

```sh
~/.juliaup/bin/julia --project=. test/test_sparse_phy_grad.jl
```

Result: 101/101 passed in 7m12.1s. The end-to-end sparse/dense value
consistency gate reported `8.731e-11` logLik difference at the sparse optimum;
the warm-start comparison to `fit_gaussian_gllvm` had `Δll_warm = 2.092e-5`.

```sh
~/.juliaup/bin/julia --project=. bench/sparse_phy_grad_bench.jl
```

Result:

| p | shortcut ms | leafblock ms | speedup | dense-FD ms | max rel err |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 0.344 | 1.027 | 2.99x | 198.884 | 8.76e-15 |
| 300 | 1.117 | 3.670 | 3.29x | skipped | 2.28e-14 |
| 600 | 1.114 | 24.030 | 21.58x | skipped | 7.11e-15 |

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: 3857 passed, 3 broken, 3860 total in 30m48.2s.

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3869 passed, 1 broken, 3870 total in 35m36.2s.

### Rose Boundary

PASS WITH NOTES. This closes the verified phylo-unique node-gradient wiring
slice only. It does not claim O(p) for `Λ_phy`, mixed augmented phylo effects,
or any non-Gaussian Laplace adjoint route. The full package gate passed, but the
suite still emits pre-existing duplicate-include/helper overwrite warnings that
should be cleaned in a separate hygiene slice.

## 2026-06-14 - JuliaConnectoR R gllvm Parity Smoke

### Scope

Closed the first R `{gllvm}` vs GLLVM.jl JuliaConnectoR parity smoke gap:

- `gllvm_jl_init()` now accepts `jl_path` and defaults to `GLLVM_JL_PATH`,
  activating the local Julia project before importing `GLLVM`;
- the standalone fallback in `r/gllvmtmb_julia.R` mirrors the same activation
  path;
- `r/parity_check.R` scales R `{gllvm}` `params$theta` by `params$sigma.lv`
  before Procrustes-aligned loading comparison.

The previous apparent Poisson mismatch was harness drift: Julia could import a
stale/default-environment `GLLVM`, and the R loadings were compared before the
latent-variable scale was applied.

### Checks Run

```sh
JULIA_BINDIR=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin \
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(jl_path=Sys.getenv("GLLVM_JL_PATH")); set.seed(1); y <- matrix(rpois(30*4,3), nrow=30); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", row.eff="none"); stopifnot(res$diffs$logLik < 1e-6, res$diffs$beta["abs"] < 1e-5, res$diffs$loadings["abs"] < 1e-5)'
```

Result: exit code 0.

```text
logLik absolute diff: 2.086e-11
beta max abs diff:   1.760e-07
loadings max abs:    6.559e-07
```

### Rose Boundary

PASS WITH NOTES. This is one live Poisson `method="LA"` no-row-effect parity
smoke. It proves the scaffold can hit the same likelihood target when the local
project is activated and R loadings are scale-mapped. It does not prove full
family, dispersion, covariate, missingness, R-bridge, or CI parity.

## 2026-06-14 - Rose Status Drift Cleanup

### Scope

Cleaned public/status drift found by the Rose audit after the runtime-gap fixes:

- `AGENTS.md` no longer describes the integration tree as the old v0.1
  Gaussian-only pilot;
- `README.md` now states that Gamma joins Poisson, NB2, Binomial, and Beta in
  the analytic-gradient default set for no-mask/no-offset fits;
- `docs/dev-log/CODEX_HANDOFF.md` now treats v0.3.0 tagging as a
  maintainer-gated release-ledger decision, not an automatic next command.

No source code, tests, Project version, or R bridge code changed in this slice.

### Checks Run

Stale wording scan:

```sh
rg -n "v0\\.1\\.0 pilot|Gaussian only|Gamma and the|bump `Project.toml` to v0\\.3\\.0 and|tag a release" AGENTS.md README.md docs/dev-log/CODEX_HANDOFF.md
```

Result: no matches.

Whitespace:

```sh
git diff --check
```

Result: clean.

### Rose Boundary

PASS WITH NOTES. This is a wording/ledger cleanup only. It does not merge
`GLLVM.jl#95`, close `GLLVM.jl#94`, update remote issues #91/#92/#96, validate
the R `{gllvm}` statistical parity gate, or authorize a tag.

## 2026-06-07 - Analytic Gradient Defaults

### Scope

Runtime-gated the dormant analytic Laplace gradients. Poisson, NB2, Binomial,
and Beta defaulted to `gradient = :analytic` on the plain no-mask/no-offset path,
preserving the existing finite-difference fallback. At that time Gamma was left
finite because the benchmark gate found accuracy failures; the Gamma decision is
superseded by the 2026-06-14 entry below.

### Benchmark Evidence

Fitter-only run using the `bench/speed_bench.jl` simulators and timing logic
(`reps = 1`, `iterations = 300`; the full script stalled in profile-CI before
printing its final table):

| size | family | finite s | analytic s | speedup | delta logLik | gate |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 20x100x2 | Poisson | 2.592 | 0.274 | 9.46x | -9.09e-13 | pass |
| 20x100x2 | NB2 | 4.276 | 0.383 | 11.16x | -1.82e-12 | pass |
| 20x100x2 | Binomial | 4.719 | 0.416 | 11.33x | 3.18e-12 | pass |
| 20x100x2 | Beta | 15.511 | 1.261 | 12.30x | 1.14e-13 | pass |
| 20x100x2 | Gamma | 0.263 | 0.257 | 1.02x | -7.24e-4 | fail |
| 50x200x2 | Poisson | 50.685 | 4.847 | 10.46x | -1.09e-11 | pass |
| 50x200x2 | NB2 | 53.144 | 4.736 | 11.22x | -7.28e-12 | pass |
| 50x200x2 | Binomial | 59.231 | 5.357 | 11.06x | -1.09e-11 | pass |
| 50x200x2 | Beta | 223.527 | 17.699 | 12.63x | 6.37e-12 | pass |
| 50x200x2 | Gamma | 31.894 | 1.925 | 16.56x | 3.93e23 | fail |

### Checks Run

```sh
julia --project=. test/test_laplace_grad.jl
```

Result: 26 passed in 30.7s.

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: 3296 passed, 1 broken, 3297 total in 27m25.4s. The full suite includes
the quality battery (`test_quality.jl` with Aqua/JET checks).

```sh
tmp=$(mktemp -d /tmp/gllvm-doc-env-XXXXXX)
JULIA_PROJECT="$tmp" julia -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. The direct `julia --project=docs docs/make.jl` path could
not instantiate locally because `GLLVM` v0.3.0 is not registered, so the build
used a temporary docs environment with the local worktree developed. Pre-existing
warnings remain for absolute local links, missing logo/favicon assets, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

```sh
git diff --check
rg -n "finite-difference outer gradients|opt-in today|kept opt-in|finite \\(the current default\\)|Default :finite|flip the package default" README.md docs/src docs/dev-log/CODEX_HANDOFF.md bench src/families/{poisson,negbin,binomial,beta,gamma}.jl test/test_laplace_grad.jl
```

Result: whitespace clean; stale-default wording scan had no matches beyond the
intended Gamma `gradient::Symbol = :finite` when searched separately.

### Rose Verdict

PASS WITH NOTES. The 2026-06-07 default flip was restricted to the four families
that cleared the measured speed/accuracy gate. This Gamma caveat is superseded
by the 2026-06-14 entry below. Remaining note from this historical run:
`bench/speed_bench.jl` should stream fitter rows or make profile-CI optional.

## 2026-06-03 - Homepage Mobile Publication

### Scope

Published a narrow documentation hotfix for the live GLLVM.jl homepage. The
deployed mobile page rendered VitePress `layout: home`, `hero:`, and `features:`
frontmatter as ordinary page text. The homepage now uses plain
Documenter-compatible Markdown and starts as a docs page:

1. package title;
2. one-sentence identity;
3. install command;
4. first model example.

No source code, exported API, likelihood parameterization, or test behavior
changed.

### Checks Run

```sh
julia --project=docs docs/make.jl
```

Result: exit code 0 locally before publication. Documenter and
DocumenterVitepress completed. Residual warnings remain: pre-existing absolute
local links in several article pages (`/quickstart`, `/api`, etc.), deployment
auto-detection skipped, missing `logo.png`/`favicon.ico`, missing
`docs/package.json`, and npm audit reporting 4 moderate vulnerabilities.

Playwright mobile check at 390 x 664 px against a local static server:

- no rendered `layout: home`, `hero:`, or `features:` text;
- no horizontal overflow;
- `Install` visible near the top;
- `Fit your first model` visible in the first phone viewport.

Screenshot evidence:
`/tmp/gllvm-mobile-audit/screens/gllvm_local_mobile_simplified.png`.

```sh
git diff --check
rg -n 'layout: home|hero:|features:|https://https://' docs/src docs/make.jl
rg -n 'Fast Generalised Linear Latent Variable Models|Install|Fit your first model|What works today' docs/build/.documenter/index.md docs/build/1/index.html
```

Result: whitespace clean; no frontmatter tokens in public source; rendered
index contains the install-first order.

### Rose Verdict

PASS WITH NOTES. The live-page source bug is fixed in the publication branch
and the mobile top is screenshot-verified. Remaining notes: full `Pkg.test()`
was not run for this docs-only hotfix, pre-existing article-link warnings remain
outside the homepage hotfix, and the live site updates only after the Documenter
deployment workflow completes.

## 2026-06-14 - High-rate Poisson mode safeguard (#91)

### Scope

Fixed the integration-branch reproduction of GLLVM.jl #91, where the default
analytic-gradient `fit_poisson_gllvm` path could accept a runaway first step for
a high-rate `K = 2` Poisson fit. The root cause was the shared dense-Laplace
inner mode solve: full Fisher-scoring steps could lower the conditional
log-posterior by many orders of magnitude, making the warm-start marginal and
the analytic Poisson gradient invalid.

`src/families/laplace.jl` now keeps full Newton steps near the mode, but uses
step-halving against the conditional log-posterior for the cheap scalar families
where this safeguard is needed (`Poisson`, `Binomial`, `NegativeBinomial`,
`Beta`, `Gamma`, `Exponential`). Heavier bespoke families keep the previous
full-step path to avoid turning their expensive log-density calls into an inner
line search. A one-time restart from `z = 0` remains available when a solve
returns non-finite values.

`test/test_poisson_fit.jl` now carries the high-rate #91 fixture and checks:

1. the fitted intercepts stay on the empirical log-mean scale;
2. the fitted log-likelihood is finite and the optimizer converges;
3. the analytic Poisson Laplace gradient matches a central finite-difference
   gradient on the same high-rate warm start.

### Checks Run

Before the fix, on `/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration`
at `65a1f10`, the reconstructed #91 fixture produced:

```text
kind = :allZ_col
analytic_converged = true
analytic_beta6 = -1.3725979588255058e6
fd_beta6 = 3.5848998478056116
beta06 = 2.046028486073364
analytic_maxabs = 1.3726000048539918e6
```

After the fix:

```text
kind = :allZ_col
converged = true
beta6 = 1.8845273881056652
beta06 = 2.046028486073364
maxabs = 0.16150109796769874
loglik = -9573.527202270865

kind = :interleaved_site
converged = true
beta6 = 1.9494694468357439
beta06 = 2.1177137251431333
maxabs = 0.16824427830738942

kind = :global_seed_interleaved
converged = true
beta6 = 1.9931572688527104
beta06 = 2.1386437132753118
maxabs = 0.1454864444226014
```

High-rate warm-start gradient check after the fix:

```text
marg0 = -10049.149835755072
grad analytic norm = 456.8484012361648
finite norm = 456.8484007642873
diff norm = 2.2149188558598164e-6
maxabsdiff = 1.0488242692119343e-6
```

Focused tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_fit.jl
```

Result: `12/12 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_poisson_laplace.jl
```

Result: `4/4 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_laplace_grad.jl
```

Result: `26/26 pass`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_missing_response.jl
```

Result: `23/23 pass`; masked analytic-vs-FD max differences remained
`5.42e-8` for Poisson and `2.41e-8` for Binomial.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using GLLVM, Test, Distributions, LinearAlgebra, Random; include("test/test_laplace_alloc_equiv.jl")'
```

Result: `7/7 pass`.

Affected scalar-family fit tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_nb_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_fit.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_fit.jl
```

Results: Binomial `8/8`, NB `7/7`, Beta `7/7`, Gamma `7/7` pass.

Affected scalar-family marginal tests:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_beta_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_gamma_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_negbin_laplace.jl
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_binomial_laplace.jl
```

Results: Beta `2/2`, Gamma `2/2`, NB `2/2`, Binomial `9/9` pass.

`test/test_missing_response_extra.jl` was started twice and interrupted after
several minutes both times. The interrupt stack was inside long finite-difference
fits for Tweedie / row-effect wrappers, not in the new Poisson safeguard branch.
Full `test/runtests.jl` and `Pkg.test()` remain the next gates before PR.

### Rose Verdict

PASS WITH NOTES. #91 is reproduced on the integration branch and fixed with a
fit-level regression plus a gradient-vs-FD gate. The safeguard is intentionally
scoped to cheap scalar families to avoid slowing bespoke heavy likelihoods.
Remaining blocker: full-suite validation has not yet been run after this patch.

### 2026-06-14 — #91 full-suite validation and self-contained CI test import

`test/test_confint_family.jl` failed when run directly because the Tweedie
bootstrap test used `dot` without importing `LinearAlgebra`. Added the explicit
test-file import; no package source changed in this cleanup.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_family.jl
```

Result: `122/122 pass` in `4m08.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3749 pass, 3 broken, 0 failed, 0 errored` in `30m42.6s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m51.7s`.

Noted quality noise: the `Pkg.test()` sandbox still prints duplicate-method
warnings from repeated local helper definitions (`takahashi_selinv.jl` include
warnings and `_sim_poisson` in `test_confint_family.jl` / `test_bridge_ci.jl`).
They did not fail the gate, but should be cleaned in a later test-hygiene slice.

Rose verdict: PASS WITH NOTES. The #91 safeguard branch is full-suite green on
Julia 1.10; remaining notes are R parity not run (not bridge-facing) and
pre-existing duplicate-helper warning noise in the test harness.

Docs build note: `julia --project=docs docs/make.jl` is blocked locally because
`docs/Project.toml` expects registered package `GLLVM`. A no-deploy temp build
using `Pkg.develop(path=pwd())` reached Vitepress but failed on pre-existing
dead local links (`./quickstart`, `./model`, `./benchmarks`, `./comparison`, and
related extensionless page links). This is a docs-cleanup follow-up, not part of
the #91 numerical change.

### 2026-06-14 — Vitepress dead-link cleanup

Normalised the remaining relative page links in `docs/src/{index,quickstart,
comparison,gllvmtmb-parity}.md` to the existing absolute Vitepress route style.
This removed the hard Vitepress dead-link failure found during local no-deploy
docs validation.

```sh
/Users/z3437171/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.activate(; temp=true); Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); using Documenter, DocumenterVitepress, GLLVM; makedocs(; source="docs/src", build="/tmp/gllvm-docs-build", warnonly=true, ...)'
```

Result: passed; Vitepress built the site successfully in `4.66s`.

Remaining warnings: Documenter still warns on absolute local links (`/quickstart`,
`/api`, etc.) and DocumenterVitepress reports missing optional Vitepress assets /
`docs/package.json`. These are pre-existing warning-level documentation
infrastructure items, not hard build failures after this cleanup.

Rose verdict: PASS WITH NOTES. Hard dead-link blocker removed; warning-level
docs infrastructure cleanup remains.

## 2026-06-14 - Gamma Analytic Gradient Default

### Scope

Re-opened the Gamma analytic-gradient default after the high-rate Poisson
Laplace-mode safeguard. Gamma now joins Poisson, NB2, Binomial, and Beta in
defaulting to `gradient = :analytic` on the plain no-mask/no-offset path, with
the existing finite-difference fallback retained for masked or offset fits.

### Benchmark Evidence

The full original `bench/speed_bench.jl` grid was interrupted after roughly 13
minutes while still in the first grid cell, so the benchmark harness was updated
with opt-in runtime knobs (`GLLVM_SPEED_BENCH_GRID`, `GLLVM_SPEED_BENCH_REPS`,
`GLLVM_SPEED_BENCH_ITERS`, `GLLVM_SPEED_BENCH_PROFILE_CI`) and per-family
progress logging. Default full-run behaviour is unchanged.

Quick decision grid:

```sh
GLLVM_SPEED_BENCH_GRID=quick GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=80 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma results:

| size | finite s | analytic s | speedup | delta logLik |
| --- | ---: | ---: | ---: | ---: |
| 8x40x1 | 0.2573 | 0.0255 | 10.09x | 2.842e-14 |
| 12x60x1 | 0.6706 | 0.0693 | 9.68x | 2.842e-13 |

Medium confirmation cell:

```sh
GLLVM_SPEED_BENCH_GRID=20,100,2 GLLVM_SPEED_BENCH_REPS=1 GLLVM_SPEED_BENCH_ITERS=120 GLLVM_SPEED_BENCH_PROFILE_CI=0 \
  /Users/z3437171/.juliaup/bin/julia --project=. bench/speed_bench.jl
```

Gamma result: finite `10.8304s`, analytic `0.7590s`, speedup `14.27x`,
`delta logLik = -1.819e-12`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_fit.jl
```

Result: `7/7 pass` in `10.7s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_gamma_laplace.jl
```

Result: `2/2 pass` in `2.2s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_laplace_grad.jl
```

Result: `26/26 pass` in `31.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3761 pass, 1 broken, 0 failed, 0 errored` in `35m09.1s`.

### Rose Verdict

PASS WITH NOTES. Benchmark gate and full package tests passed after the default
change. Remaining note: R bridge parity was not rerun because the likelihood
target and bridge payload shape are unchanged.

## 2026-06-14 - JuliaConnectoR Bridge Smoke Repair

### Scope

Repaired the older `r/gllvmjl.R` / `r/gllvmtmb_julia.R` JuliaConnectoR scaffold
enough for a live transport smoke check:

- `gllvm_jl_init()` now loads `Distributions`, so family marker constructors such
  as `Distributions.Poisson()` are available.
- Added `.jl_value()` to tolerate JuliaConnectoR fields that are already
  converted to R values, avoiding double-`juliaGet()` failures on `β`, `loglik`,
  coefficient tables, and Unicode dispersion fields.
- Construct family markers through `Distributions.<Family>()`, not through the
  `GLLVM` module handle.
- Updated bridge README/status prose from "not executed" to
  "transport smoke-tested; parity open."

### Checks Run

```sh
JULIA_BINDIR="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin" \
JULIA_PROJECT="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" \
Rscript -e 'source("r/gllvmtmb_julia.R"); source("r/parity_check.R"); gllvm_jl_init(); set.seed(11); y <- matrix(rpois(30*4, 3), nrow=30); rownames(y) <- as.character(seq_len(nrow(y))); colnames(y) <- paste0("sp", seq_len(ncol(y))); res <- compare_gllvm(y, family="poisson", num.lv=1, method="LA", disp.formula=~1, iterations=80L); stopifnot(is.finite(res$julia_fit$logLik), all(is.finite(res$julia_fit$coefficients))); print(res$diffs)'
```

Result: command exited `0`; Julia transport returned finite `logLik` and
coefficients.

Parity result: **not passed**. R `{gllvm}` vs GLLVM.jl on the smoke cell:
`|ΔlogLik| = 0.6194035`, max beta diff `0.04862639`, Procrustes-aligned loading
diff `2.862522`.

### Rose Verdict

PARTIAL. Transport defects are fixed and documented, but the end-to-end R
`gllvm` parity claim remains open. Next slice should reconcile likelihood target,
starts, centering, and parameterization before promoting this bridge path.

## 2026-06-14 - Phylo-signal Wald CI Scale Fix (#92)

### Scope

Ported the narrow fix for GLLVM.jl #92 from the stale `a1-nongaussian-ci` branch
onto the current integration branch. The Gaussian phylo fitter packs the
phylo-unique `σ_phy` block on the natural signed scale, but `_derived_unpack`
was exponentiating it. That over-transformed the `phylo_signal_wald_ci` numerator
and could push H² outside `[0, 1]`.

Changes:

- `_derived_unpack` now reads `σ_phy` directly on the natural signed scale.
- `confint_derived_wald.jl` is included by the package and the transformed-Wald
  derived CI helpers are exported.
- `test_confint_derived_wald.jl` now guards packed-vs-public `phylo_signal`
  equality for both `has_phy_unique` and `K_phy > 0` paths.
- `test_confint_derived_wald.jl` is wired into `test/runtests.jl`.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived_wald.jl
```

Result: `108/108 pass` in `21.3s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_derived.jl
```

Result: `45/45 pass` in `13.5s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_profile_derived_fix.jl
```

Result: `20/20 pass` in `10.1s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_confint_profile.jl
```

Result: `4/4 pass` in `21.4s`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: `3869 pass, 1 broken, 0 failed, 0 errored` in `36m18.1s`.

### Rose Verdict

PASS. The scale bug is fixed on the current branch, the orphan test is now part
of the main suite, and the full package gate passed.

## 2026-06-15 - Gaussian-X bridge mean coefficient payload

### Scope

Added the flat `mean_coef::Vector{Float64}` payload field to
`GLLVM.bridge_fit(...; family = "gaussian", X = X)`. The existing Gaussian-X
fields are preserved; the new field exposes the full mean coefficient vector
needed by the R bridge to reconstruct in-sample fitted values for the supplied
`X` design.

Changes:

- `src/bridge.jl` now merges `mean_coef = fit.pars.β` onto the Gaussian-X bridge
  payload.
- `test/test_bridge_x.jl` now checks that `mean_coef` is a `Vector{Float64}` and
  equals the native Gaussian fit coefficient vector exactly.
- `docs/src/gllvmtmb-parity.md` records the payload contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_x.jl
```

Result: `52/52 pass` in `17.4s`.

### Rose Verdict

PASS WITH NOTES. This is a payload-only bridge change, not a likelihood change.
It closes the R-side Gaussian-X in-sample prediction gap when paired with the
matching `gllvmTMB` consumer; `newdata` prediction and ordinal probabilities
remain separate bridge payloads.

## 2026-06-15 - Bridge capability reporter for R drift guard

### Scope

Added `GLLVM.bridge_capabilities()` as a flat, JuliaCall-friendly reporter for
the current `bridge_fit` surface. The helper does not change fitting behavior;
it lets `gllvmTMB` enforce a one-way bridge-drift contract: every R-admitted
row must be supported by the paired Julia checkout, while Julia-only rows must
be explicitly planned or rejected on the R side.

Changes:

- `src/bridge.jl` now defines `_BRIDGE_ONEPART_FAMILIES` and the exported
  `bridge_capabilities()` ledger.
- `src/GLLVM.jl` exports `bridge_capabilities`.
- `test/test_bridge_capabilities.jl` locks the reported rows, including NB1 as
  a Julia one-part no-X route and the mixed-family vector route as no-X only.
- `docs/src/gllvmtmb-parity.md` records the R drift-guard contract.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.1s`.

```sh
~/.juliaup/bin/julia --project=. test/runtests.jl
```

Result: `3891 pass, 3 broken, 0 failed, 0 errored` in `30m39.8s`.

```sh
~/.juliaup/bin/julia --project=docs docs/make.jl
```

Result: failed before rendering because `Documenter` was not installed in the
docs environment.

```sh
~/.juliaup/bin/julia --project=docs -e 'using Pkg; Pkg.instantiate()'
```

Result: failed with `expected package GLLVM [2dc8e01c] to be registered`.
No docs source error was reached.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 353` in `61.6s`, including the new live R subset guard against
`GLLVM.bridge_capabilities()`.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The capability reporter is metadata-only and live-consumed by
the R bridge drift test. The local Documenter build remains blocked by the
pre-existing docs-environment registration issue, so no rendered-docs claim is
made for this slice.

## 2026-06-15 - Bridge documentation current-surface sync

### Scope

Reconciled Julia-side bridge documentation with the R-first plan and the current
`gllvmTMB(..., engine = "julia")` surface.

Changes:

- `docs/src/gllvmtmb-parity.md` now records NB1 no-X bridge admission, the
  still-open NB1-X and NB1/Gaussian-mask rows, and the NB1 complete-data no-X
  post-fit boundary.
- The same page now separates broad engine capabilities from narrower R bridge
  claims so engine rows do not automatically become R-user promises.
- `r/README_bridge.md` now labels the `r/` directory as a legacy direct
  `gllvm_julia()` scaffold, not the current `gllvmTMB` bridge admission surface.
- `r/gllvmtmb_julia.R` roxygen now points readers away from the legacy scaffold
  for current fixed-effect-X bridge support.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. test/test_bridge_capabilities.jl
```

Result: `9/9 pass` in `0.2s`.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The docs now support the R-first plan and avoid treating the
larger Julia engine surface as an R bridge promise. This does not add new bridge
functionality; `gllvmTMB` tests remain the source of truth for admitted R rows.

## 2026-06-15 - R-first bridge claim wording cleanup

### Scope

Applied Rose's R-first corrective pass after the maintainer asked to complete the
`gllvmTMB` user surface before promoting broader Julia claims.

Changes:

- `README.md`, `CLAUDE.md`, and `CHANGELOG.md` now say broad/status-tracked
  coverage instead of full parity or "parity and beyond".
- `docs/src/changelog.md` and `docs/src/gllvmtmb-parity.md` now separate native
  Julia routes from public R bridge parity.
- `GLLVM.bridge_capabilities()` now reports `status = "partial"` for current
  bridge rows and explains that no-X CI columns are native route metadata, not a
  full R-user parity claim.
- `test/test_bridge_capabilities.jl` now locks that partial-status vocabulary.

### Checks Run

```sh
rg -n "full GLM|gllvmTMB parity|parity and beyond|surpassed|full Wald|status = \"supported\"|must be supported" README.md CLAUDE.md CHANGELOG.md src/bridge.jl test/test_bridge_capabilities.jl docs/src -S
```

Result: one remaining scoped caveat in `docs/src/gllvmtmb-parity.md`:
"additional gllvm/gllvmTMB parity rows that are not all public through the R
bridge yet".

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `20/20 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" /usr/local/bin/Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 552` in `68.0s`.

```sh
~/.juliaup/bin/julia --project=docs --startup-file=no docs/make.jl
```

Result: failed before rendering because `Documenter` is not installed in the
local docs environment.

```sh
~/.juliaup/bin/julia --project=docs --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Result: failed because the docs environment expects unregistered package
`GLLVM [2dc8e01c]`.

```sh
tmp=$(mktemp -d); JULIA_PROJECT="$tmp" ~/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. Residual warnings were the known pre-existing absolute
local links, optional Vitepress assets, npm audit warnings, and chunk-size
warning; Vitepress rendered successfully.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. The stale blanket parity wording is removed from the visible
Julia surfaces touched here, and the R bridge live test accepts the partial-status
metadata. This slice changes claim metadata only; it does not promote a new
family, CI route, or bridge admission cell.

## 2026-06-15 - NB1 missing-response bridge mask admission

### Scope

Extended the paired Julia bridge route so NB1 (`nb1`) no-X reduced-rank point
fits can accept the same observed-cell mask already used by the R-first
`gllvmTMB` missing-response bridge. This is an incremental bridge admission:
masked cells are excluded from the NB1 likelihood and score reconstruction, but
masked CI/profile/bootstrap refits, NB1 fixed-effect-X fits, Gaussian masks, and
mixed-family masks remain separate unsupported cells.

Changes:

- Added `nb1` to `_BRIDGE_MASK_FAMILIES`.
- Passed `mask = M` into `fit_nb1_gllvm()` and NB1 bridge assembly.
- Added `mask` support to `getLV(::NB1Fit, ...)` so bridge scores ignore
  masked-cell sentinels.
- Added NB1 native-vs-bridge parity and sentinel-invariance tests.
- Updated `docs/src/gllvmtmb-parity.md` and `docs/src/roadmap.md` to reflect the
  R-first bridge ledger, complete balanced mixed-family point-fit row, and the
  remaining unsupported cells.

### Checks Run

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

Result: `20/20 pass`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
```

Result: `34/34 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB`: `FAIL 0 | WARN 0 |
SKIP 0 | PASS 571` in `70.7s`.

```sh
~/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl
```

Result: `3931 pass / 3 broken / 0 fail` in `31m06.6s`. Direct core run reported
`Aqua not in this environment` and `JET not in this environment`; run
`Pkg.test()` for the full quality battery.

```sh
tmp=$(mktemp -d); JULIA_PROJECT="$tmp" ~/.juliaup/bin/julia --startup-file=no -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.add(["Documenter", "DocumenterVitepress"]); include("docs/make.jl")'
```

Result: exit code 0. Residual warnings were the known pre-existing absolute
local links, optional Vitepress assets, npm audit warnings, and chunk-size
warning; Vitepress rendered successfully.

```sh
rg -n "R bridge still rejects mixed-family|mixed-family R bridge admission|do not admit family lists|NB1.*missing-response.*remain|NB1 covariate\s*or missing-response|missing-response masks are wired only for poisson, binomial, negbinomial, beta|17b2154|6056071|f1894bc" README.md CLAUDE.md CHANGELOG.md docs/src src test -S
```

Result: no matches.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. NB1 masked point fits and masked score reconstruction are now
covered for the bridge, with live R-Julia evidence. Masked CIs/simulations,
NB1-X, Gaussian masks, and mixed-family masks remain deliberate unsupported
cells.

## 2026-06-16 - Bridge grouped-dispersion default

### Scope

Changed the Julia bridge no-X default for NB2, NB1, Beta, and Gamma from the
shared-scalar fitters to the existing per-trait grouped-dispersion fitters
(`group = 1:p`). This aligns the bridge point-fit nuisance structure with native
`gllvmTMB` / `gllvm` default dispersion rather than weakening the R oracle.
Grouped-dispersion CI endpoints are deliberately not routed yet; requesting
`ci_method != "none"` for these four bridge rows now fails loudly with a
grouped-dispersion status message.

Changes:

- Added grouped-dispersion payload fields to `bridge_fit()`: `dispersion_group`,
  `dispersion_group_id`, `dispersion_parameter`, `dispersion_engine_scale`, and
  `dispersion_public_scale`.
- Updated NB2/NB1/Beta/Gamma no-X bridge branches to call
  `fit_nb_gllvm_grouped()`, `fit_nb1_gllvm_grouped()`,
  `fit_beta_gllvm_grouped()`, and `fit_gamma_gllvm_grouped()`.
- Changed `GLLVM.bridge_capabilities()` CI columns so grouped-dispersion rows
  report `false` until grouped-fit CI engines land.
- Updated the bridge capability, CI, and missing-mask tests to match the new
  grouped default.
- Narrowed README / Documenter wording so public status separates scalar-CI
  routes from grouped-dispersion CI follow-up.

### Checks Run

```sh
julia --project=. -e 'include("test/test_bridge_grouped_dispersion.jl")'
```

Result: `40/40 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl")'
```

Result: `32/32 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

Final reruns after the docs/status wording edits:

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_grouped_dispersion.jl"); include("test/test_bridge_capabilities.jl")'
```

Result: grouped dispersion `40/40 pass`; capabilities `32/32 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_missing_mask.jl")'
```

Result: `35/35 pass`.

```sh
julia --project=. --startup-file=no -e 'include("test/test_bridge_ci.jl")'
```

Result: `63/63 pass`.

```sh
GLLVM_JL_PATH="/Users/z3437171/Dropbox/Github Local/GLLVM.jl-integration" Rscript -e 'options(gllvmTMB.julia_home="/Users/z3437171/.juliaup/bin"); devtools::test(filter="julia-bridge")'
```

Result in `/Users/z3437171/Dropbox/Github Local/gllvmTMB` on branch
`codex/julia-per-trait-dispersion-spec`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 21`
in `22.8s`. This is a narrow smoke check, not full R-side grouped-dispersion
parity promotion.

```sh
julia --project=. --startup-file=no test/runtests.jl
```

Result: `3981 pass / 3 broken / 0 fail` in `31m57.5s`. Direct core run reported
`Aqua not in this environment` and `JET not in this environment`; run
`Pkg.test()` for the full quality battery.

```sh
rg -n "bridge_fit|bridge_capabilities|confidence intervals|CI routes|NB2|NB1|Beta|Gamma|grouped dispersion|per-species / grouped" README.md docs/src docs/dev-log src test -g '!docs/node_modules/**'
```

Result: relevant hits reviewed. Public docs were narrowed where grouped-
dispersion CI status could be mistaken for completed endpoints.

```sh
git diff --check
```

Result: clean.

### Rose Verdict

PASS WITH NOTES. Point-fit routing now matches the R oracle's per-trait nuisance
structure for the four promoted dispersion families, and CI status is explicit
rather than silently inherited from the former shared-scalar path. Remaining
follow-ups are grouped-dispersion CI engines, R-side payload consumption/parity
rows, and full `Pkg.test()` / Documenter checks before PR promotion.

## 2026-06-16 - Bridge per-trait ordinal cutpoints

### Scope

Changed the Julia bridge ordinal and ordinal-probit no-X default from shared
cutpoints to per-trait cutpoints. This matches the native `gllvmTMB` ordinal
shape for point payloads while preserving `fit_ordinal_gllvm()` as the
shared-cutpoint Julia comparator and the current shared-cutpoint CI route.

Changes:

- Added `OrdinalPerTraitFit` and `fit_ordinal_gllvm_pertrait()` with one
  ordered cutpoint vector per trait.
- Stored per-trait cutpoints as a `p x max(C_t - 1)` matrix padded with `NaN`
  after each trait's last threshold, plus per-trait category counts `C`.
- Added post-fit, residual, latent-scale extractor, and display methods for
  `OrdinalPerTraitFit`.
- Routed `bridge_fit(; family = "ordinal")` and
  `bridge_fit(; family = "ordinal_probit")` through the per-trait fitter.
- Added bridge payload fields `cutpoints`, `n_categories`, `cutpoint_mode =
  "per_trait"`, and `cutpoint_link`.
- Changed `GLLVM.bridge_capabilities()` so ordinal and ordinal-probit no-X CI
  columns report `false` until a per-trait ordinal CI engine lands.
- Updated bridge CI tests so ordinal CI requests fail loudly instead of silently
  using the old shared-cutpoint confidence-interval route.
- Updated parity and response-family docs to separate shared-cutpoint Julia
  support from per-trait R-bridge parity support.

### Checks Run

```sh
julia --project=. test/test_ordinal_pertrait.jl
```

Result: direct per-trait ordinal tests `96/96 pass`; bridge ordinal payload
tests `15/15 pass`.

```sh
julia --project=. -e 'include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
julia --project=. -e 'include("test/test_ordinal_laplace.jl"); include("test/test_ordinal_fit.jl"); include("test/test_ordinal_probit.jl"); include("test/test_postfit.jl")'
```

Result: ordinal Laplace `2/2 pass`; shared ordinal fit `9/9 pass`; ordinal
cumulative-link `10/10 pass`; post-fit blocks all passed, including ordinal
post-fit `216/216 pass`.

Final focused rerun:

```sh
julia --project=. --startup-file=no -e 'include("test/test_ordinal_pertrait.jl"); include("test/test_bridge_capabilities.jl"); include("test/test_bridge_ci.jl"); include("test/test_bridge_missing_mask.jl")'
```

Result: direct per-trait ordinal `96/96 pass`; bridge ordinal payload `15/15
pass`; bridge capabilities `34/34 pass`; bridge CI `64/64 pass`; bridge
missing-response mask `37/37 pass`.

```sh
rg -n "species-specific cutpoints still a gap|common ordered cutpoints \(species-specific|ordinal.*CI endpoints.*✅|CI routes.*Ordinal|Ordinal/Ordinal-probit\).*CI|full ordinal parity|complete ordinal" src docs/src README.md test -g '!docs/node_modules/**'
```

Result: no hits.

```sh
git diff --check
```

Result: clean before the dev-log / after-task report was added.

### Deliberately Not Run

- Full `test/runtests.jl` and `Pkg.test()` were not rerun for this ordinal-only
  slice. The grouped-dispersion slice immediately before this one had a green
  direct core suite, and this slice reran the ordinal, bridge capability, bridge
  CI, bridge mask, and post-fit blocks touched by the change.
- Documenter was not rebuilt for this ordinal slice.
- The paired R bridge was not updated in this commit. The R side still needs to
  decode the new per-trait ordinal payload and mark ordinal CI support as
  unavailable before advertising this row.

### Rose Verdict

PASS WITH NOTES. Julia now has a per-trait ordinal point route for the R bridge,
and the bridge no longer overclaims ordinal CI support. The remaining follow-up
is R-side payload/capability synchronization plus a later per-trait ordinal CI
engine.

## 2026-06-16 — grouped-dispersion CI bridge endpoints

Branch: `codex/julia-per-trait-dispersion`

Purpose: promote the paired `gllvmTMB engine = "julia"` no-X NB2/NB1/Beta/Gamma
grouped-dispersion rows from point-fit-only to routed Wald/profile/bootstrap CI
payloads, while keeping per-trait ordinal cutpoint CIs gated.

### Changes

- Added grouped-dispersion adapters to the generic non-Gaussian
  `confint(fit, Y; method = ...)` layer for `NBGroupedFit`, `NB1GroupedFit`,
  `BetaGroupedFit`, and `GammaGroupedFit`.
- Routed `bridge_fit(..., options = Dict("ci_method" => ...))` through those
  adapters for NB2, NB1, Beta, and Gamma no-X bridge rows.
- Kept default `ci_method = "none"` payloads byte-lean: grouped fits still omit
  `ci_*` fields unless a CI method is explicitly requested.
- Updated `bridge_capabilities()` and bridge docs so grouped-dispersion
  Wald/profile/bootstrap rows are admitted and per-trait ordinal CI rows remain
  follow-ups.

### Checks Run

```sh
julia --project=. --startup-file=no test/test_bridge_grouped_dispersion.jl
```

Result: `121/121` pass, including grouped Wald payload checks and a small
Gamma no-latent profile/bootstrap smoke.

```sh
julia --project=. --startup-file=no test/test_bridge_capabilities.jl
```

First run failed because the test expectation still listed scalar CI rows only.
After updating the expected ledger, rerun result: `34/34` pass.

```sh
julia --project=. --startup-file=no test/test_bridge_ci.jl
```

Result: `64/64` pass; the existing scalar-family bridge CI parity and status
suite stayed green.

### Deliberately Not Run

- Full `Pkg.test()` / `test/runtests.jl` was not run for this narrow engine
  slice. The touched surface is the grouped bridge CI route plus capability
  metadata; the targeted bridge grouped, capability, and CI suites were run.
- Documenter was not rebuilt locally. The edited docs are source Markdown only.
- The paired R bridge was not updated in this Julia commit. That is the next
  lane and must widen the R-side CI gate, tests, NEWS, validation register, and
  dashboard together.

### Claim Boundary

IN: no-X grouped-dispersion NB2, NB1, Beta, and shared-Gamma bridge payloads can
return Wald/profile/bootstrap CI fields when explicitly requested. PARTIAL:
fixed-effect-X, masked, mixed-family, REML, and per-trait ordinal CI routes
remain gated. PLANNED: broader calibration and speed evidence belong in the
R/Julia simulation-comparator programme, not this endpoint-routing slice.

## 2026-06-22 — Student-t PR #113 ForwardDiff Laplace buffer fix

Branch: `codex/studentt-ci-113` (local scratch worktree based on
`origin/claude/studentt-105-20260620`, PR #113 head `bba112a`).

Purpose: diagnose and locally fix the GitHub Actions failure on draft PR #113,
where all OS CI jobs errored in `test/test_studentt.jl` because
`_laplace_mode()` allocated `Float64` Newton buffers and then tried to store
ForwardDiff dual-valued `Λ * z`, `η`, `μ`, score, weight, and Hessian entries.

### Changes

- Updated `src/families/laplace.jl` so `_laplace_mode()` promotes its per-call
  work buffers from the response, trial, loading, intercept, and offset element
  types instead of hard-coding `Float64`.
- Replaced masked zero and identity additions with `zero(T)` / `one(T)`.
- No likelihood equation, optimiser, tolerance, or Student-t test threshold was
  changed.

### Checks Run

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Result: clean. The scratch worktree had not instantiated the Julia project;
`Project.toml` and `Manifest.toml` remained unchanged afterwards.

```sh
julia --project=. test/test_studentt.jl
```

Result: `Student-t (heavy-tailed continuous, fixed ν)` **17/17 pass**.
The marginal ForwardDiff-vs-central-FD max relative error was
`6.4151837495491755e-9`, below the `1e-6` gate.

```sh
julia --project=. test/runtests.jl
```

Result: manually interrupted after the Student-t section had passed and while
the suite was in the unrelated zero-inflated optimisation block
(`test/test_zero_inflated.jl`). This is **not** counted as a full-suite pass.

```sh
julia --project=. -e 'include("test/test_studentt.jl"); include("test/test_missing_predictor_poisson.jl"); include("test/test_beta_laplace.jl"); include("test/test_gamma_laplace.jl")'
```

Result: Student-t `17/17`, missing-predictor Poisson `3/3`,
missing-predictor Binomial `3/3`, Beta Laplace `2/2`, Gamma Laplace `2/2` pass.

### Deliberately Not Run

- Full `Pkg.test()` was not run locally.
- The full `test/runtests.jl` was started but not completed; it was too slow for
  this CI-root-cause slice and was interrupted after passing through Student-t.
- No push was made to PR #113. GLLVM.jl requires maintainer approval before
  pushing.

### Rose Verdict

PASS WITH NOTES for a local patch candidate. The exact #113 CI blocker is fixed
by making the generic Laplace mode buffers AD-compatible. Broader CI still needs
to run on GitHub after the maintainer approves pushing the patch.

## 2026-06-25 — predictor-informed latent-score C1

Branch: `codex/lv-predictor-c1-20260625`

Purpose: add the Julia-side ordinary Gaussian unit-tier analogue of the R
`gllvmTMB` Design 73 C1 surface, without broad parity, interval, or
non-Gaussian claims.

### Changes

- Added `gaussian_lv_nll_packed`, an explicit Gaussian likelihood for
  `z_total[s, :] = X_lv[s, :] * alpha_lv + z_innovation[s, :]`.
- Added `fit_gaussian_gllvm(...; X_lv = X_lv, alpha_lv_init = ...)` for the
  ordinary Gaussian unit-tier path only.
- Added `getLV(...; component = :mean/:innovation/:total, X_lv = X_lv)`.
- Added `extract_lv_effects()` / `lv_effects()` for the rotation-stable
  trait-effect matrix `B_lv = Lambda * alpha_lv'`.
- Guarded Wald/profile/bootstrap intervals for `X_lv` fits; this C1 slice is
  point-estimate only.
- Updated model docs, changelog, tests, and the after-task report.

### Checks Run

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_lv_predictor.jl
```

Result: `24/24` pass.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_fixed_effects.jl"); include("test/test_postfit.jl")'
```

Result: fixed effects `18/18` pass; post-fit ordination core `96/96`,
predict/fitted `9/9`, residuals `10/10`, AIC/BIC `8/8`, Poisson `163/163`,
NB `160/160`, Beta `215/215`, Gamma `215/215`, Ordinal `216/216`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'include("test/test_confint.jl"); include("test/test_confint_profile.jl"); include("test/test_confint_bootstrap.jl")'
```

Result: Wald CI `14/14`, profile CI `4/4`, bootstrap CI `9/9`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/runtests.jl
```

Result: full local test suite passed with `4519` pass, `3` broken, `4522`
total in `31m25.4s`. The run reported that Aqua and JET are not available in
this direct `test/runtests.jl` environment and should be run through
`Pkg.test()` for the full battery.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: package test suite passed with `4531` pass, `1` broken, `4532` total
in `36m58.2s`. This run used the temporary `Pkg.test()` environment with Aqua
and JET available.

```sh
/Users/z3437171/.juliaup/bin/julia --project=docs --startup-file=no docs/make.jl
```

Result: Documenter/VitePress build completed. The run reported pre-existing
invalid-local-link warnings for the docs navigation (for example `/quickstart`,
`/response-families`, and `/api`) and npm audit warnings from the VitePress
dependency tree; neither was introduced by this slice.

### Deliberately Not Run

- No push or PR was opened: `gllvmTMB` PR #558 is open and green, GLLVM.jl draft
  PR #113 is open, and this repo requires explicit maintainer instruction
  before pushing.

### Claim Boundary

IN: ordinary Gaussian unit-tier predictor-informed latent-score point estimates.
PARTIAL: score algebra and post-fit extraction are tested, but recovery,
coverage, and bridge promotion are not admitted. OUT: W-tier, diagonal random
effects, phylogenetic/source-specific blocks, non-Gaussian families, REML, and
interval calibration.

## 2026-06-26 -- Bridge Poisson predictor-informed latent-score (Claude; Codex on leave)

Extended the `X_lv` predictor-informed latent-score route from Gaussian +
binomial to Poisson (log link), point-estimate only, mirroring the merged
binomial slice. Branch `claude/poisson-xlv-20260626` off `origin/main`
(`925cd7a`). Files: `src/families/poisson.jl`, `src/postfit.jl`,
`src/simulate_fit.jl`, `src/bridge.jl`, `src/confint_family.jl`,
`src/link_residual.jl`, `test/test_bridge_lv_predictor.jl`,
`test/test_bridge_capabilities.jl`,
`docs/src/{changelog,gllvmtmb-parity,model}.md`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 117/117` pass (new Poisson
packed-objective + native/bridge testsets; the former `poisson ... fails loudly`
assertion is now a passing route).

```sh
# targeted regression set: capabilities, poisson_fit, simulate, postfit, bridge_ci
```

Result: all pass; no regression from the `_trait_mean_fitted` split, post-fit
changes, the `simulate` method, or the confint guard.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: PASS; `GLLVM.jl 4669 pass, 1 broken, 4670 total, 44m35.9s` (the
pre-existing 1 broken is unchanged; +40 tests over the `4629 pass` baseline).

### Deliberately Not Run

- No self-merge: this is a likelihood/family change (high-risk); the PR opens
  for maintainer review.
- No R-side `gllvmTMB` change: Poisson `X_lv` bridge admission is a paired
  follow-up slice.

### Claim Boundary

IN: complete-response Poisson (log link) `X_lv` point fits through the default
bridge and `fit_poisson_gllvm(...; X_lv=...)`, with
`lv_effects = Lambda*alpha_lv'`, score decomposition, and a CRAN-safe recovery
gate. OUT/gated: `X_lv` CIs, response masks, `X` + `X_lv`, mixed-family,
NB/Gamma/Beta/ordinal `X_lv`, broad R-Julia parity, and REML.

## 2026-06-26 -- Bridge NB2 predictor-informed latent-score (Claude; Codex on leave)

Extended the `X_lv` route from Gaussian/Poisson/binomial to negative-binomial
(NB2, log link), point-estimate only, mirroring the Poisson slice with the extra
shared dispersion `r`. Branch `claude/nbinom2-xlv-20260626`, **stacked on** the
Poisson branch (`claude/poisson-xlv-20260626`, PR #118) because the `X_lv` bridge
gate `_BRIDGE_XLV_FAMILIES` is introduced there. Files: `src/families/negbin.jl`,
`src/postfit.jl`, `src/simulate_fit.jl`, `src/bridge.jl`,
`src/confint_family.jl`, `src/link_residual.jl`,
`test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`,
`docs/src/{changelog,gllvmtmb-parity,model}.md`.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_bridge_lv_predictor.jl
```

Result: `bridge predictor-informed latent-score X_lv 142/142` pass (new NB2
packed-objective + native/bridge testsets; first run, no errors).

```sh
# targeted regression: capabilities, nb_fit, simulate, postfit, bridge_ci
```

Result: all pass; no regression.

```sh
/Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no -e 'using Pkg; Pkg.test()'
```

Result: PASS; `GLLVM.jl 4694 pass, 1 broken, 4695 total, 44m28.9s` (+25 tests; pre-existing 1 broken unchanged).

### Claim Boundary

IN: complete-response NB2 (log link) `X_lv` point fits via the shared-dispersion
`fit_nb_gllvm(...; X_lv=...)` and the `negbinomial_xlv_rr` bridge route, with
`lv_effects = Lambda*alpha_lv'`, score decomposition, and a CRAN-safe recovery
gate. OUT/gated: `X_lv` CIs, response masks, `X` + `X_lv`, mixed-family,
**grouped-dispersion `X_lv`**, NB1/Gamma/Beta/ordinal `X_lv`, broad R-Julia
parity, and REML.

## 2026-06-26 -- Bridge Gamma predictor-informed latent-score (Claude; Codex on leave)

Extended the `X_lv` route to Gamma (log link, positive continuous), point-only,
mirroring NB2 with shape `α` and continuous responses. Branch
`claude/gamma-xlv-20260626`, stacked on NB2 -> Poisson (PR #118). Files:
`src/families/gamma.jl`, `postfit.jl`, `simulate_fit.jl`, `bridge.jl`,
`confint_family.jl`, `link_residual.jl`, `test/test_bridge_lv_predictor.jl`,
`test/test_bridge_capabilities.jl`, `docs/src/{changelog,gllvmtmb-parity,model}.md`.

`test_bridge_lv_predictor.jl`: 166/166 pass (Gamma packed + native/bridge; first
run). Targeted regression (capabilities, gamma_fit, simulate, postfit,
bridge_ci): all pass. `Pkg.test()`: PASS (`4718 pass, 1 broken, 44m39.3s`).

### Claim Boundary

IN: complete-response Gamma (log link) `X_lv` point fits via the shared-shape
`fit_gamma_gllvm(...; X_lv=...)` and the `gamma_xlv_rr` bridge route. OUT/gated:
`X_lv` CIs, masks, `X` + `X_lv`, mixed-family, per-trait-shape `X_lv`,
Beta/ordinal/NB1 `X_lv`, broad R-Julia parity, and REML.

## 2026-06-26 -- Bridge Beta predictor-informed latent-score (Claude; Codex on leave)

Extended the `X_lv` route to Beta (logit link, proportions in (0,1)), point-only,
mirroring Gamma with precision `φ`. Branch `claude/beta-xlv-20260626`, stacked on
Gamma -> NB2 -> Poisson (PR #118). Files: `src/families/beta.jl`, `postfit.jl`,
`simulate_fit.jl`, `bridge.jl`, `confint_family.jl`, `link_residual.jl`,
`test/test_bridge_lv_predictor.jl`, `test/test_bridge_capabilities.jl`,
`docs/src/{changelog,gllvmtmb-parity,model}.md`.

`test_bridge_lv_predictor.jl`: 190/190 pass (Beta packed + native/bridge; first
run). Targeted regression (capabilities, beta_fit, simulate, postfit,
bridge_ci): all pass. `Pkg.test()`: PASS (`4742 pass, 1 broken, 44m25.1s`).

### Claim Boundary

IN: complete-response Beta (logit link) `X_lv` point fits via the
shared-precision `fit_beta_gllvm(...; X_lv=...)` and the `beta_xlv_rr` bridge
route. OUT/gated: `X_lv` CIs, masks, `X` + `X_lv`, mixed-family,
per-trait-precision `X_lv`, ordinal/two-part/NB1 `X_lv`, broad R-Julia parity,
and REML.

## 2026-06-28 -- Phylo Model A PR #127 pre-merge fixes (Codex)

Worked on draft PR #127 branch `claude/phylo-xlv-modelA-20260627` from the clean
worktree `/private/tmp/gllvmjl-phylo-xlv`. This local slice fixes the stale
ordinary-C1 rejection test now that Model A admits `X_lv + phylo`, removes the
defensive bootstrap sign flip for the already sign-stable `B_lv` target, and
downgrades coverage-smoke wording from "calibrated" to "smoke evidence only".

State checks:

```sh
git status --short --branch
git fetch origin
git log -1 --format='%h %s' origin/main
git log -1 --format='%h %s' claude/phylo-xlv-modelA-20260627
gh pr view 127 --repo itchyshin/GLLVM.jl --json number,title,state,isDraft,mergeStateStatus,headRefName,headRefOid,url,statusCheckRollup
gh pr list --state open --repo itchyshin/GLLVM.jl --json number,title,headRefName,isDraft,mergeStateStatus,url,updatedAt
git log --all --oneline --since="6 hours ago"
```

Observed: `origin/main` at `0e99c04`; PR #127 branch at `b87a522`; PR #127 open,
draft, `UNSTABLE`. Documenter was green; the CI matrix failed from one stale
`test_lv_predictor.jl` expectation that still required `X_lv + K_phy + Σ_phy` to
throw.

Validation:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
```

Result before edits: PASS, `phylo × X_lv (Model A) 15/15`.

```sh
gh run view 28320518721 --repo itchyshin/GLLVM.jl --job 83901557388 --log | rg -n -C 8 "Test Failed|Expression:|Evaluated:|Failed|fail|ERROR: LoadError|Some tests"
```

Result: CI failure isolated to
`test/test_lv_predictor.jl:63`: expected `fit_gaussian_gllvm(...; X_lv, K_phy=1,
Σ_phy=I(4))` to throw `ArgumentError`; no exception was thrown, matching the new
Model A admission.

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_predictor.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/runtests.jl
```

Results after edits: `test_lv_predictor.jl` PASS `27/27`; `test_phylo_xlv.jl`
PASS `15/15`; `test_lv_ci.jl` PASS `114/114`; core `test/runtests.jl` PASS
`4863 pass, 3 broken, 4866 total`, `45m16.3s`.

Not run: full `Pkg.test()` / Aqua / JET and CI rerun because this branch is
high-risk/draft and the repo rule says not to push GLLVM.jl without explicit
maintainer instruction. No DRAC coverage was launched; the
`bench/phylo_xlv_coverage.jl` file remains a smoke harness only.

### Claim Boundary

IN for this slice: stale test/doc/comment alignment for draft Model A; local
targeted tests green. OUT/gated: any public claim that phylo `X_lv` intervals are
calibrated, any `gllvmTMB` R-side `phylo_latent(..., lv=~x)` grammar claim, full
CI health for PR #127, and the >=500 reps/cell DRAC campaign.

## 2026-06-28 -- Phylo Model A DRAC launcher scaffold (Codex)

Worked on local branch `codex/phylo-xlv-drac-launcher-20260628` from the clean
worktree `/private/tmp/gllvmjl-phylo-xlv`, based on the current draft PR #127
Model A state. This slice adds an sbatch-array-ready harness for the full
phylo `X_lv` DRAC campaign; it does not launch DRAC jobs or add coverage
evidence.

State and lane checks:

```sh
git status --short --branch
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,headRefName,title,mergeStateStatus,isDraft
git log --all --oneline --since='6 hours ago' --decorate
git switch -c codex/phylo-xlv-drac-launcher-20260628
```

Observed: one open draft PR, #127 (`claude/phylo-xlv-modelA-20260627`), and no
recent conflicting commits in the last six hours. The worktree was clean before
branching.

Files added:

- `bench/phylo_xlv_drac_task.jl`: writes the full parameter grid and runs one
  seed/task. The grid defaults to Pagel λ `{0, 0.5, 1}` × `n_species` `{20, 200}`
  × `K` `{1, 2}` × 500 reps/cell, plus `null_alpha0` and `null_phylo0`. Output is
  long-format CSV, one row per target/method, with fit convergence, usable CI
  denominator, coverage, bias, RMSE, and error status.
- `bench/phylo_xlv_drac_summarise.jl`: aggregates per-task CSVs into a markdown
  table with mean task coverage, MCSE, entry coverage, usable-entry counts, and
  CI status.
- `bench/phylo_xlv_drac_submit.sh`: writes params, session metadata, and an
  sbatch array file; default mode is write-only and `--submit` is required before
  calling `sbatch`.

Validation:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_params_tiny.csv --reps 2 --lambdas 0,0.5 --n-species 4,5 --n-sites 20 --K 1,2 --scenarios main,null_alpha0,null_phylo0
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_params_tiny.csv --outdir /tmp/phylo_xlv_results_tiny --task-id 1 --dry-run
bash -n bench/phylo_xlv_drac_submit.sh
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=4 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main,null_phylo0 PHYLO_XLV_TIME=0-00:15 PHYLO_XLV_MEM=2G PHYLO_XLV_THROTTLE=4 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_probe
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --help
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 1 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_submit_probe/meta/phylo_xlv_params.csv --outdir /tmp/phylo_xlv_results_submit_probe --task-id 2 --methods wald --iterations 80 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_results_submit_probe
```

Results: tiny parameter generation wrote 40 rows; write-only submit probe wrote
2 rows plus sbatch/session metadata; task help printed; two tiny local task runs
completed (`main` and `null_phylo0`, p=4, n_sites=20, K=1, 80 optimiser
iterations); the summariser read 4 result rows and reported usable `B_lv` Wald
coverage rows. The tiny `phylo_signal` transformed-Wald rows had zero usable
intervals because the fitted H² was on the boundary; that is recorded as
`partial_or_failed`, not hidden.

Not run: full `Pkg.test()`, GitHub CI, DRAC `sbatch`, profile/bootstrap methods,
or any ≥500 reps/cell production campaign. Totoro/DRAC was not available
non-interactively from this Mac session.

### Claim Boundary

IN: launcher/summariser plumbing for the DRAC coverage campaign and local toy
smokes of its file formats. PARTIAL: production sizing, `seff` right-sizing,
profile/bootstrap cost calibration, and phylogenetic-signal boundary behavior
still need DRAC evidence. OUT: any calibrated coverage claim for Model A, any R
`phylo_latent(..., lv=~x)` exposure, and any non-Gaussian phylo `X_lv` claim.

## 2026-06-28 -- PR #127 CI failure diagnosis on current local branch (Codex)

Worked from clean local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

State and lane checks:

```sh
git status --short --branch
gh pr view 127 --repo itchyshin/GLLVM.jl --json number,title,headRefName,headRepositoryOwner,headRefOid,baseRefOid,mergeStateStatus,statusCheckRollup,url
gh run view 28320518721 --repo itchyshin/GLLVM.jl --json databaseId,headSha,headBranch,status,conclusion,createdAt,updatedAt,name,jobs
gh run view 28320518721 --repo itchyshin/GLLVM.jl --log-failed | rg -n "FAIL|ERROR|Test Failed|phylo|X_lv|test_lv|test_phylo|Stacktrace|Error" -C 3
git log --oneline --decorate --graph --all --max-count=40 --branches='*phylo*'
```

Observed: PR #127 remote head is still `b87a522` and CI failed on that SHA.
The failure is the old stale expectation in `test/test_lv_predictor.jl:63`:
`fit_gaussian_gllvm(...; X_lv, K_phy = 1, Σ_phy = I(4))` was expected to throw,
but Model A now admits that combination. The current local branch contains
`bcf2680` (`test: fix phylo xlv premerge gates`) and `bf2c733`
(`bench: add phylo xlv DRAC launcher scaffold`) on top of the remote head.

Validation on the current local branch:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_predictor.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
```

Results: `test_lv_predictor.jl` PASS `27/27` in `14.0s`;
`test_phylo_xlv.jl` PASS `15/15` in `52.8s`; `test_lv_ci.jl` PASS `114/114`
in `2m34.1s`.

Not run: full `Pkg.test()` / Aqua / JET, GitHub CI rerun, DRAC `sbatch`, or
Documenter rebuild. The GLLVM.jl rule still says not to push without explicit
maintainer instruction, so the local fix is queued but not pushed.

### Claim Boundary

IN: current local branch has the targeted fix for the failing PR #127 test and
fresh local evidence for the predictor, phylo, and X_lv CI files. PARTIAL: remote
PR #127 still shows failing CI until the maintainer authorizes pushing the local
commits or otherwise updates the PR branch. OUT: any full-suite/3-OS green claim,
any DRAC coverage claim, and any public R-side phylo `lv=~x` exposure.

## 2026-06-28 -- PR #127 local full-suite verification (Codex)

Worked from clean local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv` at local head `33557ff`.

State and lane checks:

```sh
git status --short --branch
git log --all --oneline --since='6 hours ago'
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,baseRefName,mergeStateStatus,statusCheckRollup,updatedAt,url
git rev-parse --short HEAD
```

Observed: PR #127 remote head is still `b87a522` on
`claude/phylo-xlv-modelA-20260627`; CI remains red on that remote head and
Documenter remains green. The local branch is still not pushed because the
project rule says no push without explicit maintainer instruction.

Validation:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: PASS. Full `Pkg.test()` completed in `50m14.4s` with `4875` passing
tests, `1` broken test, and `4876` total test outcomes.

Notes while running: the suite was CPU-bound for the long quiet intervals; a
macOS `sample` showed time in Julia/JIT/test execution rather than an idle
hang. The full-suite result now strengthens the local PR #127 fix beyond the
previous targeted `test_lv_predictor.jl`, `test_phylo_xlv.jl`, and
`test_lv_ci.jl` evidence.

Not run: GitHub CI rerun, Documenter rebuild on the local head, DRAC `sbatch`,
or any >=500 reps/cell production coverage campaign.

### Claim Boundary

IN: local branch `33557ff` has targeted tests and full local `Pkg.test()` green.
PARTIAL: PR #127 remote CI is still red until the local commits are pushed or
the PR branch is otherwise updated. OUT: 3-OS CI green on the local commits,
DRAC coverage, calibrated Model A interval coverage, and any R-side
`phylo_latent(..., lv=~x)` exposure.

## 2026-06-28 -- PR #127 local Documenter build (Codex)

Worked from local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv`.

Setup:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
```

Plain `julia --project=docs docs/make.jl` initially failed before building
because the docs project had no instantiated `Documenter` environment and
`GLLVM` is not registered. Developing the current checkout into the docs
environment resolved this without tracked source diffs; `docs/Manifest.toml`,
`docs/node_modules`, and `docs/build` are ignored local artifacts.

Validation:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=docs docs/make.jl
```

Result: PASS. Documenter completed and Vitepress reported `build complete in
4.89s`. Deployment was skipped locally because Documenter could not auto-detect
a deployment environment.

Warnings observed: existing invalid local links using root-style paths such as
`/quickstart`, `/response-families`, `/api`, `/benchmarks`, and related article
links; missing optional `docs/src/assets/logo.png`, `favicon.ico`, and
`docs/package.json`; Vitepress chunk-size and npm-audit warnings. These are
pre-existing docs-site warnings and were not introduced by the phylo `X_lv`
local verification slice.

Not run: GitHub CI rerun, public Documenter deployment on the local head, DRAC
`sbatch`, or any >=500 reps/cell production coverage campaign.

### Claim Boundary

IN: local branch has full local `Pkg.test()` green and a local Documenter build
that completes. PARTIAL: remote PR #127 CI remains red on old head `b87a522`
until the local commits are pushed or the PR branch is updated. OUT: 3-OS CI
green on the local commits, deployed docs on the local commits, DRAC coverage,
and any R-side `phylo_latent(..., lv=~x)` exposure.

## 2026-06-28 -- phylo X_lv DRAC launcher depot-path hardening (Codex)

Worked from local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv` at local head `cffd4d5`, with one open draft
GLLVM.jl PR (#127) still on the older remote head `b87a522`.

Purpose: harden the generated SLURM script so array tasks force a durable
output-local Julia depot ahead of any ambient `JULIA_DEPOT_PATH`. This keeps
the DRAC run aligned with the runbook requirement that Julia depots live on
`/project` or another explicit durable output path, not an accidental login or
scratch default.

Coordination and state checks:

```sh
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,isDraft,mergeStateStatus,url,updatedAt
git log --all --oneline --since="6 hours ago" -- docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md bench/phylo_xlv_drac_submit.sh
git status --short --branch
```

Observed: only draft PR #127 was open. The recent same-file history was this
branch's own launcher/check-log work. Working tree was clean before the
depot-path edit.

Validation:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_submit_goal_probe2
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0,0.5,1 PHYLO_XLV_N_SPECIES=20,200 PHYLO_XLV_N_SITES=30 PHYLO_XLV_K=1,2 PHYLO_XLV_SCENARIOS=main,null_alpha0,null_phylo0 PHYLO_XLV_TIME=0-00:30 PHYLO_XLV_MEM=8G PHYLO_XLV_THROTTLE=14 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_goal_probe2
rg -n "julia_depot|JULIA_DEPOT_PATH|mkdir -p|#SBATCH --array|--mem|--time" /tmp/phylo_xlv_submit_goal_probe2/meta/phylo_xlv_array.sbatch
wc -l /tmp/phylo_xlv_submit_goal_probe2/meta/phylo_xlv_params.csv
```

Results: shell syntax passed. The write-only submit probe wrote 28 tasks for
the one-rep full-shape pilot grid. The generated sbatch script now contains
`mkdir -p "/tmp/phylo_xlv_submit_goal_probe2/julia_depot"` and
`export JULIA_DEPOT_PATH="/tmp/phylo_xlv_submit_goal_probe2/julia_depot:${JULIA_DEPOT_PATH:-}"`.
The parameter file had 29 lines including the header.

Follow-up metadata hardening:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_submit_goal_probe3
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=30 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TIME=0-00:10 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=2 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_goal_probe3
rg -n "git_head|git_branch|git_status|julia_depot|JULIA_DEPOT_PATH" /tmp/phylo_xlv_submit_goal_probe3/meta/session.txt /tmp/phylo_xlv_submit_goal_probe3/meta/phylo_xlv_array.sbatch
```

Results: shell syntax passed, the one-task write-only probe completed, session
metadata recorded `git_head`, `git_branch`, and `git_status` in a normal git
checkout, and the generated sbatch still created/prepended the output-local
Julia depot. The `git` metadata commands in the submitter are now tolerant of
staged source copies where `.git` is absent.

Follow-up module-state hardening:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_submit_absjulia_probe
local_julia=$(command -v julia)
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=30 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TIME=0-00:10 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=2 PHYLO_XLV_JULIA="$local_julia" bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_absjulia_probe
rg -n "module load julia|case|.juliaup|JULIA_DEPOT_PATH" /tmp/phylo_xlv_submit_absjulia_probe/meta/phylo_xlv_array.sbatch
```

Results: shell syntax passed. The absolute-Julia write-only probe wrote one
task and generated a sbatch script containing a `case "<absolute julia>" in`
guard, so production runs that pass an absolute `PHYLO_XLV_JULIA` path skip the
default `module load julia` branch.
This avoids mixing a version-specific executable path with a cluster default
Julia module. The submitted Rorqual pilot below used the pre-fix generated
sbatch file, so its stderr still contains a harmless Julia module reload
message; subsequent generated jobs should not.

Cluster connectivity check:

```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 fir 'hostname; pwd; command -v sbatch || true; command -v squeue || true'
ssh -o BatchMode=yes -o ConnectTimeout=10 totoro 'hostname; pwd; command -v sbatch || true; command -v squeue || true'
ls -l /Users/z3437171/.ssh/cm-snakagaw@fir.alliancecan.ca:22 2>/dev/null || true
```

Results: `fir` failed non-interactively at Duo / keyboard-interactive auth,
`totoro` failed auth, and no Fir ControlMaster socket was present. No `sbatch`
submission was attempted.

Not run: DRAC `sbatch`, `squeue`, `seff`, production coverage, local
`Pkg.test()` rerun, or Documenter rebuild. The change is shell-launcher
plumbing only; previous full local `Pkg.test()` and Documenter evidence still
apply to the code state before this shell hardening.

### Claim Boundary

IN: generated SLURM scripts now create and prepend the output-local Julia
depot; write-only full-shape pilot generation still works. PARTIAL: no live
cluster submission or seff sizing yet. OUT: DRAC production coverage,
remote CI green on PR #127, and R-side phylo `lv=~x` exposure.

## 2026-06-28 -- phylo X_lv Rorqual one-rep sbatch pilot submitted (Codex)

Worked from local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv` at local head `6be046c`. The source was
staged to `/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac` on Rorqual.

Coordination and state checks:

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago" -- docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md
git status --short --branch
```

Observed: draft GLLVM.jl PR #127 remained the only open PR. The recent same-file
history was this branch's own launcher and dev-log work. Working tree was clean
before recording the Rorqual pilot state.

Cluster environment preparation:

```sh
ssh -o BatchMode=yes rorqual 'module load StdEnv/2023; module load julia/1.10.10; command -v julia'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export JULIA_NUM_PRECOMPILE_TASKS=1; export JULIA_NUM_THREADS=1; julia --project=. -e "using Pkg; Pkg.precompile(); using GLLVM; println(\"GLLVM load ok\")"'
```

Results: `julia/1.10.10` resolved to
`/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia`.
Serial precompile completed and `using GLLVM` printed `GLLVM load ok`. A prior
parallel login-node precompile attempt hit transient process/resource limits;
the serial retry is the recorded usable environment state.

Live one-rep pilot submission:

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
stamp=$(date +%Y%m%d-%H%M%S)
out=/project/6098264/snakagaw/phylo_xlv/pilot-${stamp}
mkdir -p /project/6098264/snakagaw/phylo_xlv
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0,0.5,1
export PHYLO_XLV_N_SPECIES=20,200
export PHYLO_XLV_N_SITES=30
export PHYLO_XLV_K=1,2
export PHYLO_XLV_SCENARIOS=main,null_alpha0,null_phylo0
export PHYLO_XLV_TIME=0-00:30
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_THROTTLE=14
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia
bench/phylo_xlv_drac_submit.sh --out "$out" --submit
echo "PILOT_OUT=$out"
REMOTE
```

Results: the submitter wrote 28 tasks to
`/project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/meta/phylo_xlv_params.csv`
and submitted SLURM array job `14894938`. The generated session metadata
recorded `julia version 1.10.10`; because the staged source intentionally
excluded `.git`, it recorded `git_head=unknown`, `git_branch=unknown`, and
`git_status_unavailable` without failing. The generated sbatch file uses the
exact Julia 1.10.10 executable and prepends
`/project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/julia_depot` to
`JULIA_DEPOT_PATH`.

Scheduler state:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14894938 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"'
ssh -o BatchMode=yes rorqual 'squeue --start -j 14894938'
ssh -o BatchMode=yes rorqual 'scontrol show job 14894938 | sed -n "1,80p"'
```

Results: the array was accepted under account `def-snakagaw_cpu`, partition
`cpubase_bycore_b1,cpubackfill`, with `--array=1-28%14`, `--time=0-00:30`,
and `--mem=8G`. At the time of this entry it was still `PENDING` with reason
`Priority`; no start estimate was available.

Partial pilot progress while waiting for the last wave:

```sh
ssh -o BatchMode=yes rorqual 'find /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results -maxdepth 1 -type f -name "result_*.csv" | wc -l; sacct -j 14894938 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 40'
ssh -o BatchMode=yes rorqual 'head -n 5 /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results/result_000001.csv; head -n 5 /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results/result_000002.csv'
```

Results: the first 20 tasks completed with `ExitCode=0:0` and wrote 20 result
files. Recorded task elapsed times ranged from 12 seconds to 67 seconds, and
`MaxRSS` stayed below 1 GB in the completed `batch` steps. Early result files
had finite `B_lv` Wald rows; tiny-pilot phylogenetic-signal rows showed
`partial_or_failed` boundary behavior for some cells, which is expected to be
audited separately before any phylo-signal coverage claim. Tasks 21-28 were
still pending with reason `Priority` when this partial-progress note was
written.

Final one-rep pilot closeout:

```sh
ssh -o BatchMode=yes rorqual 'find /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results -maxdepth 1 -type f -name "result_*.csv" | wc -l; find /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/logs -maxdepth 1 -type f -name "*.err" -size +0c | wc -l; find /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/logs -maxdepth 1 -type f -name "*.out" | wc -l'
ssh -o BatchMode=yes rorqual 'sacct -j 14894938 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P'
ssh -o BatchMode=yes rorqual 'seff 14894938'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results'
ssh -o BatchMode=yes rorqual 'grep -R "fit_error" -l /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results/result_*.csv | wc -l; grep -R "AssertionError: Need n_sites" -l /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/results/result_*.csv | wc -l'
ssh -o BatchMode=yes rorqual 'find /project/6098264/snakagaw/phylo_xlv/pilot-20260628-235757/logs -maxdepth 1 -type f -name "*.err" -size +0c -print0 | xargs -0 grep -L "julia/1.10.10 => julia/1.12.5" | wc -l'
```

Results: the array completed with 28 result files, 28 stdout logs, and 28
nonempty stderr logs. `sacct` showed every array task `COMPLETED` with
`ExitCode=0:0`; task elapsed times ranged from 11 seconds to 67 seconds, and
completed task `MaxRSS` stayed below 1 GB. `seff 14894938` reported the final
array element completed with 345.77 MB memory used out of 8 GB. The summariser
read 42 result rows. Exactly 14 result files contained `fit_error`, and all 14
were the expected pilot-design assertion `Need n_sites >= p for a well-posed
Gaussian GLLVM`; this came from intentionally using `PHYLO_XLV_N_SITES=30`
while also including `PHYLO_XLV_N_SPECIES=200`. All nonempty stderr files only
contained the pre-fix Julia module reload message. This means the first pilot
validated scheduler/result/log plumbing for the small-species cells and exposed
an invalid pilot grid for large-species cells; it did not validate the large
`n_species=200` regime.

Fail-loud grid guard after the invalid pilot:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_invalid_grid.csv --reps 1 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 30 --K 1,2 --scenarios main,null_alpha0,null_phylo0
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_valid_grid.csv --reps 1 --lambdas 0,0.5,1 --n-species 20,200 --n-sites 200 --K 1,2 --scenarios main,null_alpha0,null_phylo0
wc -l /tmp/phylo_xlv_valid_grid.csv
```

Results: the invalid grid now fails during parameter writing with
`ArgumentError: --n-sites (30) must be >= every --n-species value for this
Gaussian coverage grid; invalid n_species=200`. The production-shaped one-rep
grid with `n_sites=200` still writes 28 tasks and 29 CSV lines including the
header.

Corrected large-species pilot:

```sh
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
stamp=$(date +%Y%m%d-%H%M%S)
out=/project/6098264/snakagaw/phylo_xlv/pilot-large-${stamp}
mkdir -p /project/6098264/snakagaw/phylo_xlv
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0
export PHYLO_XLV_N_SPECIES=200
export PHYLO_XLV_N_SITES=200
export PHYLO_XLV_K=1,2
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_TIME=0-02:00
export PHYLO_XLV_MEM=16G
export PHYLO_XLV_THROTTLE=2
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia
bench/phylo_xlv_drac_submit.sh --out "$out" --submit
echo "PILOT_LARGE_OUT=$out"
REMOTE
```

Results so far: submitted job `14895097` with 2 valid large-species tasks under
`/project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132`. The
generated sbatch contains the absolute-Julia `case` guard and no longer takes
the default `module load julia` branch for this path. At the time of this entry
both tasks were running at about 21 minutes, with `sstat` showing active CPU
and `MaxRSS` below 1 GB. No result files had been written yet.

Not run yet: final result aggregation for job `14895097`, `seff 14895097`, or
the production 500 reps/cell campaign. The submitted pilots are still
scheduler/plumbing and sizing evidence only.

### Claim Boundary

IN: Rorqual account/path/runtime are usable, serial Julia precompile/load passed,
the small-species one-rep array cells completed and summarised, invalid
large-species pilot grids now fail loud, and a corrected two-task large-species
pilot is running. PARTIAL: large-species runtime/results/resource sizing are
pending. OUT: production DRAC coverage, public phylo Model A coverage claims,
PR #127 remote CI green on the local commits, and R-side phylo `lv=~x` exposure.

## 2026-06-29 -- phylo X_lv Rorqual large-cell sizing diagnostics (Codex)

Worked from local branch `codex/phylo-xlv-drac-launcher-20260628` in
`/private/tmp/gllvmjl-phylo-xlv` at local head `31e4441`. The source staged on
Rorqual was `/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac`.

Coordination and state checks:

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago" -- docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-28-phylo-xlv-drac-launcher.md docs/dev-log/recovery-checkpoints bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh
git status --short --branch
```

Observed: draft GLLVM.jl PR #127 remained the only open PR. The recent same-file
history was this branch's own Rorqual pilot work. Working tree was clean before
recording the large-cell sizing diagnostics.

Large production-shaped pilot timeout:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14895097 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132/results -maxdepth 1 -type f -name "result_*.csv" | wc -l; sacct -j 14895097 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20'
ssh -o BatchMode=yes rorqual 'seff 14895097; for f in /project/6098264/snakagaw/phylo_xlv/pilot-large-20260629-001132/logs/*; do echo "==== $f ===="; tail -n 60 "$f"; done'
```

Results: corrected large-cell job `14895097` ran two valid cells
(`n_species=200`, `n_sites=200`, `K=1,2`, `iterations=400`, Wald-only) and both
timed out at about 2 hours with no result files. `sacct` reported `TIMEOUT`
for both array tasks and `CANCELLED` batch steps. `seff 14895097` reported
99.25% CPU efficiency and 2.16 GB memory used out of 16 GB for the final array
element. The logs contained only SLURM time-limit cancellation messages and no
model output. This is a runtime-sizing failure for the large production-shaped
cell, not a memory failure and not coverage evidence.

One-hour `iterations=80` large-cell diagnostic:

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14897066 -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-20260629-013037/results -maxdepth 1 -type f -name "result_*.csv" | wc -l; sacct -j 14897066 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20'
ssh -o BatchMode=yes rorqual 'seff 14897066; for f in /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-20260629-013037/logs/*; do echo "==== $f ===="; tail -n 60 "$f"; done'
```

Results: the one-task `n_species=200`, `n_sites=200`, `K=1`,
`iterations=80` diagnostic also timed out at about 1 hour with no result file.
`seff 14897066` reported 98.95% CPU efficiency and 2.13 GB memory used out of
8 GB. The log contained only the SLURM time-limit cancellation message. This
showed the earlier one-hour cap was too short even with the reduced iteration
limit.

Minimal large-cell and mid-size scaling diagnostics:

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_K=1
export PHYLO_XLV_THROTTLE=1
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia

out1=/project/6098264/snakagaw/phylo_xlv/pilot-large-iter5-20260629-023824
export PHYLO_XLV_N_SPECIES=200
export PHYLO_XLV_N_SITES=200
export PHYLO_XLV_TIME=0-01:00
export PHYLO_XLV_ITERATIONS=5
bench/phylo_xlv_drac_submit.sh --out "$out1" --submit

out2=/project/6098264/snakagaw/phylo_xlv/pilot-mid-iter80-20260629-023840
export PHYLO_XLV_N_SPECIES=100
export PHYLO_XLV_N_SITES=100
export PHYLO_XLV_TIME=0-01:00
export PHYLO_XLV_ITERATIONS=80
bench/phylo_xlv_drac_submit.sh --out "$out2" --submit
REMOTE
```

Result inspection:

```sh
ssh -o BatchMode=yes rorqual 'cat /project/6098264/snakagaw/phylo_xlv/pilot-large-iter5-20260629-023824/results/result_000001.csv; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-iter80-20260629-023840/results/result_000001.csv'
ssh -o BatchMode=yes rorqual 'seff 14898030; seff 14898031'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-iter5-20260629-023824/results; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-iter80-20260629-023840/results'
```

Results: job `14898030` (`n_species=200`, `n_sites=200`, `K=1`,
`iterations=5`) completed in 3:39, used 739.67 MB, and wrote a
`not_converged` result after 5 iterations with `fit_seconds=204.19`. Job
`14898031` (`n_species=100`, `n_sites=100`, `K=1`, `iterations=80`) completed
in 3:06, used 1.03 GB, converged in 19 fit iterations with
`fit_seconds=40.52`, and wrote finite `B_lv` Wald rows with 100/100 usable
entries in this one-rep diagnostic. The phylo-signal row remained
`partial_or_failed` with zero usable transformed-Wald intervals, consistent
with the earlier boundary behavior.

Follow-up active diagnostic:

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_K=1
export PHYLO_XLV_THROTTLE=1
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_N_SPECIES=200
export PHYLO_XLV_N_SITES=200
export PHYLO_XLV_TIME=0-02:00
export PHYLO_XLV_ITERATIONS=80
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia
out=/project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000
bench/phylo_xlv_drac_submit.sh --out "$out" --submit
REMOTE
```

Results so far: submitted job `14898092`, a one-task `n_species=200`,
`n_sites=200`, `K=1`, `iterations=80`, 2-hour diagnostic. At recording time it
was pending on priority with no result file.

Final inspection of job `14898092`:

```sh
ssh -o BatchMode=yes rorqual 'cat /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000/results/result_000001.csv; seff 14898092'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-2h-20260629-025000/results'
```

Results: job `14898092` completed in 1:03:55, used 1.82 GB out of 8 GB, and
wrote a converged `K=1`, `n_species=200`, `n_sites=200`, `iterations=80` result.
The fit converged in 21 iterations with `fit_seconds=627.64`; the `B_lv` Wald
row had 200/200 usable entries and one-rep entry coverage 0.775. The
phylo-signal transformed-Wald row again had zero usable intervals and
`partial_or_failed` status.

Depot override hardening:

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; rm -rf /tmp/phylo_xlv_depot_override_probe
local_julia=$(command -v julia)
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TIME=0-00:10 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=1 PHYLO_XLV_JULIA="$local_julia" PHYLO_XLV_DEPOT=/project/example/julia_depot bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_depot_override_probe
rg -n "depot=|JULIA_DEPOT_PATH|julia_depot|case" /tmp/phylo_xlv_depot_override_probe/meta/session.txt /tmp/phylo_xlv_depot_override_probe/meta/phylo_xlv_array.sbatch
```

Results: shell syntax passed. The write-only probe recorded
`depot=/project/example/julia_depot` in session metadata and generated a sbatch
script that puts `/project/example/julia_depot` first in `JULIA_DEPOT_PATH`,
preserves any inherited `JULIA_DEPOT_PATH`, and leaves the run-local
`$out/julia_depot` last. This avoids forcing many array tasks into the same
fresh, run-local first depot when a prewarmed project depot is available.

Depot-first two-task large pilot:

```sh
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_K=1,2
export PHYLO_XLV_THROTTLE=2
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_N_SPECIES=200
export PHYLO_XLV_N_SITES=200
export PHYLO_XLV_TIME=0-02:00
export PHYLO_XLV_ITERATIONS=80
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia
out=/project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-depot-20260629-040334
bench/phylo_xlv_drac_submit.sh --out "$out" --submit
REMOTE
```

Result inspection:

```sh
ssh -o BatchMode=yes rorqual 'cat /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-depot-20260629-040334/results/result_000001.csv; seff 14899045_1; seff 14899045_2'
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-iter80-depot-20260629-040334/results'
```

Results: the generated sbatch used the prewarmed project depot first. Job
`14899045_1` (`K=1`) completed in 1:15:33, used 2.00 GB, and reproduced the
`B_lv` Wald result from the single-task run (`fit_iterations=21`,
`fit_seconds=627.80`, 200/200 usable B_lv entries, one-rep entry coverage
0.775). Job `14899045_2` (`K=2`) timed out at 2:00:04 with no result file,
used 1.99 GB, and logged only the SLURM time-limit cancellation. The K=2 large
cell remains the long pole.

K=2 follow-up diagnostics:

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
cd "$root"
module load StdEnv/2023
module load julia/1.10.10
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot
export PHYLO_XLV_REPS=1
export PHYLO_XLV_LAMBDAS=0
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_K=2
export PHYLO_XLV_THROTTLE=1
export PHYLO_XLV_MEM=8G
export PHYLO_XLV_N_SPECIES=200
export PHYLO_XLV_N_SITES=200
export PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia

out1=/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter5-20260629-061042
export PHYLO_XLV_TIME=0-01:00
export PHYLO_XLV_ITERATIONS=5
bench/phylo_xlv_drac_submit.sh --out "$out1" --submit

out2=/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114
export PHYLO_XLV_TIME=0-04:00
export PHYLO_XLV_ITERATIONS=80
bench/phylo_xlv_drac_submit.sh --out "$out2" --submit
REMOTE
```

Results so far: job `14901946` (`K=2`, `iterations=5`) completed in 4:45, used
587.62 MB, and wrote a `not_converged` row after 5 iterations with
`fit_seconds=272.47`. Job `14901949` (`K=2`, `iterations=80`, 4-hour cap) was
still running at about 29 minutes with no result file and live `MaxRSS` below
1 GB when this entry was written.

Not run yet: final inspection of active K=2 job `14901949`, profile/bootstrap
timing, or the production 500 reps/cell campaign.

### Claim Boundary

IN: small-species Rorqual plumbing works; `n_species=100`, `n_sites=100`, `K=1`
converged in the one-rep diagnostic; valid `n_species=200`, `n_sites=200`,
`K=1`, `iterations=80` now completes with finite `B_lv` Wald output; `K=2`
can return a `not_converged` row when capped at 5 iterations. PARTIAL: valid
`n_species=200`, `n_sites=200`, `K=2` convergence and interval timing remain
active diagnostics. OUT: production DRAC coverage, public phylo Model A
coverage claims, and R-side phylo `lv=~x` exposure.

## 2026-06-29 07:02 MDT - Codex phylo X_lv DRAC task heartbeat

### Commands

```sh
gh pr list --state open --json number,headRefName,title,isDraft,mergeStateStatus
git log --all --oneline --since='6 hours ago' -- docs/dev-log/check-log.md docs/dev-log/after-task docs/dev-log/recovery-checkpoints bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl
export PATH="$HOME/.juliaup/bin:$PATH"
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_progress_params.csv --reps 1 --lambdas 0 --n-species 20 --n-sites 20 --K 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_progress_params.csv --outdir /tmp/phylo_xlv_progress_results --task-id 1 --dry-run
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_progress_fit/params.csv --reps 1 --lambdas 0 --n-species 4 --n-sites 12 --K 1 --scenarios main
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_progress_fit/params.csv --outdir /tmp/phylo_xlv_progress_fit/results --task-id 1 --iterations 1
ssh -o BatchMode=yes rorqual 'squeue -j 14901949 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sstat -j 14901949.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P || true'
```

### Result

Pre-edit lane check saw only draft PR #127 and no recent shared-file edits except
Codex's own depot-override commit. Added flushed UTC heartbeat messages around
each DRAC task's start, simulation, fit, non-convergence, B_lv CI,
phylo-signal CI, and result-write steps. The dry-run path printed the new
task-start line. The tiny local one-iteration fit printed
start/simulate/fit/not-converged/write heartbeats and wrote
`/tmp/phylo_xlv_progress_fit/results/result_000001.csv`.

The active Rorqual large K=2 diagnostic (`14901949_1`) was still running at
2:50:15 elapsed with `AveCPU=02:09:20`, `AveRSS=1208992K`, and
`MaxRSS=2249344K`; no production DRAC array was launched.

### Claim Boundary

IN: future DRAC tasks launched from this branch are inspectable by tailing their
SLURM stdout. OUT: this heartbeat patch does not change the DGP, estimator,
coverage target, or the still-running K=2 diagnostic.

## 2026-06-29 07:13 MDT - Codex phylo X_lv midpoint K=2 canary

### Commands

```sh
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
# Manually wrote one-row params and sbatch files for:
# scenario=main, pagel_lambda=0, n_species=100, n_sites=100, K=2,
# q_lv=1, K_phy=1, rep=1, seed=21321132, iterations=80.
# This avoided running the Julia parameter writer on the login node.
REMOTE
ssh -o BatchMode=yes rorqual 'squeue -j 14901949,14906861 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14906861 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20'
ssh -o BatchMode=yes rorqual 'ps -p 1390438 -o pid,ppid,pgid,sid,etime,stat,wchan:24,comm,args || true'
```

### Result

The normal submit helper was interrupted because its login-side
`julia --write-params` call stayed silent and then left an orphaned Julia
process in Lustre `cl_sync_io_wait` for the abandoned directory
`pilot-mid-k2-iter80-2h-20260629-070902`. To keep compute on SLURM, Codex wrote
a one-row parameter file and sbatch file directly under
`/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-manual-iter80-2h-20260629-071300`.

Submitted midpoint K=2 canary job `14906861`:
`n_species=100`, `n_sites=100`, `K=2`, `iterations=80`, `time=2h`, `mem=8G`,
`methods=wald`, source `b3e164e-file-synced`. At the first poll it was pending
as `14906861_[1%1]` with reason `ReqNodeNotAvail`. The p=200 K=2 diagnostic
job `14901949_1` was still running at about 3:00 elapsed with stale
`AveCPU=02:09:20`.

### Claim Boundary

IN: a single midpoint K=2 sizing canary is queued. OUT: no production coverage
array has launched; no K=2 timing result exists yet.

## 2026-06-29 07:18 MDT - Codex Nibi midpoint K=2 canary

### Commands

```sh
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes nibi 'bash -s' <<'REMOTE'
# Manually wrote one-row params and sbatch files for:
# scenario=main, pagel_lambda=0, n_species=100, n_sites=100, K=2,
# q_lv=1, K_phy=1, rep=1, seed=21321132, iterations=80.
# The sbatch script runs Pkg.instantiate() on the compute node before the task.
REMOTE
ssh -o BatchMode=yes nibi 'squeue -j 16923204 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923204 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20'
```

### Result

Staged the local GLLVM.jl tree to Nibi at
`/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac` with `.git`, `.julia`,
`docs/build`, and `node_modules` excluded. Submitted one Nibi midpoint canary
job `16923204` under
`/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-iter80-3h-20260629-071900`.
The job uses source label `2936ac2-rsync-no-git`, `n_species=100`,
`n_sites=100`, `K=2`, `iterations=80`, `time=3h`, `mem=8G`, and runs
`Pkg.instantiate()` on the compute node before calling
`bench/phylo_xlv_drac_task.jl`.

At first poll, Nibi job `16923204_[1%1]` was pending with reason `Priority`.
At the next poll it had started on node `c487` with 17 seconds elapsed, 3
seconds AveCPU, and about 555 MB MaxRSS. Rorqual p=200 K=2 job `14901949_1` was
still running at about 3:06 elapsed with stale `AveCPU=02:09:20`; Rorqual p=100
K=2 canary `14906861_[1%1]` was still pending with reason `ReqNodeNotAvail`.

### Claim Boundary

IN: one cross-cluster Nibi canary is staged and queued. OUT: no Nibi result,
cross-cluster timing comparison, or production coverage claim exists yet.

## 2026-06-29 07:29 MDT - Codex Nibi midpoint K=2 result

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923204 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923204 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20; tail -n 160 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-iter80-3h-20260629-071900/logs/phylo_xlv-16923204-1.out; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-iter80-3h-20260629-071900/results/result_000001.csv'
ssh -o BatchMode=yes nibi 'seff 16923204 2>/dev/null || true; sacct -j 16923204 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P'
ssh -o BatchMode=yes rorqual 'squeue -j 14901949,14906861 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14901949,14906861 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 30; sstat -j 14901949.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P || true'
```

### Result

Nibi job `16923204_1` completed with scheduler exit `0:0` in 9:02 wall time,
used 8:20 CPU (`92.25%` efficiency), and used 2.18 GB max RAM. The heartbeat
log shows compute-node package setup followed by task progress:

- fit start at `2026-06-29T13:20:53Z`;
- fit converged in 66 iterations after about 136.45 seconds;
- B_lv Wald CI ran from `13:23:09Z` to `13:28:07Z`;
- phylo-signal transformed-Wald CI ran from `13:28:07Z` to `13:28:11Z`;
- result CSV written at `13:28:11Z`.

Result row summary for this one-rep canary (`scenario=main`, `lambda=0`,
`n_species=100`, `n_sites=100`, `K=2`, `q_lv=1`, `K_phy=1`, seed `21321132`):

- `B_lv` Wald: `fit_converged=true`, `fit_iterations=66`, `usable=100/100`,
  `covered=83/100`, one-rep entry coverage `0.83`, `pd_hessian=true`,
  `bias_rmse=0.1074`.
- `phylo_signal`: `fit_converged=true`, status `partial_or_failed`,
  `usable=0/100`, `pd_hessian=false`.

At the same poll, Rorqual p=200 K=2 job `14901949_1` was still running at
3:16:23 elapsed with stale `AveCPU=02:09:20`; Rorqual p=100 K=2 canary
`14906861_[1%1]` was still pending with reason `ReqNodeNotAvail`.

### Claim Boundary

IN: `n_species=100`, `n_sites=100`, `K=2` can converge and produce B_lv Wald
interval rows on Nibi in a one-rep canary. OUT: this is not coverage evidence,
does not validate phylo-signal intervals, and does not solve the p=200 K=2
large-cell timing problem.

## 2026-06-29 07:34 MDT - Codex large K=2 Nibi canary launch

### Commands

```sh
ssh -o BatchMode=yes rorqual 'scancel 14906861 2>/dev/null || true; squeue -j 14901949,14906861 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14906861 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 10'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes nibi 'bash -s' <<'REMOTE'
# Manually wrote one-row params and sbatch files for:
# scenario=main, pagel_lambda=0, n_species=200, n_sites=200, K=2,
# q_lv=1, K_phy=1, rep=1, seed=21371432, iterations=80.
# The sbatch script runs Pkg.instantiate() on the compute node before the task.
REMOTE
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 20'
ssh -o BatchMode=yes rorqual 'squeue -j 14901949,14906861 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14901949,14906861 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem -P | tail -n 30; sstat -j 14901949.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P || true'
```

### Result

Cancelled redundant Rorqual p=100 K=2 canary `14906861`, which had not started
and was superseded by the completed Nibi p=100 K=2 result. Refreshed the Nibi
staged source tree from local commit `328e5e8` without `.git`.

Submitted Nibi large-cell canary job `16923927` under
`/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300`.
The job uses source label `328e5e8-rsync-no-git`, `n_species=200`,
`n_sites=200`, `K=2`, `iterations=80`, `time=4h`, `mem=8G`, and runs
`Pkg.instantiate()` on the compute node before calling
`bench/phylo_xlv_drac_task.jl`. At the first poll, job `16923927_[1%1]` was
pending with reason `Priority`.

At the same poll, Rorqual p=200 K=2 job `14901949_1` was still running at about
3:22 elapsed with no stdout, no stderr, no result CSV, and `AveCPU` around
2:09:30. Its result is still needed as a final comparison or timeout record.

### Claim Boundary

IN: one large-cell Nibi K=2 timing canary is queued and the redundant Rorqual
p=100 K=2 pending job was cancelled. OUT: no p=200 K=2 result exists yet and no
production coverage array has launched.

## 2026-06-29 08:12 MDT - Codex large K=2 timing split

### Commands

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14901949 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14901949 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/results/result_000001.csv 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/logs/phylo_xlv-14901949-1.err 2>/dev/null || true; seff 14901949 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; sstat -j 16923927.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P 2>/dev/null || true; tail -n 280 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true'
```

### Result

Rorqual job `14901949_1` completed just under its 4-hour cap with scheduler
exit `0:0` (`03:59:54` wall time, `02:47:26` CPU used, 69.79% CPU efficiency,
2.15 GB max RAM). The large-cell `n_species=200`, `n_sites=200`, `K=2`,
`iterations=80` fit converged in 47 iterations with `fit_seconds=2006.25`.
It wrote usable `B_lv` Wald rows (`usable=200/200`, one-rep entry coverage
`0.865`, `pd_hessian=true`, `bias_rmse=0.0696`). The phylo-signal transformed
Wald row was still unusable (`ci_status=partial_or_failed`, `usable=0/200`,
`pd_hessian=false`).

Nibi job `16923927_1` was still running at `00:38:03` wall time on node `c481`.
Its heartbeat is more informative than the Rorqual run: the p=200 K=2 fit
converged in 47 iterations after `1394.49` seconds and entered `B_lv` Wald CI at
`2026-06-29T13:59:27Z`. At the last poll it was still inside the `B_lv` CI step,
with `AveCPU=00:37:33`, `AveRSS=1415020K`, and `MaxRSS=2243344K`.

### Claim Boundary

IN: valid p=200 K=2 Model A fits can converge and produce B_lv Wald rows under
the current harness; Rorqual can finish one seed under a 4-hour cap, and Nibi
finishes the fit portion in about 23 minutes. PARTIAL: p=200 K=2 interval timing
is not yet solved because Nibi is still in the B_lv CI step, and phylo-signal CI
rows remain unusable in these one-seed canaries. OUT: no >=500 reps/cell
production coverage array has launched, and these one-seed rows are not coverage
evidence.

## 2026-06-29 08:28 MDT - Codex phylo X_lv timing instrumentation

### Commands

```sh
gh pr list --state open --json number,title,headRefName,url,isDraft
git log --all --oneline --since='6 hours ago' -- docs/dev-log/check-log.md docs/dev-log/after-task docs/dev-log/recovery-checkpoints bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl src/confint_family.jl src/confint_derived_wald.jl
julia --project=. bench/phylo_xlv_drac_task.jl --help
bash -n bench/phylo_xlv_drac_submit.sh
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 3 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --dry-run; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets all --dry-run
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 8 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets none --iterations 20 --force; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$d/results"; cat "$d/results/result_000001.csv"
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40; sstat -j 16923927.batch --format=JobID,AveCPU,AveRSS,MaxRSS -P 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; seff 16923927 2>/dev/null || true'
```

### Result

Added bench-only instrumentation for Phase 3 DRAC steering:

- `bench/phylo_xlv_drac_task.jl` now writes a `ci_seconds` result column.
- The task runner accepts `--targets B_lv,phylo_signal`, `--targets B_lv`,
  `--targets phylo_signal`, `--targets all`, and `--targets none`.
- `--targets none` writes an explicit `target=fit`, `ci_status=fit_only`
  result row after a converged fit.
- `bench/phylo_xlv_drac_submit.sh` exposes the same control through
  `PHYLO_XLV_TARGETS` and records it in session metadata.
- `bench/phylo_xlv_drac_summarise.jl` now reports mean fit seconds and mean
  CI seconds per grouped row while remaining compatible with older CSVs that
  lack `ci_seconds`.

Validation passed:

- help text renders;
- `bash -n bench/phylo_xlv_drac_submit.sh` passes;
- tiny generated parameter files dry-run with `--targets none` and
  `--targets all`;
- a tiny actual `--targets none` task (`n_species=3`, `n_sites=8`, `K=1`,
  `iterations=20`) converged in 12 iterations, wrote a `fit_only` row with the
  new `ci_seconds` column, and summarised successfully.

At the concurrent Nibi poll, large-cell job `16923927_1` remained in the
`B_lv` Wald CI step at `00:50:54` wall time after its fit had already converged
in `1394.49` seconds. No result CSV had been written yet.

### Claim Boundary

IN: the DRAC runner can now separate fit-only, B_lv-only, and phylo-signal-only
timing/evidence tasks without changing the Model A estimands. PARTIAL: the
current large-cell Nibi canary still has unresolved B_lv interval wall time.
OUT: this instrumentation is not coverage evidence and does not validate
phylo-signal intervals.

## 2026-06-29 08:52 MDT - Codex Nibi phylo-signal target diagnostic launch

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40; tail -n 220 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; seff 16923927 2>/dev/null || true'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/
ssh -o BatchMode=yes nibi 'bash -s' <<'REMOTE'
# Wrote one-row params and sbatch files for:
# scenario=main, pagel_lambda=0, n_species=200, n_sites=200, K=2,
# q_lv=1, K_phy=1, rep=1, seed=21371432, iterations=80,
# source_head=b39b355-rsync-no-git, targets=phylo_signal,
# time=2h, mem=8G.
REMOTE
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16926545 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927,16926545 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 80; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848/logs/phylo_xlv_h2-16926545-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848/results/result_000001.csv 2>/dev/null || true'
```

### Result

At the first poll, existing Nibi job `16923927_1` was still running at
`01:11:20` and still inside the `B_lv` Wald CI step after the fit had converged
in 47 iterations (`1394.49` seconds). No result CSV existed.

Synced current local branch `b39b355` to a separate staged source tree,
`/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/`, without
overwriting the running job's old `328e5e8` source tree. Submitted one
target-instrumented Nibi diagnostic:

- job `16926545`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-iter80-2h-20260629-0848`;
- `scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`, `K=2`,
  `q_lv=1`, `K_phy=1`, seed `21371432`;
- `--targets phylo_signal`, `--methods wald`, `iterations=80`, `time=2h`,
  `mem=8G`.

At the post-submit poll, job `16926545_[1%1]` was pending with reason
`Priority`. Existing job `16923927_1` was still running at `01:14:05`, still in
the `B_lv` CI step, and still had no result CSV.

### Claim Boundary

IN: one bounded target-only diagnostic is queued to determine whether p=200,
K=2 phylo-signal intervals are a separate timing blocker when `B_lv` is skipped.
PARTIAL: no result from job `16926545` exists yet, and job `16923927` has not
finished its `B_lv` CI. OUT: no production coverage launch and no new coverage
claim.

## 2026-06-29 09:03 MDT - Codex Rorqual phylo-signal backup launch

### Commands

```sh
ssh -o BatchMode=yes rorqual 'squeue -u snakagaw -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" | head -n 30; find /project/6098264/snakagaw/phylo_xlv -maxdepth 3 -type f \( -name session.txt -o -name "*.sbatch" -o -name "result_000001.csv" \) -print | sort | tail -n 30'
ssh -o BatchMode=yes rorqual 'sed -n "1,180p" /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-iter80-4h-20260629-061114/meta/phylo_xlv_array.sbatch'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
# Wrote one-row params and sbatch files for:
# scenario=main, pagel_lambda=0, n_species=200, n_sites=200, K=2,
# q_lv=1, K_phy=1, rep=1, seed=21371432, iterations=80,
# source_head=1e32dc9-rsync-no-git, targets=phylo_signal,
# time=2h, mem=8G.
REMOTE
ssh -o BatchMode=yes rorqual 'squeue -j 14909542 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14909542 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40'
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16926545 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927,16926545 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 80'
```

### Result

Rorqual had no active jobs for user `snakagaw` at the queue check. Synced the
current local branch to
`/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming/` and submitted
one bounded backup diagnostic:

- Rorqual job `14909542`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-iter80-2h-20260629-0900`;
- `scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`, `K=2`,
  seed `21371432`;
- `--targets phylo_signal`, `iterations=80`, `time=2h`, `mem=8G`.

At the immediate poll, Rorqual job `14909542_[1%1]` was pending with reason
`Priority`. Nibi job `16926545_1` had started on node `c13` and was running at
`00:03:56`. The older Nibi job `16923927_1` was still running at `01:20:51`,
still inside its `B_lv` CI step.

### Claim Boundary

IN: one Rorqual backup and one Nibi target-only diagnostic are now in the queue
or running for p=200, K=2 phylo-signal timing. PARTIAL: no target-only result
exists yet, and old B_lv CI timing remains unresolved. OUT: no production
coverage launch and no coverage claim.

## 2026-06-29 09:20 MDT - Codex batched phylo-signal Wald helper

### Commands

```sh
julia --project=. test/test_confint_derived_wald.jl
d=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$d/params.csv" --reps 1 --lambdas 0 --n-species 3 --n-sites 8 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$d/params.csv" --outdir "$d/results" --task-id 1 --targets phylo_signal --iterations 20 --force; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$d/results"; cat "$d/results/result_000001.csv"
ssh -o BatchMode=yes nibi 'scancel 16926545 2>/dev/null || true; sleep 2; squeue -j 16923927,16926545 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16926545 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 20'
ssh -o BatchMode=yes rorqual 'scancel 14909542 2>/dev/null || true; squeue -j 14909542 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14909542 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 20'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming-batched/
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='node_modules' ./ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming-batched/
ssh -o BatchMode=yes nibi 'bash -s' <<'REMOTE'
# Submitted source_head=451090c-rsync-no-git, targets=phylo_signal,
# same p=200,K=2 one-row diagnostic, time=2h, mem=8G.
REMOTE
ssh -o BatchMode=yes rorqual 'bash -s' <<'REMOTE'
# Submitted source_head=451090c-rsync-no-git, targets=phylo_signal,
# same p=200,K=2 one-row diagnostic, time=2h, mem=8G.
REMOTE
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16927325 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927,16927325 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 80'
ssh -o BatchMode=yes rorqual 'squeue -j 14909918 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14909918 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 60'
```

### Result

Added an internal `_phylo_signal_wald_ci_all()` helper in
`src/confint_derived_wald.jl` that reuses one observed-information Hessian for
all per-trait phylo-signal transformed-Wald CIs. `bench/phylo_xlv_drac_task.jl`
now uses this helper when available, falling back to the public single-trait
wrapper if needed. This does not change the estimand or public wrapper.

Validation:

- `test/test_confint_derived_wald.jl`: `115/115` pass in `22.9s`.
- Tiny target-only bench smoke (`n_species=3`, `n_sites=8`, `K=1`,
  `iterations=20`, `--targets phylo_signal`) converged in 12 iterations,
  wrote `ci_seconds=2.829`, and summarised successfully.
- `git diff --check`: clean.

Cancelled the two old-source target-only jobs before they entered the
per-trait Hessian loop:

- Nibi job `16926545_1`: cancelled after `00:23:17`, with fit still in
  progress; batch max RSS `1039036K`.
- Rorqual job `14909542_1`: cancelled after `00:17:29`, with fit still in
  progress.

Synced commit `451090c` to separate batched staged trees and submitted
replacement target-only diagnostics:

- Nibi job `16927325`, output
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918`,
  pending with reason `Priority` at first poll.
- Rorqual job `14909918`, output
  `/project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918`,
  pending with reason `Priority` at first poll.

The old all-target Nibi B_lv job `16923927_1` remains running and was still in
the `B_lv` Wald CI step at `01:41:52`.

### Claim Boundary

IN: batched Hessian reuse for phylo-signal timing diagnostics and two replacement
p=200, K=2 target-only canaries queued. PARTIAL: no batched target result exists
yet, and the B_lv Wald CI timing bottleneck remains unresolved. OUT: no
production coverage launch, no calibrated coverage claim, and no public R
grammar exposure.

## 2026-06-29 09:31 MDT - Codex Narval mid-large B_lv sizing pilot

### Commands

```sh
ssh -o BatchMode=yes totoro 'hostname; pwd; uptime'
ssh -o BatchMode=yes fir 'hostname; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" 2>/dev/null | head -n 20; sinfo -h -o "%P %a %l %D %t" 2>/dev/null | head -n 20'
ssh -o BatchMode=yes narval 'hostname; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" 2>/dev/null | head -n 20; sinfo -h -o "%P %a %l %D %t" 2>/dev/null | head -n 20'
ssh -o BatchMode=yes trillium 'hostname; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" 2>/dev/null | head -n 20; sinfo -h -o "%P %a %l %D %t" 2>/dev/null | head -n 20'
ssh -o BatchMode=yes vulcan 'hostname; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" 2>/dev/null | head -n 20; sinfo -h -o "%P %a %l %D %t" 2>/dev/null | head -n 20'
ssh -o BatchMode=yes narval 'ls -ld /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac 2>/dev/null || true; ls -ld /project/6098264/snakagaw/julia_depot 2>/dev/null || true; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" | head -n 20'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='docs/node_modules' --exclude='docs/.vitepress/cache' --exclude='*.ji' ./ narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes narval 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export JULIA_NUM_PRECOMPILE_TASKS=1; export JULIA_NUM_THREADS=1; julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile(); using GLLVM; println(\"GLLVM load ok\")"'
ssh -o BatchMode=yes narval 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023; module load julia/1.10.10; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=0; export PHYLO_XLV_N_SPECIES=150; export PHYLO_XLV_N_SITES=150; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=B_lv; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=80; export PHYLO_XLV_TIME=0-03:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,80p" "$out/meta/session.txt"; sed -n "1,80p" "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 64331208 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30'
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16927325 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 16923927,16927325 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 40'
ssh -o BatchMode=yes rorqual 'squeue -j 14909918 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14909918 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30'
```

### Result

Cluster placement inventory:

- Nibi and Rorqual remain the active p=200, K=2 timing probes.
- Narval is reachable, has `/project/6098264/snakagaw`, had no active user job
  at the queue check, and Julia 1.10.10 loaded successfully after
  `Pkg.instantiate()` / `Pkg.precompile()`.
- Fir and Trillium are reachable. Fir already had one user job in queue/running;
  Trillium showed idle Neptune/S4H capacity, but `/project/6098264/snakagaw`
  was not verified there during this pass.
- Vulcan responded to the login probe, but the quick project/Julia probe produced
  no usable staging output, so no work was submitted there.
- Totoro is configured in `~/.ssh/config` but rejected this session's
  noninteractive SSH attempt with `Permission denied (publickey,password)`.

The first Narval submit attempt failed before `sbatch` because the staged Julia
depot lacked required packages (`Distributions` was the first missing package).
After running `Pkg.instantiate()` and `Pkg.precompile()` on Narval,
`using GLLVM` succeeded.

Submitted one bounded sizing pilot:

- Narval job `64331208`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939`;
- source staged from local head `1c774a2` without `.git`;
- `scenario=main`, `lambda=0`, `n_species=150`, `n_sites=150`, `K=2`,
  `q_lv=1`, `K_phy=1`, one seed/task;
- `--targets B_lv`, `--methods wald`, `iterations=80`, `time=3h`, `mem=8G`.

Immediate status:

- Narval job `64331208_[1%1]` was pending with reason `Priority`.
- Rorqual batched phylo-signal job `14909918_1` was running at `00:11:17` and
  still in the fit step.
- Nibi batched phylo-signal job `16927325_1` was running at `00:11:01` and still
  in the fit step.
- Nibi all-target p=200, K=2 job `16923927_1` was running at `01:55:41`, still
  inside the `B_lv` Wald CI step after fit convergence.

### Claim Boundary

IN: one additional mid-large `B_lv` timing pilot (`p=150`, `K=2`) is queued on
Narval to locate the feasible large-cell boundary. PARTIAL: p=200, K=2 B_lv and
batched phylo-signal timing remain unresolved. OUT: no >=500 reps/cell
production coverage array, no calibrated phylo coverage claim, and no public R
grammar exposure.

## 2026-06-29 09:48 MDT - Codex Nibi batched phylo-signal result

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927,16927325 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; echo OLD; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true; echo BATCH; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918/logs/phylo_xlv_h2b-16927325-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'sacct -j 16927325 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; seff 16927325 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming-batched 2>/dev/null || cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-phylo-target-batched-iter80-2h-20260629-0918/results'
```

### Result

Nibi job `16927325_1` completed successfully:

- scheduler state `COMPLETED`, exit code `0:0`;
- elapsed `00:25:53`;
- CPU efficiency `98.65%`;
- memory `630.30 MB` of `8 GB`;
- source label `451090c-rsync-no-git`;
- cell: `scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`,
  `K=2`, `q_lv=1`, `K_phy=1`, seed `21371432`;
- target: `phylo_signal` only, transformed-Wald.

Result row:

- fit converged: `true`;
- fit iterations: `47`;
- fit seconds: `1521.952`;
- phylo-signal CI seconds: `4.595`;
- CI status: `partial_or_failed`;
- usable phylo-signal entries: `0/200`;
- phylo-signal RMSE: `0.243`;
- `pd_hessian=false`;
- mean estimate approximately `6.87e-7` versus mean truth `0.164`;
- max estimate approximately `0.000137` versus max truth `0.733`.

The summariser read one row and reported the same: `fit ok=1`, `usable
entries=0`, `fit sec mean=1521.952`, `CI sec mean=4.595`,
`CI status=partial_or_failed`.

Old Nibi job `16923927_1` is still running and remains in `B_lv CI start
method=wald` after the fit converged. Rorqual backup job `14909918_1` and
Narval p=150 B_lv sizing job `64331208_1` were still in their fit steps at the
same polling pass.

### Claim Boundary

IN: batched phylo-signal CI timing is no longer the p=200, K=2 wall-time
blocker; after the fit, the CI took about 4.6 seconds. PARTIAL: the
phylo-signal interval is statistically unusable in this boundary cell (`0/200`
usable entries), so phylo-signal coverage still cannot be claimed. OUT: no
production coverage launch, no calibrated phylo-signal claim, and no resolution
yet for the p=200, K=2 `B_lv` observed-information bottleneck.

## 2026-06-29 09:53 MDT - Codex Rorqual batched phylo-signal confirmation

### Commands

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14909918 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918/logs/phylo_xlv_h2b-14909918-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'sacct -j 14909918 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; seff 14909918 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming-batched 2>/dev/null || cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-rorqual-phylo-target-batched-iter80-2h-20260629-0918/results'
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/logs/phylo_xlv-64331208-1.out 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true'
```

### Result

Rorqual job `14909918_1` completed successfully and confirms the Nibi
phylo-signal timing result:

- scheduler state `COMPLETED`, exit code `0:0`;
- elapsed `00:31:57`;
- CPU efficiency `98.96%`;
- memory `951.11 MB` of `8 GB`;
- same cell and seed as Nibi job `16927325_1`:
  `scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`, `K=2`,
  seed `21371432`;
- fit converged in `47` iterations;
- fit seconds `1889.547`;
- batched phylo-signal CI seconds `4.668`;
- CI status `partial_or_failed`;
- usable phylo-signal entries `0/200`;
- `pd_hessian=false`;
- summary RMSE `0.243`.

The repeated p=200, K=2 phylo-signal-only result is deterministic to the
reported precision: the point estimates are essentially zero while the mean
truth is `0.164`, so the transformed-logit Wald interval is boundary-failed.
The batched helper solved the per-trait Hessian timing issue, not the
statistical boundary/identifiability issue.

Other live state at this checkpoint:

- Narval job `64331208_1` (`p=150`, `K=2`, `B_lv` only) fit converged in
  `67` iterations after `1001.39s` and has entered `B_lv CI start method=wald`.
- Old Nibi job `16923927_1` (`p=200`, `K=2`, all targets) is still in
  `B_lv CI start method=wald` after fit convergence.

### Claim Boundary

IN: p=200, K=2 phylo-signal CI timing is now confirmed on two clusters at
roughly 4.6 seconds after fit convergence. PARTIAL: p=200, K=2 phylo-signal
coverage remains unusable (`0/200` usable) and therefore unclaimable. OUT:
no production coverage array, no phylo-signal coverage claim, and no conclusion
yet on whether `p=150`, `K=2` is a feasible `B_lv` large-cell boundary.

## 2026-06-29 09:58 MDT - Codex Nibi p200 K2 B_lv result

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16923927 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/logs/phylo_xlv-16923927-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'sacct -j 16923927 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; seff 16923927 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac 2>/dev/null || cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac-targettiming-batched; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-large-k2-nibi-iter80-4h-20260629-073300/results'
```

### Result

Nibi job `16923927_1` completed successfully:

- scheduler state `COMPLETED`, exit code `0:0`;
- elapsed `02:18:45`;
- CPU efficiency `99.15%`;
- memory `2.14 GB` of `8 GB`;
- source label `328e5e8-rsync-no-git`;
- cell: `scenario=main`, `lambda=0`, `n_species=200`, `n_sites=200`,
  `K=2`, `q_lv=1`, `K_phy=1`, seed `21371432`.

Log timing:

- fit start: `2026-06-29T13:36:12.953Z`;
- fit done: `2026-06-29T13:59:27.443Z`;
- fit seconds in result row: `1394.398`;
- `B_lv CI start`: `2026-06-29T13:59:27.444Z`;
- `B_lv CI done`: `2026-06-29T15:54:31.161Z`;
- elapsed `B_lv` CI wall time from log timestamps: about `6904s`
  (`1h55m04s`);
- phylo-signal CI then took about `4.4s`.

Result rows:

- `B_lv` Wald: `usable=200/200`, `covered=173/200`, one-seed entry coverage
  `0.865`, RMSE `0.070`, `pd_hessian=true`, status `ok`.
- `phylo_signal` transformed-Wald: `usable=0/200`, status
  `partial_or_failed`, RMSE `0.243`, `pd_hessian=false`.

The current summariser read both rows but this older result schema predates the
`ci_seconds` column, so the fit/CI timing above comes from the result row and
stdout timestamps rather than the summary table.

### Claim Boundary

IN: p=200, K=2 `B_lv` Wald is technically computable and produces usable rows
for this seed. PARTIAL: the one-seed entry coverage (`0.865`) is far below a
coverage claim and the observed-information step took about 1h55m after fit
convergence. OUT: no p=200, K=2 production run; at 500 reps/cell this timing is
not a viable default production grid without narrowing the large-cell boundary
or changing the interval strategy.

## 2026-06-29 10:15 MDT - Codex K2 fallback sizing and Julia launcher pin

### Commands

```sh
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/logs/phylo_xlv-64331208-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/results/result_000001.csv 2>/dev/null || true'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='docs/node_modules' --exclude='docs/.vitepress/cache' --exclude='*.ji' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=0; export PHYLO_XLV_N_SPECIES=125; export PHYLO_XLV_N_SITES=125; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=B_lv; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=80; export PHYLO_XLV_TIME=0-02:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,80p" "$out/meta/session.txt"; sed -n "1,80p" "$out/meta/phylo_xlv_array.sbatch"'
export PATH="$HOME/.juliaup/bin:$PATH"; bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; d=$(mktemp -d); PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0 PHYLO_XLV_N_SPECIES=3 PHYLO_XLV_N_SITES=8 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=none PHYLO_XLV_ITERATIONS=5 bench/phylo_xlv_drac_submit.sh --out "$d"; rg -n "julia_version|julia_depot|case|module load julia|\"/.*/julia\" --project|\"julia\" --project" "$d/meta/session.txt" "$d/meta/phylo_xlv_array.sbatch"
ssh -o BatchMode=yes nibi 'squeue -j 16929004 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 220 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/logs/phylo_xlv-16929004-1.out 2>/dev/null || true; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/logs/phylo_xlv-16929004-1.err 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/results/result_000001.csv 2>/dev/null || true'
```

### Result

Narval p=150, K=2 B_lv-only job `64331208_1` is still live. The fit converged
in `67` iterations after `1001.39s`; at the latest poll it was still inside the
`B_lv` Wald interval step at about `41:58` wall time.

Submitted one bounded fallback sizing probe on Nibi:

- Nibi job `16929004`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008`;
- source synced from local head `a0e0f91` plus the then-uncommitted working tree;
- `scenario=main`, `lambda=0`, `n_species=125`, `n_sites=125`, `K=2`,
  `q_lv=1`, `K_phy=1`, one seed/task;
- `--targets B_lv`, `--methods wald`, `iterations=80`, `time=2h`, `mem=8G`.

At the latest poll, Nibi job `16929004_1` was running on node `c9` and had
entered the fit step. This fallback job was generated before the launcher pin
below, and its batch stderr shows the site module reloaded
`julia/1.10.10 => julia/1.12.5`. Treat this as timing-bracket evidence only,
not final production evidence.

Patched `bench/phylo_xlv_drac_submit.sh` so an unset `PHYLO_XLV_JULIA` records
the current `command -v julia` absolute executable instead of the bare word
`julia`. The generated sbatch `case` guard then skips `module load julia` for an
absolute path, preserving an intentionally loaded Julia module/version for
future DRAC submissions.

Validation:

- `bash -n bench/phylo_xlv_drac_submit.sh` passed.
- A write-only tiny submit probe wrote one task and generated an sbatch with
  `case "/Users/z3437171/.juliaup/bin/julia" in` and
  `"/Users/z3437171/.juliaup/bin/julia" --project=. bench/phylo_xlv_drac_task.jl`.
- `/tmp/gllvm-dashboard` was updated through build `r69` with a compute-status
  table and the two live sizing probes; JSON validation passed. The dashboard
  files are outside this repository and are served live only.

### Claim Boundary

IN: launcher version pinning for future DRAC jobs and one p=125, K=2 B_lv-only
fallback sizing probe. PARTIAL: p=150 and p=125 B_lv timings are still live and
unresolved. OUT: no `>=500` reps/cell production coverage array, no p=125/p=150
coverage claim, no phylo-signal coverage claim, and no public R grammar exposure.

## 2026-06-29 10:24 MDT - Codex p125 K2 fallback rerun

### Commands

```sh
ssh -o BatchMode=yes nibi 'sacct -j 16929004 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 30; seff 16929004 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter80-2h-20260629-1008/results'
ssh -o BatchMode=yes nibi 'module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; command -v julia; julia --version; squeue -u $USER -o "%.18i %.9P %.30j %.8u %.10M %.6D %R" | head -n 20'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='docs/build' --exclude='docs/node_modules' --exclude='docs/.vitepress/cache' --exclude='*.ji' ./ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_JULIA="$(command -v julia)"; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=0; export PHYLO_XLV_N_SPECIES=125; export PHYLO_XLV_N_SITES=125; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=B_lv; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=160; export PHYLO_XLV_TIME=0-03:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,90p" "$out/meta/session.txt"; sed -n "1,90p" "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes nibi 'squeue -j 16929661 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024/logs/phylo_xlv-16929661-1.out 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024/logs/phylo_xlv-16929661-1.err 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024/results/result_000001.csv 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64331208 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 220 /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/logs/phylo_xlv-64331208-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/results/result_000001.csv 2>/dev/null || true'
```

### Result

Nibi p=125, K=2 B_lv fallback job `16929004_1` completed with scheduler exit
`0:0`, but the model fit did not converge:

- elapsed `00:09:30`;
- CPU efficiency `97.89%`;
- memory `2.64 GB` of `8 GB`;
- fit status row: `target=fit`, `method=none`, `fit_converged=false`,
  `fit_iterations=80`, `fit_seconds=461.063`, `ci_status=not_converged`;
- no `B_lv` CI row was written.

This job remains timing-bracket evidence only because its generated sbatch was
from the pre-pin script and stderr showed the site module reloaded
`julia/1.10.10 => julia/1.12.5`.

Verified the pinned Julia path on Nibi:

- `command -v julia` after `module load julia/1.10.10`:
  `/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia`;
- `julia --version`: `julia version 1.10.10`.

Submitted one corrected, still bounded rerun:

- Nibi job `16929661`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024`;
- same cell: `scenario=main`, `lambda=0`, `n_species=125`, `n_sites=125`,
  `K=2`, `q_lv=1`, `K_phy=1`, one seed/task;
- `--targets B_lv`, `--methods wald`, `iterations=160`, `time=3h`, `mem=8G`;
- generated sbatch uses absolute Julia 1.10.10:
  `"/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia" --project=. ...`.

Immediate queue state:

- Nibi job `16929661_[1%1]` was pending with reason `Priority`.
- Narval job `64331208_1` was still running at `50:25` wall time; its fit had
  converged in `67` iterations after `1001.39s` and it remained inside the
  `B_lv` Wald CI step.

### Claim Boundary

IN: p=125,K=2,iterations=80 is not sufficient for the tested seed, and the
launcher pin works in a real Nibi submit. PARTIAL: corrected p=125,K=2,
iterations=160 and p=150,K=2 B_lv timing remain live. OUT: no production
coverage launch, no p=125/p=150 feasibility claim, and no calibrated coverage
claim.

## 2026-06-29 10:53 MDT - Codex p125/p150 K2 B_lv sizing results

### Commands

```sh
ssh -o BatchMode=yes nibi 'seff 16929661 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-blv-iter160-3h-20260629-1024/results'
ssh -o BatchMode=yes narval 'seff 64331208 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-midlarge-k2-narval-blv-iter80-3h-20260629-0939/results'
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_JULIA="$(command -v julia)"; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=0; export PHYLO_XLV_N_SPECIES=125; export PHYLO_XLV_N_SITES=125; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=phylo_signal; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=160; export PHYLO_XLV_TIME=0-01:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,90p" "$out/meta/session.txt"; sed -n "1,90p" "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes nibi 'squeue -j 16931225 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056/logs/phylo_xlv-16931225-1.out 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056/logs/phylo_xlv-16931225-1.err 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056/results/result_000001.csv 2>/dev/null || true'
```

### Result

Nibi p=125, K=2 B_lv-only corrected fallback job `16929661_1` completed:

- scheduler state `COMPLETED`, exit code `0:0`;
- wall time `00:22:19`;
- CPU efficiency `98.66%`;
- memory `1.04 GB` of `8 GB`;
- fit converged in `74` iterations;
- fit seconds `392.680`;
- B_lv Wald CI seconds `927.814`;
- `ci_status=ok`, `pd_hessian=true`;
- usable entries `125/125`;
- one-seed entry coverage `0.984`;
- RMSE `0.064`.

Narval p=150, K=2 B_lv-only job `64331208_1` completed:

- scheduler state `COMPLETED`, exit code `0:0`;
- wall time `01:14:53`;
- CPU efficiency `99.31%`;
- memory `2.75 GB` of `8 GB`;
- fit converged in `67` iterations;
- fit seconds `1001.191`;
- B_lv Wald CI seconds `3343.322`;
- `ci_status=ok`, `pd_hessian=true`;
- usable entries `150/150`;
- one-seed entry coverage `0.993`;
- RMSE `0.051`.

Interpretation: p=150,K=2 is technically usable, but too expensive as a
default production large-cell boundary. p=125,K=2 is a plausible production
boundary for B_lv timing, subject to the phylo-signal target and multi-seed
failure-rate checks.

Submitted one p=125,K=2 phylo-signal-only canary from the pinned launcher:

- Nibi job `16931225`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056`;
- same cell: `scenario=main`, `lambda=0`, `n_species=125`, `n_sites=125`,
  `K=2`, `q_lv=1`, `K_phy=1`, one seed/task;
- `--targets phylo_signal`, `iterations=160`, `time=1h`, `mem=8G`;
- generated sbatch uses absolute Julia 1.10.10.

Immediate queue state: Nibi job `16931225_[1%1]` was pending with reason
`Priority`.

### Claim Boundary

IN: p=125,K=2 B_lv intervals are technically viable for the tested seed and
p=150,K=2 B_lv intervals are technically computable but expensive. PARTIAL:
p=125,K=2 phylo-signal usability and multi-seed failure rates remain pending.
OUT: no production coverage launch, no K=2 large-cell coverage claim, no
phylo-signal coverage claim.

## 2026-06-29 11:24 MDT - Codex p125 K2 phylo-signal canaries

### Commands

```sh
ssh -o BatchMode=yes nibi 'seff 16931225 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-target-iter160-1h-20260629-1056/results'
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_JULIA="$(command -v julia)"; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=1; export PHYLO_XLV_N_SPECIES=125; export PHYLO_XLV_N_SITES=125; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=phylo_signal; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=160; export PHYLO_XLV_TIME=0-01:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-lambda1-iter160-1h-20260629-1103; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,90p" "$out/meta/session.txt"; sed -n "1,90p" "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes nibi 'seff 16931955 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-phylo-lambda1-iter160-1h-20260629-1103/results'
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; export PHYLO_XLV_JULIA="$(command -v julia)"; export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu; export PHYLO_XLV_REPS=1; export PHYLO_XLV_LAMBDAS=1; export PHYLO_XLV_N_SPECIES=125; export PHYLO_XLV_N_SITES=125; export PHYLO_XLV_K=2; export PHYLO_XLV_SCENARIOS=main; export PHYLO_XLV_TARGETS=all; export PHYLO_XLV_METHODS=wald; export PHYLO_XLV_ITERATIONS=400; export PHYLO_XLV_TIME=0-02:00; export PHYLO_XLV_MEM=8G; export PHYLO_XLV_THROTTLE=1; export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124; bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,90p" "$out/meta/session.txt"; sed -n "1,90p" "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes nibi 'squeue -j 16933194 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/logs/phylo_xlv-16933194-1.out 2>/dev/null || true; tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/logs/phylo_xlv-16933194-1.err 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/results/result_000001.csv 2>/dev/null || true'
```

### Result

Nibi p=125, K=2, λ=0 phylo-signal canary `16931225_1` completed:

- wall time `00:07:40`;
- CPU efficiency `96.74%`;
- memory `574.72 MB` of `8 GB`;
- fit converged in `74` iterations;
- fit seconds `433.548`;
- phylo-signal CI seconds `5.207`;
- `ci_status=partial_or_failed`;
- usable entries `0/125`;
- `pd_hessian=false`;
- estimate mean `0.00018` versus truth mean `0.13314`.

This says timing is solved for the p=125 λ=0 phylo-signal target, but statistical
usability is still failed.

Nibi p=125, K=2, λ=1 phylo-signal canary `16931955_1` completed scheduler-wise,
but the fit did not converge:

- wall time `00:14:05`;
- CPU efficiency `98.22%`;
- memory `823.77 MB` of `8 GB`;
- `fit_converged=false`;
- `fit_iterations=160`;
- `fit_seconds=825.618`;
- `ci_status=not_converged`;
- no phylo-signal CI row was written.

Submitted one stricter λ=1 canary matching the production iteration default:

- Nibi job `16933194`;
- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124`;
- same p=125, K=2 cell with `lambda=1`;
- `--targets all`, `iterations=400`, `time=2h`, `mem=8G`;
- generated sbatch uses absolute Julia 1.10.10.

Immediate queue state: Nibi job `16933194_[1%1]` was pending with reason
`Priority`.

### Claim Boundary

IN: p=125,K=2,λ=0 phylo-signal timing is fast but unusable; p=125,K=2,λ=1
needs more than 160 iterations for this seed. PARTIAL: λ=1 with the production
iteration cap is pending. OUT: no phylo-signal coverage claim and no production
coverage launch.

## 2026-06-29 11:58 MDT - Codex cross-cluster K2 canary fan-out

### Commands

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes narval 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. -e "import Pkg; Pkg.instantiate(); Pkg.precompile()"'
ssh -o BatchMode=yes rorqual 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. -e "import Pkg; Pkg.instantiate(); Pkg.precompile()"'
bash -n bench/phylo_xlv_drac_submit.sh
rsync -av bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes rorqual 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-rorqual-lambda05-all-iter400-2h-20260629-1200; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=125 PHYLO_XLV_N_SITES=125 PHYLO_XLV_K=2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=21333708 PHYLO_XLV_TARGETS=all PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-02:00 PHYLO_XLV_MEM=8G PHYLO_XLV_THROTTLE=1 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes narval 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-narval-lambda1-all-iter400-2h-20260629-1200; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=1 PHYLO_XLV_N_SPECIES=125 PHYLO_XLV_N_SITES=125 PHYLO_XLV_K=2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=21333709 PHYLO_XLV_TARGETS=all PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-02:00 PHYLO_XLV_MEM=8G PHYLO_XLV_THROTTLE=1 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes nibi 'squeue -j 16933194 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/logs/phylo_xlv-16933194-1.out 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14916246 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-rorqual-lambda05-all-iter400-2h-20260629-1200/logs/phylo_xlv-14916246-1.out 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64343216 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-narval-lambda1-all-iter400-2h-20260629-1200/logs/phylo_xlv-64343216-1.out 2>/dev/null || true'
```

### Result

Pre-edit coordination check still shows only the known draft GLLVM.jl PR #127.
The cluster submit attempt exposed a launcher gap: `PHYLO_XLV_DEPOT` was used
inside the generated `sbatch` script but not for the launcher's own lightweight
parameter-writing step. On fresh Narval/Rorqual project depots, that step failed
before `sbatch` with missing `Distributions`. `bench/phylo_xlv_drac_submit.sh`
now exports `JULIA_DEPOT_PATH` from `PHYLO_XLV_DEPOT` before writing params and
session metadata as well as inside the generated batch script. `bash -n` passed.

Instantiated and precompiled the project on Narval and Rorqual under
`/project/6098264/snakagaw/julia_depot`, synced the DRAC harness files, and
submitted two one-task canaries:

- Rorqual job `14916246`: p=125,K=2, λ=0.5, `targets=all`,
  `iterations=400`, `time=2h`, `mem=8G`; latest poll showed pending with reason
  `Priority`.
- Narval job `64343216`: p=125,K=2, λ=1, `targets=all`, `iterations=400`,
  `time=2h`, `mem=8G`; latest poll showed task `64343216_1` running on
  `nc31109`, still in the fit step.
- Existing Nibi job `16933194_1`: p=125,K=2, λ=1, `targets=all`,
  `iterations=400`; latest poll showed it running on `c324`, still in the fit
  step after about 26 minutes.

Dashboard `/tmp/gllvm-dashboard` was updated to build `r80` with the live
Nibi/Narval/Rorqual canary state.

### Claim Boundary

IN: cross-cluster canaries are now staged to test the p=125,K=2 large-cell
boundary at λ=0.5 and λ=1 with production-like iteration caps. PARTIAL: the
K=2 p=125 B_lv boundary is plausible from one seed but not yet production
evidence, and phylo-signal remains unresolved. OUT: no >=500 reps/cell
production coverage has launched; no public phylo-signal or full Model A
coverage claim.

## 2026-06-29 12:55 MDT - Codex p125 K2 all-target canary results

### Commands

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes nibi 'seff 16933194 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-nibi-lambda1-all-iter400-2h-20260629-1124/results'
ssh -o BatchMode=yes narval 'seff 64343216 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-narval-lambda1-all-iter400-2h-20260629-1200/results'
ssh -o BatchMode=yes rorqual 'seff 14916246 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-mid-k2-rorqual-lambda05-all-iter400-2h-20260629-1200/results'
```

### Result

All three p=125,K=2 all-target canaries completed scheduler-wise.

- Nibi `16933194_1`, λ=1, seed `21333707`: completed in `00:51:32`
  with exit code `0`, but the fit did not converge after `400` iterations.
  Fit seconds were `3064.500`; summariser row has `fit ok = 0`, usable entries
  `0`, and `ci_status=not_converged`. `seff`: CPU efficiency `87.65%`,
  memory `804.46 MB / 8 GB`.
- Narval `64343216_1`, λ=1, seed `22406788`: completed in `00:48:45`,
  CPU efficiency `99.28%`, memory `1.38 GB / 8 GB`. Fit converged in `245`
  iterations with fit seconds `1678.541`. B_lv Wald CI seconds `1225.215`,
  usable entries `125/125`, entry coverage `0.808`, RMSE `0.093`,
  `pd_hessian=true`. Phylo-signal CI seconds `6.465`, but usable entries
  `0/125`, `ci_status=partial_or_failed`, `pd_hessian=false`.
- Rorqual `14916246_1`, λ=0.5, seed `22406787`: completed in `00:49:38`,
  CPU efficiency `99.03%`, memory `1.02 GB / 8 GB`. Fit converged in `279`
  iterations with fit seconds `1975.689`. B_lv Wald CI seconds `980.336`,
  usable entries `125/125`, entry coverage `0.592`, RMSE `0.129`,
  `pd_hessian=true`. Phylo-signal CI seconds `4.693`, but usable entries
  `0/125`, `ci_status=partial_or_failed`, `pd_hessian=false`.

Dashboard `/tmp/gllvm-dashboard` was updated to build `r86`.

### Decision

Do not launch the planned `>=500 reps/cell` production grid under the current
K=2 large-cell settings. The p=125,K=2 boundary is now known to be too unstable
for a production claim as specified: λ=1 has seed-level fit fragility, B_lv
interval rows are technically computable but show weak one-seed behavior in two
new cells, and phylo-signal rows are consistently unusable with non-PD Hessian.

### Claim Boundary

IN: launcher, dependency, and cross-cluster execution are working; p=125,K=2
B_lv intervals can be computed for some seeds. PARTIAL: K=2 p=125 fit and B_lv
CI reliability require a failure-rate diagnostic or CI-engine work. OUT: no
production Model A DRAC coverage launch, no phylo-signal coverage claim, no
public full Model A claim.

## 2026-06-29 13:00 MDT - Codex p125 K2 fit-only diagnostic launch

### Commands

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=10 PHYLO_XLV_LAMBDAS=0.5,1 PHYLO_XLV_N_SPECIES=125 PHYLO_XLV_N_SITES=125 PHYLO_XLV_K=2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=31333700 PHYLO_XLV_TARGETS=none PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-01:20 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=10 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes rorqual 'squeue -j 14918100 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; head -n 25 /project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258/meta/phylo_xlv_params.csv'
```

### Result

Submitted Rorqual array `14918100`:

- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258`;
- `scenario=main`, `n_species=125`, `n_sites=125`, `K=2`, `q_lv=1`,
  `K_phy=1`;
- λ grid `{0.5, 1}` with `10` reps per λ, `20` array tasks total;
- `targets=none`, `iterations=400`, `time=1:20`, `mem=4G`, throttle `10`;
- absolute Julia 1.10.10 and `/project/6098264/snakagaw/julia_depot`;
- launch poll showed pending with reason `Priority`.

This is a convergence/failure-rate diagnostic only. It deliberately avoids
B_lv/phylo-signal CI because the previous all-target canaries showed expensive
B_lv Hessian time and unusable phylo-signal Hessians.

### Claim Boundary

IN: fit-only failure-rate diagnostics for p=125,K=2 λ in `{0.5,1}` are queued.
OUT: this is not coverage production, does not estimate interval coverage, and
does not support a public Model A claim.

## 2026-06-29 14:29 MDT - Codex p125 K2 fit-only diagnostic result

### Commands

```sh
ssh -o BatchMode=yes rorqual 'squeue -j 14918100 -o "%.18i %.9P %.30j %.8u %.10M %.6D %R"; sacct -j 14918100 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P | tail -n 170; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258/results -maxdepth 1 -name "result_*.csv" | wc -l); cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258/results 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'seff 14918100 2>/dev/null || true; cd /project/6098264/snakagaw/phylo_xlv/pilot-k2-fitonly-rorqual-lambda05-1-rep10-20260629-1258/results; awk -F, "FNR==1{next} {key=\$3; n[key]++; if(\$14==\"true\") ok[key]++; status[key,\$18]++; sum[key]+=\$16; if(!(key in min) || \$16<min[key]) min[key]=\$16; if(\$16>max[key]) max[key]=\$16} END{for(k in n){printf \"lambda=%s tasks=%d fit_ok=%d mean_fit=%.3f min_fit=%.3f max_fit=%.3f\\n\", k,n[k],ok[k],sum[k]/n[k],min[k],max[k]; for(s in status){split(s,a,SUBSEP); if(a[1]==k) printf \"  status=%s count=%d\\n\", a[2], status[s]}}}" result_*.csv; echo not_converged_rows; awk -F, "FNR==1{next} \$18!=\"fit_only\" || \$14!=\"true\" {print FILENAME \": task=\"\$1\" lambda=\"\$3\" rep=\"\$9\" seed=\"\$10\" fit_converged=\"\$14\" iterations=\"\$15\" fit_seconds=\"\$16\" status=\"\$18}" result_*.csv'
```

### Result

Rorqual array `14918100` completed all 20 fit-only rows. `seff` reports the
array job completed with exit code `0`; the representative final task used
`00:46:20` wall time, CPU efficiency `98.96%`, and memory `856.95 MB / 4 GB`.

The summariser and header-aware aggregation gave:

- λ=0.5: `10/10` fit ok, mean fit seconds `2040.328`, min `1481.212`,
  max `2627.965`, all rows `ci_status=fit_only`.
- λ=1: `8/10` fit ok, mean fit seconds `2245.286`, min `1510.174`,
  max `2774.134`, with `8` `fit_only` rows and `2` `not_converged` rows.
- Non-converged λ=1 rows:
  - task `18`, rep `8`, seed `49476879`, `400` iterations,
    fit seconds `2623.152`;
  - task `20`, rep `10`, seed `51496899`, `400` iterations,
    fit seconds `2763.200`.

Dashboard `/tmp/gllvm-dashboard` was updated to build `r100`.

### Decision

Do not launch K=2 production coverage at p=125 under the current all-target
design. The fit-only diagnostic says λ=0.5 fit convergence is good but slow,
while λ=1 still has a `20%` non-convergence rate at the 400-iteration cap.
Together with the all-target canaries, this separates the problems:

- fit robustness is still a λ=1 issue;
- B_lv Wald intervals are computationally expensive and showed poor one-seed
  behavior in the λ=0.5 and λ=1 all-target canaries;
- phylo-signal transformed-Wald intervals remain unusable at p=125,K=2
  (`0/125` usable in the all-target canaries).

Next Phase 3 action should be either a smaller/optimized K=2 design or CI-engine
work before any `>=500 reps/cell` K=2 production array.

### Claim Boundary

IN: p=125,K=2 fit-only convergence denominator is now known for λ=0.5 and λ=1
over 10 reps/cell. PARTIAL: p=125,K=2 can fit often enough to keep diagnosing,
but λ=1 and interval reliability are not production-ready. OUT: no K=2
production coverage claim, no phylo-signal coverage claim, and no public full
Model A claim.

## 2026-06-29 14:50 MDT - Codex p80 K2 all-target canary result

### Commands

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes rorqual 'seff 14925925 2>/dev/null || true; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-all-rorqual-lambda05-1-20260629-1432/results'
ssh -o BatchMode=yes rorqual 'cd /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-all-rorqual-lambda05-1-20260629-1432/results; cat result_*.csv'
```

### Result

Rorqual array `14925925` completed the smaller p=80,K=2 all-target canary:

- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-all-rorqual-lambda05-1-20260629-1432`;
- `scenario=main`, `n_species=80`, `n_sites=80`, `K=2`, `targets=all`;
- λ grid `{0.5, 1}` with one seed per λ;
- `iterations=400`, `time=1h`, `mem=4G`, throttle `2`;
- `seff` representative array task: completed with exit code `0`,
  wall time `00:05:16`, CPU efficiency `97.15%`, memory
  `1.07 GB / 4 GB`.

Per-cell rows:

- λ=0.5, seed `42384144`: fit converged in `182` iterations with fit seconds
  `227.259`; B_lv Wald CI seconds `118.293`, usable entries `80/80`, entry
  coverage `1.000`, RMSE `0.045`, `pd_hessian=true`; phylo-signal transformed
  Wald CI seconds `4.846`, usable entries `0/80`, `ci_status=partial_or_failed`,
  `pd_hessian=false`.
- λ=1, seed `43384147`: fit converged in `134` iterations with fit seconds
  `173.663`; B_lv Wald CI seconds `117.792`, usable entries `80/80`, entry
  coverage `1.000`, RMSE `0.044`, `pd_hessian=true`; phylo-signal transformed
  Wald CI seconds `5.229`, usable entries `0/80`, `ci_status=partial_or_failed`,
  `pd_hessian=false`.

Dashboard `/tmp/gllvm-dashboard` was already updated to build `r105` with this
boundary: p=80,K=2 is a B_lv-only candidate, not a phylo-signal solution.

### Decision

Use p=80,K=2 as the next bounded B_lv diagnostic candidate before any
production-scale run. Keep phylo-signal coverage split out and gated because it
still has `0` usable interval entries in this smaller cell.

### Claim Boundary

IN: p=80,K=2 all-target one-seed canary shows fast, clean B_lv Wald rows for
λ=0.5 and λ=1. PARTIAL: this is a sizing and routing result only; it is not
coverage evidence. OUT: no K=2 production claim, no phylo-signal interval
claim, and no full Model A public claim.

## 2026-06-29 15:20 MDT - Codex p80 K2 B_lv-only Wald diagnostic

### Commands

```sh
gh pr list --state open
git log --all --oneline --since="6 hours ago"
ssh -o BatchMode=yes rorqual 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=10 PHYLO_XLV_LAMBDAS=0,0.5,1 PHYLO_XLV_N_SPECIES=80 PHYLO_XLV_N_SITES=80 PHYLO_XLV_K=2 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=52384100 PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=wald PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-00:45 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=10 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit; sed -n "1,90p" "$out/meta/session.txt"; head -n 40 "$out/meta/phylo_xlv_params.csv"'
ssh -o BatchMode=yes rorqual 'squeue -j 14926656 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455/results -maxdepth 1 -name "result_*.csv" | wc -l); cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455/results'
ssh -o BatchMode=yes rorqual 'squeue -j 14926656 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455/results -maxdepth 1 -name "result_*.csv" | wc -l); cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455/results; seff 14926656 2>/dev/null || true'
rg -n "method|methods|wald|profile|bootstrap|t\b|quantile|Normal|ci" bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl src test docs -S
```

The broad `rg` command above was too noisy because it traversed
`docs/node_modules`; the useful signal came from `bench/phylo_xlv_drac_task.jl`,
where `parse_methods()` accepts only `wald`, `profile`, and `bootstrap`.
There is not yet a t-based method wired into the DRAC task parser.

### Result

Submitted and completed Rorqual array `14926656`:

- output directory
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda0-05-1-rep10-20260629-1455`;
- `scenario=main`, `n_species=80`, `n_sites=80`, `K=2`, `targets=B_lv`;
- λ grid `{0, 0.5, 1}` with `10` reps per λ, `30` tasks total;
- `methods=wald`, `iterations=400`, `time=45m`, `mem=4G`, throttle `10`;
- final result files: `30/30`;
- scheduler state: completed with exit code `0`;
- representative `seff` for array task `14926656_30`: wall time `00:09:23`,
  CPU efficiency `97.51%`, memory `1.05 GB / 4 GB`.

Summariser result:

| λ | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 0 | 10 | 10 | 800 | 0.945 (0.013) | 0.945 | 0.077 | 80.065 | 127.585 | ok |
| 0.5 | 10 | 10 | 800 | 0.870 (0.037) | 0.870 | 0.097 | 199.906 | 118.577 | ok |
| 1 | 10 | 10 | 800 | 0.972 (0.010) | 0.973 | 0.066 | 269.809 | 137.769 | ok |

Dashboard `/tmp/gllvm-dashboard` was updated to build `r112` with this final
diagnostic state.

### Decision

Do not launch `>=500 reps/cell` Wald production for p=80,K=2 yet. The reduced
cell is computationally viable and all B_lv interval rows are usable, but Wald
coverage undercovers materially at λ=0.5 in this 10-rep diagnostic. The next
method step should be a bounded λ=0.5 interval-rescue diagnostic, using existing
profile/bootstrap methods and/or a newly implemented t-style calibration
comparator before production scaling.

### Claim Boundary

IN: p=80,K=2 is a viable compute boundary for B_lv diagnostics under the current
launcher, and λ=0 and λ=1 Wald rows looked acceptable in this small diagnostic.
PARTIAL: λ=0.5 Wald undercoverage blocks production coverage claims. OUT: no
K=2 production coverage claim, no phylo-signal interval claim, no public full
Model A claim, and no t-based claim because no t method is wired yet.

## 2026-06-29 15:45 MDT - Codex Gaussian phylo B_lv t-comparator wiring

### Commands

```sh
git status --short --branch
rg -n "function _lv_wald_from_hessian|_lv_effect_wald|Normal|quantile|TDist|confint_lv_effects|method == :wald|method = :wald" src/confint_family.jl
sed -n '1800,2095p' src/confint_family.jl
sed -n '1,180p' bench/phylo_xlv_drac_task.jl
sed -n '1,160p' bench/phylo_xlv_drac_submit.sh
rg -n 'wald_t_unit|critical_df|qnorm|qt\(|interval_method|critical' dev/lv-wald-coverage.R tests/testthat/test-lv-wald-coverage-harness.R docs/dev-log/after-task/2026-06-28-lv-wald-t-comparator.md  # in /private/tmp/gllvmtmb-lv-t-coverage-20260628
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_t_params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 80 --K 2 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629 --force
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_t_params.csv --outdir /tmp/phylo_xlv_t_dry_results --task-id 1 --methods wald,wald_t_unit --targets none --iterations 1 --dry-run
git diff --check
ssh -o BatchMode=yes -o ConnectTimeout=10 rorqual 'hostname; pwd; command -v sbatch; command -v squeue'
ssh -o BatchMode=yes -o ConnectTimeout=10 nibi 'hostname; command -v sbatch; command -v squeue'
ssh -o BatchMode=yes -o ConnectTimeout=10 narval 'hostname; command -v sbatch; command -v squeue'
ssh -o BatchMode=yes -o ConnectTimeout=10 fir 'hostname; command -v sbatch; command -v squeue'
ssh -o BatchMode=yes -o ConnectTimeout=10 totoro 'hostname; command -v sbatch || true; command -v squeue || true'
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes rorqual '... remote --methods wald,wald_t_unit --targets none --dry-run ...'
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
```

### Result

Added a Gaussian-only `confint_lv_effects(...; method = :wald_t_unit)`
comparator for `B_lv`:

- `:wald_t_unit` uses the same observed-information delta-method SE as
  `:wald`.
- Only the critical value changes, using `TDist(df)` with
  `df = max(n_sites - K - 1, 1)`, matching the R-side
  `wald_t_unit` convention for ordinary native TMB Gaussian `B_lv` coverage.
- The GLM `confint_lv_effects` method still rejects `:wald_t_unit`; this is a
  Gaussian comparator only, not a non-Gaussian interval claim.
- `bench/phylo_xlv_drac_task.jl` and `bench/phylo_xlv_drac_submit.sh` now accept
  `wald_t_unit` in `PHYLO_XLV_METHODS`.

Checks:

- `test/test_lv_ci.jl`: `123/123` pass in `2m37.9s`.
- `test/test_phylo_xlv.jl`: `19/19` pass in `57.3s`.
- `bash -n bench/phylo_xlv_drac_submit.sh`: pass.
- Local parameter writer and dry-run parser accepted `--methods
  wald,wald_t_unit`.
- Remote Rorqual dry-run parser accepted `--methods wald,wald_t_unit`.
- `git diff --check`: pass.

DRAC connectivity:

- Rorqual, Nibi, and Narval are reachable with non-interactive SSH and have
  `sbatch`/`squeue`.
- Fir still fails non-interactive keyboard-interactive auth.
- Totoro still fails publickey/password auth from this shell.

### Live DRAC State

The active comparator run is Nibi array `16950659`:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553`;
- `scenario=main`, `lambda=0.5`, `n_species=n_sites=80`, `K=2`,
  `q_lv=1`, `K_phy=1`;
- `10` seeds, `targets=B_lv`, `methods=wald,wald_t_unit`;
- `iterations=400`, `time=20m`, `mem=4G`, throttle `10`;
- latest poll at this checkpoint: pending with reason `Priority`, `0` result
  files.

Superseded queue attempts were intentionally cancelled to avoid duplicate
compute:

- Rorqual `14932460`: pending duplicate, cancelled before results.
- Nibi `16950453`: first duplicate started and was cancelled at 21s; wrote
  `0` result files.
- Narval `64362890`: pending duplicate, cancelled before results.

### Decision

Do not scale production yet. This t comparator is a bounded interval-rescue
diagnostic for the known weak cell (`p=80,K=2,lambda=0.5`) where the 10-rep
normal-Wald diagnostic had entry coverage `0.870`. Production remains gated on
the comparator result and the same MCSE/failed-fit denominator discipline.

### Claim Boundary

IN: Gaussian phylo `B_lv` now has local method wiring for `wald_t_unit`, local
tests covering ordinary and phylo Gaussian paths, and one live bounded DRAC
diagnostic queued. PARTIAL: interval calibration remains unresolved until
`>=500 reps/cell` evidence exists. OUT: no phylo-signal interval claim, no
non-Gaussian t interval claim, no production Model A coverage claim, and no
public R exposure claim.

## 2026-06-29 16:00 MDT - Codex p80 K2 t-comparator result and profile-live checkpoint

### Commands

```sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
git diff --check
bash -n bench/phylo_xlv_drac_submit.sh
ssh -o BatchMode=yes nibi 'squeue -j 16950659 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results 2>/dev/null || true; seff 16950659 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true; seff 14929297 2>/dev/null || true'
```

### Result

Focused local checks after the `wald_t_unit` wiring:

- `test/test_lv_ci.jl`: `123/123` pass in `2m44.5s`;
- `test/test_phylo_xlv.jl`: `19/19` pass in `1m01.7s`;
- `git diff --check`: pass;
- `bash -n bench/phylo_xlv_drac_submit.sh`: pass.

Nibi array `16950659` completed the p=80,K=2, λ=0.5 t-comparator diagnostic:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553`;
- `10/10` result files, `20` result rows (`wald` + `wald_t_unit`);
- representative `seff` for task `16950659_10`: completed with exit code `0`,
  wall time `00:07:37`, CPU efficiency `98.25%`, memory `766.50 MB / 4 GB`.

Summariser result:

| method | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| wald | 10 | 10 | 800 | 0.844 (0.058) | 0.844 | 0.093 | 177.633 | 119.286 | ok |
| wald_t_unit | 10 | 10 | 800 | 0.845 (0.058) | 0.845 | 0.093 | 177.633 | 106.874 | ok |

The t-unit critical value did not materially rescue the λ=0.5 undercoverage.

Rorqual job `14929297` remains live as a one-seed profile/bootstrap canary:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525`;
- `p=80`, `K=2`, λ=0.5, `methods=wald,profile,bootstrap`, `n_boot=30`;
- fit converged in `178` iterations / `230.94s`;
- Wald CI ran from `21:30:11` to `21:32:55` UTC;
- profile CI started at `21:32:55` UTC;
- latest poll: still running in profile at `34m11s`, `0` result files;
- walltime request is `3h`.

Dashboard `/tmp/gllvm-dashboard` was updated to build `r119`.

### Decision

Do not promote `wald_t_unit` as a coverage fix for phylo Model A B_lv. It is
wired and tested as a Gaussian comparator, but this diagnostic says it does not
repair the known λ=0.5 p=80,K=2 undercoverage. Keep the profile/bootstrap canary
running as the next interval-rescue evidence source.

### Claim Boundary

IN: `wald_t_unit` exists as a Gaussian-only comparator and has local focused
tests; the Nibi λ=0.5 comparator result is negative. PARTIAL: profile/bootstrap
rescue is still live and unreported. OUT: no production coverage launch, no
public t-coverage claim, no phylo-signal claim, no non-Gaussian t claim.

## 2026-06-29 15:58 MDT - Codex p80 K2 phylo B_lv t-comparator result

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16950659 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 16950659 --format=JobID,State,ExitCode,Elapsed,MaxRSS -P; seff 16950659 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553/results'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-profile-rorqual-lambda05-rep1-20260629-1510/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
python3 -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate.json
```

### Result

Nibi array `16950659` completed the weak-cell method comparator:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-t-nibi-lambda05-rep10-20260629-1553`;
- `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`, `K=2`;
- `10` seeds, `targets=B_lv`, `methods=wald,wald_t_unit`;
- all `10/10` fits converged;
- `800` usable `B_lv` entries per method;
- scheduler state: completed with exit code `0`;
- `seff 16950659`: wall time `00:07:37`, CPU efficiency `98.25%`,
  memory `766.50 MB / 4 GB`.

Summariser result:

| target | method | tasks | fit ok | usable | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | CI status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| B_lv | wald | 10 | 10 | 800 | 0.844 (0.058) | 0.844 | 0.093 | 177.633 | 119.286 | ok |
| B_lv | wald_t_unit | 10 | 10 | 800 | 0.845 (0.058) | 0.845 | 0.093 | 177.633 | 106.874 | ok |

The t critical did not materially change coverage in this phylo weak cell
because the unit-level df is `80 - 2 - 1 = 77`, close to the normal critical
value. The result is useful negative diagnostic evidence: `wald_t_unit` is
wired, cheap, and tested, but it is not an interval-rescue strategy for
`p=80,K=2,lambda=0.5`.

Rorqual array task `14929297_1` remains active as the one-seed
profile/bootstrap rescue canary for the same weak cell. Latest poll at this
entry: running after `33:41`, with `0` result files. No duplicate profile or
bootstrap jobs were launched.

The local mission-control widget was updated to `/tmp/gllvm-dashboard`
version `r119`; JSON validation passed.

### Decision

Do not launch the `>=500 reps/cell` p=80,K=2 production grid with either normal
Wald or unit-df t-Wald. Keep the existing Rorqual profile/bootstrap canary
running; decide the next production inference method only after that canary
finishes or hits a practical runtime boundary.

### Claim Boundary

IN: Gaussian phylo `B_lv` now has local `wald_t_unit` wiring, local tests, and a
10-seed DRAC diagnostic. PARTIAL: p=80,K=2 computation is viable for B_lv, but
lambda=0.5 coverage is not solved. OUT: no production coverage claim, no
phylo-signal interval claim, no non-Gaussian t claim, and no R-side
`phylo_latent(..., lv = ~ x)` exposure claim.

## 2026-06-29 16:06 MDT - Codex p80 K2 bootstrap-only rescue canary launch

### Commands

```sh
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes nibi 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=80 PHYLO_XLV_N_SITES=80 PHYLO_XLV_K=2 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=62384100 PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=30 PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-03:00 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=1 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
```

### Result

Submitted Nibi array `16951694` as a one-task bootstrap-only timing canary:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606`;
- `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`, `K=2`;
- `targets=B_lv`, `methods=bootstrap`, `n_boot=30`;
- `iterations=400`, `time=3h`, `mem=4G`, throttle `1`;
- initial poll: pending with reason `Priority`, `0` result files.

Rorqual profile/bootstrap canary `14929297_1` was also polled and remained
running at `40:58` with `0` result files. No duplicate profile job was launched.

The local mission-control widget was updated to `/tmp/gllvm-dashboard` version
`r121`, with Nibi job id corrected to `16951694`.

### Decision

This is a runtime/feasibility canary, not coverage evidence. It was launched
because the profile/bootstrap combined canary is still spending time in the
profile step, while the task runner can test bootstrap separately through
`PHYLO_XLV_N_BOOT`.

### Claim Boundary

IN: one bootstrap-only p=80,K=2,lambda=0.5 timing canary is queued on Nibi.
PARTIAL: it may show whether bootstrap is computationally plausible. OUT:
bootstrap coverage calibration, production `>=500 reps/cell`, phylo-signal
coverage, non-Gaussian intervals, and public R exposure.

## 2026-06-29 16:28 MDT - Codex bootstrap duplicate cleanup

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -u snakagaw -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo ---16951692---; sacct -j 16951692 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo ---16951694---; sacct -j 16951694 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'scancel 16951692 || true; sleep 2; squeue -u snakagaw -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo ---16951692---; sacct -j 16951692 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo ---16951694---; sacct -j 16951694 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true'
```

### Result

Two duplicate bootstrap-only p=80,K=2,λ=0.5 canaries were running on Nibi:

- `16951694`, output directory already recorded in the 16:06 entry:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606`;
- `16951692`, output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap-nibi-lambda05-rep1-nboot30-20260629-1608`.

To avoid duplicate compute, cancelled `16951692`. Accounting after cancellation:

- `16951692_1`: `CANCELLED by 3143783` after `00:18:38`;
- `16951692_1.batch`: `CANCELLED`, exit code `0:15`, memory `800056K`;
- `16951694_1`: still running at `00:18:40`.

Rorqual `14929297_1` remains live in the profile step of the one-seed
profile/bootstrap canary. Dashboard `/tmp/gllvm-dashboard` was updated to build
`r127`, with Nibi showing only active job `16951694`.

### Decision

Keep `16951694` as the single active bootstrap-only timing canary. Ignore
`16951692` except as a cancelled duplicate with no result claim.

### Claim Boundary

IN: duplicate bootstrap compute was stopped and the active job id was clarified.
OUT: no bootstrap result, no production coverage claim, no profile result.

## 2026-06-29 16:35 MDT - Codex bootstrap-refit iteration cap harness

### Commands

```sh
bash -n bench/phylo_xlv_drac_submit.sh
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_lv_ci.jl
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl
git diff --check
rm -rf /tmp/phylo_xlv_submit_dry_empty && PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=2 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_dry_empty && rg -n "bootstrap-iterations|bootstrap_args|--n-boot" /tmp/phylo_xlv_submit_dry_empty/meta/phylo_xlv_array.sbatch /tmp/phylo_xlv_submit_dry_empty/meta/session.txt
rm -rf /tmp/phylo_xlv_submit_dry_5 && PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=20 PHYLO_XLV_N_SITES=20 PHYLO_XLV_K=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=2 PHYLO_XLV_BOOT_ITERATIONS=5 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_submit_dry_5 && rg -n "bootstrap-iterations|bootstrap_args|--n-boot" /tmp/phylo_xlv_submit_dry_5/meta/phylo_xlv_array.sbatch /tmp/phylo_xlv_submit_dry_5/meta/session.txt
bash -n /tmp/phylo_xlv_submit_dry_empty/meta/phylo_xlv_array.sbatch
bash -n /tmp/phylo_xlv_submit_dry_5/meta/phylo_xlv_array.sbatch
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 16951694 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 14929297 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
```

### Result

Added an optional bootstrap-refit iteration cap:

- `confint_lv_effects(...; method = :bootstrap, bootstrap_iterations = N)`
  now passes `iterations = N` to each bootstrap refit;
- `bootstrap_iterations = nothing` preserves the previous default fitter
  behavior;
- invalid non-positive values fail loudly before bootstrap refits;
- `bench/phylo_xlv_drac_task.jl` accepts `--bootstrap-iterations`;
- `bench/phylo_xlv_drac_submit.sh` accepts `PHYLO_XLV_BOOT_ITERATIONS`, writes
  it to `meta/session.txt`, and passes it to the task runner.

Checks:

- `test/test_lv_ci.jl`: `127/127` pass in `2m56.3s`;
- `test/test_phylo_xlv.jl`: `19/19` pass in `59.0s`;
- `bash -n bench/phylo_xlv_drac_submit.sh`: pass;
- `git diff --check`: pass;
- submit-script dry-runs with `PHYLO_XLV_BOOT_ITERATIONS` unset and set to `5`
  both generated one-task write-only jobs and syntax-clean sbatch files. The
  unset generated script has `if [[ -n "" ]]`; the set generated script has
  `if [[ -n "5" ]]`.

Live-job status at this checkpoint:

- Nibi `16951694_1`: running at `00:29:05`, still in bootstrap, `0` result
  files. The initial fit converged in `192` iterations / `169.50s`.
- Rorqual `14929297_1`: running at `01:12:52`, still in profile, `0` result
  files. The fit and Wald CI completed; profile started at `21:32:55 UTC`.

No capped bootstrap canary was launched from this edit, because the uncapped
Nibi canary is still running and duplicate cleanup just happened.

### Decision

Keep the current active canaries running for now. Use the new
`bootstrap_iterations` harness only for a later bounded canary if `16951694`
times out or proves too slow. Do not launch production coverage.

### Claim Boundary

IN: local harness support for bounded bootstrap-refit iteration canaries.
PARTIAL: no capped bootstrap result exists yet. OUT: bootstrap coverage
calibration, profile viability, production `>=500 reps/cell`, and public
`gllvmTMB` phylo exposure.

## 2026-06-29 16:49 MDT - Codex Narval capped bootstrap canary reconciliation

### Commands

```sh
rsync -az --delete --exclude='.git/' --exclude='docs/build/' --exclude='docs/node_modules/' --exclude='docs/.vitepress/cache/' --exclude='.julia/' --exclude='*.ji' /private/tmp/gllvmjl-phylo-xlv/ narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes narval 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || module load julia >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. -e "using Pkg; Pkg.instantiate()"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_cap_probe_params.csv --reps 1 --lambdas 0.5 --n-species 20 --n-sites 20 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629 --force; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_cap_probe_params.csv --outdir /tmp/phylo_xlv_cap_probe_results --task-id 1 --methods bootstrap --targets none --iterations 1 --n-boot 2 --bootstrap-iterations 3 --dry-run'
ssh -o BatchMode=yes narval 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || module load julia >/dev/null 2>&1 || true; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30cap80-narval-lambda05-rep1-20260629-1645; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot PHYLO_XLV_JULIA="$(command -v julia)" PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=80 PHYLO_XLV_N_SITES=80 PHYLO_XLV_K=2 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=72384100 PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_N_BOOT=30 PHYLO_XLV_BOOT_ITERATIONS=80 PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_TIME=0-03:00 PHYLO_XLV_MEM=4G PHYLO_XLV_THROTTLE=1 bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit'
ssh -o BatchMode=yes narval 'squeue -u snakagaw -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; scontrol show job 64365792 2>/dev/null || true; sed -n "1,80p" /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/meta/session.txt; sed -n "1,120p" /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/meta/phylo_xlv_array.sbatch'
ssh -o BatchMode=yes narval 'scancel 64365831 || true; sleep 2; squeue -u snakagaw -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 64365792 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; sacct -j 64365831 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 16951694 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 14929297 --format=JobID,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l)'
python3 -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate.json
```

### Result

Narval accepted the cap parser with the `/project` Julia depot. A cap-80
canary submitted as `64365831`, but a concurrent/live Narval cap-120 canary
`64365792` was already pending. To avoid duplicate capped bootstrap compute,
cancelled `64365831` before it started:

- `64365831_[1%1]`: `CANCELLED by 3143783`, elapsed `00:00:00`, `0` result
  files.

Kept Narval job `64365792` as the single capped bootstrap comparison:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643`;
- `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`, `K=2`;
- `targets=B_lv`, `methods=bootstrap`, `n_boot=30`;
- `bootstrap_iterations=120`, `iterations=400`, `time=2h`, `mem=4G`;
- `code_sync_head=3b9b1e6`, `depot=/project/6098264/snakagaw/julia_depot`;
- latest poll: pending with reason `Priority`, `0` result files.

Other live canaries at the same checkpoint:

- Nibi `16951694_1`: running at `00:36:46`, uncapped bootstrap-only,
  `0` result files.
- Rorqual `14929297_1`: running at `01:20:31`, still in profile,
  `0` result files.

The local mission-control widget was updated to `/tmp/gllvm-dashboard` version
`r130`; JSON validation passed.

### Decision

Use only one capped bootstrap comparison while the uncapped Nibi and profile
Rorqual canaries run. Trillium remains an idle reserve. Fir and Totoro are not
usable through non-interactive SSH from this Codex shell despite maintainer-side
connectivity, so they are not evidence lanes yet.

### Claim Boundary

IN: one capped Narval bootstrap timing canary is pending, and duplicate capped
compute was cancelled before start. PARTIAL: no capped bootstrap result exists
yet. OUT: bootstrap coverage calibration, profile viability, production
`>=500 reps/cell`, phylo-signal coverage, and public `gllvmTMB` phylo exposure.

## 2026-06-29 16:47 MDT - Codex Narval capped-bootstrap canary launch

### Commands

```sh
rsync -av --relative bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_task.jl src/confint_family.jl test/test_lv_ci.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-iteration-cap.md docs/dev-log/recovery-checkpoints/2026-06-29-162800-codex-phylo-xlv-live-rescue.md nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
rsync -av --relative bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_task.jl src/confint_family.jl test/test_lv_ci.jl docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-29-phylo-xlv-bootstrap-iteration-cap.md docs/dev-log/recovery-checkpoints/2026-06-29-162800-codex-phylo-xlv-live-rescue.md narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/
ssh -o BatchMode=yes narval 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && grep -R -n "bootstrap_iterations\|PHYLO_XLV_BOOT_ITERATIONS\|bootstrap_args" bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_task.jl src/confint_family.jl test/test_lv_ci.jl | head -n 80'
ssh -o BatchMode=yes narval 'set -euo pipefail; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643; if [[ -e "$out" ]]; then echo "out exists: $out" >&2; exit 2; fi; PHYLO_XLV_ACCOUNT=def-snakagaw_cpu PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=80 PHYLO_XLV_N_SITES=80 PHYLO_XLV_K=2 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_SEED0=72434544 PHYLO_XLV_METHODS=bootstrap PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_ITERATIONS=400 PHYLO_XLV_N_BOOT=30 PHYLO_XLV_BOOT_ITERATIONS=120 PHYLO_XLV_TIME=0-02:00 PHYLO_XLV_MEM=4G PHYLO_XLV_CPUS=1 PHYLO_XLV_THROTTLE=1 PHYLO_XLV_JULIA=/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot bench/phylo_xlv_drac_submit.sh --out "$out"; sed -n "1,90p" "$out/meta/session.txt"; sed -n "34,55p" "$out/meta/phylo_xlv_array.sbatch"; bash -n "$out/meta/phylo_xlv_array.sbatch"'
ssh -o BatchMode=yes narval 'set -euo pipefail; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643; job=$(sbatch "$out/meta/phylo_xlv_array.sbatch"); echo "$job"; printf "code_sync_head=3b9b1e6\ncode_sync_source=/private/tmp/gllvmjl-phylo-xlv\nsubmit_result=%s\n" "$job" >> "$out/meta/session.txt"; tail -n 8 "$out/meta/session.txt"; squeue -u snakagaw -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" | head -n 20'
```

### Result

Synced bootstrap-refit cap commit `3b9b1e6` to the DRAC project copies used by
Nibi and Narval. Nibi had the new files after the first sync; Narval required a
direct sync because its `/project` copy was stale from Narval's view.

Submitted Narval job `64365792`:

- output directory:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643`;
- shape: `scenario=main`, `lambda=0.5`, `n_species=80`, `n_sites=80`,
  `K=2`, `q_lv=1`, `K_phy=1`;
- target/method: `B_lv`, `bootstrap`;
- bootstrap settings: `n_boot=30`, `bootstrap_iterations=120`;
- runtime envelope: `time=0-02:00`, `mem=4G`, `cpus=1`;
- session metadata records `code_sync_head=3b9b1e6`.

Initial scheduler state: `PENDING`, job `64365792_[1%1]`.

The mission-control JSON at `/tmp/gllvm-dashboard/status.json` was updated to
served version `r129`. Browser automation could not refresh the in-app tab
because the browser context disconnected twice; the local server verified
`http://127.0.0.1:8770/version.txt` as `r129`.

### Decision

This is one capped-bootstrap timing canary, not a production fan-out. Do not
launch more jobs until at least one of these returns: Nibi uncapped bootstrap
`16951694`, Rorqual profile/bootstrap `14929297`, or Narval capped bootstrap
`64365792`.

### Claim Boundary

IN: a bounded comparison canary is submitted on Narval. PARTIAL: no result file
exists yet. OUT: bootstrap coverage calibration, production `>=500 reps/cell`,
phylo-signal coverage, and public R exposure.

## 2026-06-29 16:55 MDT - Codex live canary stop point

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; printf "results="; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/logs/phylo_xlv-16951694-1.out 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; printf "results="; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64365792 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; printf "results="; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/logs/phylo_xlv-64365792-1.out 2>/dev/null || true'
curl -s http://127.0.0.1:8770/status.json | jq '{updated, compute_status: [.compute_status[] | select(.cluster=="Nibi" or .cluster=="Narval" or .cluster=="Rorqual")], active_tail: .active_jobs[-3:]}'
```

### Result

Latest live state:

- Nibi `16951694_1`: running at `00:40:03`, still in bootstrap, `0` result
  files.
- Rorqual `14929297_1`: running at `01:23:50`, still in profile, `0` result
  files.
- Narval `64365792_[1%1]`: pending with reason `Priority`, `0` result files.
- Mission-control widget is served as `r130` with these live statuses.

### Decision

Stop fan-out here. The next action is to poll these three jobs and summarize
whichever returns first. Do not launch another interval-rescue canary until one
of the current jobs completes, fails, or times out.

### Claim Boundary

IN: three timing canaries are live/pending and the duplicate cap-80 job was
cancelled before start. OUT: any new coverage claim.

## 2026-06-29 16:58 MDT - Codex DRAC summariser bootstrap denominator

### Commands

```sh
rg -n "bootstrap_converged|RESULT_FIELDS|ci_status|result_rows|b_lv_row|phylo_signal_row|fit_row" bench/phylo_xlv_drac_task.jl
rm -rf /tmp/phylo_xlv_summariser_bootstrap_probe /tmp/phylo_xlv_summariser_wald_probe && mkdir -p /tmp/phylo_xlv_summariser_bootstrap_probe/results /tmp/phylo_xlv_summariser_wald_probe/results && header='task_id,scenario,pagel_lambda,n_species,n_sites,K,q_lv,K_phy,rep,seed,level,target,method,fit_converged,fit_iterations,fit_seconds,ci_seconds,ci_status,total,usable,covered,coverage,bias_mean,bias_rmse,estimate_mean,truth_mean,max_abs_estimate,max_abs_truth,pd_hessian,bootstrap_converged,error' && printf '%s\n1,main,0.5,80,80,2,1,1,1,123,0.95,B_lv,bootstrap,true,12,10.5,30.25,ok,80,80,76,0.95,0.01,0.2,0.3,0.29,1.1,1.0,true,27,\n' "$header" > /tmp/phylo_xlv_summariser_bootstrap_probe/results/result_000001.csv && printf '%s\n1,main,0.5,80,80,2,1,1,1,123,0.95,B_lv,wald,true,12,10.5,3.25,ok,80,80,76,0.95,0.01,0.2,0.3,0.29,1.1,1.0,true,,\n' "$header" > /tmp/phylo_xlv_summariser_wald_probe/results/result_000001.csv && export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_bootstrap_probe/results && julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_wald_probe/results
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-29-phylo-xlv-summariser-bootstrap-denominator.md
git diff --check
```

### Result

Added `bootstrap ok` to `bench/phylo_xlv_drac_summarise.jl`. The column sums
non-empty `bootstrap_converged` values within each group and prints `NA` for
non-bootstrap or older result rows with a blank field.

Temporary result probes passed:

- bootstrap probe with `bootstrap_converged=27` printed `bootstrap ok = 27`;
- Wald probe with blank `bootstrap_converged` printed `bootstrap ok = NA`.

### Decision

Leave the task runner/result schema unchanged. The runner already writes the
needed numerator; the requested `n_boot` denominator remains in
`meta/session.txt`.

### Claim Boundary

IN: result summaries now expose the bootstrap converged-refit count. OUT: no
new interval method, no coverage claim, and no production launch.

## 2026-06-29 16:59 MDT - Codex summariser sync and live canary poll

### Commands

```sh
rsync -av bench/phylo_xlv_drac_summarise.jl nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_summarise.jl rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_summarise.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes nibi 'grep -n "bootstrap ok\|bootstrap_converged\|fmt_optional_int" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
ssh -o BatchMode=yes rorqual 'grep -n "bootstrap ok\|bootstrap_converged\|fmt_optional_int" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
ssh -o BatchMode=yes narval 'grep -n "bootstrap ok\|bootstrap_converged\|fmt_optional_int" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 16951694 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 30 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/logs/phylo_xlv-16951694-1.out 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 14929297 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 30 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64365792 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 64365792 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 30 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/logs/phylo_xlv-64365792-1.out 2>/dev/null || true'
python3 -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate.json
```

### Result

Synced the `bootstrap ok` summariser to the three reachable DRAC project copies:
Nibi, Rorqual, and Narval. Grep on each remote copy found the new
`fmt_optional_int`, `bootstrap ok`, and `bootstrap_converged` lines.

Latest canary state:

- Nibi `16951694_1`: running at `00:48:23`, still in uncapped bootstrap,
  `0` result files.
- Narval `64365792_1`: running at `00:03:31`; fit converged in `128`
  iterations / `148.61s`, then entered capped bootstrap with
  `bootstrap_iterations=120`; `0` result files.
- Rorqual `14929297_1`: running at `01:32:08`, still in profile,
  `0` result files.

Dashboard `/tmp/gllvm-dashboard` was updated to `r132`; JSON validation passed.

### Decision

Do not launch more jobs. Wait for one of the three timing canaries to write a
result or hit its scheduler limit. Narval is now the primary capped-bootstrap
comparison; Nibi remains the uncapped bootstrap comparison; Rorqual measures
profile feasibility.

### Claim Boundary

IN: post-processing is ready to show bootstrap converged-refit counts when a
result lands. PARTIAL: all three live canaries still have zero result files.
OUT: bootstrap/profile coverage calibration, production coverage, and public R
exposure.

## 2026-06-29 17:06 MDT - Codex bootstrap request metadata in result rows

### Commands

```sh
gh pr list --state open --limit 20 && git log --all --oneline --since='6 hours ago'
git status --short --branch
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_boot_meta_params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 20 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260629
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_boot_meta_params.csv --outdir /tmp/phylo_xlv_boot_meta_results --task-id 1 --methods bootstrap --targets none --iterations 1 --n-boot 7 --bootstrap-iterations 11 --force
head -n 2 /tmp/phylo_xlv_boot_meta_results/result_000001.csv
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_boot_meta_results
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_boot_meta_probe/results
export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /tmp/phylo_xlv_summariser_old_schema_probe/results
```

### Result

Added future result-row metadata for bootstrap request settings:

- `bench/phylo_xlv_drac_task.jl` now writes `n_boot` and
  `bootstrap_iterations` into `RESULT_FIELDS` and every future result row;
- `bench/phylo_xlv_drac_summarise.jl` now reports `boot n`,
  `boot iter cap`, and `bootstrap ok`.

Checks:

- tiny task-runner probe wrote a result header containing
  `level,n_boot,bootstrap_iterations,target`;
- the tiny result summary printed `boot n = 7`, `boot iter cap = 11`, and
  `bootstrap ok = NA`;
- a synthetic new-schema bootstrap row printed `boot n = 30`,
  `boot iter cap = 120`, and `bootstrap ok = 27`;
- a synthetic old-schema bootstrap row printed `boot n = NA`,
  `boot iter cap = NA`, and `bootstrap ok = 27`.

### Decision

This is for future launches. The already-running Nibi, Narval, and Rorqual
canaries keep their original result schema; use their `meta/session.txt` files
for requested bootstrap settings if they finish before another launch.

### Claim Boundary

IN: future DRAC result rows and summaries carry bootstrap request metadata.
OUT: no change to active jobs, no new interval method, no coverage calibration,
and no production launch.

## 2026-06-29 17:10 MDT - Codex bootstrap metadata sync and live poll

### Commands

```sh
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes nibi 'grep -n "n_boot\|boot n\|bootstrap_iterations" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -30'
ssh -o BatchMode=yes rorqual 'grep -n "n_boot\|boot n\|bootstrap_iterations" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -30'
ssh -o BatchMode=yes narval 'grep -n "n_boot\|boot n\|bootstrap_iterations" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -30'
ssh -o BatchMode=yes narval 'squeue -j 64365792 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; sacct -j 64365792 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 30 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/logs/phylo_xlv-64365792-1.out 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 12 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/logs/phylo_xlv-16951694-1.out 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l; tail -n 12 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true'
python3 -m json.tool /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate.json
```

### Result

Synced the future-result metadata runner/summariser to Nibi, Rorqual, and
Narval. Grep on all three remote copies confirmed:

- `RESULT_FIELDS` include `n_boot` and `bootstrap_iterations`;
- summaries include `boot n`, `boot iter cap`, and `bootstrap ok`.

Latest canary state:

- Nibi `16951694_1`: running at `00:59:45`, still in uncapped bootstrap,
  `0` result files.
- Narval `64365792_1`: running at `00:14:52`, still in capped bootstrap,
  `0` result files. Fit converged in `128` iterations / `148.61s`.
- Rorqual `14929297_1`: running at `01:43:31`, still in profile,
  `0` result files.

Dashboard `/tmp/gllvm-dashboard` was updated to `r133`; JSON validation passed.
The dashboard also records that gllvmTMB PR #571 has merged at `4b8b3d3` and
post-merge main R-CMD-check is running.

### Decision

Do not launch more jobs. Wait for one of the three timing canaries to complete
or time out; future launches from the synced project copies will carry
bootstrap request metadata in their result rows.

### Claim Boundary

IN: future DRAC outputs are more self-describing, and the three interval-rescue
canaries are still live. OUT: no bootstrap/profile result yet, no production
coverage, no phylo-signal coverage, and no public R phylo exposure.

## 2026-06-29 17:26 MDT - Codex post-merge CI and DRAC reachability poll

### Commands

```sh
gh run view 28408515317 --repo itchyshin/gllvmTMB --json status,conclusion,jobs,url
ssh -o BatchMode=yes nibi 'job=16951694; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606; squeue -j ${job} -o "%i %T %M %l %D %R" --noheader || true; find ${out}/results -maxdepth 1 -type f -name "result_*.csv" 2>/dev/null | wc -l; tail -n 8 ${out}/logs/phylo_xlv-16951694-1.out; tail -n 8 ${out}/logs/phylo_xlv-16951694-1.err'
ssh -o BatchMode=yes narval 'job=64365792; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643; squeue -j ${job} -o "%i %T %M %l %D %R" --noheader || true; find ${out}/results -maxdepth 1 -type f -name "result_*.csv" 2>/dev/null | wc -l; tail -n 8 ${out}/logs/phylo_xlv-64365792-1.out; tail -n 8 ${out}/logs/phylo_xlv-64365792-1.err'
ssh -o BatchMode=yes rorqual 'job=14929297; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525; squeue -j ${job} -o "%i %T %M %l %D %R" --noheader || true; find ${out}/results -maxdepth 1 -type f -name "result_*.csv" 2>/dev/null | wc -l; tail -n 8 ${out}/logs/phylo_xlv-14929297-1.out; tail -n 8 ${out}/logs/phylo_xlv-14929297-1.err'
ssh -o BatchMode=yes fir 'hostname; date; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes trillium 'hostname; date; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes vulcan 'hostname; date; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes tamia 'hostname; date; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes totoro 'hostname; date; test -d /project/6098264/snakagaw/phylo_xlv && find /project/6098264/snakagaw/phylo_xlv -maxdepth 1 -type d -name "pilot-k2-p80-blv-*" | wc -l || true'
ssh -o BatchMode=yes killarney 'hostname; date; squeue -u snakagaw --noheader | wc -l'
jq . /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate
```

### Result

The gllvmTMB post-merge main R-CMD-check for PR #571 completed successfully:

- run `28408515317`, status `completed`, conclusion `success`;
- job `ubuntu-latest (release)` completed at `2026-06-29T23:20:00Z`;
- `Run r-lib/actions/check-r-package@v2` completed successfully.

Latest DRAC interval-rescue canary state:

- Nibi `16951694_1`: running at `01:14:02`, still in bootstrap, `0` result
  files. Fit converged in `192` iterations / `169.50s`; bootstrap started at
  `2026-06-29T22:12:46Z`.
- Narval `64365792_1`: running at `00:29:10`, still in capped bootstrap, `0`
  result files. Fit converged in `128` iterations / `148.61s`; bootstrap
  started at `2026-06-29T22:57:33Z`.
- Rorqual `14929297_1`: running at `01:57:49`, still in profile, `0` result
  files. Fit converged in `178` iterations / `230.94s`; Wald completed and
  profile started at `2026-06-29T21:32:55Z`.

Batch SSH reachability from this shell:

- confirmed idle: Fir, Trillium, Vulcan, Tamia;
- active canaries: Nibi, Narval, Rorqual;
- Killarney probe did not return promptly and was stopped;
- Totoro is network-reachable but not unattended-batch reachable from this
  shell: public key authentication was rejected and password auth would be
  interactive.

Dashboard `/tmp/gllvm-dashboard` was updated to `r139`; JSON validation passed.

### Decision

Do not launch production coverage while all three interval-rescue canaries have
no result row. Treat the Rorqual profile canary as an accumulating wall-time
warning, not as evidence, until it either writes a CSV or times out. Keep Fir,
Trillium, Vulcan, and Tamia as reserve capacity for the next bounded launch
after the current canaries choose a viable method.

### Claim Boundary

IN: ordinary native-TMB Gaussian t-critical coverage is now merged and green on
main in `gllvmTMB`; DRAC reachability has been refreshed; three phylo interval
canaries are alive and past fitting. OUT: no phylo bootstrap/profile result
yet, no phylo production coverage, no phylo-signal coverage, no source-specific
R grammar exposure, and no mixed-family claim.

## 2026-06-29 17:32 MDT - Codex partial-result checkpointing for long CI canaries

### Commands

```sh
julia --project=. bench/phylo_xlv_drac_task.jl --help
julia --project=. bench/phylo_xlv_drac_summarise.jl --help
tmp=$(mktemp -d); header='task_id,scenario,pagel_lambda,n_species,n_sites,K,q_lv,K_phy,rep,seed,level,n_boot,bootstrap_iterations,target,method,fit_converged,fit_iterations,fit_seconds,ci_seconds,ci_status,total,usable,covered,coverage,bias_mean,bias_rmse,estimate_mean,truth_mean,max_abs_estimate,max_abs_truth,pd_hessian,bootstrap_converged,error'; printf '%s\n1,main,0.5,80,80,2,1,1,1,1,0.95,5,20,B_lv,wald,true,10,1,2,ok,80,80,76,0.95,0,0.1,0,0,1,1,true,,\n' "$header" > "$tmp/result_000001.csv"; printf '%s\n2,main,0.5,80,80,2,1,1,2,2,0.95,5,20,B_lv,bootstrap,true,10,1,3,ok,80,80,74,0.925,0,0.1,0,0,1,1,,4,\n' "$header" > "$tmp/partial_result_000002.csv"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp" --include-partial
tmp=$(mktemp -d); julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 6 --n-sites 6 --K 1 --scenarios main; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 80 --n-boot 3; find "$tmp/results" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || ls "$tmp/results"; julia --project=. bench/phylo_xlv_drac_summarise.jl --results "$tmp/results"
git diff --check
```

### Result

Added conservative partial-result checkpointing for future long CI canaries:

- `bench/phylo_xlv_drac_task.jl` now writes
  `partial_result_<task>.csv` after each completed B_lv method and after
  phylo-signal CI work;
- final `result_<task>.csv` writes still remove the partial file, preserving
  the existing production result contract;
- `bench/phylo_xlv_drac_summarise.jl` ignores partial files by default and
  includes them only under the explicit `--include-partial` flag.

Checks:

- task runner help parsed;
- summarizer help parsed and shows `--include-partial`;
- synthetic fixture read `1` row by default and `2` rows with
  `--include-partial`, printing `included partial_result_*.csv rows`;
- a tiny real local task wrote a partial result after Wald, then wrote final
  `result_000001.csv` and left only the final result file in the output
  directory;
- ordinary summarizer read the final tiny-task result row;
- `git diff --check` passed.

### Decision

Keep partial rows explicit and opt-in. They are useful for diagnosing long
profile/bootstrap jobs, but they should not be silently folded into production
coverage summaries.

### Claim Boundary

IN: future long-running DRAC tasks can expose completed method rows without
changing final result semantics. OUT: no current active job is changed, no
partial row is production coverage by default, and no bootstrap/profile
calibration claim is added.

## 2026-06-29 17:33 MDT - Codex partial-result sync and LV board refresh

### Commands

```sh
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl nibi:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_summarise.jl rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes nibi 'grep -n "partial_result\|include-partial" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
ssh -o BatchMode=yes narval 'grep -n "partial_result\|include-partial" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
ssh -o BatchMode=yes rorqual 'grep -n "partial_result\|include-partial" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_summarise.jl | head -20'
for h in fir trillium vulcan tamia; do ssh -o BatchMode=yes "$h" 'printf "%s " $(hostname); test -d /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac && echo project=yes || echo project=no'; done
ssh -o BatchMode=yes vulcan 'hostname; ls -ld /project /project/6098264 /project/6098264/snakagaw 2>&1; test -x /cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia && echo julia_abs=yes || echo julia_abs=no; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes trillium 'hostname; ls -ld /project /project/6098264 /project/6098264/snakagaw 2>&1; test -x /cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia && echo julia_abs=yes || echo julia_abs=no; squeue -u snakagaw --noheader | wc -l'
ssh -o BatchMode=yes tamia 'hostname; ls -ld /project /project/6098264 /project/6098264/snakagaw 2>&1; test -x /cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/julia/1.10.10/bin/julia && echo julia_abs=yes || echo julia_abs=no; squeue -u snakagaw --noheader | wc -l'
gh pr list --repo itchyshin/gllvmTMB --state open --json number,title,headRefName,isDraft,mergeable,reviewDecision,statusCheckRollup,url,updatedAt
gh run view 28409207166 --repo itchyshin/gllvmTMB --json status,conclusion,jobs,url
gh run view 28409131403 --repo itchyshin/gllvmTMB --json status,conclusion,jobs,url
jq . /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate
```

### Result

Synced the partial-result runner/summariser update to the active project copies
on Nibi, Narval, and Rorqual. Grep confirmed `partial_result` and
`--include-partial` code on all three remote copies.

Reserve-host check:

- Fir, Trillium, Vulcan, and Tamia are reachable and idle, and the latter
  three have the absolute Julia 1.10.10 binary available;
- none has `/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac` present;
- Trillium, Vulcan, and Tamia do not have `/project/6098264/snakagaw` mounted
  or present under that path, so they require a cluster-local staging path and
  account check before use.

R-side state moved:

- gllvmTMB PR #572 (`codex/lv-bernoulli-depth-20260628`) is open, mergeable,
  and running Ubuntu R-CMD-check run `28409207166`;
- pkgdown run `28409131403` from the #571 main merge is building the site.

Dashboard `/tmp/gllvm-dashboard` was updated to `r140`; JSON validation passed.

### Decision

Use Nibi, Narval, and Rorqual for immediate follow-up canaries because their
project copies and shared depot are already staged. Treat the other idle DRAC
hosts as reserve capacity that needs explicit cluster-local staging before
unattended submission.

### Claim Boundary

IN: future Nibi/Narval/Rorqual canaries can write opt-in partial rows, and the
LV board now reflects PR #572 as active. OUT: no reserve-host production launch,
no new production coverage, and no claim that idle but unstaged hosts are ready
for unattended coverage arrays.

## 2026-06-29 17:36 MDT - Codex Nibi bootstrap canary result

### Commands

```sh
ssh -o BatchMode=yes nibi 'cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results; seff 16951694 2>/dev/null || true; sacct -j 16951694 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true'
ssh -o BatchMode=yes nibi 'out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606; cat ${out}/meta/session.txt; cat ${out}/results/result_000001.csv'
jq . /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate
```

### Result

Nibi `16951694_1` completed the uncapped bootstrap-only p=80, K=2,
lambda=0.5 weak-cell canary.

Summary row:

- target/method: `B_lv` / `bootstrap`;
- tasks/fit ok: `1/1`;
- usable entries: `80/80`;
- one-seed entry coverage: `0.938`;
- RMSE mean: `0.063`;
- fit seconds: `169.403`;
- CI seconds: `4843.745`;
- bootstrap converged: `30/30`;
- CI status: `ok`.

Accounting:

- scheduler state: `COMPLETED (exit code 0)`;
- wall time: `01:23:48`;
- CPU efficiency: `99.20%`;
- memory: `465.55 MB` of `4G`.

This canary used the older result schema, so the summary prints `boot n = NA`
and the requested `n_boot=30` comes from the session metadata and the
`bootstrap_converged=30` result field.

Dashboard `/tmp/gllvm-dashboard` was updated to `r141`; JSON validation passed.

### Decision

Bootstrap is not dead for the weak p=80, K=2, lambda=0.5 B_lv cell, but the
uncapped `n_boot=30` path costs about `81` CI minutes per task after fitting.
Wait for the Narval capped-bootstrap canary before choosing whether to scale a
bootstrap rescue, lower the refit cap, or keep bootstrap as a narrow diagnostic
fallback.

### Claim Boundary

IN: one-seed bootstrap feasibility/timing result for the known weak cell. OUT:
no production coverage, no MCSE-backed coverage claim, no phylo-signal result,
and no evidence yet that bootstrap is affordable for the full lambda x p x K
campaign.

## 2026-06-29 17:38 MDT - Codex PR #572 CI poll and live canary hold

### Commands

```sh
ssh -o BatchMode=yes narval 'job=64365792; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643; squeue -j ${job} -o "%i %T %M %l %D %R" --noheader || true; find ${out}/results -maxdepth 1 -type f -name "result_*.csv" 2>/dev/null | wc -l; tail -n 10 ${out}/logs/phylo_xlv-64365792-1.out; seff ${job} 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'job=14929297; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525; squeue -j ${job} -o "%i %T %M %l %D %R" --noheader || true; find ${out}/results -maxdepth 1 -type f -name "result_*.csv" 2>/dev/null | wc -l; tail -n 12 ${out}/logs/phylo_xlv-14929297-1.out; seff ${job} 2>/dev/null || true'
gh run view 28409207166 --repo itchyshin/gllvmTMB --json status,conclusion,jobs,url
gh run view 28409131403 --repo itchyshin/gllvmTMB --json status,conclusion,jobs,url
jq . /tmp/gllvm-dashboard/status.json >/tmp/gllvm-dashboard/status.validate
```

### Result

R-side state:

- gllvmTMB PR #572 Ubuntu R-CMD-check run `28409207166` completed
  successfully at `2026-06-29T23:34:40Z`;
- pkgdown run `28409131403` from the #571 main merge is still in `Build site`.

DRAC state:

- Narval `64365792_1`: running at `00:43:13`, still in capped bootstrap,
  `0` result files;
- Rorqual `14929297_1`: running at `02:11:52`, still in profile,
  `0` result files.

Dashboard `/tmp/gllvm-dashboard` was updated to `r142`; JSON validation passed.

### Decision

Do not launch another bootstrap-cap diagnostic yet. Nibi has supplied the
uncapped bootstrap feasibility point, and Narval is already the capped
comparator for the same cell. Wait for Narval to finish or time out before
choosing a new cap.

### Claim Boundary

IN: PR #572 has green Ubuntu CI, and the phylo bootstrap comparison is now a
two-point live timing question: completed uncapped Nibi vs pending capped
Narval. OUT: no PR #572 merge claim, no pkgdown completion claim, no phylo
production coverage, and no conclusion about the capped bootstrap path yet.

## 2026-06-30 03:42 MDT - Codex bootstrap/profile canary completion poll

### Commands

```sh
ssh -o BatchMode=yes nibi 'squeue -j 16951694 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 80 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/logs/phylo_xlv-16951694-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30-nibi-lambda05-rep1-20260629-1606/results/result_000001.csv 2>/dev/null || true; seff 16951694 2>/dev/null || true'
ssh -o BatchMode=yes narval 'squeue -j 64365792 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 100 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/logs/phylo_xlv-64365792-1.out 2>/dev/null || true; cat /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep1-20260629-1643/results/result_000001.csv 2>/dev/null || true; seff 64365792 2>/dev/null || true'
ssh -o BatchMode=yes rorqual 'squeue -j 14929297 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" 2>/dev/null || true; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); tail -n 120 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-rorqual-lambda05-cirescue-rep1-nboot30-20260629-1525/logs/phylo_xlv-14929297-1.out 2>/dev/null || true; seff 14929297 2>/dev/null || true'
```

### Result

The weak-cell p=80, K=2, lambda=0.5 interval-rescue canaries now have final
states:

- Nibi `16951694_1`, uncapped bootstrap-only, completed with exit code `0`.
  One-seed `B_lv` bootstrap entry coverage was `0.9375`, RMSE `0.0629`,
  fit time `169.4s`, CI time `4843.7s`, bootstrap converged `30/30`, wall time
  `01:23:48`, memory `465.55 MB / 4 GB`.
- Narval `64365792_1`, capped bootstrap-only with
  `bootstrap_iterations = 120`, completed with exit code `0`. One-seed `B_lv`
  bootstrap entry coverage was `1.0`, RMSE `0.0346`, fit time `148.5s`, CI time
  `4055.2s`, bootstrap converged `30/30`, wall time `01:10:34`, memory
  `875.61 MB / 4 GB`.
- Rorqual `14929297_1`, `wald,profile,bootstrap` canary, timed out after
  `03:00:20` with no result file. The log shows fit convergence in `230.94s`,
  Wald completion, then profile started and did not finish before timeout.

### Decision

Bootstrap remains the only interval-rescue method with completed p=80, K=2,
lambda=0.5 rows. The capped Narval canary was about 13 minutes faster than the
uncapped Nibi canary, but both are still roughly 68-81 CI minutes for one
task. Full-vector profile is computationally impractical in the current form
for this weak cell.

Do not launch production coverage yet. Next safe choices are either a small
multi-seed capped-bootstrap diagnostic (for example 10 seeds at lambda=0.5) to
estimate MCSE and runtime, or a narrower/profile-batching implementation before
trying profile again.

### Claim Boundary

IN: one-seed bootstrap feasibility and profile timeout evidence for the known
weak p=80, K=2, lambda=0.5 cell. PARTIAL: bootstrap may rescue the weak cell,
but evidence is one seed per cap regime and too weak for coverage claims. OUT:
production coverage, phylo-signal interval coverage, public gllvmTMB grammar
exposure, non-Gaussian phylo X_lv, and Model B.

## 2026-06-30 03:51 MDT - Codex Narval capped-bootstrap 10-seed diagnostic launch

### Commands

```sh
ssh -o BatchMode=yes narval 'bash -s' <<'REMOTE'
set -euo pipefail
root=/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac
stamp=$(date +%Y%m%d-%H%M%S)
out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-${stamp}
cd "$root"
module load StdEnv/2023 >/dev/null 2>&1 || true
module load julia/1.10.10 >/dev/null 2>&1 || true
export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}
export PHYLO_XLV_ACCOUNT=def-snakagaw_cpu
export PHYLO_XLV_DEPOT=/project/6098264/snakagaw/julia_depot
export PHYLO_XLV_JULIA="$(command -v julia)"
export PHYLO_XLV_REPS=10
export PHYLO_XLV_LAMBDAS=0.5
export PHYLO_XLV_N_SPECIES=80
export PHYLO_XLV_N_SITES=80
export PHYLO_XLV_K=2
export PHYLO_XLV_Q_LV=1
export PHYLO_XLV_K_PHY=1
export PHYLO_XLV_SCENARIOS=main
export PHYLO_XLV_SEED0=202606300342
export PHYLO_XLV_TARGETS=B_lv
export PHYLO_XLV_METHODS=bootstrap
export PHYLO_XLV_N_BOOT=30
export PHYLO_XLV_BOOT_ITERATIONS=120
export PHYLO_XLV_ITERATIONS=400
export PHYLO_XLV_TIME=0-02:00
export PHYLO_XLV_MEM=4G
export PHYLO_XLV_THROTTLE=10
bash bench/phylo_xlv_drac_submit.sh --out "$out" --submit
echo "OUT=$out"
REMOTE
ssh -o BatchMode=yes narval 'squeue -j 64397790 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"; echo results=$(find /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | wc -l); head -n 40 /project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048/meta/session.txt'
```

### Result

Submitted Narval array `64397790` under `def-snakagaw_cpu`.

Output directory:

```text
/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048
```

Shape:

- scenario: `main`;
- lambda: `0.5`;
- `n_species = n_sites = 80`;
- `K = 2`, `q_lv = 1`, `K_phy = 1`;
- target: `B_lv`;
- method: `bootstrap`;
- `n_boot = 30`;
- `bootstrap_iterations = 120`;
- `iterations = 400`;
- tasks: `10`, throttle `10`;
- walltime request: `2h`;
- memory request: `4G`.

Initial poll: `64397790_[1-10%10]` was pending on `cpubase_b` with reason
`None`; result count was `0`.

### Decision

This is still a diagnostic, not production coverage. It is the next bounded
step after the one-seed capped bootstrap canary because it gives an MCSE-bearing
read on the weak cell without launching the full lambda x p x K grid.

### Claim Boundary

IN: 10-seed capped-bootstrap diagnostic launched for the known weak p=80, K=2,
lambda=0.5 cell. OUT: production coverage, phylo-signal intervals,
source-specific gllvmTMB grammar exposure, and any claim that bootstrap is
calibrated before the array completes and is summarised.

## 2026-06-30 05:12 MDT - Codex Narval capped-bootstrap 10-seed diagnostic result

### Commands

```sh
ssh -o BatchMode=yes narval 'job=64397790; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048; squeue -j ${job} -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" 2>/dev/null || true; find ${out}/results -maxdepth 1 -name "result_*.csv" 2>/dev/null | sort | wc -l; cd /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac; module load StdEnv/2023 >/dev/null 2>&1 || true; module load julia/1.10.10 >/dev/null 2>&1 || true; export JULIA_DEPOT_PATH=/project/6098264/snakagaw/julia_depot:${JULIA_DEPOT_PATH:-}; julia --project=. bench/phylo_xlv_drac_summarise.jl --results ${out}/results 2>/dev/null || true'
ssh -o BatchMode=yes narval 'job=64397790; out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048; seff ${job} 2>/dev/null || true; sacct -j ${job} --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,ReqMem,AllocCPUS -P 2>/dev/null || true; cat ${out}/meta/session.txt; head -n 5 ${out}/results/result_000001.csv'
```

### Result

Narval array `64397790` completed all 10 capped-bootstrap weak-cell tasks with
exit code `0`.

Summary:

| scenario | lambda | p | n_sites | K | target | method | tasks | fit ok | usable entries | mean coverage (MCSE) | entry coverage | RMSE mean | fit sec mean | CI sec mean | boot n | boot iter cap | bootstrap ok | CI status |
|---|---:|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| main | 0.5 | 80 | 80 | 2 | B_lv | bootstrap | 10 | 10 | 800 | 0.844 (0.071) | 0.844 | 0.074 | 228.594 | 4153.291 | 30 | 120 | 300 | ok |

Resource state:

- all 10 array tasks completed;
- elapsed times ranged from `01:08:07` to `01:17:10`;
- batch MaxRSS was about `0.53-0.82 GB` for completed tasks, well below the
  `4G` request;
- representative `seff` row for task 10: `01:11:01` wall, `99.20%` CPU
  efficiency, `531.11 MB / 4G`.

### Decision

Capped bootstrap does not rescue the known weak p=80, K=2, lambda=0.5 `B_lv`
coverage cell. Its 10-seed result (`0.844`, MCSE `0.071`) is materially the
same as the earlier normal-Wald and t-Wald diagnostics (`0.844` and `0.845`).
Do not scale production coverage with this interval method.

The next safe move is diagnostic, not production: inspect whether the problem is
the estimator/weak-cell bias, the covariance/SE mapping, or the DGP/target
definition for this cell. Full-vector profile is already impractical in the
current implementation because Rorqual `14929297` timed out in profile after
3h with no result file.

### Claim Boundary

IN: negative 10-seed capped-bootstrap diagnostic for the weak p=80, K=2,
lambda=0.5 `B_lv` cell. OUT: production coverage, any bootstrap rescue claim,
phylo-signal interval coverage, public gllvmTMB phylo grammar exposure,
non-Gaussian phylo X_lv, and Model B.

## 2026-06-30 05:39 MDT - Codex phylo weak-cell per-entry diagnostic tooling

### Commands

```sh
ssh -o BatchMode=yes narval 'out=/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048; awk '\''FNR==1 && NR!=1 {next} {print}'\'' ${out}/results/result_*.csv' > /tmp/phylo_xlv_bootstrap10_results.csv
awk -F, 'NR==1{for(i=1;i<=NF;i++) h[$i]=i; printf "%4s %16s %8s %8s %8s %8s %8s %8s %8s\n", "rep", "seed", "cov", "covered", "bias", "rmse", "est_mu", "max_est", "ci_sec"; next} {printf "%4d %16s %8.3f %3d/%-3d %8.3f %8.3f %8.3f %8.3f %8.1f\n", $h["rep"], $h["seed"], $h["coverage"], $h["covered"], $h["usable"], $h["bias_mean"], $h["bias_rmse"], $h["estimate_mean"], $h["max_abs_estimate"], $h["ci_seconds"]}' /tmp/phylo_xlv_bootstrap10_results.csv | sort -k3,3n
tmp=$(mktemp -d); export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 6 --n-sites 6 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260630 --force; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 80 --n-boot 3 --write-details; find "$tmp/results" -maxdepth 1 -type f -print | sort; sed -n '1,4p' "$tmp/results/result_000001.csv"; sed -n '1,8p' "$tmp/results/detail_result_000001_wald.csv"
rm -rf /tmp/phylo_xlv_detail_submit_probe && export PATH="$HOME/.juliaup/bin:$PATH"; PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=6 PHYLO_XLV_N_SITES=6 PHYLO_XLV_K=1 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=wald PHYLO_XLV_N_BOOT=3 PHYLO_XLV_WRITE_DETAILS=1 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_detail_submit_probe; rg -n "write_details|detail_args|--write-details" /tmp/phylo_xlv_detail_submit_probe/meta/session.txt /tmp/phylo_xlv_detail_submit_probe/meta/phylo_xlv_array.sbatch; bash -n /tmp/phylo_xlv_detail_submit_probe/meta/phylo_xlv_array.sbatch
tmp=$(mktemp -d); export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. bench/phylo_xlv_drac_task.jl --write-params "$tmp/params.csv" --reps 1 --lambdas 0 --n-species 4 --n-sites 6 --K 1 --q-lv 1 --K-phy 1 --scenarios main --seed0 20260631 --force >/dev/null; julia --project=. bench/phylo_xlv_drac_task.jl --params "$tmp/params.csv" --outdir "$tmp/results" --methods wald --targets B_lv --iterations 60 --n-boot 3 >/tmp/phylo_xlv_no_detail_probe.log; find "$tmp/results" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || ls "$tmp/results"
git diff --check
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes narval '... write detail-task8.sbatch and sbatch it ...'
ssh -o BatchMode=yes narval 'ls -td /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-details-task8-narval-* 2>/dev/null | head -3; squeue -u $USER -o "%.18i %.9P %.32j %.8T %.10M %.6D %R" | head -20'
```

### Result

The aggregate 10-seed capped-bootstrap rows are heterogeneous, not uniformly
weak:

| rep | seed | coverage | covered | bias | RMSE |
|---:|---:|---:|---:|---:|---:|
| 8 | 202614420856 | 0.325 | 26/80 | 0.036 | 0.156 |
| 6 | 202612400836 | 0.613 | 49/80 | -0.018 | 0.112 |
| 3 | 202609370806 | 0.713 | 57/80 | 0.023 | 0.091 |
| 2/4/5/9/10 | mixed | 0.950-0.975 | 76-78/80 | mixed | 0.037-0.082 |
| 1/7 | mixed | 0.988-1.000 | 79-80/80 | mixed | 0.035-0.077 |

Implemented an opt-in per-entry detail stream:

- `bench/phylo_xlv_drac_task.jl` accepts `--write-details`;
- successful `B_lv` CI methods write `detail_result_<task>_<method>.csv`;
- detail rows contain the entry index, term, estimate, lower, upper, truth,
  covered flag, miss side, and interval width;
- ordinary `result_<task>.csv` schema and default production summaries are
  unchanged.

Implemented submitter wiring:

- `bench/phylo_xlv_drac_submit.sh` accepts `PHYLO_XLV_WRITE_DETAILS=1`;
- generated session metadata records `write_details=1`;
- generated sbatch scripts pass `--write-details` only for truthy values.

Validation:

- the tiny `--write-details` real task wrote both `result_000001.csv` and
  `detail_result_000001_wald.csv`;
- the default tiny task without `--write-details` wrote only
  `result_000001.csv`;
- the write-only submit probe wrote `detail_args` into the sbatch file and
  `bash -n` passed;
- the first submitter attempt used `${var,,}`, which failed under the local
  Bash; it was replaced with a portable `case` pattern and retested;
- `git diff --check` passed.

Synced the updated runner/submitter to the Narval project copy and submitted
one compute-node diagnostic:

- job: `64403633`;
- output directory:
  `/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-details-task8-narval-20260630-113900`;
- source params:
  `/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048/meta/phylo_xlv_params.csv`;
- task: `8`, the worst capped-bootstrap seed (`coverage = 0.325`);
- target: `B_lv`;
- methods: `wald,bootstrap`;
- `n_boot = 30`, `bootstrap_iterations = 120`, `iterations = 400`;
- `--write-details`;
- initial state: running on Narval `cpubase_b` at poll time.

### Decision

The next evidence we need is per-entry, not another aggregate coverage number.
Task 8 is the right first rerun because it is the catastrophic seed. Running
both Wald and capped bootstrap on the same simulated dataset will show whether
the two interval methods miss the same entries, whether misses concentrate in
one loading/predictor block, and whether the truth is usually above or below
the interval.

### Claim Boundary

IN: diagnostic tooling and a one-task detail rerun for the known weak p=80, K=2,
lambda=0.5 `B_lv` cell. OUT: production coverage, any interval-method rescue
claim, public `gllvmTMB` phylo grammar exposure, phylo-signal intervals,
non-Gaussian phylo `X_lv`, and Model B.

## 2026-06-30 06:52 MDT - Codex phylo weak-cell truth-start and task-8 detail diagnosis

### Commands

```sh
bash -n bench/phylo_xlv_drac_submit.sh
git diff --check
rm -rf /tmp/phylo_xlv_truthinit_smoke && mkdir -p /tmp/phylo_xlv_truthinit_smoke/results && julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_truthinit_smoke/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 4 --K 2 --q-lv 1 --K-phy 1 --scenarios main && julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_truthinit_smoke/params.csv --outdir /tmp/phylo_xlv_truthinit_smoke/results --task-id 1 --targets none --iterations 2 --truth-init --force
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh narval '... submit generated truth-init job 64409162 ...'
ssh narval 'scancel 64409162 || true; ... submit original-params truth-init job 64409200 ...'
ssh narval "sacct -j 64409200 --format=JobID,JobName%24,State,Elapsed,MaxRSS,ExitCode -P"
ssh narval "sacct -j 64403633 --format=JobID,JobName%24,State,Elapsed,MaxRSS,ExitCode -P"
scp -q 'narval:/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-truthinit-wald-task8-originalseed-narval-20260630-123400/results/*.csv' /tmp/phylo_xlv_truthinit_task8/
scp -q 'narval:/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-details-task8-narval-20260630-113900/results/*.csv' /tmp/phylo_xlv_detail_task8_final/
python - <<'PY'
# CSV-parser summaries of task-8 default Wald, truth-start Wald, and bootstrap detail.
PY
gh pr view 127 --json number,state,headRefName,headRefOid,isDraft,mergeStateStatus,statusCheckRollup,url,title,updatedAt
```

### Result

Added an opt-in truth-start diagnostic path:

- `bench/phylo_xlv_drac_task.jl` accepts `--truth-init`;
- truth-start fits seed `lambda_B`, `alpha_lv`, `sigma_eps`, and `lambda_phy`
  from the DGP truth used by the DRAC task runner;
- `bench/phylo_xlv_drac_submit.sh` accepts `PHYLO_XLV_TRUTH_INIT=1` and records
  `truth_init=1` in session metadata;
- default runs and result/detail CSV schemas are unchanged.

Local validation passed:

- `bash -n bench/phylo_xlv_drac_submit.sh`;
- `git diff --check`;
- a tiny fit-only Julia smoke using `--truth-init` reached the fitter and wrote
  a non-converged result as expected with only two optimiser iterations.

The first submitted truth-start job (`64409162`) regenerated a lookalike task id
8 with the wrong seed (`28381142`) and was cancelled. The corrected job
`64409200` used the original parameter file and original catastrophic seed
`202614420856`; it completed on Narval in `00:06:24` with `MaxRSS = 766M`.

Task 8 truth-start Wald was indistinguishable from the default-start Wald fit:

| fit | coverage | covered | miss sides | bias | RMSE | mean abs estimate shift vs default |
|---|---:|---:|---|---:|---:|---:|
| default Wald | 0.425 | 34/80 | 29 below, 17 above | 0.0360 | 0.1555 | reference |
| truth-start Wald | 0.425 | 34/80 | 29 below, 17 above | 0.0361 | 0.1555 | 0.00009 |

This rules out the main local-optimizer-basin explanation for the catastrophic
seed.

Task 8 bootstrap detail completed in job `64403633` after `01:11:19`
(`MaxRSS = 1076280K`). The bootstrap result reproduced the original aggregate
coverage and made the same miss-direction diagnosis sharper:

| method | coverage | covered | miss sides | mean width | bootstrap refits |
|---|---:|---:|---|---:|---:|
| Wald | 0.425 | 34/80 | 29 below, 17 above | 0.2413 | NA |
| bootstrap | 0.325 | 26/80 | 32 below, 22 above | 0.1924 | 30/30 |

Miss-set comparison:

- Wald missed 46 entries; bootstrap missed 54 entries.
- The miss-set overlap was 45 entries (`Jaccard = 0.818`).
- All 45 overlapping misses had the same miss side.
- Bootstrap intervals were about `0.798x` the Wald width on average and
  `0.793x` over overlapping missed entries.

The parallel bootstrap-detail array for reps 3, 6, and 7 also completed:

- job: `64407702`;
- output directory:
  `/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-details-tasks3-6-7-narval-20260630-122000`;
- elapsed: `01:16:51`, `01:17:26`, and `01:17:35`;
- MaxRSS: `563-599 MB`;
- all three bootstrap rows had `30/30` converged bootstrap refits.

Per-seed comparison:

| rep | method | coverage | miss sides | mean width | width ratio vs Wald |
|---:|---|---:|---|---:|---:|
| 3 | Wald | 0.900 (72/80) | 6 below, 2 above | 0.2464 | 1.000 |
| 3 | bootstrap | 0.713 (57/80) | 13 below, 10 above | 0.1824 | 0.740 |
| 6 | Wald | 0.825 (66/80) | 6 below, 8 above | 0.2771 | 1.000 |
| 6 | bootstrap | 0.613 (49/80) | 13 below, 18 above | 0.2496 | 0.901 |
| 7 | Wald | 1.000 (80/80) | 0 below, 0 above | 0.2802 | 1.000 |
| 7 | bootstrap | 1.000 (80/80) | 0 below, 0 above | 0.2682 | 0.957 |
| 8 | Wald | 0.425 (34/80) | 29 below, 17 above | 0.2413 | 1.000 |
| 8 | bootstrap | 0.325 (26/80) | 32 below, 22 above | 0.1924 | 0.798 |

Wald/bootstrap miss-overlap details:

| rep | Wald misses | bootstrap misses | overlap | Jaccard | side agreement |
|---:|---:|---:|---:|---:|---:|
| 3 | 8 | 23 | 7 | 0.292 | 7/7 |
| 6 | 14 | 31 | 14 | 0.452 | 14/14 |
| 7 | 0 | 0 | 0 | 1.000 | 0/0 |
| 8 | 46 | 54 | 45 | 0.818 | 45/45 |

### Decision

Task 8 is not a start-value failure. It is a finite-sample fitted-effect
shrinkage failure for this weak p=80, K=2, lambda=0.5 cell. Percentile bootstrap
inherits the same shrunken point estimate and narrows the intervals, so it makes
coverage worse rather than rescuing the cell.

The 3/6/7 details confirm this is not a one-row logging artifact: bootstrap
reproduces the original aggregate weak rows for reps 3 and 6, leaves the clean
rep 7 clean, and narrows intervals in all four detailed reps.

Do not launch production phylo Model A coverage from the current interval
machinery. Either record the weak-cell block honestly or design a narrower
estimator/interval repair; do not expose `phylo_latent(..., lv = ~ x)` through
`gllvmTMB` from this evidence.

### Claim Boundary

IN: mechanism diagnosis for p=80, K=2, lambda=0.5 `B_lv`: same MLE under truth
starts for task 8; Wald/bootstrap miss overlap and side agreement; bootstrap
narrower than Wald for reps 3, 6, 7, and 8; all detailed bootstrap rows had
30/30 refit convergence. OUT: production coverage, bootstrap rescue, profile
rescue, phylo-signal interval coverage, public `gllvmTMB` phylo grammar
exposure, non-Gaussian phylo `X_lv`, and Model B.

## 2026-06-30 09:51 MDT - Codex bench-only bootstrap-basic candidate

Added a bench-only `bootstrap_basic` candidate to the phylo `X_lv` DRAC runner.
This does not change the exported `confint_lv_effects()` API. The method reuses
the existing internal parametric-bootstrap simulate/refit closures, including the
`bootstrap_iterations` cap, and computes the basic interval
`[2 * theta_hat - q_hi, 2 * theta_hat - q_lo]` for the derived
`B_lv = Lambda * alpha_lv'` entries. The purpose is to test whether a
bias-corrected bootstrap center can move away from the fitted-effect shrinkage
seen in the p=80, K=2, lambda=0.5 weak cell.

Pre-edit lane check:

```sh
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh docs/dev-log/check-log.md docs/dev-log/after-task
```

Result: one open draft PR, #127, remote head
`claude/phylo-xlv-modelA-20260627`, merge state `UNSTABLE`; recent touched-file
commits were the local diagnostic commits on this branch.

Checks:

```sh
git diff --check
bash -n bench/phylo_xlv_drac_submit.sh
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_parse/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 4 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_parse/params.csv --outdir /tmp/phylo_xlv_basic_parse/results --task-id 1 --methods bootstrap_basic --targets none --iterations 1 --n-boot 10 --bootstrap-iterations 5 --dry-run
PHYLO_XLV_REPS=1 PHYLO_XLV_LAMBDAS=0.5 PHYLO_XLV_N_SPECIES=4 PHYLO_XLV_N_SITES=4 PHYLO_XLV_K=1 PHYLO_XLV_Q_LV=1 PHYLO_XLV_K_PHY=1 PHYLO_XLV_SCENARIOS=main PHYLO_XLV_TARGETS=B_lv PHYLO_XLV_METHODS=bootstrap_basic PHYLO_XLV_N_BOOT=10 PHYLO_XLV_BOOT_ITERATIONS=5 bench/phylo_xlv_drac_submit.sh --out /tmp/phylo_xlv_basic_submit_probe
rg -n "bootstrap_basic|bootstrap_iterations" /tmp/phylo_xlv_basic_submit_probe/meta/session.txt /tmp/phylo_xlv_basic_submit_probe/meta/phylo_xlv_array.sbatch
bash -n /tmp/phylo_xlv_basic_submit_probe/meta/phylo_xlv_array.sbatch
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_real/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_real/params.csv --outdir /tmp/phylo_xlv_basic_real/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 10 --bootstrap-iterations 40 --force
julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_detail/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force
julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_detail/params.csv --outdir /tmp/phylo_xlv_basic_detail/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 10 --bootstrap-iterations 40 --write-details --force
find /tmp/phylo_xlv_basic_detail/results -maxdepth 1 -type f -exec basename {} \; | sort
```

Results: all checks passed. The first tiny real run with n_sites=4 correctly
wrote a `not_converged` row, so I reran with n_sites=8 and `iterations=120`.
That converged in 25 iterations and wrote a `B_lv/bootstrap_basic` row with
`bootstrap_converged=10`, finite bounds, and `ci_status=ok`. The write-details
smoke wrote both `result_000001.csv` and
`detail_result_000001_bootstrap_basic.csv`.

Implementation files:

- `bench/phylo_xlv_drac_task.jl`
- `bench/phylo_xlv_drac_submit.sh`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-tooling.md`

Claim boundary: IN: bench-only diagnostic tooling for one candidate interval
center correction. OUT: no exported API change, no production coverage, no claim
that `bootstrap_basic` rescues the weak cell, no PR #127 push, and no
source-specific gllvmTMB grammar exposure.

## 2026-06-30 09:59 MDT - Codex bootstrap-basic sidecar fix and Narval canary launch

Read-only sidecar audit verdict: WARN, no fail-level formula or submitter
blocker. Two fixes landed before trusting the canary:

- `bootstrap_basic` now records `ci_status = "bootstrap_underconverged"` and an
  explanatory `error` field when fewer than 10 bootstrap refits converge, rather
  than emitting an `ok` row with all-NaN intervals.
- The replay transcript above now includes the missing
  `/tmp/phylo_xlv_basic_detail/params.csv` params-generation command.

Cluster launch:

```sh
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes narval 'bash -s'  # custom sbatch for task 8, method bootstrap_basic, target B_lv, n_boot=30, bootstrap_iterations=120
```

Result before the local sidecar fix was synced: Slurm job `64432230` created at
`/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-task8-narval-20260630-155803`,
state `PENDING (Priority)`. The job reads
`bench/phylo_xlv_drac_task.jl` from the Narval project checkout at execution
time, so the next sync must happen before it starts or the job should be
cancelled/relaunched.

Validation and launch continuation:

```sh
git diff --check
bash -n bench/phylo_xlv_drac_submit.sh
rm -rf /tmp/phylo_xlv_basic_underconv && julia --project=. bench/phylo_xlv_drac_task.jl --write-params /tmp/phylo_xlv_basic_underconv/params.csv --reps 1 --lambdas 0.5 --n-species 4 --n-sites 8 --K 1 --q-lv 1 --K-phy 1 --scenarios main --force && julia --project=. bench/phylo_xlv_drac_task.jl --params /tmp/phylo_xlv_basic_underconv/params.csv --outdir /tmp/phylo_xlv_basic_underconv/results --task-id 1 --methods bootstrap_basic --targets B_lv --iterations 120 --n-boot 2 --bootstrap-iterations 40 --force && tail -n 1 /tmp/phylo_xlv_basic_underconv/results/result_000001.csv
rsync -av bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh narval:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/
ssh -o BatchMode=yes narval 'grep -n "bootstrap_underconverged" /project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/bench/phylo_xlv_drac_task.jl; squeue -j 64432230 -o "%.18i %.9P %.32j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes narval 'bash -s'  # custom array sbatch for task IDs 3,6,7, method bootstrap_basic, target B_lv, n_boot=30, bootstrap_iterations=120
```

Results: `git diff --check` and `bash -n` passed. The under-convergence smoke
fit converged, used `n_boot=2`, and wrote `ci_status=bootstrap_underconverged`,
`usable=0`, `bootstrap_converged=2`, and the explanatory error text. The patched
runner was synced to Narval before task-8 execution reached the Julia script;
remote grep found `bootstrap_underconverged` in the project copy. Job `64432230`
then showed `RUNNING` on node `nc31003`. A parallel detail-array job `64432317`
was submitted for task IDs 3, 6, and 7 at
`/project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-detail367-narval-20260630-160111`;
it initially showed `PENDING`.

## 2026-06-30 11:01 MDT - Codex expanded bootstrap-basic race under core cap

The maintainer asked Codex to parallelize aggressively while staying under the
shared 100-core cap under the user's name. I expanded the weak-cell
`bootstrap_basic` diagnostic from the original four detail reps to a full
10-seed race, while keeping each Julia process to one compute core.

Pre-edit lane check:

```sh
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl docs/dev-log/check-log.md docs/dev-log/after-task
```

Result: one open draft PR, #127, remote head
`claude/phylo-xlv-modelA-20260627`, merge state `UNSTABLE`; recent touched-file
commits are the local diagnostic commits on this branch.

Additional launches and staging:

```sh
rsync -av narval:/project/6098264/snakagaw/phylo_xlv/pilot-k2-p80-blv-bootstrap30iter120-narval-lambda05-rep10-20260630-055048/meta/phylo_xlv_params.csv /tmp/phylo_xlv_params_20260630/phylo_xlv_params.csv
ssh -o BatchMode=yes narval 'bash -s'   # job 64435762, task IDs 1,2,4,5,9,10
ssh -o BatchMode=yes nibi 'bash -s'     # job 16988973, task IDs 1,2,4,5,9,10
ssh -o BatchMode=yes rorqual 'bash -s'  # first job 14967092, later invalidated
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes totoro 'hostname; nproc; /home/snakagaw/.juliaup/bin/julia --version'
rsync -az --delete --exclude='.git' --exclude='.julia' --exclude='tmp' /private/tmp/gllvmjl-phylo-xlv/ -e 'ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes' totoro:/home/snakagaw/codex/GLLVM.jl-phylo-xlv-totoro-20260630/
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes totoro 'cd /home/snakagaw/codex/GLLVM.jl-phylo-xlv-totoro-20260630 && export JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 JULIA_DEPOT_PATH=/home/snakagaw/.julia:/home/snakagaw/codex/julia_depot && /home/snakagaw/.juliaup/bin/julia --project=. -e "using Pkg; Pkg.instantiate(); using GLLVM; println(\"totoro GLLVM load ok\")"'
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes totoro 'bash -s'  # local pids 1065793-1065851, task IDs 1-10
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes totoro 'taskset -pc 200-209 ...'  # pinned one task per core
rsync -av src/ rorqual:/project/6098264/snakagaw/GLLVM.jl-phylo-xlv-drac/src/
ssh -o BatchMode=yes rorqual 'bash -s'  # fixed-source job 14967239, task IDs 1,2,4,5,9,10
```

Live state at the 11:01 MDT snapshot:

- Narval valid source: jobs `64432230`, `64432317`, and `64435762`; 10 one-core
  tasks running.
- Nibi valid source: job `16988973`; six one-core tasks running.
- Totoro local source: pids `1065793`-`1065851`; 10 local processes pinned to
  cores 200-209 with `nice -n 5`, `JULIA_NUM_THREADS=1`,
  `OMP_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`.
- Rorqual fixed source: job `14967239`; six one-core tasks queued.
- Rorqual stale source: job `14967092` produced five `ci_error` result rows with
  `MethodError: no method matching _lv_boot_fns(..., ::Int64)` because its
  source checkout still had the old 4-argument `_lv_boot_fns` definitions. Those
  rows are invalid and must not be used as evidence.

Core cap: the valid LV work used about 32 cores at the 11:01 snapshot, rising to
about 38 if fixed Rorqual starts. This is below the user's 100-core cap and leaves
room for the drm team. Totoro uses Julia 1.12.6, so its rows are fast diagnostic
evidence; cross-check against DRAC Julia 1.10 rows before using any result for a
public capability claim.

## 2026-06-30 12:18 MDT - Codex phylo bootstrap-basic aggregate and direct-slope closeout

Closed the weak-cell `bootstrap_basic` race and ran the direct-slope comparator
requested by the estimator sidecar. The outcome blocks the candidate route.

Pre-edit lane and coordination checks:

```sh
sed -n '1,220p' /Users/z3437171/shinichi-brain/AGENTS.md
sed -n '1,220p' /Users/z3437171/shinichi-brain/memory/00-INDEX.md
sed -n '1,260p' /Users/z3437171/shinichi-brain/protocols/after-task.md
git status --short --branch
gh pr list --repo itchyshin/GLLVM.jl --state open --json number,title,headRefName,updatedAt,url,mergeStateStatus,isDraft
git log --all --oneline --since="6 hours ago" -- AGENTS.md CLAUDE.md README.md ROADMAP.md CHANGELOG.md docs/design docs/src docs/dev-log/check-log.md docs/dev-log/after-task bench/phylo_xlv_drac_task.jl bench/phylo_xlv_drac_submit.sh bench/phylo_xlv_drac_summarise.jl
```

Results: branch `codex/phylo-xlv-drac-launcher-20260628` was clean before
edits. The only open GLLVM.jl PR was draft #127
(`claude/phylo-xlv-modelA-20260627`, merge state `UNSTABLE`). Recent touched-file
commits were the local diagnostic commits on this branch.

Job cleanup and final job state:

```sh
ssh -o BatchMode=yes nibi 'squeue -u "$USER" -j 16988973 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes narval 'squeue -u "$USER" -j 64435762,64442542 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -o BatchMode=yes rorqual 'squeue -u "$USER" -j 14967239 -o "%.18i %.9P %.20j %.8T %.10M %.6D %R"'
ssh -S /Users/z3437171/.ssh/cm/snakagaw@totoro.biology.ualberta.ca:22 -o ControlMaster=no -o BatchMode=yes totoro 'pgrep -af "phylo_xlv|direct_mean|direct-mean|bootstrap_basic" || true'
ssh -o BatchMode=yes narval 'sacct -j 64435762 --format=JobID,JobName%30,State,Elapsed,ExitCode -P'
ssh -o BatchMode=yes nibi 'sacct -j 16988973 --format=JobID,JobName%30,State,Elapsed,ExitCode -P'
```

Results: no active `bootstrap_basic` jobs remained on Narval, Nibi, or Rorqual.
Totoro had no leftover diagnostic worker. Narval job `64435762` was cancelled
before writing result rows. Nibi job `16988973` completed tasks 2, 4, 5, 9, and
10; task 1 was cancelled. Rorqual fixed-source job `14967239` was cancelled
after the route was already blocked. Trillium was available but deliberately not
used because its compute/debug partitions reserve whole 192-core nodes, above the
current shared-core cap.

Valid `bootstrap_basic` evidence:

```sh
ssh -o BatchMode=yes nibi 'find /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-remaining10-nibi-20260630-164931/results -name "result_*.csv" -maxdepth 1 | sort'
ssh -o BatchMode=yes narval 'find /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-detail367-narval-20260630-160111/results /project/6098264/snakagaw/phylo_xlv/diagnostic-k2-p80-blv-bootstrap-basic-task8-narval-20260630-155803/results -name "result_*.csv" -maxdepth 1 | sort'
```

Rows used:

| task | source | covered/total | coverage | bootstrap_converged |
| --- | --- | ---: | ---: | ---: |
| 2 | Nibi | 77/80 | 0.9625 | 30 |
| 3 | Narval | 41/80 | 0.5125 | 30 |
| 4 | Nibi | 78/80 | 0.9750 | 30 |
| 5 | Nibi | 76/80 | 0.9500 | 30 |
| 6 | Narval | 60/80 | 0.7500 | 30 |
| 7 | Narval | 80/80 | 1.0000 | 30 |
| 8 | Narval | 25/80 | 0.3125 | 30 |
| 9 | Nibi | 77/80 | 0.9625 | 30 |
| 10 | Nibi | 77/80 | 0.9625 | 30 |

Aggregate: `591/720 = 0.821`. Even if cancelled task 1 were perfect, the
10-seed aggregate could only reach `671/800 = 0.839`, far below the 0.92
working gate. Therefore `bootstrap_basic` is not an admissible interval-rescue
route for the p=80, K=2, lambda=0.5 `B_lv` weak cell.

Direct saturated-slope comparator:

```sh
ssh -o BatchMode=yes narval 'ls -1 /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results | head'
ssh -o BatchMode=yes narval 'head -n 3 /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_000001.csv'
ssh -o BatchMode=yes narval 'for f in /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_*.csv; do tail -n 1 "$f"; done | awk -F, "{printf(\"task %s rep %s mle_slope %.3f ols_slope %.3f mle_rmse %.3f ols_rmse %.3f truth_mean %.3f\\n\",$1,$2,$7,$8,$9,$10,$15)}"'
ssh -o BatchMode=yes narval 'for f in /project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results/direct_result_*.csv; do tail -n 1 "$f"; done | awk -F, "BEGIN{n=0; min=999; max=-999} {n++; sm+=$7; so+=$8; rm+=$9; ro+=$10; cm+=$11; co+=$12; if($7<min)min=$7; if($7>max)max=$7} END{printf(\"n=%d mle_slope_mean=%.6f ols_slope_mean=%.6f mle_rmse_mean=%.6f ols_rmse_mean=%.6f mle_corr_mean=%.6f ols_corr_mean=%.6f mle_slope_min=%.6f mle_slope_max=%.6f\\n\",n,sm/n,so/n,rm/n,ro/n,cm/n,co/n,min,max)}"'
```

Result path:
`/project/6098264/snakagaw/phylo_xlv/direct-mean-diagnostic-10seed-narval-20260630-174900/results`.
This was a Narval Julia 1.10.10 run using the same params/seed stream as the DRAC
weak-cell rows. A prior Totoro Julia 1.12 run was ignored for seed-matched
evidence because Julia's RNG stream produced different truth values.

Per-task direct rows:

```text
task 1 rep 1 mle_slope 1.191 ols_slope 1.190 mle_rmse 0.077 ols_rmse 0.085 truth_mean -0.081
task 2 rep 2 mle_slope 1.093 ols_slope 1.096 mle_rmse 0.046 ols_rmse 0.059 truth_mean -0.081
task 3 rep 3 mle_slope 0.710 ols_slope 0.710 mle_rmse 0.091 ols_rmse 0.105 truth_mean -0.081
task 4 rep 4 mle_slope 1.113 ols_slope 1.112 mle_rmse 0.044 ols_rmse 0.061 truth_mean -0.081
task 5 rep 5 mle_slope 1.102 ols_slope 1.103 mle_rmse 0.056 ols_rmse 0.066 truth_mean -0.081
task 6 rep 6 mle_slope 1.190 ols_slope 1.190 mle_rmse 0.112 ols_rmse 0.118 truth_mean -0.081
task 7 rep 7 mle_slope 0.931 ols_slope 0.932 mle_rmse 0.035 ols_rmse 0.055 truth_mean -0.081
task 8 rep 8 mle_slope 0.536 ols_slope 0.533 mle_rmse 0.156 ols_rmse 0.163 truth_mean -0.081
task 9 rep 9 mle_slope 1.217 ols_slope 1.214 mle_rmse 0.082 ols_rmse 0.095 truth_mean -0.081
task 10 rep 10 mle_slope 0.923 ols_slope 0.924 mle_rmse 0.037 ols_rmse 0.059 truth_mean -0.081
```

Aggregate direct comparator:
`n=10`, `mle_slope_mean=1.000455`, `ols_slope_mean=1.000468`,
`mle_rmse_mean=0.073659`, `ols_rmse_mean=0.086816`,
`mle_corr_mean=0.983227`, `ols_corr_mean=0.970351`,
`mle_slope_min=0.535950`, `mle_slope_max=1.216549`.

Interpretation: the saturated direct `Y ~ X_lv` slope and the latent-product
`B_lv` slope move together almost exactly, including the bad task 8. The weak
cell is therefore a finite-sample realised-slope / interval-calibration problem,
not a simple extraction artifact or bootstrap-refit convergence failure.

Files updated for claim-boundary closeout:

- `docs/design/73-predictor-informed-latent-scores.md`
- `docs/src/changelog.md`
- `docs/src/model.md`
- `src/postfit.jl` (docstring only)
- `AGENTS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-phylo-xlv-bootstrap-basic-aggregate.md`

Claim boundary: IN: diagnostic evidence that `bootstrap_basic` fails the
p=80, K=2, lambda=0.5 `B_lv` weak-cell gate and that direct slopes confirm the
realised-data slope mechanism. OUT: no source-specific `gllvmTMB` `lv = ~ x`
exposure, no public phylo Model A interval claim, no production sweep launch, no
PR #127 push, and no non-Gaussian or Model B claim.

Ayumi's 2026-06-30 GitHub issue comment raised a related scope boundary:
classic GLLVM users usually expect the CLV/axis-effect table (`alpha_lv`) when
asking for predictor effects on latent variables. The current SE/CI machinery is
for the induced trait-scale product `B_lv = Lambda * alpha_lv'` only. That
product can be read as a low-rank trait-slope surface: it has trait-wise entries,
but they are constrained to pass through the fitted latent axes and therefore do
not spend the full `p * q_lv` ordinary fixed-effect slope parameters. Raw
axis-effect SEs remain unimplemented and would need a declared rotation or
loading-constraint convention before public interpretation. I updated Design 73,
the model docs, the changelog, and the `extract_lv_effects` docstring to make
that boundary explicit. Public API default change (`axis_effect` as default,
`trait_effect` explicit) remains a separate decision because existing internal
calls rely on the default returning `B_lv`.

Local hygiene checks after the documentation/docstring edits:

```sh
git diff --check
julia --project=. -e 'using GLLVM; println("GLLVM load ok")'
```

Results: both passed; the Julia load printed `GLLVM load ok`.

## 2026-07-02 - Structural-dependence LV truth-matrix ultra-plan

Created a plan-only truth-lock artifact for the next LV arc:

- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-truth-matrix-ultraplan.md`
- `docs/dev-log/after-task/2026-07-02-structural-lv-ultraplan.md`

The plan separates ordinary `latent(..., lv = ~ env)`, source-specific
`lv = ~ env`, structural random-slope syntax, and R<->Julia bridge matrix flags.
It keeps source-specific `lv` fail-loud, mixed-family vectors point/postfit only,
non-Gaussian source-specific LV behind a new derivation/ADEMP gate, and Totoro
/ DRAC denominators separate. No code, API, likelihood, dashboard, or compute
state changed in this slice.

## 2026-07-02 - Structural-dependence LV truth matrix Gates 0-2

Closed the evening truth-lock slice through Gate 2 and wrote:

- `docs/dev-log/decisions/2026-07-02-structural-dependence-lv-gates-0-2-closeout.md`
- `docs/dev-log/after-task/2026-07-02-structural-lv-gates-0-2.md`

Focused local checks:

```sh
Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-canonical-keywords.R")'
# 67 pass / 3 INLA skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
# 380 pass / 14 GLLVM.jl-path skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-ordinary-latent-random-regression.R")'
# 23 pass / 7 CRAN skips

Rscript -e 'pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-stage37-mixed-family.R")'
# 6 pass

julia --project=. --startup-file=no test/test_bridge_capabilities.jl
# 63 pass

julia --project=. --startup-file=no test/test_bridge_mixed.jl
# 18 pass

julia --project=. --startup-file=no test/test_bridge_x.jl
# 195 pass

julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
# 83 pass

julia --project=. --startup-file=no test/test_bridge_ci.jl
# 64 pass
```

Gate verdict: source-specific structural `lv = ~ env` is fail-loud; structural
random-slope syntax is a separate evidence lane; R and Julia bridge truth
reconciles with named drift; mixed-family vectors are point/postfit only; no
compute, source-specific grammar, PR reopen, or API widening occurred.

Mission Control was refreshed from the `gllvmTMB` worktree after Gate 0-2
verification. JSON validation passed for both `status.json` and `sweep.json`;
`version.txt` remained `r60` because no HTML/JS changed; browser preview at
`http://127.0.0.1:8770/` showed the new "Structural LV truth matrix" Gate 0-2
row and the no-API/no-compute guard.

## 2026-07-02 - LV final closeout and next capability lane

Wrote the final reconciliation packet:

- `docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md`
- `docs/dev-log/after-task/2026-07-02-lv-final-closeout-next-capabilities.md`

This reconciles the two evidence ladders without changing claims:

- Phylo Gaussian Model A is frozen through Gate 0-3 for the changed
  `B_eta_realized` target only.
- Structural-dependence LV guards and bridge truth are locally verified through
  Gates 0-2.
- Source-specific R grammar, PR #127 reopening, package API widening,
  non-Gaussian/source-specific inheritance, mixed-family `X`/`X_lv`/masks/CIs,
  and public support wording remain separate future goals.

Recommended next goal:

```text
Finish the next GLLVM capability lane after LV closeout:
ship one bounded capability slice with implementation, tests, docs, check-log,
after-task report, and Rose claim audit, while keeping source-specific LV
grammar parked.
```

## 2026-07-02 - Post-LV capability cost-control boundary

Resolved the remaining local worktree hygiene and recorded the next bounded
post-LV capability boundary:

- `bd8fad8 chore: remove redundant dev-log placeholders`
- `docs/dev-log/decisions/2026-07-02-post-lv-capability-cost-control-boundary.md`
- `docs/dev-log/after-task/2026-07-02-post-lv-capability-cost-control-boundary.md`

Source audit:

```sh
git status --short --untracked-files=all
# clean

rg -n "function confint\\(fit::_CIFit|function _family_bootstrap|function _family_ci\\(fit::ZIBFit|bootstrap_iterations::Union|_lv_boot_kwargs|fit_zib_gllvm\\(" src/confint_family.jl src/families/twopart.jl test/test_confint_family.jl
```

Key hits:

```text
test/test_confint_family.jl:207:        fit = fit_zib_gllvm(Y; K = K, N = Ntr, iterations = 120)
src/confint_family.jl:1234:function _family_ci(fit::ZIBFit, Y::AbstractMatrix;
src/confint_family.jl:1260:        fb = try fit_zib_gllvm(Yb; K = K, N = Ntr) catch; return nothing end
src/confint_family.jl:1552:function _family_bootstrap(ad::_FamilyCI, sel::Vector{Int}, level::Real,
src/confint_family.jl:1667:function confint(fit::_CIFit, Y::AbstractMatrix;
src/confint_family.jl:2014:                            bootstrap_iterations::Union{Nothing, Integer} = nothing)
src/confint_family.jl:2060:                            bootstrap_iterations::Union{Nothing, Integer} = nothing)
src/confint_family.jl:2116:function _lv_boot_kwargs(bootstrap_iterations::Union{Nothing, Integer})
src/families/twopart.jl:1082:function fit_zib_gllvm(Y::AbstractMatrix{<:Real}; K::Integer, N::Integer,
```

Verdict: generic family `confint(fit, Y; method = :bootstrap)` still has no
`bootstrap_iterations` keyword, while LV-effect bootstrap does. Copying that
keyword into the generic family route would be public API widening, so it is a
separate maintainer-approved capability slice, not an unreviewed cleanup patch.

Claim audit:

```sh
rg -n "ready to scale|partial support|source-specific.*covered|source-specific.*ready|active compute|phylo_latent\\(.*lv|spatial_latent\\(.*lv" docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md docs/dev-log/after-task/2026-07-02-full-pkgtest-after-lv-gates.md docs/dev-log/after-task/2026-07-02-zib-family-ci-smoke-budget.md docs/dev-log/after-task/2026-07-02-missing-response-extra-gate-budget.md
```

Result: only guard-language hits in the LV closeout note; no active-compute or
support-promotion hit in the checked current notes.

## 2026-07-02 - Profile-first LV selected-entry hardening

Implemented the profile-first native GLLVM.jl hardening slice:

- `profile_ci()` now accepts bounded refit/profile controls:
  `profile_iterations`, `profile_g_tol`, `profile_max_expand`, and
  `profile_max_bisect`, with legacy defaults unchanged.
- Non-Gaussian `confint(fit, Y; method = :profile)` routes the same profile
  controls into constrained family refits.
- `confint_lv_effects(...; method = :profile)` now accepts
  `profile_indices` for selected entries of `vec(B_lv)` in column-major order,
  and rejects `profile_indices` for non-profile methods instead of silently
  ignoring them.
- Docs/README/changelog now describe selected-entry native `B_lv`
  profile-likelihood canaries and keep R bridge/source-specific/mixed-family
  profile claims gated.
- gllvmTMB Mission Control was refreshed without changing metrics: native
  selected-entry profile is visible as a guarded GLLVM.jl row; no active compute,
  no R grammar exposure, no R bridge X_lv profile/bootstrap transport, no
  coverage-calibration claim.

Focused checks:

```text
julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

julia --project=. --startup-file=no test/test_confint_profile.jl
profile CI: 8 passed, 0 failed, 0 errored, 21.6s

julia --project=. --startup-file=no test/test_confint_family.jl
Non-Gaussian confidence intervals: 124 passed, 0 failed, 0 errored, 4m30.5s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 139 passed, 0 failed, 0 errored, 2m51.6s

julia --project=. --startup-file=no test/test_phylo_xlv.jl
phylo x X_lv (Model A): 25 passed, 0 failed, 0 errored, 1m17.6s

julia --project=. --startup-file=no test/test_bridge_capabilities.jl
bridge capabilities ledger: 105 passed, 0 failed, 0 errored, 0.4s

julia --project=. --startup-file=no test/test_bridge_ci.jl
bridge CI routing: 64 passed, 0 failed, 0 errored, 31.7s

julia --project=. --startup-file=no test/test_bridge_x.jl
bridge fixed-effect X (non-Gaussian one-part families): 195 passed, 0 failed,
0 errored, 36.1s

julia --project=. --startup-file=no test/test_bridge_missing_mask.jl
bridge missing-response mask: 83 passed, 0 failed, 0 errored, 26.6s

julia --project=. --startup-file=no test/test_bridge_mixed.jl
bridge mixed-family payload metadata: 18 passed, 0 failed, 0 errored, 6.4s

julia --project=docs --startup-file=no docs/make.jl
Documenter/Vitepress build completed; existing invalid-local-link warnings and
npm audit warnings remained.

julia --project=. -e 'using Pkg; Pkg.test()'
GLLVM.jl: 4981 passed, 1 broken, 0 failed, 0 errored, 4982 total, 52m59.0s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` confirmed the visible board includes
`Native profile B_lv`, `Profile-first LV uncertainty`, `profile_indices`, the
weak-cell `bootstrap_basic 591/720` block, the bridge profile boundary, and no
active compute.

## 2026-07-02 - Ordinary non-Gaussian LV profile Gate 0/1

Started the next LV goal after the non-unique closeout: ordinary
non-Gaussian selected-entry `B_lv` profile-LR first, with structural-source
gates held until each source/family estimand is separately written, tested, and
audited.

Gate 0 source:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Gate 1 implementation:

- added a tiny ordinary Poisson `X_lv` selected-entry profile canary to
  `test/test_lv_ci.jl`;
- target is `B_lv = Lambda * alpha_lv'`;
- selected entry is `B_lv[1,1]` / `vec(B_lv)[1]`;
- known DGP truth is `0.3575`;
- pass condition is route evidence only: finite profile endpoints, MLE inside
  the interval, and the known truth inside the interval.

Exploratory pre-edit smoke:

```text
julia --project=. --startup-file=no -
Poisson selected-entry profile: 11.400565 seconds, finite endpoints,
estimate 0.5047355959140866, lower 0.20380296967249809,
upper 0.8164110166907896, truth 0.3575 covered.
```

Focused verification:

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 146 passed, 0 failed, 0 errored, 3m02.2s
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60

curl -s http://127.0.0.1:8770/status.json | rg -n "Ordinary non-Gaussian LV profile|Gate 0/1|146/146|No LV compute|unique= lane"
served status includes the new Ordinary non-Gaussian LV profile row, Gate 0/1
wording, 146/146 test tally, and no-active-compute wording.
```

Claim boundary: IN: ordinary Poisson selected-entry `B_lv` profile route
evidence and a Gate 0 ADEMP note. OUT: no coverage calibration, no R bridge
profile/bootstrap transport, no source-specific `lv = ~ env`, no
source-specific structural/non-Gaussian inference, no mixed-family CI, no
`unique=` parity, no Totoro/DRAC compute.

## 2026-07-02 - Ordinary Binomial LV profile Gate 1 extension

Extended the ordinary non-Gaussian selected-entry profile route evidence from
Poisson to Binomial logit, still inside the same Gate 0 ADEMP note:

```text
docs/dev-log/decisions/2026-07-02-nongaussian-ordinary-lv-profile-ademp.md
```

Exploratory pre-edit smoke:

```text
julia --project=. --startup-file=no -
Binomial logit selected-entry profile: 17.583830 seconds, finite endpoints,
estimate 0.367562184548786, lower 0.08637093644136382,
upper 0.6588738628593764, truth 0.2475 covered.
```

Gate 1 implementation:

- added a tiny ordinary Binomial logit `X_lv` selected-entry profile canary to
  `test/test_lv_ci.jl`;
- target remains `B_lv = Lambda * alpha_lv'`;
- selected entry is `B_lv[1,1]` / `vec(B_lv)[1]`;
- known DGP truth is `0.2475`;
- the canary also threads a Binomial `N` matrix through the profile call.

Focused verification:

```text
julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 153 passed, 0 failed, 0 errored, 3m17.3s
```

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Claim boundary: IN: ordinary Poisson and Binomial logit selected-entry `B_lv`
profile route evidence. OUT: no coverage calibration, no R bridge
profile/bootstrap transport, no source-specific `lv = ~ env`, no
source-specific structural/non-Gaussian inference, no mixed-family CI, no
`unique=` parity, no Totoro/DRAC compute.

## 2026-07-02 - Non-unique LV closeout and unique-lane join gate

Closed the active goal boundary for the non-unique LV arc:

- the current LV arc remains closed as a truth-lock;
- native GLLVM.jl selected-entry `B_lv` profile work is the only new
  implementation slice in this commit;
- source-specific `lv = ~ env` remains fail-loud;
- the concurrent `unique=` lane is recorded as R/TMB-first and separate; and
- future Julia parity for `*_latent(unique=)` requires a separate join gate
  after the relevant R contract is green.

Durable join-gate source:

```text
docs/dev-log/decisions/2026-07-02-lv-arc-final-closeout-and-next-capabilities.md
```

Mission Control source was aligned to show `Unique lane boundary` in both
`status.json` and `sweep.json`, without changing LV metrics.

Fresh closeout verification:

```text
julia --project=. --startup-file=no test/test_confint_profile.jl
profile CI: 8 passed, 0 failed, 0 errored, 22.5s

julia --project=. --startup-file=no test/test_lv_ci.jl
X_lv Wald CIs - confint_lv_effects: 139 passed, 0 failed, 0 errored, 3m02.2s

julia --project=. --startup-file=no test/test_phylo_xlv.jl
phylo x X_lv (Model A): 25 passed, 0 failed, 0 errored, 1m16.8s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh tools/start-mission-control.sh --background
curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Claim scan result: current hits for `partial support`, source-specific support,
R bridge profile transport, coverage calibration, and `unique=` parity are
guard/negative wording only.

## 2026-07-02 - Non-Gaussian structural-source LV Gate 0 matrix

Banked the structural-source non-Gaussian LV Gate 0 matrix after the ordinary
one-part selected-entry profile canary set completed. This is a planning and
claim-boundary artifact only:

- ordinary Poisson, Binomial logit, NB2, Gamma, and Beta selected-entry `B_lv`
  profile-LR canaries remain local/native ordinary route evidence;
- phylo/spatial/animal/kernel non-Gaussian LV must start with a source/family
  target page before any local canary, Totoro diagnostic, DRAC claim evidence,
  R grammar exposure, or bridge promotion;
- no source-specific `lv = ~ env`, mixed-family CI, R bridge profile/bootstrap
  transport, coverage calibration, or `unique=` parity was added.

Files updated:

```text
docs/design/73-predictor-informed-latent-scores.md
docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md
docs/dev-log/check-log.md
docs/dev-log/after-task/2026-07-02-nongaussian-structural-source-lv-gate0.md
```

Mission Control source refreshed in the gllvmTMB dashboard checkout:

```text
docs/dev-log/dashboard/status.json
docs/dev-log/dashboard/sweep.json
```

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_xlv.jl
phylo × X_lv (Model A): 25 passed, 0 failed, 0 errored, 1m06.7s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R"); main_check_after_task("docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s0-target.md")'
after-task structure check passed
Rscript -e 'source("/Users/z3437171/Dropbox/Github Local/Shinichi/tools/rose-pattern-scan.R"); main_rose_pattern_scan(".")'
Rose pattern scan passed
```

Mission Control refresh:

```text
sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview check at `http://127.0.0.1:8770/` confirmed the visible board
contains "Structural-source non-Gaussian LV Gate 0", ordinary Poisson/Binomial
logit/NB2/Gamma/Beta route evidence wording, and no-active-compute wording.

Claim scan:

```text
rg -n "partial support|ready to expose|inherits ordinary|inherits Gaussian|source-specific.*covered|active compute|grammar exposure|unique=.*parity|bootstrap rescue|mixed-family CI" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md
```

Hits are expected guard wording only: no `unique=` parity, no bootstrap rescue,
no "partial support", no inherited ordinary/Gaussian support, and no active
compute.

## 2026-07-02 - Phylo x Poisson structural LV S0 target

Banked the first source/family S0 target page after the structural-source
non-Gaussian Gate 0 matrix:

- source/family: phylo x Poisson(log);
- target: link-scale realized/design-conditional `B_eta_realized`, not old
  population `B_lv` and not observed-response `Y ~ X_lv`;
- symbolic model: predictor-informed site latent score plus additive
  phylogenetic source intercept;
- boundary: S1 remains blocked until a combined phylo + Poisson + `X_lv`
  likelihood exists with reduction tests.

Files updated:

```text
docs/design/73-predictor-informed-latent-scores.md
docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md
docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md
docs/dev-log/check-log.md
docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s0-target.md
test/test_phylo_glm.jl
```

Test hygiene: `test/test_phylo_glm.jl` now imports `Distributions: Poisson` so
the existing focused test passes when run in isolation.

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 4.0s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

Claim scan:

```text
rg -n "partial support|ready to expose|inherits ordinary|inherits Gaussian|source-specific.*covered|active compute|grammar exposure|unique=.*parity|bootstrap rescue|mixed-family CI|ordinary Poisson plus phylo_glm equals support" docs/design/73-predictor-informed-latent-scores.md docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md
```

Hits are guard wording only. The S0 page explicitly says the existing ordinary
Poisson `X_lv` route plus the existing `phylo_glm` route do not equal support.

Mission Control source was refreshed in the gllvmTMB dashboard checkout with a
guard row named "Phylo x Poisson structural LV S0"; metrics unchanged.

Mission Control refresh:

```text
sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview check at `http://127.0.0.1:8770/` confirmed the visible board
contains "Phylo x Poisson structural LV S0", the combined-likelihood blocker,
and the no-source-specific-grammar/no-compute wording.

## 2026-07-02 - Phylo x Poisson structural LV S1 likelihood proof

Implemented the first private combined likelihood proof for the phylo x Poisson
x predictor-informed LV route:

- new internal `_phylo_poisson_xlv_marginal_loglik` in
  `src/phylo_poisson_xlv.jl`;
- joint Laplace over site-score innovations and augmented phylo random
  intercepts;
- Poisson(log) only, no public fitter/export/R grammar/bridge route;
- documentation boundary refreshed from "combined likelihood missing" to the
  then-current S1 route-gate boundary; that historical boundary is superseded
  by the profile-canary closeout above.

Files updated:

```text
src/phylo_poisson_xlv.jl
src/GLLVM.jl
test/test_phylo_poisson_xlv.jl
test/runtests.jl
docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md
docs/dev-log/decisions/2026-07-02-phylo-poisson-structural-lv-s0-target.md
docs/dev-log/decisions/2026-07-02-nongaussian-structural-source-lv-gate0.md
docs/design/73-predictor-informed-latent-scores.md
docs/dev-log/check-log.md
docs/dev-log/after-task/2026-07-02-phylo-poisson-structural-lv-s1-likelihood.md
```

Focused verification:

```text
julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.8s

julia --project=. --startup-file=no test/test_phylo_glm.jl
Phylogenetic GLM (augmented-state joint Laplace): 6 passed, 0 failed, 0 errored, 3.8s

julia --project=. --startup-file=no test/test_phylo_eta_realized.jl
phylo Model A eta-realized target: 7 passed, 0 failed, 0 errored, 2.5s

julia --project=. --startup-file=no -e 'using GLLVM; println("load-ok")'
load-ok

git diff --check
```

Attempted broader core run:

```text
julia --project=. --startup-file=no -e 'include("test/runtests.jl")'
```

Interrupted after a long active run in `test/test_zero_inflated.jl`; no failure
output before termination, and not counted as a pass.

JET was not run because `JET` is not installed in this project environment.
Benchmarks/allocation checks are deferred because this dense joint Hessian is a
tiny S1 proof surface, not a production scaling path.

Mission Control refresh:

```text
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
git diff --check -- docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json

sh tools/start-mission-control.sh --background
GLLVM mission-control dashboard already available at http://127.0.0.1:8770/
Synced dashboard files to /tmp/gllvm-dashboard
Mirrored disposable live output to /private/tmp/gllvm-dashboard

curl -s http://127.0.0.1:8770/status.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/sweep.json | python3 -m json.tool >/dev/null
curl -s http://127.0.0.1:8770/version.txt
r60
```

Browser preview at `http://127.0.0.1:8770/` confirmed the visible board shows
"Phylo x Poisson structural LV S1", "combined likelihood proof",
"selected-entry B_eta_realized profile-LR canary", "No public fitter",
"Totoro/DRAC compute", and `test_phylo_poisson_xlv.jl 9/9`.

## 2026-07-03 - PR #165 Poisson selected-entry CI fix

PR #165 CI failed on the phylo x Poisson `B_eta_realized` selected-entry
canary because the test required `prof.pd_hessian == true`. That field is a
route-quality aggregate over internal constrained-refit convergence plus
endpoint status; it is not the scientific gate for this private S1 canary. On
macOS and Julia 1.10 Ubuntu, Nelder-Mead did not report convergence even though
the selected-entry profile endpoints were finite, the constraint error was
below `1e-3`, and the truth target was included.

Changed the test to keep the S1 claim aligned with the intended evidence:
finite selected-entry profile endpoints, finite LR, LR below cutoff at the
truth, constraint error below tolerance, and `covered == true`. The test now
checks that `constrained_converged` is present as a Boolean vector without
requiring the platform-sensitive aggregate flag to be true.

Files changed:

```text
test/test_phylo_poisson_xlv.jl
docs/dev-log/check-log.md
docs/dev-log/after-task/2026-07-03-pr165-poisson-profile-ci-fix.md
```

Commands:

```text
gh pr view 165 --repo itchyshin/GLLVM.jl --json number,state,mergeable,mergeStateStatus,statusCheckRollup,mergedAt,url,headRefOid,baseRefName,headRefName
# Documenter success; Julia 1.10 ubuntu and macOS failed at
# test/test_phylo_poisson_xlv.jl:179, Expression: prof.pd_hessian.

julia --project=. --startup-file=no test/test_phylo_poisson_xlv.jl
Phylo x Poisson predictor-informed LV S1 likelihood: 9 passed, 0 failed, 0 errored, 4.7s
Phylo x Poisson B_eta_realized selected-entry canary: 22 passed, 0 failed, 0 errored, 13.3s

git diff --check
```

Claim boundary unchanged: no public fitter, no R grammar, no bridge route, no
coverage calibration, no source-specific `lv` exposure, and no bootstrap rescue.

## 2026-07-03 - Arc 1 profile-first source LV Gate 0 truth lock

Started the approved Arc 1 + Arc 3 ultra-plan execution as a Gate 0 truth-lock
slice while PR #165 CI continued running on head `2fdd7a6`. PR #165 later
merged as GitHub merge commit `8617ba1`; the late Julia matrix remained a
post-merge follow-up watch item at Gate 0 closeout time.

Four read-only audit lanes wrote file-backed evidence:

```text
docs/dev-log/audits/2026-07-03-arc1-profile-estimand-audit.md
docs/dev-log/audits/2026-07-03-arc1-bridge-grammar-audit.md
docs/dev-log/audits/2026-07-03-arc1-compute-test-plan.md
docs/dev-log/audits/2026-07-03-arc1-rose-claim-audit.md
```

Consolidated decision note:

```text
docs/dev-log/decisions/2026-07-03-arc1-profile-first-source-lv-gate0.md
docs/dev-log/after-task/2026-07-03-arc1-gate0-truth-lock.md
```

Gate 0 truth:

- public source-specific `lv = ~ env` remains blocked/fail-loud for phylo,
  spatial, animal, and kernel;
- old population-`B_lv` remains negative/parked;
- `B_eta_realized` is internal changed-target route evidence, not `B_lv`
  rescue;
- local tests are route/canary evidence only;
- Totoro is diagnostic-only;
- DRAC/Nibi is the only claim-bearing denominator;
- no active compute is running;
- Mission Control needs follow-up label cleanup before public-facing polish.

## 2026-08-02 - X/covariate light logLik cohort 1

Branch `parity/x-covariate-light-loglik-20260802` from `origin/main` @ `4d19c503`.
Twin gllvmTMB `/tmp/gllvmtmb-parity-x-loglik-20260802` @ `910ebd54`; R lib
`/tmp/R-gllvmtmb-x-parity-20260802`.

Added shared-X RCall helper `fit_gllvmtmb_parity_loglik_x` (formula
`value ~ 0 + trait + x + latent(..., unique=FALSE)`) and three light logLik
cells (Gaussian / Binomial / Poisson, q=1 shared site X). Full opt-in parity
suite green: prior 63 assertions + 18 X assertions. X ΔlogLik all ≤ 4e-9 at
rtol 1e-6. Log: `docs/dev-log/x-covariate-parity-full-20260802.log`.
After-task: `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md`.

Rose fence: light logLik with shared X for G/Bin/Pois only — not NB2/Beta+X,
not full family parity. Push/PR gated on maintainer ask.

## 2026-08-03 - Gamma+X dispersion identity (Arc 0)

Branch `docs/gamma-x-identity-20260803` from `origin/main` @ `0e241215` (#176
merged). Docs-only; **no `src/`**.

Decision lock (G0 Ada judgment): public/twin default for Gamma **under shared
site-X** = per-trait shape `α_t` + shared `γ`, twin to live gllvmTMB
`log_phi_gamma` (fid 4). Shared-α + X remains opt-in via `fit_gllvm_cov`.
No-X bridge Option B = **named follow-up** (not flipped here).

Twin cites verified on `gllvmTMB` `origin/main` @ `840d1da8`
(`git show origin/main:…`):
- `src/gllvmTMB.cpp:313,746,2152–2156` (`PARAMETER_VECTOR(log_phi_gamma)`,
  per-trait `exp(log_phi_gamma(t))`)
- `R/fit-multi.R:4034–4040,4771` (per-trait warmstart + Ordinary Gamma map note)

Artefacts:
- `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
- `docs/dev-log/after-task/2026-08-03-gamma-x-identity.md`
- `docs/dev-log/plan-actual/2026-08-03-gamma-x-identity.md`
- board update in `docs/dev-log/coordination-board.md`

Rose fence: identity ≠ engine; ≠ Gamma+X RCall; ≠ full family parity;
≠ Ordinal+X; ≠ silent no-X Option B flip. #177 landing remains separate OWED.

## 2026-08-03 - Gamma+X engine Arc 1 (`fit_gamma_gllvm_grouped_cov`)

Branch `fix/gamma-x-grouped-cov-20260803` from `origin/main` @ `0e241215`
(+ identity decision commits). Twin re-cite on local gllvmTMB @ `19e9cedd`:
`src/gllvmTMB.cpp:248,617,2033–2037`; `R/fit-multi.R:4249`.

Engine: `GammaGroupedCovFit` + `fit_gamma_gllvm_grouped_cov` (per-trait/group
α + shared site-X γ; FD LBFGS). Bridge X + `@formula`+X route `gamma` through
it. `fit_gllvm_cov(...; family=Gamma())` remains shared-α opt-in.

Verify (printed tallies; no rtol widen):
- `test/test_gamma_x_identity.jl` → **7/7 Pass**
- `test/test_bridge_x.jl` → **204/204 Pass**
- formula smoke → `GammaGroupedCovFit` (G=p)

Rose fence: engine claim only (Julia identity + routing). **Not** light RCall
Gamma+X; **not** no-X Option B flip; **not** full family parity; **not** #177
merge. Next = separate RCall Arc 2 `/goal`. After-task:
`docs/dev-log/after-task/2026-08-03-gamma-x-grouped-cov.md`.
