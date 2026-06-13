# Session handover — GLLVM.jl + gllvmTMB twin (2026-06-12)

**Purpose.** This session's context was compacted twice and the live workflow handles
degraded. All *durable* state is on disk (git + plan + memory + dashboard). A fresh
session reads this file + the three anchors below and continues cleanly. Nothing is lost
by restarting.

> **Session log — what landed in the 2026-06-12 drain pass (kept current live):**
> - **GLLVM.jl wave-2 → `integration` `12e7551`**: Exponential NA-FIML (26/26) ·
>   Exponential VA/ELBO (18/18) · ordination-score uncertainty (36/36). Merged, export
>   conflict resolved, module load-checked, **80/80 together** in the merged tree.
> - **gllvmTMB unique-removal → `remove-unique-family` `2997e96`**: code (`f3d6962`,
>   PSI_FOLD_OK) + page sweep (`8a82b48`, spec-verified: 36 A-drops, +42 `indep`, 74 prose
>   rewords; prefixed/augmented/extractor LEFT per §B.1/§C). Code+pages now one branch.
> - **Open (autonomous):** Julia-side `latent`=Ψ-default follow-on (twin-consistency analog
>   of the R change — see §4.4); Florence 3D refinement; #43/#44/#45 pre-tag fixes.
> - **Open (maintainer, local):** `pkgdown::build_site()` on the 2 conceptual recasts; full
>   `Pkg.test()` terminal-side; the push/registry/CRAN decisions.
> - **Decision (2026-06-12):** Gaussian residual default = **per-trait Ψ** (trait-specific) —
>   matches gllvmTMB/gllvm + the FA standard; single shared σ² is the *special case*
>   (isotropic/PPCA: standardized same-scale traits, pure ordination, large-p speed). The
>   ~340× headline rides on the single-σ² closed-form σ²_eps profile-out ⇒ re-scope that claim
>   to the single-σ² path + re-confirm phylo parity is apples-to-apples. `fit_gaussian_pervar_gllvm`
>   already exists ⇒ flip is routing+claim-scoping, not new math. Awaiting explicit go on the
>   flagship-default flip.

---

## 0. The standing goal (unchanged)

Finish **both** packages as a fully-capable twin pair, bridged one-way (R
`gllvmTMB(engine="julia")` runs the GLLVM.jl engine). **Consistency across the two is the
priority.** CPU only for the finish line; GPU is post-registry v2. No push without an
explicit maintainer instruction; stage by name (never `git add -A`); one concern per commit.

## 1. Read these first (the durable brain)

1. **Plan** — `~/.claude/plans/declarative-snuggling-eclipse.md` — the full twin plan
   (sub-projects SP1–SP7, roadmap phases A–E, the update log through Update 11 + SP1.5).
2. **Memory** — `~/.claude/memory/memory_summary.md` (curated) + `MEMORY.md` (comprehensive
   task-group doctrine). Repo-specific rules for gllvmTMB live there.
3. **Migration spec (unique-removal)** — in the gllvmTMB repo:
   `docs/dev-log/2026-06-12-unique-migration-spec.md` (§C page buckets, §D per-page line
   lists, §G mis-bucketing flags) + `-unique-removal-codereview.md` +
   `-latent-psi-fold-design.md`.

Also: both repos' `CLAUDE.md`; the GLLVM.jl Florence plan
`docs/dev-log/2026-06-12-visuals-plan-florence.md`.

## 2. Bring up the widget (dashboard)

The live build dashboard is a static site served via the preview manager:

- `preview_start` with config name **`status-dashboard`** (from
  `GLLVM.jl/.claude/launch.json`) → serves `.claude/preview/` on **port 8770**.
- `.claude/preview/index.html` = the build dashboard (roadmap phases, team toggles,
  activity feed; auto-refresh 15s — the numbers are curated, not live-wired).
- `.claude/preview/florence.html` = the plot gallery (`florence/*.png` + the interactive
  Plotly 3D at `florence/ordiplot3d_interactive.html`).
- **GLLVM uses 8770; DRM uses 8765/8744 — keep them distinct.** Let the preview manager
  own the port (do NOT start a second `python -m http.server` on 8770 by hand — that was
  the "port in use" clash this session).

## 3. Worktree map (durable — the real state)

