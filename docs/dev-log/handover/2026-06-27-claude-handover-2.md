# Claude → Claude handover (2026-06-27, evening) — `latent(lv=~x)` trio DONE; phylo Model A in build

**You are Claude, resuming a long, productive session.** This is the SECOND handover of
2026-06-27 (the first, PR #122, was closed — superseded). Codex is on leave; this session ran
the live Julia/R toolchain by hand. Read this top-to-bottom before touching anything. The chat
is gone; the repo is the source of truth.

> **Companion design + research docs** (read before building the phylo feature):
> `~/shinichi-brain/intake/2026-06-27-phylo-xlv-design.md` (the Model A/B design),
> `~/shinichi-brain/intake/2026-06-27-profile-likelihood-research.md`,
> `~/.claude/memory/memory_summary.md` (doctrine, repo rules, the v1.0 split),
> `~/shinichi-brain/memory/DECISIONS.md` D-12 (profile-is-hero).

---

## 0. The goal (durable why)

`/goal`: **finish ALL the work for `latent(..., lv = ~ x)` across R and Julia** — CIs, all
families, structured sources, the article — each gated by recovery/coverage. The broader frame
(set this session): **both packages (gllvmTMB + GLLVM.jl/drmTMB) to v1.0**; lv work is a slice.

**Hard constraints (verbatim — do not violate):**
- **Never** do PR work from `/Users/z3437171/Dropbox/Github Local/gllvmTMB` (the dirty
  mission-control tree — never clean/reset/commit/harvest it). Use the `/private/tmp/gllvm*` worktrees.
- **One open PR at a time.** Never `git add -A` (Documenter artifacts). Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`. PR bodies end with the Claude Code line.
- Family/likelihood/**engine/grammar** changes are HIGH-RISK → maintainer sign-off before merge.
- Keep user-facing advertising / capability-promotion **parked** until the register/NEWS/article slice.
- No GPU lane. Keep REML/AI-REML language Gaussian-only. Don't claim broad R↔Julia parity.

---

## 1. Headline state — two big wins + the headline feature in build

1. **The CI trio for `B_lv` is COMPLETE and MERGED to GLLVM.jl `main`** (`0e99c04`):
   Wald + bootstrap (#125) + profile (#126), all six families + Gaussian, native. Plus the
   package-wide `2f0` Wald-SE fix (#119) and all six X_lv bridge routes (#118/#120/#121/#123 +
   Gaussian #116/binomial #117). **Task A done.**
2. **The R env is FIXED on the Mac** — a single bad `~/.Rprofile` line forced a Linux R-4.4
   libpath on macOS R-4.6 → segfault. Now gated on `Sys.info()[["sysname"]]=="Linux"`; deps
   installed. **Live `devtools::test()` works** — the session-long "R is parse-only" blocker is gone.
3. **Headline feature in build: phylo × `X_lv` = MODEL A** (maintainer chose A over B). On branch
   **`claude/phylo-xlv-modelA-20260627`** (`a06bf17`, pushed). **Phase 1 (engine) + Phase 2a (Wald
   CI) DONE and tested 8/8.** The hard correctness question is *verified* (see §3).

---

## 2. Mission control

### GLLVM.jl (Julia) — `github.com/itchyshin/GLLVM.jl`, `main` = `0e99c04`

| item | branch / PR | state |
|---|---|---|
| X_lv routes (6 families) + 2f0 fix + **CI trio (Wald/profile/bootstrap)** | #116–#126 | ✅ **on main** |
| **phylo Model A (engine + Wald CI)** | `claude/phylo-xlv-modelA-20260627` (`a06bf17`) | 🟡 pushed, WIP — needs Phases 2b/3/4 + sign-off |

### gllvmTMB (R) — `github.com/itchyshin/gllvmTMB`

| item | branch | state |
|---|---|---|
| R: admit Poisson X_lv (engine='julia') | `claude/poisson-xlv-r-20260626` (`1404783`) | pushed, held — needs PR + CI |
| R: admit NB2/Gamma/Beta X_lv | `claude/nbgammabeta-xlv-r-20260627` (`b940a96`) | pushed, held — needs PR + CI |
| **R CI reader (option-b, Wald CIs)** | `claude/xlv-r-ci-reader-20260627` (`29abe90`) | pushed, **live-validated 532/0** — needs PR + CI |

> These three R branches are the **R side of the bridge X_lv** (separate from phylo). They land
> *after* the Julia bridge is on main (it is). They are **live-testable now** (R env fixed).
> Land order: poisson-xlv-r → nbgammabeta → ci-reader. Each its own PR + gllvmTMB CI + maintainer merge.

### Sister-package issues filed
- [drmTMB#680](https://github.com/itchyshin/drmTMB/issues/680) (t-calibration), [#682](https://github.com/itchyshin/drmTMB/issues/682) (profile trio + boundary trap).

---

## 3. The phylo Model A build — what's done, what's next (THE active work)

**Model A** = predictor-informed score MEAN (`X_lv·α`, site axis) composed with the **existing
trait-axis phylo trait-covariance** (`Σ_phy`, species axis). Orthogonal, additive, **no new
identifiability hazard**. Estimand `B_lv = Λ_B·α'` (rotation-stable). Reuses the J3 closed-form
phylo marginal verbatim. (Model B — the latent score itself evolves on the tree, = phylogenetic
factor analysis — is **post-v1.0**, task #26.)

**DONE (commit `a06bf17`, tested `test/test_phylo_xlv.jl` 8/8):**
- `likelihood.jl`: `gaussian_lv_nll_packed` unpacks a phylo block (σ_phy/Λ_phy, same order as the
  non-X_lv J3 path) and threads it into `gaussian_marginal_loglik` (the J3 branch already existed).
- `fit.jl`: lifted the X_lv+phylo rejections; extended init + NLL call + post-fit unpacking (Λ_B
  was assumed last); populate Λ_phy/σ_phy + **store Σ_phy on the fit**; **PosDefException guard**
  (free `log σ_eps` + J3 Cholesky fails when the line search drives σ_eps→0 → return a large finite
  value so LBFGS backtracks; the non-X_lv path avoids this via its *profiled* objective).
- `confint_family.jl`: `confint_lv_effects(::GllvmFit)` rebuilds the Hessian on the SAME augmented
  objective (carries the phylo block). The B_lv extractor + delta method are **unchanged** (phylo
  tail appended after Λ_B; delta uses only the α/Λ block of Σ=inv(H), inflated by the phylo params).
- **★ Verified correctness:** the J3 rotation trick matches a dense `vec(y)~N(μ, I_n⊗A + J_n⊗B)`
  Gaussian to **machine precision (7e-15) WITH the X_lv mean shift** — the design's #1 risk, dead.
  Recovery cor 0.999; Wald CI finite + brackets.

**NEXT (the remaining Model A phases):**
- **Phase 2b — profile + bootstrap CI under phylo.** `confint_lv_effects(::GllvmFit)` profile path
  reuses the same nll (already carries phylo now); **bootstrap** (`_lv_bootstrap`) refits via
  `fit_gaussian_gllvm` and must thread `K_phy/has_phy_unique/Σ_phy` through the refit. Test both.
- **Phase 3 — recovery/coverage GATE (the design's hard bar).** Must prove the predictor MEAN and
  the phylo COVARIANCE are *separable*: a **phylo-COLLINEAR X_lv arm** (X_lv simulated as a Brownian
  trait on the same tree) + **two nulls** (true α=0/phylo>0 → α̂≈0, B_lv covers 0; true phylo=0/α≠0 →
  phylo≈0, B_lv unbiased). Sweep λ∈{0,0.5,1}, n_species∈{~20,~200}, K∈{1,2}, ≥500 reps, vec(B_lv)
  bias/coverage via Frobenius/Procrustes + phylo-signal coverage. **DRAC-able** (one seed per array task).
- **Phase 4 — R `lv=~x` grammar.** Does NOT exist on the R side. Admit on `phylo_latent` (and plain
  `latent`) via `rewrite_canonical_aliases()` (`R/brms-sugar.R`) with a **FAIL-LOUD gate** — an unknown
  `lv=` currently falls to `cs$extra` and is **SILENTLY DROPPED** (the Sokal anti-pattern). Keep STRICTLY
  separate from the augmented-LHS reaction-norm grammar (`1+x|sp`). Extractor contract + create the
  missing **Design 73** doc (the Julia comments already reference it).
- Then: open the Model A PR (HIGH-RISK → maintainer sign-off), and decide D5/D6/D7 (default: extend all
  three CIs; BM/Pagel-λ kernel first; Gaussian-only v1). Non-Gaussian phylo X_lv = separate later gate.

---

## 4. Gotchas / hard-won lessons (do not relearn)

- **Workflows DIE on live-toolchain work.** The profile build crashed 3×, the ELR audit / reply
  draft / roadmap / lit search all died on server rate-limiting. **Use Workflow ONLY for read-only
  design / research / audit.** Live Julia/R compilation + iterative debugging = **by hand** (that's
  how the whole CI trio + Model A engine got built).
- **The merge gate.** `gh pr merge` was permission-DENIED for me for most of the session (the
  maintainer merged #123/#124 manually); it later opened and I merged #125/#126. A fresh session may
  hit the deny again — if so, hand the maintainer the one-line `gh pr merge N --squash --repo …`.
- **Model A PosDef guard** — see §3. The free-σ_eps explicit objective needs it; the profiled
  objective doesn't.
- **The lit search (`wzysqad3k`) to ground Model A's framing** (gllvm concurrent ordination, Hmsc,
  phylo factor analysis, RRR) was launched but likely died — **relaunch it** (read-only, should
  survive) before writing the article; it tells you what Model A is *called* in the field.
- Smoke test scripts live in `/tmp/phylo_xlv_*.jl` (uncommitted); the committed test is
  `test/test_phylo_xlv.jl`.

---

## 5. How to resume (TARGET = Claude)

1. Read `~/.claude/memory/memory_summary.md` + this doc + the two intake design/research notes (§0 banner).
2. `cd` into a `/private/tmp/gllvm*` worktree — **never** the Dropbox mission-control tree. Map state:
   ```bash
   cd /private/tmp/gllvmjl-phylo-xlv && git fetch origin
   git log -1 --format='%h %s' origin/main            # expect 0e99c04 (trio on main)
   git log -1 --format='%h %s' claude/phylo-xlv-modelA-20260627   # a06bf17 (Model A WIP)
   export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl   # expect 8/8
   ```
3. **Continue the phylo Model A build** (§3 Next): Phase 2b → 3 → 4, by hand. Then PR (sign-off).
4. **In parallel, land the 3 held R branches** (§2) — live-testable now (`devtools::test()` works).
5. **Live R/Julia is fine on this Mac now.** Spawn the repo's review lens (Rose) before any public
   capability claim. Workflows ONLY for read-only design/research.

### One-command resume (paste in your authenticated terminal)
```
claude "Rehydrate from docs/dev-log/handover/2026-06-27-claude-handover-2.md in the GLLVM.jl repo; continue the phylo Model A build (Phase 2b profile/bootstrap CI → Phase 3 recovery/coverage gate → Phase 4 R lv=~x grammar) and land the 3 held R branches."
```

---

## 6. Files created / modified this session (key)

**GLLVM.jl `main` (merged):** `src/confint_family.jl` (the CI trio: Wald/bootstrap/profile +
`confint_lv_effects`), `src/bridge.jl` (X_lv routes + `ci_method="wald"`), `test/test_lv_ci.jl`
(114), `src/confint_family.jl` `_fd_hessian` 2f0 fix + `test_fd_hessian.jl`, the family X_lv routes.

**GLLVM.jl `claude/phylo-xlv-modelA-20260627` (`a06bf17`, WIP):** `src/likelihood.jl`, `src/fit.jl`,
`src/confint_family.jl`, `test/test_phylo_xlv.jl` — Model A engine + Wald CI. + this handover doc +
the AGENTS snapshot edit.

**gllvmTMB (held branches):** `R/julia-bridge.R`, `R/extractors.R`, `tests/testthat/test-julia-bridge.R`
(the option-b CI reader + family admissions).

**Durable memory:** `~/.claude/memory/memory_summary.md` (profile-hero, v1.0 split, R-env-fixed,
phylo Model A headline), `~/shinichi-brain/memory/DECISIONS.md` D-12,
`~/shinichi-brain/intake/2026-06-27-{phylo-xlv-design,profile-likelihood-research}.md`.

**Tasks #19–26** carry the deferred/post-v1.0 items (native-TMB CI, Ayumi follow-up, t-cal NOT needed,
profile cutoff, ELR post-1.0, phylo Model A, Model B post-1.0).
