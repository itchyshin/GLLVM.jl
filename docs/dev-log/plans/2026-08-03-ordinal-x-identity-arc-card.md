# ARC CARD — Ordinal+X cutpoint / identity (Arc 0)

**Mode:** size  
**Requested outcome:** not quantified — lock the Ordinal (+ shared site-X)
cutpoint / identity decision as a durable docs-only note before any Ordinal+X
engine or light-parity work.  
**Mechanism authority:** docs-only decision note + board/plan pointers in a
**fresh worktree off post-landing `origin/main`** (preferred) or parallel-docs
lane if landings stay gated. Explicit exclusions: no `src/` engine; no Ordinal+X
light RCall; no ADEMP/coverage; no Phylo Model A; no dual-PR of
`fix/gamma-x-grouped-cov-20260803`; no Dropbox-protected-checkout writes; no
`git add -A`; no push without ask; no silent no-X Option B flip; no “full family
parity” claim.  
**Recommended arc:** **90 minutes** (range **60–120 min**)  
**Time contract:** ceiling ~2 h (outcome-first within the size band)  
**Estimate confidence:** **measured** (direct analogues: NB2/Beta+X identity
#174 ~same shape; Gamma+X identity Arc 0 actuals ~75 min)  
**Arc 0 outcome:** ACCEPTED (or explicitly REJECTED-with-fence) decision note at
`docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` (or dated
equivalent), citing twin `ordinal_probit` cutpoint convention + Julia shared vs
per-trait ordinal routes + Rose fence + engine follow-on order.  
**State transition:** preparation / design lock — **no metric change** (no new
parity cells, no capability-matrix promotion). Unlocks later Ordinal+X Arc 1/2
only after acceptance.  
**Executable rung and evidence:** write + self-review the decision doc against
Gamma/NB2 mirrors + live twin `tau_1 = 0` / per-trait free cutpoints; docs-only
PR when approved. Engine remains **blocked** until this doc is accepted.

### Alternatives reconciled (plan-write 2026-08-03 ~10:17 MDT)

| Candidate | Verdict | Why |
| --- | --- | --- |
| **(a) Merge #177 now** | **Not Arc 0** | `gh pr checks 177`: Documenter **pass**; Julia 1.10 + Julia 1 matrix (**4 jobs**) still **pending/IN_PROGRESS**. MERGEABLE ≠ green. Treat as **dependency / watch**, not force-merge. |
| **(b) Gamma land push/PR** | **OWED · gated** | Preferred tip `parity/gamma-x-arc2-20260803` @ `064b7bf0`, **8 ahead / 0 behind** `origin/main`, **not pushed**. Smallest arc that lands owed work (~30–45 min) **if** Shinichi grants push in Phase 0.4. Duplicate `fix/…` tip stays CARRIED-OVER. |
| **(c) Ordinal+X identity Arc 0** | **Ada-default capability** | Handover START HERE next capability after landings; docs-only; no push required to draft; mirrors Gamma identity. |

**Landing gate (honest):** Gamma push + #177 merge are still **OWED**. This Arc
Card plans the **next capability** (c). If Shinichi answers Phase 0.4 Q1 with
“push/PR Gamma first,” **swap**: Landing becomes Arc 0 (~30–45 min) and Ordinal
identity becomes the next fresh-chat arc — do not invent engine work either way.

### Capacity ladder (optional — size mode)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Contigent Landing (only if Q1 = yes) | 30–45 min | `parity/gamma-x-arc2-20260803` pushed + PR open; #177 merged iff Julia CI green | Explicit maintainer ask |
| Arc 0 | 90 min | Ordinal+X identity decision note ready for review | Start after G0 via `/goal` (fresh chat preferred) |
| Rung 1 (later programme) | — | Ordinal+X engine (covariate / cutpoint path) | Only if Arc 0 ACCEPTED |
| Rung 2 (later programme) | — | Light Ordinal+X RCall cell | Only after Arc 1 greens |
| Integrate/close | 10 min | check-log + after-task + board pointer | Always for Arc 0 |

### Budget (Arc 0 — Ordinal identity)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Post-landing `origin/main` (or parallel-docs base); twin `ordinal_probit` cites; Julia shared vs per-trait ordinal + “no covariate kernel yet” |
| Core | 45 | Draft decision (problem · twin rule · Julia map · decision · rejected · Rose fence · follow-ups) |
| Verify | 15 | Diff vs Gamma + NB2/Beta mirrors; twin file:line; no claim inflation |
| Repair reserve | 10 | Reconcile τ₁=0 / K−2 free vs Julia unconstrained-increment packing if wording drifts |
| Closeout | 5 | Board pointer + after-task path + Actuals |
| **Total** | **90** | |

**In scope:** one Ordinal+X (and related no-X ordinal default consistency)
identity decision note; explicit fence; board / START HERE pointers.  
**Not in this arc:** any `src/` change; Ordinal+X parity tests; Gamma engine
edits; dual-PR Gamma fix tip; Phylo Model A; ADEMP; force-merge #177 while red;
push without ask.  
**Evidence used:**
- Analogues: `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
  (ACCEPTED); `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`
- Handover: `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md`
- Twin `gllvmTMB` @ `ab49638b`: `ordinal_probit` fid 14; `tau_1 = 0` fixed;
  K−2 free log-spacings per trait (`src/gllvmTMB.cpp`, `man/ordinal_probit.Rd`)
- Julia: `fit_gllvm` → `fit_ordinal_gllvm_pertrait` (no-X); bridge documents
  ordinal/nb1 **no covariate kernel yet** (`src/bridge.jl`)
- Live: `parity/gamma-x-arc2-20260803` @ `064b7bf0` unpushed; #177 OPEN /
  MERGEABLE / Julia CI IN_PROGRESS; Dropbox checkout PROTECTED

**Risk branch:** If twin evidence shows ordinal under site-X uses a **different**
cutpoint identity than no-X `ordinal_probit` (or Julia already has a hidden X
path), stop cargo-culting Gamma “API B under X” and rewrite as
**retain-blocked / map-first** — do not invent an engine claim.

**Done when:** decision note exists, cites twin + Julia route map, states chosen
default under X (and no-X consistency), lists rejected alternatives, Rose fence
forbids full-family / engine-before-acceptance / ADEMP / Phylo Model A / dual-PR
Gamma, and Shinichi (or explicit “use your judgment”) accepts it.  
**First action (after G0 — Ordinal path):** cut fresh worktree from post-landing
`origin/main` (or from `origin/main` with parallel-docs allowance if landings
still gated):

```sh
cd "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
git fetch origin
git worktree add ".worktrees/gllvmjl-ordinal-x-identity-20260803" \
  -b docs/ordinal-x-identity-20260803 origin/main
```

### Actuals (complete at close)

**Recommended / actual:** 90 / ~under-run (docs; packing already τ₁=0/K−2) · **Requested / used:** N/A / session ·
**Rungs/cohorts completed:** Arc 0 (S0–S7 identity lock)  
**Under-run event:** Contigent Landing skipped (G0 Q1=WAIT); no engine  
**Calibration:** orient shorter — Julia per-trait unpack already twin-aligned; gap is missing site-X kernel  
**Metric movement:** none — preparation only (expected)  
**Result:** LOCAL DONE / ACCEPTED · **Next arc:** Ordinal+X engine Arc 1
(`fit_ordinal_*_pertrait_cov`) in FRESH chat after docs PR; parallel OWED =
Gamma push/PR + merge #177 when green

---

HAND TO ULTRA PLAN: size-mode Arc 0, **~90 min (60–120)**, outcome =
Ordinal+X cutpoint/identity decision doc only; no engine; mirror Gamma # identity;
fence ADEMP / Phylo Model A / dual-PR Gamma / silent Option B; PLATFORM = Cursor;
after G0 run via `/goal` in a **fresh chat**. Contigent Landing (Gamma push +
#177) only if Phase 0.4 Q1 grants it.
