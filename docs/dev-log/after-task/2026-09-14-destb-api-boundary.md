# Destination B — `API-BOUNDARY` static audit (G1)

**Date:** 2026-09-14  
**Lane:** `honest-070-destb` (Cursor Ada)  
**Branch:** `cursor/honest-070-destb` (includes LOOP post-#334 sync)  
**Rehydrate base:** `origin/main` @ `23fd0496`  
**Frozen oracle:** gllvmTMB 0.7.0 `b4d5fee64def88bc768dda1f1f77c29b295edd86`

## Scope

Static **API-BOUNDARY** gate for Destination B: confirm the reconciled **32-row**
scope identity matches the signed gate-tier list, document the **public Julia API
admission fence** for those rows (what users may invoke vs what the programme must
not claim), and record negative controls. No fit, optimizer, R/TMB call, or
`Pkg.test()` full suite.

Complements (does not replace) `docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md`
(B1/S3b/S4 process lines only).

## Evidence (commands run)

```sh
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/GLLVM.jl"
node tools/destination_b_scope_check.mjs
rg '^version = ' Project.toml
rg 'experimental partial R-to-Julia bridge' README.md
rg 'b4d5fee64def88bc768dda1f1f77c29b295edd86' docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md
```

**Scope checker:** exit 0; printed `enumerated: 32`, counts A15/B4/C5/D8, oracle hash
match, trailing line `SCOPE_HISTORY_AND_NEGATIVE_CONTROLS_PASS`.

**Version fence:** `Project.toml` → `version = "0.3.0"` (unchanged; no bump in-programme).

**Public wording fence:** README line 12 — *"GLLVM.jl remains an experimental partial
R-to-Julia bridge, not 0.7 parity."* Destination B qualification explicitly *in progress*
(lines 7–11).

## Verdict

**`API-BOUNDARY` — STATIC PASS** for scope identity + documented public API fence.
This is **not** `FINAL-REVIEW`, **not** row-level parity qualification, and **not**
capability-status promotion (G2).

## Public API surfaces (programme boundary)

| Surface | Role in DestB 32-row scope | Admission fence |
|---|---|---|
| `gllvm` / `fit_gllvm` / family fitters | Primary **native** route (NAT) for A-rows, D6/D7 input contracts | Status-gated per `docs/design/capability-status.md`; Arc 0 covariance wrappers exist in `src/` but ledger rows may still read `planned` until Rose G2 |
| `bridge_fit` / `bridge_capabilities` | **Bridge** route (BRG) for R→Julia JuliaCall flat contract (`src/bridge.jl`, exported last in module) | Experimental; not generic 0.7 admission; S3b consumer narrowly fenced in G2 closeout |
| `fit_gllvm(...; grouping=..., unit=...)` | B-rows (four named grouping levels) | Vocabulary fixed (`_GROUPING_TERM_NAMES`); B1 Wald grouping curvature **closed-as-limit** (G0 Q1); not full grouping programme qualification |
| `destination_b_*` postfit / fixed-effect helpers | D2–D5 extractor spine where implemented | Destination-B-specific; not blanket public 0.7 parity |
| Arc 0 `fit_*_dep_gllvm` / `fit_*_latent_gllvm` / kernel/spatial scaffolds | **Outside** the 32-row DestB list (honest-0.7 grid parallel track) | Must not be read as DestB row receipts; promotion deferred to G2 |

**Claim direction (T1):** qualification evidence is **one-directional** (R workflow → Julia).
Reverse gaps are tool-dispositioned (`D8`), not Julia lane debt.

## 32-row static route map (summary)

Authoritative row names: `docs/dev-log/core070/true-parity-gate-tier-2026-09-05.md`.
Checker binds names + oracle only (`destination_b_scope_check.mjs`).

| Block | Rows | Primary Julia/API path | DestB static boundary note |
|---|---|---|---|
| **A** families + ordination/phylo cov | A1–A11 | `fit_gllvm` / `gllvm` + family fitters; BRG via `bridge_fit` where bridge receipts exist | 1FO/2SO/RSZ tiers are **receipt classes**, not satisfied by this audit; A14/A15 phylo latent sequenced post transport; S4 public formula **held** (arc #3) |
| **B** grouping | B1–B4 | `grouping` terms + `bridge_fit` kwargs `unit` / `unit_obs` / `cluster` / `cluster2` | Name parity + adapter scope; B1 interface limit permanent; B1-RECOVERY **NOT AUTHORIZED** |
| **C** real-data | C1–C5 | `engine = "julia"` workflows (future); scouts only today | T7 blocked on gllvmTMB #1236; no public “real-data parity done” claim |
| **D** bridge spine + extractors | D1–D8 | `bridge_fit`, StatsAPI postfit (`predict`, `vcov`, `confint`, …), `tools/parity_ledger.py` for D8 | D1 meta-receipt template; D2–D5 subject to T3 second-order scope; D8 R-lane owned |

**Numerical gates unchanged:** B1-JOINT-*, B1-RECOVERY (off), S4-PUBLIC-FORMULA (held),
S3B-CONSUMER (done on #318 with narrow fence). See `docs/dev-log/2026-09-13-destination-b-g2-closeout.md`.

## Rose review (static)

- Scope enumeration matches signed history — **OK**
- No silent upgrade from harness/Arc 0 to DestB parity — **OK** (README + this receipt)
- `Project.toml` version untouched — **OK**
- No S4 probe, no gllvmTMB engine edit — **OK**

**Remaining blockers before `FINAL-REVIEW`:** G2 capability promotion, T13–T15 hygiene,
#323 advisory smoke (Totoro), S4 push/probe per G0 Q2, joint decision note (G11).

## What this slice did not do

- Edit `docs/design/capability-status.md` (G2)
- Run Totoro / DRAC campaigns
- Push gllvmTMB S4 recorder
- Merge to `main` or open a ready-for-review PR
