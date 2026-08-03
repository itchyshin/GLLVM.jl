# ARC CARD — Gamma+X engine Arc 1 (`fit_gamma_gllvm_grouped_cov`)

**Mode:** size  
**Requested outcome:** not quantified — implement the locked Gamma+X twin
identity as an engine path: **per-trait / grouped shape α + shared site-X**,
with Julia-only identity tests. No light RCall Arc 2 in this arc.  
**Mechanism authority:** surgical `src/` + tests + docs cascade in a **fresh
engine worktree** (see First action). Explicit exclusions: no Gamma+X RCall
parity cells; no no-X Option B flip; no Ordinal+X; no `X_lv`; no ADEMP/coverage;
no Phylo Model A; no Dropbox-protected-checkout writes; no `git add -A`; no push
without ask; no “full family parity”; **do not merge or “fix” #177 inside this
goal** (fence touching conflicted check-log/board hunks when possible).  
**Recommended arc:** **3.5 hours** (range **2.5–4.5 h**)  
**Time contract:** ceiling ~4.5 h (size-mode Arc 0 = the engine land)  
**Estimate confidence:** **inferred** (direct analogue: NB2/Beta #175
`fit_*_gllvm_grouped_cov` — 633 insertions / 10 files for **two** families;
Gamma is one family with `fit_gamma_gllvm_grouped` + offset-capable grouped
Laplace already present → ~50–70% of that surface)  
**Arc 0 outcome:** exported `fit_gamma_gllvm_grouped_cov` + `GammaGroupedCovFit`;
bridge X + `@formula`+X route `gamma` through it (per-trait default under X);
`fit_gllvm_cov(...; family=Gamma())` remains shared-α + X opt-in; identity tests
green (G=1+fisher ≈ shared cov; constant-αvec marginal check); docs + check-log
+ after-task; Rose OK for engine claim only.  
**State transition:** current = identity locked, X path still shared-α via
`fit_gllvm_cov` → intended = twin API B under X for Gamma (per-trait α + shared
γ) with Julia identity evidence. **Not** a light-parity metric transition
(that is Arc 2).  
**Executable rung and evidence:** implement fitter mirroring
`fit_nb_gllvm_grouped_cov` / `fit_beta_gllvm_grouped_cov`; route bridge/formula;
run `test/test_gamma_x_identity.jl` (or extend `test_nb_beta_x_identity.jl`);
retain printed pass tallies; no rtol widen.

### Capacity ladder (size mode; Arc 0 = engine)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 3.5 h | `fit_gamma_gllvm_grouped_cov` + identity + bridge/formula + docs | Start after G0 via `/goal` |
| Rung 1 (later) | — | Gamma+X light RCall Arc 2 (rtol 1e-6) | Only after Arc 1 on `main` |
| Rung 2 (named) | — | No-X Option B consistency | Separate decision; not bundled |
| Integrate/close | 25 min | check-log + after-task + Rose fence | Always |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 25 | Rehydrate #175 pattern; confirm `gamma_grouped_marginal_*` offset; twin cite refresh |
| Core | 100 | `GammaGroupedCovFit` + `fit_gamma_gllvm_grouped_cov`; exports; CI adapters |
| Bridge/formula | 40 | Route `gamma` under X; keep shared `fit_gllvm_cov` opt-in |
| Verify | 40 | Identity tests + bridge/formula smoke; record tallies |
| Repair reserve | 40 | Hessian/G=1 identity band, bridge assemble, FD/opt issues |
| Closeout | 25 | Docs cascade + check-log (surgical) + after-task + Actuals |
| **Total** | **~210 (~3.5 h)** | |

**In scope:** one-family #175 mirror for Gamma under X; identity tests; bridge +
`@formula` routing; Wald/profile/bootstrap adapters as needed for bridge CI;
docs fence (capability / response-families / parity pages).  
**Not in this arc:** light RCall Gamma+X cells; no-X Option B flip; Ordinal+X;
`X_lv`; ADEMP; Phylo Model A; merging #177; Dropbox writes; push without ask.  
**Evidence used:**
- Decision (LOCKED): `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
  @ lane tip `b657b27e` / `8af4f00f`
- Mirror engine: #175 `2846d9da` — `fit_nb_gllvm_grouped_cov` /
  `fit_beta_gllvm_grouped_cov` in `src/families/grouped_dispersion.jl:318+`,
  `:661+`; after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md`
- Identity tests pattern: `test/test_nb_beta_x_identity.jl`
- No-X Gamma grouped already: `fit_gamma_gllvm_grouped` (`grouped_dispersion.jl:871+`)
- Bridge X still falls through Gamma → shared `fit_gllvm_cov`
  (`src/bridge.jl:1132–1135`); formula same (`src/formula.jl:113–120`)
- Twin: `gllvmTMB` `PARAMETER_VECTOR(log_phi_gamma)` / fid-4 per-trait shape
  (re-cite at execute; local tip line nos may drift vs decision’s `840d1da8`)
- #177 OPEN/CONFLICTING — out of scope; fence shared docs files

**Risk branch:** If G=1+`hessian=:fisher` identity vs `fit_gllvm_cov` fails outside
the #172/#175 band, **stop expanding scope** — diagnose Fisher/observed Hessian
and offset packing first; do not invent a new estimand or widen tolerances.

**Done when:** fitter exported; bridge+formula route Gamma+X to per-trait
grouped_cov; identity tests pass without rtol widen; docs state twin default
under X; Rose OK for engine claim; Arc 2 / Option B / #177 explicitly deferred.  
**First action (after G0):** cut a **fresh** engine worktree (do not write
engine into the docs-only identity branch long-term):

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin
# Prefer: after identity docs PR on main. If identity still local-only,
# cut from origin/main and either wait or include the ACCEPTED decision note.
git worktree add ".worktrees/gllvmjl-gamma-x-grouped-cov-20260803" \
  -b fix/gamma-x-grouped-cov-20260803 origin/main
```

### Actuals (complete at close)

**Recommended / actual:** 210 / ~session · **Requested / used:** N/A / N/A ·
**Rungs/cohorts completed:** Arc 1 engine (identity 7/7; bridge_x 204/204)  
**Under-run event:** none (did not start RCall Arc 2)  
**Calibration:** one-family #175 mirror landed  
**Metric movement:** Gamma+X public path = per-trait α (Julia identity)  
**Result:** LOCAL DONE · **Next arc:** Gamma+X light RCall Arc 2 (after merge)

---

HAND TO ULTRA PLAN: size-mode **Gamma+X engine Arc 1**, **~3.5 h (2.5–4.5)**,
outcome = `fit_gamma_gllvm_grouped_cov` + identity + bridge/formula (no RCall);
PLATFORM = Cursor → `/goal` after G0; fence #177 / Option B / Ordinal+X.
