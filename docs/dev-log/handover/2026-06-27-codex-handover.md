# Claude → Codex handover (2026-06-27) — `latent(lv=~x)`: CI trio shipped; phylo Model A engine done; LIVE-TOOLCHAIN work for Codex

**You are Codex, picking up the `latent(..., lv = ~ x)` program.** A long Claude session built the
Julia engine + CI work by hand (it cannot reliably run the heavy/live toolchain at scale); the
**remaining work is exactly your lane** — real fits at scale, the DRAC coverage campaign, `R CMD
check`, the R-side grammar + bridge, and rendering. This doc stands alone (you never saw that chat).

> **Source of truth:** `AGENTS.md` (read first), this doc, and the cross-tool routing below. The
> companion design/research live in the shared brain:
> `~/shinichi-brain/intake/2026-06-27-phylo-xlv-design.md` (Model A/B design + the 7 decisions),
> `~/shinichi-brain/intake/2026-06-27-profile-likelihood-research.md`,
> `~/.claude/memory/memory_summary.md` (doctrine, repo rules, v1.0 split),
> `~/shinichi-brain/memory/DECISIONS.md` D-12. The Claude-side companion handover is
> `docs/dev-log/handover/2026-06-27-claude-handover-2.md` (same facts, Claude-tuned recipe).

---

## 0. Goal + hard constraints (verbatim)

**Goal:** finish ALL `latent(lv = ~ x)` work across R and Julia — CIs, all families, structured
sources (phylo first), the article — each **gated by recovery/coverage**. Broader frame: **both
packages (gllvmTMB + GLLVM.jl/drmTMB) to v1.0**.

**Constraints — do not violate:**
- **Never** do PR work from `/Users/z3437171/Dropbox/Github Local/gllvmTMB` (dirty mission-control
  tree). Use `/private/tmp/gllvm*` worktrees / fresh clones.
- **One open PR at a time.** Never `git add -A` (Documenter/check artifacts). Commit trailer:
  `Co-Authored-By: …` your own. PR bodies end with the tool's generated-by line.
