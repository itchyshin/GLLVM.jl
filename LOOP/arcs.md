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
| A2 | Live Gaussian logLik vs gllvmTMB | **DONE** (Δ≈9.8e-9; 30/30) | Rose claim fence |
| A2b | Bridge transport smoke | **DONE** | — |
| A3 | Binomial then Poisson logLik cells | **DONE** (Bin Δ≈1.8e-10; Pois Δ≈6.7e-9) | — |
| A4 | #132 / #148 dispersion alignment (Julia→R) | **DONE via parity routes** | grouped `1:p` (not shared default) |
| A5 | #133 ordinal location/cuts + probit oracle | **DONE** | **ordinal_probit** + observed Hess. |
| A6 | NB2 / Beta / Ordinal logLik cells after A4/A5 | **DONE** | NB2 ~2.5e-4; Beta ~6e-9; Ord ~5e-9 |
| Close | check-log + after-task + Rose + Melissa | **DONE** (this closeout) | claim fence |

## Sequencing (locked — completed)

1. ~~A0–A2 Gaussian~~  
2. ~~A3 Binomial → Poisson~~  
3. ~~OPEN GATE #132/#148/#133~~  
4. ~~A6 family cells on twin-aligned routes~~  

## Fenced out of arc

- #129 (CI scale), #128 (H² denom)  
- ADEMP, coverage, Totoro/DRAC, structured-source public claims  
- “Full family parity” / default shared-φ NB2·Beta / ordinal-logit twin claims  