### GLLVM.jl (Julia, MIT)
| Branch / worktree | HEAD | State |
|---|---|---|
| `integration` (`GLLVM.jl-integration`) | `12e7551` | **The green tree.** bridge+VCV+REML+boundary+slopes+Xβ+two-level+NG-slopes + **wave-2 (Exp NA-FIML, Exp VA/ELBO, ordination-uncertainty) merged 2026-06-12**. Module loads clean; new tests 26/26+18/18+36/36. 0 uncommitted. |
| `bridge-juliacall` (`GLLVM.jl-bridge`) | `8670d22` | Canonical JuliaCall `bridge_fit` on main v0.3.0 + REML/boundary/VCV salvage. 0 uncommitted. |
| `viz-plots2` (`GLLVM.jl-viz2`) | `aa19b77` | Florence Plots.jl extension (Fig-3 panels + ordination d=1/2/3). **1 uncommitted** (refinement). |
| `va-complete` (`GLLVM.jl-va`) | `07061d4` | **DRAINED → integration.** Exponential VA/ELBO. |
| `missing-complete` (`GLLVM.jl-missing`) | `e1bb812` | **DRAINED → integration.** Exponential NA-FIML. |
| `ord-uncertainty` (`GLLVM.jl-ord`) | `33f7eda` | **DRAINED → integration.** Per-site score uncertainty (`_verify_ord.jl` scratch removed). |