- Family/likelihood/**engine/grammar** changes are HIGH-RISK → **maintainer sign-off before merge**
  (the `ROADMAP.md` Discussion-Checkpoints list is authoritative).
- Keep user-facing advertising/capability-promotion **parked** until the register/NEWS/article slice.
- No GPU lane. REML/AI-REML language Gaussian-only. Don't claim broad R↔Julia parity.
- **Rose audit (`.codex/agents/*.toml`, mirrored from the team) is MANDATORY before any public claim.**

---

## 1. State: what's DONE (don't redo)

- **GLLVM.jl `main` = `0e99c04`.** All six `X_lv` bridge routes (Gaussian/binomial/Poisson/NB2/Gamma/
  Beta), the package-wide `2f0` Wald-SE fix (#119), and the **full `B_lv` CI trio — Wald + profile +
  bootstrap** (`confint_lv_effects`, #125/#126). `test_lv_ci.jl` 114/114.
- **R env on the Mac is FIXED.** A bad `~/.Rprofile` line forced a Linux R-4.4 libpath on macOS R-4.6
  → segfault; now gated `if Sys.info()[["sysname"]]=="Linux"`. **Live `devtools::test()` works.**
- **Phylo × X_lv = MODEL A — engine + full CI trio + coverage smokes DONE** on branch
  **`claude/phylo-xlv-modelA-20260627`** (tip `e5e7bc7`, **draft PR #127**, do not merge):
  - `likelihood.jl` `gaussian_lv_nll_packed` threads a phylo block (σ_phy/Λ_phy) into the existing J3
    closed-form marginal on the X_lv residual; `fit.jl` lifts the X_lv+phylo rejections + extends the
    packed layout + a PosDefException guard + stores Σ_phy; `confint_family.jl` rebuilds the Hessian on
    the augmented objective (B_lv extractor unchanged).
  - **Verified:** J3-rotation-trick correctness pinned to **7e-15** WITH the X_lv mean shift (vs dense
    `vec(y)~N(μ, I_n⊗A + J_n⊗B)`); recovery cor 0.999; **`test/test_phylo_xlv.jl` 15/15** (Wald +
    profile + bootstrap all finite + bracketing under phylo); **coverage smokes** (`bench/phylo_xlv_
    coverage.jl`): single-cell 0.975 + both nulls clean; multi-cell K=1/K=2 × large/small n = 0.93–0.97,
    90/90 converged.

### Held R branches (gllvmTMB — the bridge X_lv R-side, pushed, NOT merged)
- `claude/poisson-xlv-r-20260626` (`1404783`) — admit Poisson X_lv on `engine='julia'`.
- `claude/nbgammabeta-xlv-r-20260627` (`b940a96`) — admit NB2/Gamma/Beta X_lv.
- `claude/xlv-r-ci-reader-20260627` (`29abe90`) — the option-b CI reader (surfaces Wald `lower/upper/se`);
  **live-validated 532/0** on the Mac.

---

## 2. YOUR work (live toolchain) — routed to Codex

Claude does planning/design/refactor/prose. **Codex runs the live toolchain.** Priorities:

1. **Phase 3 — the full DRAC coverage campaign for Model A.** `bench/phylo_xlv_coverage.jl` is the
   committed seed (40-rep + multi-cell smokes pass). Scale to the v1 gate: sweep **λ/Pagel ∈ {0,0.5,1}
   × n_species ∈ {~20,~200} × K ∈ {1,2}, ≥500 reps/cell**, one seed per **SLURM array task** on Fir/
   Nibi/Narval/Rorqual/Trillium (CPU, no GPU). Targets: vec(B_lv) bias/coverage (Frobenius/Procrustes,
   never elementwise — B_lv is sign-stable so no alignment needed for Wald), ~95% trio coverage, +
   phylo-signal-parameter coverage, + the two nulls. Model A is **orthogonal-axes** → it needs coverage
   + the two nulls **only**, NOT the phylo-collinear arm (that's a Model B confound). Put the depot/R
   lib on `/project` not `/scratch`; `seff` after one run to right-size. Gate behind `skip_if_not_heavy`.
2. **Phase 4 — R `lv = ~ x` grammar + bridge for Model A.** The grammar does NOT exist on the R side.
   Admit `lv = ~ x` on `latent()`/`phylo_latent()` via `rewrite_canonical_aliases()` (`R/brms-sugar.R`)
   with a **FAIL-LOUD gate** — an unknown `lv=` currently falls to `cs$extra` and is **SILENTLY DROPPED**
   (the Sokal anti-pattern; mirror `.assert_no_augmented_lhs`). Keep STRICTLY separate from the
   augmented-LHS reaction-norm grammar (`1+x|sp`). The bridge needs **3 new layers** (per the design):
   `gllvm_julia_fit()` X_lv + phylo VCV inputs; drop the X/phylo exclusion for the X_lv+phylo route;
   the dispatch gate `GJL-GATE-STRUCTURED-TERMS` must stop rejecting `phylo_rr` when paired with an lv
   predictor + build the n×q_lv X_lv design. Create the missing **Design 73** doc (Julia comments
   reference it). Wide + long calls present together; forced-unknown-lv negative test. `R CMD check`.
3. **Land the 3 held R branches** (§1) — each its own PR + gllvmTMB `R CMD check`/CI + maintainer merge.
   Land order: poisson → nbgammabeta → ci-reader.
4. **Native-TMB `B_lv` CI** (task #19, Ayumi's `engine='TMB'` path): coverage study on the sdreport
   delta-method intervals; if it holds, flip `wald_sdreport_no_ci_validation` → admitted. Live R/TMB.
5. **Later gates (separate sign-offs):** non-Gaussian phylo X_lv (genuinely new Laplace-core derivation —
   structured prior ≠ I), Model B (post-v1.0, task #26, native-TMB design-65 kernel_latent), the article.

**Open Model-A decisions to confirm with the maintainer (Phase 0):** D5 CI scope (default: all three),
D6 kernel (default: BM/Pagel-λ first; OU not implemented), D7 family (Gaussian-only v1).

---

## 3. Live-env exports (Codex)

```bash
export PATH="$HOME/.juliaup/bin:$PATH"          # Julia (juliaup)
# Julia: cd into a /private/tmp/gllvmjl-* worktree; Manifest.toml is gitignored →
#   julia --project=. -e 'using Pkg; Pkg.instantiate()'   (once per fresh worktree)
#   julia --project=. test/test_phylo_xlv.jl              (expect 15/15)
# R (macOS, FIXED): R 4.6, libpath now correct; for the gated/Suggests tests:
export NOT_CRAN=true                            # e.g. devtools::test() on the gllvmTMB R worktrees
# DRAC: full runbook in ~/shinichi-brain/tools/drac-setup.md — sbatch/salloc only (never login
#   nodes); depot + R lib on /project (NOT /scratch, purged ~60d); set --account/--time/--mem.
```

---

## 4. Gotchas / lessons (do not relearn)

- **The merge gate.** `gh pr merge` was permission-blocked for Claude most of the session (the
  maintainer merged manually) then opened. If you hit a deny, hand the maintainer the one-line
  `gh pr merge N --squash --repo …`.
- **Model A PosDef guard** — the free-σ_eps explicit objective can drive σ_eps→0 in the line search →
  J3 Cholesky `PosDefException`; the guard returns a large finite value so LBFGS backtracks. The
  non-X_lv path avoids this via its *profiled* objective. Keep the guard.
- **Coverage discipline:** target `vec(B_lv)` (rotation-stable), NEVER elementwise on `α`/`Λ`.
- Smoke scripts are in `/tmp/phylo_xlv_*.jl` (uncommitted, throwaway); the committed evidence is
  `test/test_phylo_xlv.jl` + `bench/phylo_xlv_coverage.jl`.
- The Claude-side multi-agent workflows **die on live-toolchain work** — irrelevant to you (you run
  the real thing); but it's why the engine was hand-built.

---

## 5. How to resume (Codex)

1. Read `AGENTS.md`, then this doc + the design note (§ banner). Map state:
   ```bash
   cd /private/tmp/gllvmjl-phylo-xlv && git fetch origin
   git log -1 --format='%h %s' origin/main                          # 0e99c04 (trio)
   git log -1 --format='%h %s' claude/phylo-xlv-modelA-20260627     # e5e7bc7 (Model A engine+CI+smokes)
   export PATH="$HOME/.juliaup/bin:$PATH"; julia --project=. test/test_phylo_xlv.jl   # 15/15
   ```
2. Spawn the mandatory **Rose** audit lens before any public claim.
3. Drive Phase 3 (DRAC sweep) and Phase 4 (R grammar + bridge), land the 3 R branches, do the native-TMB
   coverage study — all live. Get the Model A design + D5/D6/D7 sign-off before merging draft #127.

### Mission control
| repo | ref | state |
|---|---|---|
| GLLVM.jl `main` | `0e99c04` | X_lv routes + 2f0 fix + **CI trio** ✅ |
| GLLVM.jl `claude/phylo-xlv-modelA-20260627` | `e5e7bc7` (draft #127) | **Model A engine + trio + coverage smokes** ✅ — needs DRAC sweep, R grammar/bridge, sign-off |
| gllvmTMB `claude/poisson-xlv-r-20260626` | `1404783` | held — PR + check + merge |
| gllvmTMB `claude/nbgammabeta-xlv-r-20260627` | `b940a96` | held — PR + check + merge |
| gllvmTMB `claude/xlv-r-ci-reader-20260627` | `29abe90` | held, live-validated 532/0 — PR + check + merge |

Deferred/post-v1.0 (tasks #19–26): native-TMB CI (#19), Ayumi follow-up (#20), t-cal NOT needed (#21),
profile-cutoff calibration (#23), ELR post-1.0 (#24), Model B post-1.0 (#26).
