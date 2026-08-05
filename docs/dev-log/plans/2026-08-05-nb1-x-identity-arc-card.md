# ARC CARD — NB1+X dispersion identity (Arc 0)

**Status:** **PLAN** — Ultra Plan follows in same turn; awaiting G0. Docs-only;
no execute until `/goal` after approval.

**Mode:** size  
**Requested outcome:** not quantified — lock the NB1 (+ shared site-X)
dispersion identity as a durable docs-only note before any NB1+X engine or
light-parity work. Theme = **R–Julia parity** (light gllvmTMB track).  
**Mechanism authority:** docs-only decision note + board/plan pointers from
**fresh tip off `origin/main`**. Explicit exclusions: no `src/` engine; no
NB1+X light RCall; no ADEMP/coverage; no Phylo Model A; no silent no-X default
flip beyond what the decision names; no Dropbox-protected-checkout writes; no
`git add -A`; no push without ask; no “full family parity” claim; no inventing
Tweedie/ZIP/+X in this arc.  
**Recommended arc:** **75 minutes** (range **60–100 min**)  
**Time contract:** ceiling ~2 h (outcome-first within the size band)  
**Estimate confidence:** **measured** (direct analogues: NB2/Beta+X identity
#174; Gamma+X identity; Ordinal+X identity — all same shape)  
**Arc 0 outcome:** ACCEPTED (or explicitly REJECTED-with-fence) decision note at
`docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` (or dated
equivalent), citing twin NB1 / `nbinom1` / `negative.binomial1` dispersion +
Julia no-X grouped route + bridge “nb1 no covariate kernel yet” gap + Rose
fence + engine follow-on order.  
**State transition:** preparation / design lock — **no metric change** (no new
parity cells). Unlocks later NB1+X Arc 1/2 only after acceptance.  
**Executable rung and evidence:** write + self-review the decision against
NB2/Beta/Gamma mirrors + live twin + Julia routes; docs-only PR when approved.
Engine remains **blocked** until this doc is ACCEPTED.

### Alternatives reconciled (plan-write 2026-08-05)

| Candidate | Verdict | Why |
| --- | --- | --- |
| **(a) Jump straight to NB1+X engine** | **Reject for Arc 0** | Bridge already fences nb1 X (“no covariate kernel”); false parity risk without identity lock (same lesson as #174). |
| **(b) NB1+X identity Arc 0** | **Ada-default** | Owner chose R–Julia parity next; NB1 is the next one-part family with no-X per-trait path but missing +X kernel. |
| **(c) Gamma no-X Option B consistency** | **Defer** | Named follow-up from Gamma decision; orthogonal to NB1+X ladder. |
| **(d) X-cohort recon of all remaining families** | **Defer** | Useful later; owner asked NB1+X identity specifically. |

### Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 60–100 min | NB1+X identity decision note ready for review | After G0 via `/goal` |
| Rung 1 (later) | — | `fit_nb1_gllvm_grouped_cov` (or equiv.) | Only if Arc 0 ACCEPTED |
| Rung 2 (later) | — | Light NB1+X RCall cell @ rtol 1e-6 | Only after Arc 1 greens |
| Integrate/close | 10 min | check-log + after-task + board pointer | Always for Arc 0 |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 10–15 | Twin NB1 φ surface; Julia `fit_nb1_*` / bridge X gap; NB2 mirror |
| Core | 35–45 | Draft decision (problem · twin · Julia map · decision · rejected · Rose · follow-ups) |
| Verify | 10–15 | Diff vs NB2/Beta/Gamma mirrors; twin file:line; no claim inflation |
| Repair reserve | 10 | Scale map (gllvm `φ` vs Julia packing) if wording drifts |
| Closeout | 5–10 | Board + AGENTS snapshot + after-task + Actuals |
| **Total** | **~75–100** | |

**In scope:** one NB1+X (and related no-X consistency) identity decision note;
explicit fence; board / START HERE pointers.  
**Not in this arc:** any `src/` change; NB1+X parity tests; Gamma Option B flip;
Tweedie/ZIP/+X; Phylo Model A; ADEMP; capability-matrix promotion to “full
parity.”

**Evidence used (plan-write):**
- Mirrors: `docs/dev-log/decisions/2026-08-02-nb2-beta-x-dispersion-identity.md`
  (#174); `docs/dev-log/decisions/2026-08-03-gamma-x-dispersion-identity.md`
- Julia no-X: `fit_gllvm` → `fit_nb1_gllvm_grouped` (`src/families/fit_gllvm.jl`);
  shared `fit_nb1_gllvm` remains (`src/families/negbin1.jl`); grouped Laplace in
  `src/families/grouped_dispersion.jl`
- Julia +X gap: bridge documents nb1 **no covariate kernel**
  (`src/bridge.jl` ~UNSUPPORTED / “nb1 is a documented follow-up”);
  `test/test_bridge_x.jl` expects `ArgumentError` for `family="nb1"` + `X`
- No `fit_nb1_gllvm_grouped_cov` in tree (contrast NB2/Beta/Gamma `*_grouped_cov`)
- No NB1 rows in `test/parity/test_x_covariate_parity.jl`
- Live: `origin/main` @ `13d97b13` (post hygiene #183/#184); START HERE idle;
  open PRs none at plan cut; Dropbox PROTECTED
- `/ask-brain`: shinichi-brain MCP **unavailable** in this cloud run

**Risk branch:** If twin evidence shows ordinary NB1 under site-X is **not**
per-trait on current `gllvmTMB` (scalar only), stop cargo-culting API B under X
and rewrite as retain-shared + explicit native-expansion follow-up.

**Done when:** decision note exists, cites twin + Julia route map, states chosen
default under X (and no-X consistency), lists rejected alternatives, Rose fence
forbids full-family / engine-before-acceptance / ADEMP / Phylo Model A, and
Shinichi (or “use your judgment”) accepts it.

**First action (after G0):**

```sh
git fetch origin
git checkout -b docs/nb1-x-identity-20260805 origin/main
# cloud: cursor/nb1-x-identity-arc0-fffd already holds plan artifacts
```

### Actuals (complete at close)

**Recommended / actual:** 75 / _TBD_ · **Rungs completed:** _TBD_  
**Result:** _TBD_ · **Next arc:** NB1+X engine Arc 1 (only if ACCEPTED)

---

**HAND TO ULTRA PLAN:** size-mode NB1+X identity Arc 0, **~75 min (60–100)**,
outcome = decision doc only; no engine; mirror NB2/Beta/Gamma; PLATFORM =
Cursor; after G0 via `/goal`. Ultra Plan written same turn.
