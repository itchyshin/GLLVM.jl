# After-task — the two OWED light RCall Δ cells, paid live (twin fid 3 + fid 10)

**Date:** 2026-08-24
**Lane:** `parity-catchup` on `handover/2026-08-24-claude`, worktree
`/Users/z3437171/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818`, cut from
`origin/main` @ `c5b72310` (#262). PLATFORM: claude.
**Other lanes:** cursor + open PR #254 — its three files (`AGENTS.md`,
`coordination-board.md`, `2026-08-18-cursor-handover.md`) were not opened.
**Identity locks:** `docs/dev-log/decisions/2026-08-15-lognormal-identity.md` and
`docs/dev-log/decisions/2026-08-15-truncated-poisson-identity.md` (both ACCEPTED).
**Reviewed as:** Ada (orchestration), Shannon (lane), Gauss (numerics), Rose
(claim-vs-evidence).

## Goal, stated as a check before writing code

`test/parity/` gains a live no-X logLik oracle cell for lognormal (twin fid 3) and
truncated_poisson (twin fid 10), each agreeing with `gllvmTMB` at rtol 1e-6 in a run
that also re-verifies every previously-green cell — **or**, if the twin cannot be
reached, the cells exist and no number is quoted.

## What changed, and why the OWED status was revisited

The 2026-08-24 handover marked both cells **OWED**, on the explicit premise that this
session could not run the live twin. That premise was **re-tested rather than
inherited**, and it did not hold:

| Check | Result |
|---|---|
| R | 4.6.0 (2026-04-24), `/usr/local/bin/R` |
| `gllvmTMB` | **0.7.0**, `~/Library/R/arm64/4.6/library/gllvmTMB` |
| `RCall.Rhome` vs `R RHOME` | identical — no rebuild needed |
| fid 3 + fid 10 in `.valid_family` | true |

Full provenance: `docs/dev-log/parity-provenance-20260824.md`.

This is the one judgement call in the arc worth stating plainly: the handover's
instruction was conditional, and the condition was false. Paying the cells live is
what the handover asked for when the twin *is* reachable; it is not a scope
expansion.

## Canary before anything new

The whole existing suite was re-run unchanged first — **144/144, exit 0**. All Δ
~1e-10..1e-8 except NB2 at −2.58e-4 on logLik −820.415 (3.1e-7 relative; inside the
locked rtol 1e-6, and the expected magnitude for Laplace-vs-Laplace). A new number is
only worth trusting if the old ones still reproduce on this toolchain.

## Live result

Full suite **with** both new cells: **167/167 pass, exit 0**, zero failures.

```
── lognormal logLik oracle (seed=52, p=5, K=2, n=60; twin fid 3) ──
  Julia logLik          = -594.6707717158076
  gllvmTMB logLik       = -594.6707717381979
  gllvmTMB -objective   = -594.6707717381979
  Δ logLik (jl − r)     = 2.2390281628759112e-8

── truncated_poisson logLik oracle (seed=53, p=5, K=2, n=60; twin fid 10) ──
  Julia logLik          = -618.0776776554326
  gllvmTMB logLik       = -618.0776776581457
  gllvmTMB -objective   = -618.0776776581457
  Δ logLik (jl − r)     = 2.7131363822263665e-9
```

| Cell | Pass/Total |
|---|---|
| Gaussian / Binomial / Poisson / NB2 / Beta / Ordinal-probit | 30 / 6 / 6 / 8 / 8 / 5 |
| **lognormal (new)** | **15 / 15** |
| **truncated_poisson (new)** | **8 / 8** |
| Shared site-X cohort | 65 / 65 |
| Species-specific XB | 16 / 16 |
| **Total** | **167 / 167** |

## The Jacobian was verified twice, not assumed

The lognormal Identity requires the reported y-scale log-likelihood to include the
change-of-variables term `−Σ log y`. `src/families/lognormal.jl` does compute
`ll = gfit.logLik - sum(log.(Y))`, but *reading* that is not evidence, so the cell
gates the Δ behind two independent checks:

1. **Structural.** The reported value reproduces `gaussian_marginal(centred log Y) −
   Σ log Y` to atol 1e-8.
2. **Behavioural, and the decisive one.** Refit both sides on `2·Y`. Because the
   centred log-residuals are unchanged by a common rescaling, an exact y-scale
   log-likelihood must shift by exactly `−p·n·log 2` on **both** sides, leaving Δ
   invariant.

Why (2) matters more than (1): a dropped Jacobian is a *data-dependent constant*. On
any single dataset it can sit inside a tolerance and read as "small disagreement". A
side that had dropped it would be **invariant** under the rescaling while the other
moved — a discrepancy no tolerance check on one dataset can see. Both sides shifted
as predicted.

Comparability is also the best available here: `log y` is exactly Gaussian, so this
is **exact-vs-exact**, not approximation-vs-approximation. truncated_poisson, by
contrast, is Laplace on both sides — noted in that cell's header so the Δ is read
correctly.

## Seeds

The plan pre-registered 45 and 46. Both collide with existing cells (45 = NB2 **and**
Beta; 46 = Ordinal-probit). They were re-registered to **52** and **53** *before
either cell had ever been executed* — a legibility fix so a receipt naming a seed
identifies one cell, **not** a re-roll after seeing a Δ. Reserved next: 54 Gamma, 55
nb1, 56 betabinomial.

## Files changed