`a1-nongaussian-ci` (`GLLVM.jl-a1-ci`, `09fc846`) is the older pre-integration feature
trunk (120+ commits; folded into integration's lineage). The `fam-*`, `a2/a4/a5/a6`,
`slopes*`, `twolevel`, `mixed` worktrees are already-merged feature lanes — leave them.

### gllvmTMB (R, GPL-3)
| Branch / worktree | HEAD | State |
|---|---|---|
| `engine-julia` (main checkout `gllvmTMB`) | `7a7e209` | R-side bridge: `R/julia-bridge.R` (`gllvm_julia_setup`/`_fit`/`.gllvmTMB_julia_dispatch`) + `engine=c("tmb","julia")` arg in `gllvmTMB()`. JuliaCall transport (ecosystem standard). |
| `remove-unique-family` (`gllvmTMB-unique-removal`) | `2997e96` | **unique-removal CODE + PAGES — done + spec-verified (2026-06-12).** Code (`f3d6962`): latent auto-emits companion Ψ BY DEFAULT, `residual=FALSE` opt-out (**PSI_FOLD_OK**: −187.3845 vs −190.262). Pages (`8a82b48`, merged `2997e96`): 36 bucket-A `+unique` drops, +42 standalone→`indep`, 74 prose rewords; prefixed `*_unique`/augmented/extractor correctly LEFT per §B.1/§C. **REMAINING (maintainer, local):** `pkgdown::build_site()` render of the 2 conceptual recasts (covariance-correlation, api-keyword-grid) — not verifiable in-agent. |
| `page-sweep` (`gllvmTMB-pages`) | `8a82b48` | **DRAINED → remove-unique-family.** 17 files (16 vignettes + README). 0 uncommitted. |
| `delta-lift` (`gllvmTMB-families`) | `de29450` | delta-lognormal/delta-gamma — confirmed already fitting (`test-delta-families.R`). |
| `cran-prep` (`gllvmTMB-cran`) | `99ed573` | CRAN mechanics WIP. |
| `deprecate-unique` (`gllvmTMB-taxonomy`) | `74c91e8` | Superseded by `remove-unique-family` — soft-deprecation path; do not merge (full removal wins). |

The dozens of `/private/tmp/gll-*` worktrees are **prunable** older agent lanes — ignore.

## 4. In-flight work to drain (the immediate next actions)

1. ~~**Page-sweep**~~ — **DONE 2026-06-12.** Spec-verified (36 A-drops, +42 `indep`, 74 prose
   rewords; prefixed/augmented/extractor LEFT per §B.1/§C), committed `8a82b48`, merged into
   `remove-unique-family` (`2997e96`) — code+pages now one branch. **Maintainer step left:**
   `pkgdown::build_site()` to confirm the 2 conceptual recasts render before any push.
2. ~~**Wave-2** (GLLVM.jl `va`/`missing`/`ord`)~~ — **DONE 2026-06-12.** All three
   focused-tested, committed, merged into `integration` (now `12e7551`); merge conflict in
   `src/GLLVM.jl` export block resolved additively; merged module load-checked.
3. **Florence refinement** (`viz-plots2`, 1 uncommitted): bake the small-marker (≈1.8) +
   red loading-arrow biplot into the ext `gllvm_ordiplot3d`; 2D biplot label-repel +
   equal-aspect + symmetric loadings limit. The interactive 3D HTML was regenerated v2
   (small markers + loading vectors); caveat — Plotly 3D may drop series_annotations text
   (hover-text fallback offered).
4. **Julia/bridge consistency follow-on** (the unique-removal's Julia side) — **DECISION
   RECORDED 2026-06-12 (awaiting explicit go on the flagship flip).** Make Gaussian `latent`
   default to ΛΛᵀ + **per-trait Ψ** (via `fit_gaussian_pervar_gllvm`, which already exists +
   is tested) with a `residual=FALSE` opt-out, and align the bridge vocabulary to
   `latent`/`indep`/`dep`. **Why per-trait is the default:** gllvmTMB, gllvm, and factor
   analysis all carry per-variable uniquenesses; in JSDM/ecology species almost never share
   residual dispersion (abundant vs rare; different scales), and honest cross-trait
   correlation needs each trait's own residual. **When single shared σ² is the right model
   (the special case, not the default):** isotropic/PPCA-style ordination, pre-standardized
   same-scale traits, data-poor pooling, or a deliberate large-p speed simplification. **The
   one real consequence:** GLLVM.jl's ~340× headline comes from the single-σ² closed-form
   σ²_eps profile-out (`profile.jl`); `gaussian_pervar` likely lacks that exact single-scalar
   profile, so (a) re-scope the speed claim to the single-σ² path and (b) re-confirm the
   Gaussian+phylo parity is apples-to-apples before trusting the machine-precision wording.
   Since the per-trait fitter exists, the flip is **routing/default/vocab + claim-scoping, not
   new math.** Unblocked (R code settled @ f3d6962). **Quick next step to quantify the cost:**
   a pure-Julia head-to-head (`fit_gaussian_gllvm` vs `fit_gaussian_pervar_gllvm` on one
   simulated dataset — both exist on `integration`) gives the per-var slowdown factor that
   scopes the speed wording. Per `gaussian_pervar.jl`'s own header the per-var fit optimises
   `p` log-variances numerically with **no** closed-form profile, so it *is* slower — the only
   open number is by how much (2× vs ≫). **Maintainer's lean (2026-06-12): per-trait is what's
   wanted; single-σ² is the special case.**

   **Measured 2026-06-12 (one heteroscedastic dataset, n = 200, K = 2, median of 5 reps,
   integration worktree).** Single-σ² `fit_gaussian_gllvm`: 0.24 / 0.35 / 1.37 ms at
   p = 8 / 16 / 32. The current per-var `fit_gaussian_pervar_gllvm` (L-BFGS + ForwardDiff):
   48.5 / 153.5 / 901.8 ms — **201× / 437× / 656×** slower, growing with p (forward-mode AD
   cost scales with the pK+p parameter count). **But that is an implementation artifact, not the
   model's floor.** The repo's existing closed-form EM-FA (`em_fa.jl`, Rubin & Thayer 1982 — the
   *identical* ΛΛᵀ+diag(ψ) model) reaches the same ML log-lik (Δ ≤ 2e-7) at 2.0 / 13.5 / 13.8 ms
   — **11×–65× faster than the L-BFGS fitter**, leaving per-var only ~8–40× the single-σ² time
   (one order of magnitude, not three). **So: (a)** scope the ~340× headline to the single-σ²
   closed-form path (#44 — done in user docs 2026-06-12); **(b)** the per-trait-Ψ default is NOT
   prohibitively slow — the open speed slice is wiring `em_fa` (+ optional SQUAREM tail / a few
   L-BFGS polish steps) as the per-var fitter; **(c)** the Julia-per-var-vs-R apples-to-apples
   number remains unmeasured (needs the local bench repo).

**Note on the full re-test:** canonical `Pkg.test()` is ~25 min (COM-Poisson truncated
sums) and exceeds the 10-min agent Bash cap — it cannot complete in one agent call. Run the
full Aqua/JET suite **terminal-side**:
`julia --project=. -e 'using Pkg; Pkg.test()'`. The focused-suite 3303/3304 is the
in-agent integration evidence.

## 5. Pending task ledger (priorities)

- **#47 / #29** unique-removal cross-package — code DONE+verified; pages in-flight (drain #1);
  Julia/bridge consistency follow-on (#4 above).
- **#43 BLOCKING (pre-tag, Rose)** — wire the external parity/feature gates *in-suite*;
  clarify README family claims (engine families vs the 8 bridge-exposed); remove stale
  `r/README_bridge.md` (obsolete JuliaConnectoR scaffold — current transport is JuliaCall).
- **#44 BLOCKING** — parity-evidence: back the ~340× speedup claim with the bench artifacts
  (see untracked `bench/results/`) or soften the wording.
- **#45 BLOCKING** — `fit_gllvm` delta dispatcher bug + orphan tests + changelog drift
  (from the gllvmTMB-thread code review in `docs/dev-log/2026-06-12-gllvmTMB-thread-*`).
- **#37** gllvmTMB `engine="julia"` retarget to main's `bridge_fit` + CRAN-readiness.
- **#32/#33/#34** bridge expansion: NA cells · structured/phylo terms · CRAN mechanics
  (JuliaCall Suggests + tests).
- **#40** REML speed: analytic Takahashi selected-inverse REML gradient + AI-REML Fisher
  scoring (beat ASReml; DRM co-dev). Current REML uses an FD gradient — the speed gap.
- **#46** GLLVM.jl registry polish (Aqua/JET/[compat]); **#42** mixture/gengamma → v2 (large C++).
- **#26** exact-REML SEs in confint; **#15** Ordinal NA-FIML; **#16** trim COM-Poisson test
  runtime behind a `GLLVM_SLOW_TESTS` flag (so routine gates fit the cap).

## 6. Discipline (carry forward)

Stage by name (never `git add -A`/`.` — disjoint agents in parallel). One concern per
commit. No push without explicit maintainer instruction (both repos). gllvmTMB is editable
this session per the maintainer's "work on both" override (its CLAUDE.md "read-only" note is
superseded). Subagents get **dedicated worktrees** — never the main checkout (a lane
collision this session switched the main gllvmTMB checkout's branch; lesson logged).
Verify before claiming; paste the real pass/fail tally.

## 7. Path to "shipped" (the finish-line definition — the standing goal)

**"Finished twin pair" = all three true:** (a) GLLVM.jl tagged + registered in the Julia
General registry; (b) gllvmTMB accepted on CRAN; (c) `gllvmTMB(engine="julia")` round-trips
for the shipped capability set with parity fixtures green. We are **handoff-ready, not
shipped** — mid-phase *by design* (context compacted twice ⇒ a fresh session that reads this
file finishes faster than continuing here). Nothing is lost by closing.

**Autonomous (a fresh session can do without the maintainer):**
- **#43** — wire the external parity/feature gates *in-suite*; README family clarity (engine
  families vs the 8 bridge-exposed); remove stale `r/README_bridge.md`.
- **#44** — back the ~340× claim with `bench/results/` artifacts **or** soften it (now doubly
  relevant: scope it to the single-σ² path per the §4.4 decision).
- **#45** — `fit_gllvm` delta dispatcher bug + orphan tests + changelog drift.
- **Per-trait Ψ default flip** (§4.4) — *once the maintainer says go*; `fit_gaussian_pervar_gllvm`
  exists ⇒ routing + claim-scoping, not new math.
- **Bridge expansion** #32/#33/#34 (NA cells · structured/phylo · CRAN mechanics); **#46**
  registry polish; **#40** REML speed.

**Maintainer-only (local; cannot be automated from an agent):**
- `pkgdown::build_site()` render of the 2 conceptual recasts (covariance-correlation,
  api-keyword-grid) before any push.
- Full `Pkg.test()` terminal-side (the ~25-min Aqua/JET + COM-Poisson run exceeds the agent cap).
- Merge the green feature branches → `main`; **the push** (no-push rule holds for both repos).
- The Julia General **registry PR** (register GLLVM.jl); the gllvmTMB **CRAN submission**
  (`rcmdcheck --as-cran` + `cran-extrachecks` clean, then submit).

**Open maintainer decisions that gate the finish line:** (1) the per-trait Ψ default flip +
the 340×-claim rescoping (§4.4); (2) release sequencing (registry + CRAN in parallel — plan D5).
