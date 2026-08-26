# Maintainer decision document — the four unpaid twin-parity cells

Read-only synthesis of the four cell briefs (tweedie fid 6, student fid 9, delta_lognormal
fid 12, delta_gamma fid 13). No Julia or R was run; every claim traces to a file:line read
in the lane (`/Users/z3437171/local-scratch/lanes/GLLVM.jl-beyond-20260824`) or the twin
(`/Users/z3437171/Dropbox/Github Local/gllvmTMB`, 0.7.0, read-only). The reader is the
maintainer; §3 is the decision list.

---

## 1. The one-paragraph summary

**The ladder cannot be closed to 17/17 unqualified, and it should not be.** Of the four
unpaid cells, **zero are payable today as unrestricted, house-pattern fit-vs-fit cells**,
and zero can *ever* be paid unqualified without changing the GLLVM.jl model to match the
twin — a scientific decision, not a test fix, in three of the four cells (tweedie: one
shared power vs the twin's per-trait power vector; delta_lognormal and delta_gamma: Julia's
two-predictor hurdle vs the twin's single shared η, a parameterisation the twin itself
documents as provisional). **All four are payable as RESTRICTED cells**: two with **zero
Julia source change today** (delta_lognormal fixed-θ kernel Δ; delta_gamma p = 1, K = 1
evaluate-at-twin's-θ, subject to two live preconditions), and two after **small,
precedented engineering** (tweedie: observed-curvature selector + `power_fixed` keyword;
student: `hessian` keyword threading, then a p = 1, K = 1, ν-pinned cell). The honest
ceiling is therefore **13 unqualified + 4 RESTRICTED**, reported exactly in that form —
never "17/17". Two of the four restricted cells are additionally a **new, weaker receipt
genre** (evaluate-at-θ kernel identity, not fit-vs-fit) and must be registered as such.
Separately, the ledger's recorded blockers are stale or wrong in three cells and must be
corrected regardless of what else is decided.

---

## 2. Per cell

### 2.1 tweedie (fid 6) — blocker kind: both

**What differs.**
- *Power.* Twin: per-trait free power, `PARAMETER_VECTOR(logit_p_tweedie)`
  (`src/gllvmTMB.cpp:1166-1167`, used at `:2752-2755`); with default `tweedie()` all
  `n_traits` powers are freely estimated (`R/dispersion-trait-map.R:63-65`). With
  `tweedie(p = p0)` the twin pins them exactly (`R/fit-multi.R:5297-5299`). Julia: one
  scalar power always, on both routes (`src/families/tweedie.jl:287-295`,
  `src/families/grouped_dispersion.jl:1653-1661`). Same reparameterisation
  (p = 1 + invlogit(ξ), both default to p = 1.5); only the length differs.
- *Laplace curvature.* Julia's Tweedie log-det uses the Fisher weight
  (`tweedie.jl:25-26`); TMB's is structurally the observed Hessian. Genuinely different
  functions for Tweedie/log (`docs/design/capability-status.md:250-290`: "Tweedie |
  Fisher | not yet decided"). Neither Tweedie entry point can currently be asked for
  observed curvature (shared route drops the kwarg at `tweedie.jl:136-140`; grouped route
  has no `hessian` argument at all, `grouped_dispersion.jl:1498-1535`). The 2026-08-25
  role-separation audit fixed NB2/Beta/Gamma/NB1 grouped kernels but **not Tweedie**.
- *Not different:* the density (TMB `dtweedie` ≡ `tweedie_logpdf`, same Dunn–Smyth EDM
  form) and the dispersion granularity (both per-trait via
  `fit_tweedie_gllvm_grouped(…, group = collect(1:p))`).
- *Stale ledger:* the three recorded engine defects (warm start, 1e12 sentinel, naked
  convergence verdict) were repaired by #236/#238; blocker 1 is discharged. STOP #234
  fences `fit_gllvm` bare-marker admit and `src/bridge.jl`, neither of which a
  `test/parity/` cell touches.

**Model decision or engineering gap?** Both. The default free-per-trait-power cell is a
**model decision** (one power vs p powers). The pinned-power cell is pure **engineering**:
(i) observed-curvature selector, (ii) `power_fixed` keyword. Neither is a model choice.

**Options.**
- (a) Match the twin fully: per-trait power vector + observed curvature. Pays the
  default cell but adds p−1 parameters on the (φ, power) ridge the twin's own source
  cites as the reason it offers a pin; breaks `TweedieFit.p` as a single estimate and the
  CI plumbing; re-opens the estimator #236/#238 spent two arcs stabilising. **Not
  recommended.**
- **(b) RECOMMENDED:** keep the shared power; pay a RESTRICTED fixed-power cell.
  Twin `tweedie(p = 1.5)` vs Julia `power_fixed = 1.5, hessian = :observed`. Same free
  parameters (β, packed Λ, per-trait log φ), same likelihood, rtol 1e-6. Cost: two small
  additive changes. Forfeits: the default free-power cell stays unpaid.
- (c) Leave unpaid: cost 0, but the recorded reason is two-thirds stale.
- (d) Fixed-parameter engine Δ via `fit_r$tmb_obj$fn(par)`: still blocked by curvature,
  off-pattern, brittle. Not the primary route.

**Restricted cell payable today?** Not zero-code. Payable after the two engineering items,
**in this order**: (1) curvature selector (verify `hessian = :fisher` reproduces today's
numbers bit-for-bit), (2) `power_fixed`, (3) the cell, (4) record per-trait power as a
named estimand gap in `docs/src/gllvmtmb-parity.md`. Wrong order produces a failing Δ
misdiagnosed as a power problem.

### 2.2 student (fid 9) — blocker kind: implementation gap

**What differs.**
- *ν (df).* **The recorded blocker "the twin estimates df" is FALSE.** `student(df = ν)`
  pins it exactly (`R/families.R:365-367`, `R/fit-multi.R:5325-5348`, exercised in the
  twin's own tests). Not a blocker; not a maintainer decision. Constraint: twin enforces
  df > 1; use ν > 1.
- *σ.* Twin: per-trait `log_sigma_student`, always free, no collapsing map exists
  (`src/gllvmTMB.cpp:1184`, `R/dispersion-trait-map.R:57-69`). Julia: one shared scalar
  (`studentt.jl:115-124`), no grouped route (`fit_gllvm.jl:327-329` throws). Engineering
  gap with four precedents (NB2, Beta, NB1, BetaBinom). Vanishes by construction at p = 1.
- *Curvature — the decisive, unrecorded blocker.* Julia uses the Fisher weight
  (ν+1)/((ν+3)σ²)·me², a constant free of y (`studentt.jl:75-77`); TMB uses the observed
  curvature (ν+1)(νσ² − r²)/(νσ² + r²)², y-dependent and negative for |r| > σ√ν. O(1)
  gap; no Δ at rtol 1e-6 is possible at any p or ν without it. `fit_studentt_gllvm`
  accepts no `hessian` keyword. Favourable asymmetry: the Student-t fitter uses
  `autodiff = :finite` (`studentt.jl:207`) — no analytic-gradient coupling to
  desynchronise, unlike NB2/Gamma/Beta.
- *Not different:* the density (location–scale t, exact match to
  `dt(z, df, log=TRUE) − log σ`, `gllvmTMB.cpp:2793-2800` vs `studentt.jl:80-90`) and the
  link (both identity-only at fit time).

**Model decision or engineering gap?** Pure engineering. No model decision exists in this
cell.

**Options.**
- **(a) RECOMMENDED:** thread `hessian::Symbol = :fisher` (opt-in, default unchanged)
  through `fit_studentt_gllvm` / `studentt_marginal_loglik_laplace`, add the closed-form
  observed weight, pay a RESTRICTED p = 1, K = 1, ν-pinned cell whose header names the
  non-default `hessian = :observed` route. A few hours of work.
- (b) Flip the default to :observed: same code plus a 12-seed quadrature study the flip
  precedent demands (the analogous flip was measured WORSE for Beta 2/12 and GP-1;
  Student-t is unmeasured); changes every existing Student-t estimate. Deferred.
- (c) Also build `fit_studentt_gllvm_grouped` (per-trait σ) for a full p = 5 cell.
  Largest cost; only widens an already-paid cell from p = 1 to p = 5. Defer.
- (d) Leave unpaid: only defensible if the ledger entry is rewritten anyway.

**Restricted cell payable today?** **No — nothing, honestly.** The curvature gap survives
every restriction (p = 1, ν pinned, ν → ∞ dodge all fail; the ν = 1e6 trick is a failing
Δ dressed as a passing one). Payable only after the opt-in keyword lands.

### 2.3 delta_lognormal (fid 12) — blocker kind: both

**What differs.**
- Twin: **one shared linear predictor** drives both hurdle components
  (`src/gllvmTMB.cpp:2816-2830`; self-documented as provisional at
  `R/gllvmTMB.R:151-154`, "share one linear predictor under the current
  implementation"), with **per-trait σ** (`gllvmTMB.cpp:1195`).
- Julia: **two predictors** η^z, η^c with v1 default Λ_z = 0 and free β^z ≠ β^c
  (`twopart.jl:196-206`, `:223`, `:301`), **one shared σ**. Neither model nests the
  other; parameter counts differ by exactly one (2p + rr vs 2p + rr + 1) — a dof check
  would nearly pass while the models are entirely different. Do not use dof as evidence.
- The Julia default came from a documented *guess* at the twin's convention
  (`docs/superpowers/specs/2026-05-31-two-part-families-design.md:98-115`, flagged
  "verify against the gllvmTMB source before claiming exact parity"); this brief performs
  that verification and the guess was wrong. The capability table's recorded blocker
  ("no fit_gllvm / @formula / bridge arm") is also wrong — the surface arm has existed
  since 2026-08-16; the real blocker is the model difference.
- *Crucial asymmetry:* the Julia **kernel** already expresses the twin's model exactly —
  `delta_lognormal_marginal_loglik_laplace(Y, Λ, β, β, σ; Λz = Λ)` is exported
  (`src/GLLVM.jl:209-210`), and for DeltaLogNormal Fisher ≡ observed curvature on both
  blocks (Bernoulli-logit π(1−π); Gaussian 1/σ²), so the two Laplace approximations
  coincide term for term. Only a constrained fitter and per-trait σ are missing.

**Model decision or engineering gap?** Both, cleanly split: shared-vs-split predictor is a
**model decision** (the twin's choice ties occurrence log-odds to abundance median —
species cannot be common-and-small); the constrained fitter + per-trait σ is
**engineering** (~40-60 lines, no new mathematics).

**Options.**
- (a) Change the Julia default to shared η: destroys the public API, invalidates
  recovery tests, forfeits the scientifically standard decoupled hurdle (sdmTMB,
  glmmTMB ziformula) to match a parameterisation the twin flags as provisional.
  **Not recommended.**
- **(b-lite) RECOMMENDED FIRST:** zero-code fixed-θ **kernel Δ** — evaluate both engines'
  log-marginal at one common (β, Λ, σ) via `fit$tmb_obj$fn`/`$report(par)$Lambda_B` on
  the R side (forcing all `log_sigma_lognormal_delta` equal) and the exported evaluator
  with `Λz = Λ` on the Julia side. Highest evidence-per-line in the whole option set;
  should agree tighter than any fit-vs-fit cell (no optimiser noise).
- (b) Then optionally a RESTRICTED shared-η fit-vs-fit cell via a new named non-default
  fitter (`fit_delta_lognormal_shared_eta_gllvm`) + per-trait σ threading.
- (c) Leave unpaid: forfeits a sharp, genuinely available identity check and leaves a
  wrong recorded blocker in place.
- *Rejected sub-case:* the hypothesised Λ_c = 0 / intercept-only restriction is NOT
  payable (K = 0 is not a GLLVM; p = 1 delta-lognormal is not identified). The payable
  restriction is the opposite tie, Λ_z = Λ_c.

**Restricted cell payable today?** **Yes — (b-lite), zero source change.** One parity test
file. Caveats: simulate from the *twin's* model (one β, occurrence and abundance move
together); keep |η| ≲ 5 clear of Julia's `_clamp_eta` ±30; `integration = "laplace"`,
`unique = FALSE`, no OLRE; pre-registered seed avoiding 42-49, 52, 53, 58.

### 2.4 delta_gamma (fid 13) — blocker kind: both

**What differs.**
- Same shared-η vs two-predictor split as fid 12 (`gllvmTMB.cpp:2831-2844` vs
  `twopart.jl:1-19`, `:49-50`, `:704-774`; twin statement of intent to decouple later at
  `R/gllvmTMB.R:422-430`). Plus per-trait `log_phi_gamma_delta` (twin) vs one shared
  scalar α (Julia, `twopart.jl:620-622`). Neither model nests the other; the sign of a
  fitted logLik difference is not predictable a priori.
- *Not different:* the positive density (Gamma(1/φ², μφ²) ≡ Gamma(α, μ/α) with α = 1/φ²)
  and — since PR #264 — the **curvature**: DeltaGamma's log-det weight is now the
  observed α·y/μ (`twopart.jl:640-650`). Curvature is no longer a blocker for fid 13.
- *Unlike fid 12*, the positive block has a real Fisher-vs-observed distinction, which is
  exactly why PR #264 currently has **no twin-anchored evidence at all** — the payable
  cell below is its only available regression receipt.

**Model decision or engineering gap?** Both: shared-vs-split predictor is the **model
decision**; per-trait α is an **engineering gap** (with a cheap design lead: `_tp_pieces`
has 8 methods but only two call sites, `twopart.jl:51` and `:118`, so a vector-of-markers
dispatch avoids the feared ~10-family signature change — a lead, not verified).

**Options.**
- (a) New tied-η + per-trait-α fitter (`fit_delta_gamma_gllvm_shared_eta`), full
  fit-vs-fit cell at p = 5, K = 2. Only as a NEW fitter, never a replacement. Buys parity
  against a parameterisation the twin flags as provisional.
- **(b) RECOMMENDED FIRST:** p = 1, K = 1 evaluate-at-twin's-θ cell, zero source change:
  `delta_gamma_marginal_loglik_laplace(Y, Λ̂, β̂, β̂, 1/φ̂²; Λz = Λ̂)` at a converged
  twin fit's θ̂. At p = 1 the dispersion gap is absent, not restricted away. Load-bearing
  for PR #264: with λ̂ ≠ 0 observed vs Fisher Wc give different log-dets.
- (c) Leave unpaid: discards the only cheap twin-anchored regression test for #264.

**Restricted cell payable today?** **Yes — (b), zero source change**, with three gates
before quoting a number: (i) confirm live that gllvmTMB admits
`latent(0 + trait | site, d = 1)` at a single trait; (ii) confirm `_clamp_eta`'s ±30 is
non-binding at θ̂; (iii) the non-zero-Λz code path has never been exercised anywhere in
the test suite (`test/test_twopart_alloc_equiv.jl:22` sets Λz = 0) — show it correct
against a small K = 1 quadrature oracle first. Pin the receipt to gllvmTMB 0.7.0.

---

## 3. The decisions the maintainer must take

Each is yes/no or a named option. Recommended answer in bold; consequence stated.

1. **Tweedie: does GLLVM.jl's Tweedie carry one power or p powers?** — **One (option b).**
   Consequence of "one": two additive keywords, no breaking change, a RESTRICTED
   fixed-power cell, and the per-trait-power gap recorded as a named estimand gap.
   Consequence of "p" (option a): re-opens an estimator that needed two arcs (#236, #238)
   to stop lying about convergence with a single power, on a ridge the twin's own source
   documents as the reason it offers a pin.

2. **Tweedie: land the observed-curvature selector BEFORE `power_fixed`, with a
   bit-for-bit Fisher-default regression check?** — **Yes.** Consequence of "no": a
   failing Δ that gets misattributed to the power, repeating the misdiagnosis this brief
   exists to prevent.

3. **Student: correct the ledger entry now, independent of everything else?** — **Yes.**
   The recorded blocker (twin estimates df) is false — `student(df = ν)` pins it exactly
   — and the decisive blocker (Fisher-vs-observed curvature) is unrecorded. Consequence
   of "no": the ledger keeps blaming a non-blocker and hiding the real one.

4. **Student: opt-in `hessian` keyword (option a) or default flip (option b)?** —
   **Option (a), opt-in, default untouched.** Consequence of (a): an honest restricted
   cell for a few hours' work; the accuracy question stays open, correctly, because
   Student-t is not in the 12-seed quadrature study. Consequence of (b): every existing
   Student-t estimate changes and a quadrature study becomes mandatory first.

5. **Student: defer the per-trait-σ grouped fitter (option c)?** — **Yes, defer.** It is
   the larger half and only widens an already-paid cell from p = 1 to p = 5.

6. **delta_lognormal: keep the two-predictor Julia model as the public default (i.e.
   reject option a)?** — **Yes, keep it.** It is the more general, scientifically
   standard hurdle formulation; the twin itself calls its shared predictor provisional.
   Consequence of changing it: public API break, invalidated recovery tests, and parity
   bought against a parameterisation the twin may abandon.

7. **delta_lognormal: pay the zero-code fixed-θ kernel Δ (option b-lite) now?** —
   **Yes.** Consequence: the sharpest available identity check for the cell, at the cost
   of one test file. It is a kernel Δ, not a fit Δ — see decision 10.

8. **delta_lognormal: additionally ship `fit_delta_lognormal_shared_eta_gllvm` (route B)
   to upgrade to a fit-vs-fit restricted cell?** — **Defer until b-lite has landed and
   been read**; then decide as a separate ~40-60-line slice. Consequence of shipping: a
   house-pattern restricted cell; consequence of not: the cell stays kernel-only.

9. **delta_gamma: pay the p = 1, K = 1 evaluate-at-θ cell (option b), gated on the two
   live preconditions and a K = 1 quadrature check of the never-tested Λz ≠ 0 path?** —
   **Yes.** Consequence: the only twin-anchored evidence the PR #264 curvature fix will
   have. Consequence of "no": #264 remains without any twin receipt.

10. **Register "kernel Δ / evaluate-at-θ" as a NEW, WEAKER receipt genre in
    `capability-status.md`, distinct from the 13 fit-vs-fit cells?** — **Yes.**
    Consequence of "no": the restricted delta cells silently inherit the paid-cell
    vocabulary and overstate what was proven.

11. **delta_gamma: ship a second, twin-shaped shared-η fitter now (option a)?** —
    **No, not now.** Its only purpose is parity against a parameterisation gllvmTMB has
    itself flagged as provisional (`R/gllvmTMB.R:428-430`). Revisit if the twin commits
    to the shared predictor, or if fid 13 is wanted as a real fit-vs-fit ladder cell. If
    ever built, it is a NEW fitter alongside `fit_delta_gamma_gllvm`, never a
    replacement.

12. **Ladder accounting: is the headline "13 unqualified + 4 RESTRICTED", never
    "17/17"?** — **Yes.** Consequence of "no": every restricted fence in §4 is
    eventually violated by summary drift.

---

## 4. What must never be claimed, whatever is decided

Across all four cells:

- **Never "17/17"**, "ladder closed", or "N/17 paid" counting a restricted cell without
  its qualifier. The honest form is "13 unqualified + k RESTRICTED", each restricted cell
  named with its restriction.
- **Never unqualified family parity**: not "tweedie parity" (fixed-power only; the
  default free-per-trait-power cell stays unpaid), not "Student-t parity" (p = 1, ν
  pinned, non-default curvature route), not "delta_lognormal parity" or "delta_gamma
  parity" (shared-η restricted / kernel-only; GLLVM.jl's default two-predictor Delta
  models remain unpaired at any Δ).
- **Never a fit claim from an evaluate-at-θ cell.** Kernel Δs say two log-marginals agree
  at a point; nothing about either optimiser, warm start, or convergence. Label them as
  the new genre (decision 10).
- **Never that the public default path was validated** where the Δ used a non-default
  route: `fit_gllvm(Y; family = StudentTFamily(ν))` still runs the Fisher log-det;
  `fit_gllvm(Y; family = DeltaLogNormal())` / `fit_delta_gamma_gllvm` maximise
  non-nesting parameter spaces the cells never touch.
- **Never an accuracy claim from a curvature flip.** Observed-curvature is a **parity**
  goal ("matches TMB's log-det"), not an accuracy improvement — the quadrature study
  found Gamma better 12/12 but Beta 2/12 and GP-1 worse, and **no Tweedie or Student-t
  quadrature evidence exists**.
- **Never a recovery, coverage, or ADEMP claim** from any of these cells; the Student-t
  p = 1 cell is additionally weakly identified (λ² vs σ) — logLik oracle only.
- **Never per-trait power (Tweedie), estimated ν (Student-t), per-trait/per-species σ or
  `disp_group` support (Student-t), or per-trait α (delta_gamma)** as supported
  capabilities — none exist in Julia after the recommended path.
- **Never anything touching STOP #234's fence**: no `fit_gllvm` bare-marker Tweedie
  claims, no `@formula` claims, and `src/bridge.jl` stays shut.
- **Never extend a delta receipt sideways**: the fid 12 argument does not carry to fid 13
  without its own curvature check (it has one, #264); neither carries to
  delta_lognormal_mix, delta_gengamma, or `type = "poisson-link"` (twin aborts on it).
- **Pin the delta receipts to gllvmTMB 0.7.0** — the twin may decouple its predictors in
  a future release, which invalidates the tie both cells are built on.
- **Never quote a number that has not run live** against a real gllvmTMB (house rule,
  `test/parity/test_lognormal_parity.jl:17-18`); the delta_gamma preconditions (single-
  trait `latent()` admission, `_clamp_eta` non-binding) are unverified in this read-only
  brief and must be checked before any number is reported.
