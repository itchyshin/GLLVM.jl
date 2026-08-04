# ARC CARD — Species-specific XB light RCall (Arc 0)

**Status:** **READY FOR G0** — shared site-X light cohort closed (#170–#181);
`fit_gllvm_speciescov` already on `main`; no live `(0 + trait):x` oracle yet.

**Mode:** size  
**Requested outcome:** one light gllvmTMB logLik cell green at rtol `1e-6` for
**species-specific** site-X slopes — R formula `(0 + trait):x` vs Julia
`fit_gllvm_speciescov` (Poisson first). Not a rebuild of the B engine.  
**Mechanism authority:** `test/parity/` helper + one `@testset` + narrow docs
fence. Exclusions: no engine redesign unless cell proves a packing bug; no
ADEMP; no X_lv; no “full family parity”; no Dropbox protected writes; no
`git add -A`; no push without ask; no silent rtol widen.  
**Recommended arc:** **90–150 min** (range **1–2.5 h**) from `origin/main`
@ `a92c5040`  
**Time contract:** ceiling ~2.5 h  
**Estimate confidence:** **inferred** (shared-X Arc 2 analogues ~45–150 min;
engine already exists — risk is R formula / packing / DGP, not B fitter).  
**Arc 0 outcome:** Poisson species-XB light logLik Pass @ rtol 1e-6 (or honest
scaffold + OWED if R absent) + parity README / board fence updated.  
**State transition:** shared-γ light cohort done → species-specific XB light
cohort **started** (one cell).  
**Executable rung and evidence:** new helper (or switch) for
`(0 + trait):x`; `@testset` calling `fit_gllvm_speciescov`; live
`GLLVM_PARITY_TESTS=1`; paste Δ.

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Under-run 0 | 15–25 min | Board/AGENTS/parity-README: #181 MERGED; drop stale “Ordinal+X not claimed” / ROADMAP “B next” drift | Always first if still stale |
| Arc 0 | 90–120 min | One Poisson species-XB light cell @ 1e-6 | After G0 → `/goal` |
| Integrate/close | 15–20 min | after-task + check-log + Rose ≠ full parity | Always |
| Rung 1 (later) | — | Binomial/Gaussian species-XB cell | Only if Arc 0 greens and Shinichi asks |
| Rung 2 (later) | — | NB2/Beta/Gamma species-XB (dispersion identity?) | Separate identity if needed |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient / LOOP | 15–20 | Worktree from `main`; twin formula cite; confirm `fit_gllvm_speciescov` export |
| Helper + cell | 40–55 | `(0 + trait):x` RCall path; one Poisson `@testset` |
| Live RCall verify | 20–30 | Δ logLik; rtol 1e-6 |
| Repair reserve | 20–30 | DGP/seed/formula — never rtol widen |
| Closeout | 15–20 | Docs + after-task + commit (no push until ask) |
| **Total** | **~110–155** | |

**In scope:** one Poisson species-XB light oracle; helper widen; stale-claim
docs fix.  
**Not in this arc:** rebuild `species_covariates.jl`; Ordinal speciescov;
X_lv light RCall; ADEMP; registration; Phylo Model A; multi-family XB cohort.  
**Evidence used:** `fit_gllvm_speciescov` + tests already on `main`; shared-X
helper explicitly fences `(0 + trait):x`; parity README still lists
“species-specific XB” / stale “Ordinal+X” as unclaimed; ROADMAP §1 “B next”
is **stale** (engine landed).  
**Risk branch:** If R Δ ≫ 1e-6 from formula mismatch (shared `+ x` vs
`(0+trait):x`) or family packing, stop and diagnose — do not widen rtol. If
dispersion families are attempted early, stop and write identity first.

**Done when:** live Poisson cell Pass @ 1e-6 (or honest OWED) + after-task +
Rose fence.  
**First action after G0:** `/goal` on fresh worktree from `origin/main`;
optional under-run board hygiene in the same lane.

### Actuals (complete at close)
**Recommended / actual:** 90–150 / _TBD_ · **Rungs completed:** _TBD_  
**Result:** _TBD_ · **Next arc:** expand species-XB cohort or X_lv light
(separate G0)

**HAND TO ULTRA PLAN:** size-mode Species-specific XB light RCall Arc 0,
~90–150 min, outcome = one Poisson `(0+trait):x` logLik cell @ rtol 1e-6 via
`fit_gllvm_speciescov`; no engine rebuild; PLATFORM Cursor; execute via
`/goal` after G0. Under-run first: close #181 board/README drift if still
open.
