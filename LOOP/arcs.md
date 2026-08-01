# Arcs — gllvm-jl-catchup-loglik

Binding arc ids follow the `/goal` launch contract (inventory = A1, Gaussian headline = A2).
Plan file slice table remains authoritative detail in `ultra-plan.md`.

**Recon citations (do not re-inventory):**
- A1: `docs/dev-log/plans/scratch/2026-08-01-correctness-inventory.md` → `LOOP/notes/A1-correctness-inventory.md`
- A2 call shape: `docs/dev-log/plans/scratch/2026-08-01-gaussian-rcall-shape.md` → `LOOP/notes/A2-rcall-callshape-audit.md`

| Arc | Intent | Status | Gate |
|---|---|---|---|
| A0 | Lane from `origin/main` + twin main; drift probe | **DONE** (`n_drift=0`) | — |
| A1 | Correctness inventory folded from scout note | **DONE** | — |
| A2 | Live Gaussian logLik vs gllvmTMB | **DONE** (Δ≈9.8e-9; 30/30) | Rose before board claim upgrade |
| A2b | Bridge transport smoke | **DONE** | — |
| A3 | Binomial then Poisson logLik cells | **DONE** (Bin Δ≈1.8e-10; Pois Δ≈6.7e-9) | — |
| A4 | #132 / #148 dispersion alignment (Julia→R) | PENDING | **OPEN GATE** — API/param; blocks default NB2/Beta |
| A5 | #133 ordinal location/cuts alignment | PENDING | **OPEN GATE** — API/param; blocks Ordinal |
| A6 | NB2 / Beta / Ordinal logLik cells after A4/A5 | PENDING — do **not** open before OPEN GATE | claim fence |
| Close | check-log + after-task + Rose + Melissa reconcile | PARTIAL (A2+A3 after-tasks written) | — |

## Sequencing (locked)

1. ~~A0–A2 Gaussian~~  
2. ~~A3 Binomial → Poisson~~  
3. **STOP** at OPEN GATE before #132/#148/#133  
4. Only then A6 family cells  

## Fenced out of arc

- #129 (CI scale), #128 (H² denom)  
- ADEMP, coverage, Totoro/DRAC, structured-source public claims  