| File | Change |
|---|---|
| `test/parity/parity_helpers.jl` | `:lognormal` + `:truncated_poisson` in the no-X family gate and R `fam_obj` switch; docstring records the shared-σ pairing rule and the untruncated-mean rule |
| `test/parity/test_lognormal_parity.jl` | **new** — 15 tests incl. both Jacobian gates |
| `test/parity/test_truncated_poisson_parity.jl` | **new** — 8 tests incl. support gate |
| `test/parity/runparity.jl` | include both; order-lock comment updated |
| `docs/design/capability-status.md` | two OWED clauses → live Δ receipts |
| `docs/dev-log/check-log.md` | arc entry |
| `docs/dev-log/parity-provenance-20260824.md` | **new** — toolchain + canary receipt |

**`src/` was not opened.** No engine change, so no `Pkg.test()` obligation: the parity
project is structurally isolated and the default suite is untouched.

## Fences held

- `capability-status.md` L47 `none × dep` still **`planned`** — not flipped.
- AGHQ rows untouched; `src/families/aghq_grid.jl` not opened (PARKED, 4 arcs serialize).
- #254's three files not opened.
- `test/runtests.jl` contains **zero** references to `test/parity/` (verified) — the
  default suite stays runnable on machines without R.
- No tolerance widened anywhere.
- Global *"Full family R↔Julia parity claim"* remains **`rejected`**. Twin-verified
  no-X coverage moves **6/17 → 8/17**; that is a count of logLik-agreement cells at
  one fixed seed each, and nothing more.

## Defect found in passing — pre-existing, not introduced, not fixed here

Running `runparity.jl` **mutates its own `test/parity/Project.toml`**: `Pkg.develop`
strips the comment block explaining why GLLVM must not appear in `[deps]`, then adds
GLLVM to `[deps]`. So the file's own documentation is destroyed by the mechanism it
documents, and every parity run leaves the tree dirty. `Manifest.toml` is gitignored;
`Project.toml` is not. Restored from HEAD here and deliberately **not** staged.
Fixing it (gitignore, or a `--project` temp env, or an explicit `[deps]` entry with
the comment preserved) is a separate chip.

## What did not go smoothly

- `test/parity/` had no `Manifest.toml`, so the first `using RCall` failed until
  `Pkg.instantiate()` ran. Expected given the deliberate isolation, not a defect —
  but it is undocumented in `test/parity/README.md`, which jumps straight to the run
  command. Worth a line there.
- The plan's pre-registered seeds collided with existing cells; caught before running.

## Remaining risks / limitations

1. **One seed, one fixture per family.** Each Δ is a single (p=5, K=2, n=60) draw. It
   is evidence of *same-model agreement*, not a coverage or recovery claim.
2. **No-X only.** No X, X_lv, mask, or CI transport for either family.
3. **truncated_poisson is Laplace-vs-Laplace** — a genuine approximation comparison,
   unlike lognormal's exact-vs-exact.
4. `truncated_nbinom2` (fid 11) is a *different* Identity and is not covered here.

## OWED after this arc

No-X cells for Gamma(4), betabinomial(8), nbinom1(15) — cheap clones, identity
already settled. Identity decisions still needed for student(9) (ν: fixed vs
estimated), truncated_nbinom2(11) (dispersion granularity, to be read from
`gllvmTMB` source not assumed), delta_lognormal(12) and delta_gamma(13) (two-part
parameterisation), multinomial(16) (data shape — needs a new oracle helper, not a
clone). tweedie(6) stays blocked behind the grouped-route defects recorded in the
check-log; a Δ there today would be a number about a defective route.

## Next command

```sh
GLLVM_PARITY_TESTS=1 GLLVM_PARITY_R_LIBS=/Users/z3437171/Library/R/arm64/4.6/library \
  julia --project=test/parity test/parity/runparity.jl
```

## Rose verdict

**ROSE VERDICT: PASS WITH NOTES** — no blockers. Rose re-verified every quoted float
digit-by-digit against the run logs (all six byte-exact; rounding in the ledger
correct), independently re-ran the toolchain probe, confirmed both cells use the no-X
oracle and never the X variant, confirmed the previously-green cells were green **in
the same invocation** (30+6+6+8+8+5+15+8+65+16 = 167), and verified all four fences by
command. `git diff c5b72310 -- test/ | grep -E "^[-+].*(rtol|atol|tol)"` is empty — no
tolerance touched.

Three notes were raised and **all three are fixed in this arc**:

1. **Tautological assertion.** `@test jl_fit.σ isa Real` could never fail —
   `LognormalFit.σ::Float64` is statically scalar — while the testset name promised a
   shared-vs-per-trait check it did not perform. Replaced with an honest smoke check
   plus a comment stating that the **Δ itself** is the evidence for the pairing: had
   the twin fitted `p` free `sigma_eps` against Julia's single σ, its log-likelihood
   would be materially higher and a Δ of ~1e-8 impossible.
2. **Overstated Jacobian justification — a real error on my part.** The first draft
   claimed no tolerance check on a single dataset could detect a dropped Jacobian.
   Wrong: a **one-sided** drop offsets the log-likelihood by `Σ log y ≈ 375` against
   ≈ −594.67, a relative error of ~0.6 that `rtol = 1e-6` catches trivially. The
   scale-shift gate's real and narrower value is detecting a **both-sides** drop — a
   shared convention error where both engines omit the term and still agree — and
   pinning the Jacobian's functional form. Corrected in both the check-log and the
   test comment.
3. **Terminology drift.** "Twin-verified coverage 6/17 → 8/17" was a *no-X* count
   wearing a general label; Gamma(4), betabinomial(8) and nbinom1(15) already carry
   live +X Δ evidence in the same log. Reworded to "**no-X** twin-verified coverage"
   with the +X evidence named explicitly.

Rose also noted the Stage-0 toolchain probe left **no log artifact**, so a future
auditor on an upgraded machine could not reproduce it. Recorded here as a process fix
for the next rung: tee the probe to the scratchpad like the suite runs.
