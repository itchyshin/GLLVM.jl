# Arcs — gllvm-jl-catchup-loglik

Binding arc ids follow the `/goal` launch contract (inventory = A1, Gaussian headline = A2).
Plan file slice table remains authoritative detail in `ultra-plan.md`.

**Recon citations (do not re-inventory):**
- A1: `docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md` → `LOOP/notes/A1-correctness-inventory.md`
- A2 call shape: `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md` → `LOOP/notes/A2-rcall-callshape-audit.md`

| Arc | Intent | Status | Gate |
|---|---|---|---|
| A0 | Lane from `origin/main` + twin main; re-run capability-drift probe; record SHAs + n_drift | **DONE** (`n_drift=0`, `unregistered=0`) | — |
| A1 | Correctness inventory folded from scout note | **DONE** (Bin/Pois clear; #132/#148/#133 gate; #129/#128 fenced) | — |
| A2 | **HEADLINE** — live Gaussian logLik vs gllvmTMB | **DONE** (ΔlogLik ≈ 9.78e-9; 30/30) | Rose before README/board claim upgrade |
| A2b | Bridge transport smoke (JuliaCall) without heavy fits | PENDING / parallel | — |
| A3 | Binomial then Poisson fixed-seed logLik cells | **NEXT** | — |
| A4 | #132 / #148 dispersion alignment (Julia→R) | PENDING | **OPEN GATE** — API/param; blocks default NB2/Beta |
| A5 | #133 ordinal location/cuts alignment | PENDING | **OPEN GATE** — API/param; blocks Ordinal |
| A6 | NB2 / Beta / Ordinal logLik cells after A4/A5 | PENDING — do **not** open before OPEN GATE | claim fence |
| Close | check-log + after-task + Rose + Melissa reconcile | PARTIAL (A2 after-task written) | — |

## Sequencing (locked)

1. ~~A0 hygiene + drift receipt~~  
2. ~~A2 Gaussian transport green~~  
3. **A3 Binomial → Poisson**  
4. **STOP** at OPEN GATE before #132/#148/#133  
5. Only then A6 family cells  

## Fenced out of arc

- #129 (CI scale), #128 (H² denom) — inference/derived only  
- ADEMP, coverage, Totoro/DRAC, structured-source public claims  
