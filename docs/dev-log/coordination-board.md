# Coordination Board — GLLVM.jl

## Active Lane Split

| Lane | Status | Branch / tip | Current handover / pointer | Owns |
|---|---|---|---|---|
| **ZIP+X engine Arc 0** | **STOP (DoD landed; uncommitted)** | `feat/zip-x-engine-20260809` wt @ base `6f9050e5` | LOOP `lanes/zip-x-engine-20260809/LOOP/` · after-task `docs/dev-log/after-task/2026-08-09-zip-x-engine.md` | Engine + identity/FD + bridge/`@formula` green (`Pkg.test` 5324/1 broken). Awaiting commit/PR ask. **≠ twin Δ ≠ ZINB+X ≠ ADEMP**. |
| **Post-#192 capacity programme** | **CLOSED** (#197+#198 MERGED) | `main` @ `6f9050e5` | LOOP `lanes/post-bb-x-capacity-20260807/LOOP/` · decision `docs/dev-log/decisions/2026-08-09-zip-x-identity.md` | S1 #196 · S2 #197 · S3 #198 Identity. Closed before ZIP engine; engine is the lane above. |
| **Post-#192 ultra-plan G0** | **MERGED** #194 | `main` @ `49056186` | ultra-plan `docs/dev-log/plans/2026-08-07-post-bb-x-capacity-programme.md` | Binding G0 + arc card. Closed. |
| **Post-#192 board/handover hygiene** | **MERGED** #193 | `main` @ `2f07ad37` | handover `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x.md` | Board/AGENTS truth + Cursor handover. Closed. |
| **BetaBinomial+X engine Arc 1+2** | **MERGED** #192 | `main` @ `f56befc1` | after-task `docs/dev-log/after-task/2026-08-05-betabinomial-x-engine-arc12.md` | Engine + bridge/`@formula` + light RCall Δ abs ≈1.50e-8 (seed=49). Closed. |
| **BetaBinomial+X Identity Arc 0** | **MERGED** #191 | `main` @ `d5d61cb7` | decision `docs/dev-log/decisions/2026-08-05-betabinomial-x-dispersion-identity.md` | ACCEPTED: per-trait φ + shared site-X γ. Closed. |
| **Post-NB1 closeout programme** | **DONE** (packaging A) | `main` @ `#187`/`#190` + this Identity | LOOP `lanes/post-nb1-closeout-20260805/LOOP/` · after-task `docs/dev-log/after-task/2026-08-05-post-nb1-closeout-programme.md` | Hygiene + Species-XB + Identity. Closed. |
| **Species-XB light RCall Arc 0** | **MERGED** #190 | `main` @ `a8d19579` | after-task `docs/dev-log/after-task/2026-08-04-species-xb-light-rcall.md` | Poisson `(0+trait):x` Δ≈4.20e-9. Closed. |
| **Post-NB1 hygiene** | **MERGED** #187 | `main` @ `f230b372` | after-task `docs/dev-log/after-task/2026-08-05-post-nb1-hygiene.md` | Board truth + Distributions + capabilities golden. Closed. |
| **NB1+X combined Arc 1+2** | **MERGED** #186 | `main` @ `a100cc63` | after-task `docs/dev-log/after-task/2026-08-05-nb1-x-engine-arc12.md` | Engine + light cell; **live Δ abs ≈1.53e-9** (seed=48). Closed. |
| **NB1+X identity Arc 0** | **MERGED** #185 | `main` @ `210de76d` | decision `docs/dev-log/decisions/2026-08-05-nb1-x-dispersion-identity.md` · after-task `docs/dev-log/after-task/2026-08-05-nb1-x-identity.md` | ACCEPTED: per-trait φ + shared site-X γ. Closed. |
| **Board / snapshot hygiene** | **MERGED** #183/#184 | `main` @ `13d97b13` | after-task `docs/dev-log/after-task/2026-08-05-board-hygiene.md` | Post-#181 pointer truth + merged-branch GC. Closed. |
| **Ordinal+X light RCall Arc 2** | **MERGED** #181 | `main` @ `a92c5040` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-arc2-parity.md` | `:ordinal` X helper + light `ordinal_probit`+X cell (Δ≈5e-9). Closed. |
| **Ordinal+X engine Arc 1** | **MERGED** #180 | `main` @ `e4c20195` | after-task `docs/dev-log/after-task/2026-08-03-ordinal-x-engine.md` | `fit_ordinal_gllvm_pertrait_cov` + bridge/`@formula`. Closed. |
| **Ordinal+X identity Arc 0** | **MERGED** #179 | `main` @ `0630f8e4` | decision `docs/dev-log/decisions/2026-08-03-ordinal-x-cutpoint-identity.md` | ACCEPTED: per-trait cutpoints + shared γ. Closed. |
| **Gamma+X Arc 1–2 land** | **MERGED** #178 | `main` @ `5f027f19` | handover `docs/dev-log/handover/2026-08-03-cursor-handover-gamma-x-arc2-close.md` | Identity+engine+OH+Gamma+X light cell. Closed. |
| **NB2/Beta+X Arc 2** | **MERGED** #177 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-arc2-parity.md` | Closed. |
| **NB2/Beta+X engine Arc 1** | **MERGED** #175 | `main` | after-task `docs/dev-log/after-task/2026-08-02-nb2-beta-x-grouped-cov.md` | Closed. |
| **Windows row-effect NA budget** | **MERGED** #176 | `main` | after-task `docs/dev-log/after-task/2026-08-02-windows-roweffect-na-gate.md` | Closed. |
| **Grouped dispersion one-group bug** | **MERGED** #172 | `main` | after-task `docs/dev-log/after-task/2026-08-02-grouped-dispersion-one-group.md` | Closed. |
| **MC Julia capability-status** | **MERGED** #173 | `main` | `docs/design/capability-status.md` | Closed. |
| **X/covariate light logLik** | **MERGED** #170 | `main` | after-task `docs/dev-log/after-task/2026-08-02-x-covariate-light-loglik.md` | Closed. |
| **Default-route NB2/Beta φ** | **MERGED** #169 | `main` | `docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md` | Closed. |
| **Catch-up logLik oracle** | **DONE** | `catchup/loglik-oracle-20260801` | `docs/dev-log/handover/2026-08-01-cursor-handover.md` | Closed. |
| **Phylo Model A redesign** | Deferred / parked | PR #127 closed | `docs/dev-log/handover/2026-06-30-codex-handover.md` | Do not orphan. |
| **Dropbox checkout (stale fork)** | **PROTECTED** | `claude/jl-bridge-capabilities-20260619` | — | Never write. New work = `origin/main` worktree. |

