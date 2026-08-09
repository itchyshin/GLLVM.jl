# ARC CARD — ZIP+X engine Arc 0

**Status:** **SIZED + G0 APPROVED** (2026-08-09) — scaffold only; engine gated
on `#197` + `#198` MERGED.  
**Mode:** size  
**Requested outcome:** first executable ZIP+X engine slice after Identity
ACCEPTED — not quantified cells; ship Julia fitter under locked estimand  
**Mechanism authority:** fresh `.worktrees/` off `origin/main` **after**
`#197`+`#198` merged; edit `src/` / `test/` / docs cascade. **Exclude:**
Dropbox checkout writes; merge/push without ask; twin light RCall Δ;
ZINB/hurdle/Tweedie+X; ADEMP/coverage; Phylo #127; silent rtol widen  
**Recommended arc:** **~3.5–4.5 h** (range **2.5–5.5** with ladder)  
**Time contract:** ceiling ~5.5 h (size-mode; not a fill request)  
**Estimate confidence:** **inferred** (Gamma/Ordinal+X engine lands ~3.5 h
measured; ZIP dual-γ novel; Laplace `offsetz`/`offsetc` + `_build_offset`
already exist — reduces substrate risk)  
**Arc 0 outcome:** exported `fit_zip_gllvm_cov` / `ZIPCovFit` packing
`[βz; γ^z; βc; γ^c; pack(Λc)]` with `Λ_z = 0`; Julia identity (zero-X ≈
`fit_zip_gllvm`; packed FD ≤ 1e-6); bridge/`@formula` admit **both** no-X
`zip` and ZIP+X (`ZIPCovFit`)  
**State transition:** Identity-only / no ZIP+X fitter / `zip` ∉ `_BRIDGE_*`
→ Julia ZIP+X fit path live under Identity + bridge one-part + X admitted
(still **no** twin parity claim)  
**Executable rung and evidence:** implement cov fitter threading
`Oz=_build_offset(X,γz)`, `Oc=_build_offset(X,γc)` into
`zip_marginal_loglik_laplace(...; offsetz=Oz, offsetc=Oc)`; retain
`test/test_zip_x_identity.jl` tallies + bridge smoke; Rose fence forbids
twin Δ

### G0 locks (2026-08-09 — Q1–Q3)

1. **Q1:** Rung 2 ZIP+X confint = **NOT in DoD**; optional under-run only.
2. **Q2:** Bridge admit **both** no-X `zip` (`_BRIDGE_ONEPART` →
   `fit_zip_gllvm`) and ZIP+X (`_BRIDGE_X` → `ZIPCovFit`) in this arc.
3. **Q3:** Persist this Arc Card + ultra-plan under `docs/dev-log/plans/`.

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| **Merge gate** | — | `#197` + `#198` MERGED on `origin/main` | External (other lane) |
| Arc 0 | 3.5–4.5 h | Engine + identity/FD + bridge/@formula (one-part + X) | Start only after merge gate |
| Rung 1 | 45–75 min | Docs/board/after-task polish | If Arc 0 under-runs |
| Rung 2 | 45–60 min | ZIP+X CI adapter or explicit guard | **Optional under-run only** (not DoD) |
| Integrate/close | 20–30 min | Actuals + board pointer | Always |
| **Total capacity** | **~5–5.5 h** | | Stop before ZINB+X / ADEMP / twin light Δ |

### Budget

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 25–35 | Confirm `#197`+`#198` on `main`; twin ZIP still cut; map `twopart.jl` ZIP + `_build_offset` + bridge/formula call-sites |
| Core | 110–150 | `ZIPCovFit` + `fit_zip_gllvm_cov`; export; postfit hooks as needed; bridge + `@formula` after identity green |
| Verify | 45–60 | `test_zip_x_identity.jl` (zero-X≈no-X; FD≤1e-6); focused bridge_x / capabilities smoke |
| Repair reserve | 30–40 | Dual-γ packing / `offsetz` wiring / warm-start issues |
| Closeout | 20–30 | check-log + after-task + Rose fence + Actuals |
| **Total** | **~210–260 (~3.5–4.5 h)** | |

**In scope:** `fit_zip_gllvm_cov` under Identity; Julia identity/FD;
bridge/`@formula` one-part + ZIP+X admit; surgical docs.  
**Not in this arc:** twin light RCall; ZINB+X; ADEMP; free `Λ_z`; shared
single-γ forced equal; merging `#197`/`#198`; Dropbox tree; Rung 2 confint
as DoD.  
**Evidence used:** decision
`docs/dev-log/decisions/2026-08-09-zip-x-identity.md` (ACCEPTED); LOOP
checkpoint S3 done / wait merge; `fit_zip_gllvm` + `offsetz`/`offsetc` in
`twopart.jl`; `_build_offset` in `covariates.jl`; Gamma/Ordinal+X engine
~3.5 h analogues; BB/NB1+X after-tasks (twin Δ path **not** reusable).  
**Risk branch:** If `#197`/`#198` not both MERGED, **do not code** — return
blocked. If `offsetz` kwargs path is incomplete for ZIP, fix substrate first
(≤30 min) before packing. If dual-γ FD >1e-6 by minute ~90 of core, stop
bridge admit and return packing diagnosis. If twin ZIP unexpectedly restored,
**re-open Identity** before any light Δ — do not invent a cell in this arc.

**Done when:** `fit_zip_gllvm_cov` exported and fits; identity+FD tests green
(printed tallies); bridge/`@formula` admit no-X `zip` + ZIP+X without
twin-parity claims; after-task + Rose fence on disk.  
**First action:** After `#197`+`#198` merge-on-green STOP —

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin
git worktree add ".worktrees/gllvmjl-zip-x-engine-YYYYMMDD" \
  -b feat/zip-x-engine-YYYYMMDD origin/main
# then /goal RESUME from lanes/zip-x-engine-20260809/LOOP/
```

### Actuals (complete at close)

**Recommended / actual:** 210–260 / \<TBD\> · **Requested / used:** N/A /
\<TBD\> · **Rungs/cohorts completed:** \<TBD\>  
**Under-run event:** \<TBD\>  
**Calibration:** \<TBD\>  
**Metric movement:** no ZIP+X fitter → ZIP+X Julia path + bridge admit
(still no twin Δ)  
**Result:** \<TBD\> · **Next arc:** ZIP+X confint under X **or** twin-ZIP
Identity re-check + light Δ only if twin restores — fresh `/arc-creation`

---

**HAND TO ULTRA PLAN:** done —
`docs/dev-log/plans/2026-08-09-zip-x-engine-arc0-ultra-plan.md` (Phases 0–2,
G0 approved 2026-08-09). Engine execute via `/goal` only after `#197`+`#198`
MERGED (fresh chat + fresh worktree off `origin/main`).
