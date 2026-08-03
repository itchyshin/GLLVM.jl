# ARC CARD — Gamma+X dispersion identity (Arc 0)

**Mode:** size  
**Requested outcome:** not quantified — lock the Gamma + shared site-X
dispersion identity (twin with gllvmTMB) as a durable decision note before any
engine or light-parity work.  
**Mechanism authority:** docs-only decision note + board/plan pointers in a
**fresh worktree off `origin/main`** (after #177 lands or with explicit
parallel-docs allowance). Explicit exclusions: no `src/` engine edits; no
Gamma+X light RCall cells; no Ordinal+X; no `X_lv`; no ADEMP/coverage; no Phylo
Model A; no Dropbox-protected-checkout writes; no `git add -A`; no push without
ask; no “full family parity” claim.  
**Recommended arc:** **90 minutes** (range **60–120 min**)  
**Time contract:** ceiling ~2 h (outcome-first within the size band)  
**Estimate confidence:** **measured** (direct analogue: NB2/Beta+X identity Arc 0
→ #174; mirror file already on `main`)  
**Arc 0 outcome:** ACCEPTED (or explicitly REJECTED-with-fence) decision note at
`docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md` (or dated
equivalent), citing twin evidence, Rose fence, and the engine/parity follow-on
order.  
**State transition:** preparation / design lock — **no metric change** (no new
parity cells, no capability-matrix promotion). Unlocks later Arc 1/2 only after
acceptance.  
**Executable rung and evidence:** write + self-review the decision doc against
the NB2/Beta mirror + live twin `log_phi_gamma` / bridge Option B notes; PR
docs-only when approved. Engine remains **blocked** until this doc is accepted.

### Capacity ladder (optional — size mode; short Arc 0)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 90 min | Gamma+X identity decision note ready for review | Start after G0 approval via `/goal` |
| Rung 1 (later programme) | — | Engine `fit_gamma_gllvm_grouped_cov` (or equivalent) | Only if Arc 0 accepts per-trait+X |
| Rung 2 (later programme) | — | Light Gamma+X RCall cell | Only after Arc 1 identity greens |
| Integrate/close | 10 min | check-log + after-task + board pointer | Always for Arc 0 |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Rehydrate `origin/main`, #177/#176 state, twin Gamma comments, bridge Option B |
| Core | 45 | Draft decision doc (problem · twin rule · decision · rejected · Rose fence · follow-ups) |
| Verify | 15 | Diff against NB2/Beta mirror; cite twin file:line; no claim inflation |
| Repair reserve | 10 | Reconcile shared-bridge-vs-per-trait-TMB tension if wording drifts |
| Closeout | 5 | Board pointer + after-task stub path + Actuals |
| **Total** | **90** | |

**In scope:** one Gamma+X (and related no-X Gamma default consistency) identity
decision note; explicit fence text; pointers on coordination board / START HERE.  
**Not in this arc:** any `src/` change; Gamma+X parity tests; Ordinal+X;
renaming `fit_gllvm_cov`; flipping NB2/Beta; Phylo Model A; merging #177 (separate
OWED, may be a landing gate).  
**Evidence used:**
- Mirror: `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md` (#174)
- Handover: `docs/dev-log/handover/2026-08-03-cursor-handover-nb2-beta-x-arc2-close.md`
- Twin: `gllvmTMB` `PARAMETER_VECTOR(log_phi_gamma)` + “Ordinary Gamma … per-trait”
  (`src/gllvmTMB.cpp`, `R/fit-multi.R`)
- Julia bridge Option B (shared Gamma group): `src/bridge.jl` comments +
  `docs/dev-log/check-log.md` (~2026-06-16) + after-task
  `2026-06-16-gamma-shared-bridge-parity`
- Live plan-write state (2026-08-03 ~13:20 UTC): `origin/main` @ `0e241215`
  (#176 MERGED); #177 OPEN, `mergeable=CONFLICTING` (base still `9f5133a7`,
  behind #176 docs touch), Julia CI still pending; Dropbox checkout PROTECTED

**Risk branch:** If twin evidence shows ordinary Gamma under X is **not**
per-trait on current `gllvmTMB` `origin/main` (map forces scalar, or formula
differs), stop drafting “API B under X” and rewrite the decision as
**shared-default retain** + explicit native-expansion follow-up — do not cargo-cult
NB2/Beta.

**Done when:** decision note exists, cites twin + bridge history, states chosen
default under X, lists rejected alternatives, Rose fence forbids full-family /
Ordinal+X / engine-before-acceptance claims, and Shinichi (or explicit “use your
judgment”) accepts it.  
**First action (after G0):** cut fresh worktree from post-merge `origin/main`
(or rebase onto main if #177 still open and parallel docs are approved):

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin
git worktree add ".worktrees/gllvmjl-gamma-x-identity-20260803" \
  -b docs/gamma-x-identity-20260803 origin/main
```

### Actuals (complete at close)

**Recommended / actual:** 90 / ~75 · **Requested / used:** N/A / ~75 ·
**Rungs/cohorts completed:** Arc 0  
**Under-run event:** none material — Phase 0.25 map reused at execute  
**Calibration:** orient shorter than budgeted (plan already held twin cites)  
**Metric movement:** none — preparation only  
**Result:** capacity used · **Next arc:** engine Arc 1
(`fit_gamma_gllvm_grouped_cov`) after docs PR on `main`; parallel OWED = land
#177

---

HAND TO ULTRA PLAN: size-mode Arc 0, **~90 min (60–120)**, outcome = Gamma+X
dispersion identity decision doc only; no engine; mirror NB2/Beta #174; fence
Ordinal+X / ADEMP / full parity; PLATFORM = Cursor; after G0 run via `/goal`.