## Current Rule

- Rehydrate via **this Active-Lane-Split**, not a single orphaned START HERE bullet.
- `START HERE (Cursor):` **ZIP+X engine Arc 0** on
  `feat/zip-x-engine-20260809` (fresh wt from `origin/main` @ `6f9050e5` after
  #197+#198 MERGED). LOOP `lanes/zip-x-engine-20260809/LOOP/`. Ship
  `fit_zip_gllvm_cov` / `ZIPCovFit` + identity/FD≤1e-6 + bridge/`@formula`
  (one-part + X). Do **not** invent twin light Δ (ZIP still cut in gllvmTMB).
- Rose fence: ZIP+X Julia engine ≠ twin parity ≠ ADEMP ≠ ZINB+X ≠ Phylo #127;
  ZIP+X Identity ≠ free `Λ_z`; BB/NB1/Ordinal+X precedents ≠ light RCall for ZIP.
- Bridge execution R→Julia only (JuliaCall); RCall = opt-in oracle.
- Stage by name; never `git add -A`; no push without instruction.
- Dropbox checkout remains PROTECTED.

## Status

- 2026-08-09 — ZIP+X engine Arc 0 **ACTIVE** on `feat/zip-x-engine-20260809`
  (base `6f9050e5` = #198). Dual-γ packing + bridge admit; no twin Δ.
- 2026-08-09 — Capacity S3 ZIP+X Identity **MERGED**
  [#198](https://github.com/itchyshin/GLLVM.jl/pull/198) @ `6f9050e5`.
- 2026-08-09 — Capacity S2 BetaBinomial grouped CI **MERGED**
  [#197](https://github.com/itchyshin/GLLVM.jl/pull/197) @ `9c2b18d6`.
- 2026-08-09 — Capacity S3 ZIP+X Identity **ACCEPTED** (docs-only): decision
  `2026-08-09-zip-x-identity.md` (separate `γ^z`/`γ^c`, `Λ_z=0`, twin-
  asymmetric). Programme → **STOP** before ZIP engine (engine lane opened after merges).
- 2026-08-09 — Capacity S2 BetaBinomial grouped(_cov) CI **PR #197**
  (Wald/profile/bootstrap routed, FD Hessian; guard lifted). Focused
  tallies: capabilities 130; grouped_dispersion 131; missing_mask 89;
  confint_family 163; bridge_x 248.
- 2026-08-08 — Capacity S1 Species-XB Binomial **MERGED**
  [#196](https://github.com/itchyshin/GLLVM.jl/pull/196) @ `6aa8e0cb`
  (Δ abs ≈1.322e-9). Gaussian skipped.
- 2026-08-07 — Capacity programme ultra-plan G0 **MERGED**
  [#194](https://github.com/itchyshin/GLLVM.jl/pull/194) @ `49056186`.
  Next: `/goal` via handover
  `docs/dev-log/handover/2026-08-07-cursor-handover-post-bb-x-goal.md`.
- 2026-08-07 — Post-#192 board/handover hygiene **MERGED**
  [#193](https://github.com/itchyshin/GLLVM.jl/pull/193) @ `2f07ad37`.
- 2026-08-07 — BetaBinomial+X engine Arc 1+2 **MERGED**
  [#192](https://github.com/itchyshin/GLLVM.jl/pull/192) @ `f56befc1`
  (live Δ abs ≈1.50e-8).
- 2026-08-05 — BetaBinomial+X engine Arc 1+2 **live Δ proven** (pre-merge
  tip): abs Δ ≈ `1.50e-8`, rel Δ ≈ `1.29e-11` @ rtol `1e-6` (seed=49).
- 2026-08-05 — BetaBinomial+X Identity Arc 0 **MERGED**
  [#191](https://github.com/itchyshin/GLLVM.jl/pull/191) @ `d5d61cb7`.
- 2026-08-05 — Post-NB1 closeout programme **packaging A complete** (#187
  hygiene, #190 Species-XB, this BetaBinomial+X Identity).
- 2026-08-05 — Species-XB **MERGED**
  [#190](https://github.com/itchyshin/GLLVM.jl/pull/190) @ `a8d19579`
  (Poisson Δ≈4.20e-9).
- 2026-08-05 — Post-NB1 hygiene **MERGED**
  [#187](https://github.com/itchyshin/GLLVM.jl/pull/187) @ `f230b372`
  (#189 closed as superseded).
- 2026-08-05 — NB1+X **live Δ proven** (local focused cell seed=48): abs
  Δ ≈ `1.531e-9`, rel Δ ≈ `1.379e-12` @ rtol `1e-6`.
- 2026-08-05 — NB1+X **combined Arc 1+2 MERGED**
  [#186](https://github.com/itchyshin/GLLVM.jl/pull/186) @ `a100cc63`.
- 2026-08-05 — NB1+X **identity Arc 0 MERGED**
  [#185](https://github.com/itchyshin/GLLVM.jl/pull/185) @ `210de76d`.
- 2026-08-05 — Board hygiene **merged** [#183](https://github.com/itchyshin/GLLVM.jl/pull/183) /
  [#184](https://github.com/itchyshin/GLLVM.jl/pull/184) @ `13d97b13`.
- 2026-08-04 — Ordinal+X **light RCall Arc 2 merged**
  [#181](https://github.com/itchyshin/GLLVM.jl/pull/181) @ `a92c5040`.
- 2026-08-04 — Ordinal+X **engine Arc 1 merged**
  [#180](https://github.com/itchyshin/GLLVM.jl/pull/180) @ `e4c20195`.
- 2026-08-03 — Ordinal+X identity Arc 0 **merged**
  [#179](https://github.com/itchyshin/GLLVM.jl/pull/179) @ `0630f8e4`.
- 2026-08-03 — Gamma+X stack **merged** [#178](https://github.com/itchyshin/GLLVM.jl/pull/178) @ `5f027f19`.
- 2026-08-03 — #177 **merged**; #176 **merged**.
- 2026-08-02 — NB2/Beta+X engine #175 / identity #174 / grouped #172 / MC #173 /
  X cohort #170 / default-route φ #169 **merged**.
