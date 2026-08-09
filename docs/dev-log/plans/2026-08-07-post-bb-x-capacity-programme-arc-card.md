# ARC CARD — Post-#192 / post-BB+X capacity programme

**Mode:** fixed capacity (owner: all 3 rungs as one programme)  
**Requested outcome:** (1) Species-XB Binomial light RCall cell (+ Gaussian optional under-run); (2) BetaBinomial grouped(_cov) CI + bridge guard lift; (3) ACCEPTED ZIP+X Identity Arc 0 (**docs-only**)  
**Mechanism authority:** S1 parity tests + helpers; S2 `confint_family.jl` + bridge; S3 decision note only — **no ZIP engine** in this programme. Merge each packaging-A PR when CI green (G0 merge-on-green = yes).  
**Recommended arc:** **~5.5 hours** (range **4.5–7.5 h**) as one capacity programme  
**Time contract:** fixed capacity fill for S1–S3; stop at ZIP Identity ACCEPTED (do not start ZIP engine Arc 1)  
**Estimate confidence:** measured priors (Species-XB Poisson Δ≈4.20e-9; BB+X Δ≈1.50e-8; NB1/Beta grouped CI packing exists) + inferred BB CI port risk  
**Arc 0 outcome:** programme locked + worktree from `origin/main` @ `2f07ad37` (#193)  
**State transition:** Species-XB Poisson-only → +Binomial; BB CI fail-loud → routed; idle next Identity → ZIP+X decision on disk  
**Executable rung and evidence:** Poisson species-XB + BB engine already on `main`; ZIP Julia no-X exists; twin ZIP cut (honest Identity fence)

### Capacity ladder
| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 / orient | 15–20 min | Fresh worktree from `origin/main`; LOOP kit | Start `/goal` after this plan lands |
| **S1 — Species-XB widen** | 70–100 min | Binomial `(0+trait):x` light cell; Gaussian optional under-run | After Arc 0; PR1 merge-on-green |
| **S2 — BB grouped CI** | 100–140 min | `_family_ci` for BB grouped(_cov); lift `_bridge_ci_guard_betabinomial` | After S1 merged; PR2 merge-on-green |
| **S3 — ZIP+X Identity Arc 0** | 50–80 min | Decision ACCEPTED (**docs-only**; twin asymmetry noted) | After S2 merged (draft OK while CI runs); PR3 merge-on-green |
| Integrate/close | 15–25 min | Board START HERE; check-log; Actuals; STOP (no ZIP engine) | Always |
| **Total capacity** | **~330 min (5.5 h)** | | |

### Budget (whole programme)
| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15–20 | Worktree + LOOP |
| Core S1 | 55–80 | Binomial cell + optional Gaussian |
| Core S2 | 80–110 | CI methods + bridge + tests |
| Core S3 | 40–60 | Twin recon + decision prose |
| Verify | 30–45 | Focused parity/CI smokes; CI watch |
| Repair reserve | 30–45 | Binomial DGP / BB Hessian / bridge edge |
| Closeout | 15–25 | Board + Actuals + STOP |
| **Total** | **~330** | |

**In scope:** S1–S3 as locked; packaging A; merge-on-green.  
**Not in this arc:** ZIP/ZINB/hurdle engine or light RCall; Tweedie+X; ADEMP; Phylo Model A; Dropbox protected writes; `git add -A`; full family parity claims.

**Evidence used:** `origin/main` @ `2f07ad37` (#193); #192 BB+X Δ abs ≈1.50e-8; #190 Poisson species-XB Δ≈4.20e-9; `_bridge_ci_guard_betabinomial`; twin ZIP cut in gllvmTMB `known-limitations.md`; Julia `fit_zip_gllvm`.

**Risk branch:** If Binomial species-XB Δ fails >40 min, land helper+test scaffold with honest OWED Δ and continue S2 (do not pad with ZIP engine). If BB CI Hessian non-PD on grouped_cov, ship Wald-only or document method fence — do not widen rtol. If ZIP Identity twin cites are empty (expected), ACCEPTED-with-fence citing Julia two-part design + twin known-limitation — do not invent twin file:line.

**Done when:** (1) Binomial species-XB PR merged (Gaussian optional); (2) BB CI PR merged with guard lifted for supported methods; (3) ZIP+X Identity ACCEPTED docs-only; programme STOP before any ZIP engine.

**First action:** `/goal` on the ultra-plan (G0 already locked).

### Actuals (complete at close)
**Recommended / actual:** 330 / multi-session (S1 2026-08-08; S2+S3 2026-08-09) · **Requested / used:** 3-rung programme / S1–S3 delivered · **Rungs completed:** S1 (#196), S2 (PR #197), S3 (this Identity)  
**Under-run event:** Gaussian species-XB skipped (no Laplace speciescov path); S2 landed on sibling lane `feat/betabinomial-grouped-ci-20260808` (#197) rather than a second S2 branch  
**Calibration:** packaging A serial landings held; twin ZIP cut forced ACCEPTED-with-fence as planned  
**Metric movement:** Species-XB +Binomial light cell; BB CI fail-loud → routed; ZIP+X Identity on disk  
**Result:** capacity used (pending PR2/PR3 merge-on-green) · **Next arc:** ZIP+X engine Arc 1 (fresh `/arc-creation` or ultra-plan) only after merges — and only if twin ZIP status is re-checked at that G0.
