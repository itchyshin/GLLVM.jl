# Destination B — G7 Track B local frozen-R smoke (narrow three-cell)

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb` @ `7eee6fc2`  
**Executor:** Cursor Ada slice (local probe only; **no Totoro spend**)

## Outcome

**BLOCKED → Totoro** — frozen oracle build not present on this machine; CI-equivalent build would exceed the 30-minute local progress fence before any cell could run.

## Scope attempted

Track B only (per [`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](2026-09-14-destb-g7-frozen-r-smoke-handoff.md)): after frozen oracle build, run three holdout cells:

| Cell ID | Fixture |
|---|---|
| `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl` |
| `NATIVE-12-TRUNCATED-NB2` | `test/parity/test_truncated_nbinom2_parity.jl` |
| `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl` |

**Not run:** Track A full `runparity.jl`.

## Local environment probe (evidence)

| Check | Result |
|---|---|
| R on PATH | `/usr/local/bin/R` — **R 4.6.0** (2026-04-24) |
| Contract R (CI + receipts) | **4.5.3** + Posit PPM `2026-08-31` noble |
| `.unlazy/r-build/build.json` | **missing** (no prebuilt frozen oracle) |
| `.unlazy/r-source` at pin `b4d5fee6` | **missing** (not cloned in this checkout) |
| gllvmTMB pin object (sibling repo) | `commit` exists locally (sibling @ `1133ce35f`, not built into `R_LIBS`) |
| Handoff D-139 Track B estimate | **~60–90 min** wall (oracle build dominates) |

## Why STOP (not FAIL)

1. **No oracle artifact** — Track B requires the same `core070_build_oracle.py` pipeline as CI (`prepare` → `build` → `verify`). Without `.unlazy/r-build`, parity env vars (`R_LIBS`, `GLLVM_PARITY_R_SOURCE_PIN`) cannot be set honestly.
2. **Time fence** — maintainer slice rule: if local R/oracle missing or **>30 min without progress**, STOP; do not invent pass. Build alone is budgeted 60–90 min on Totoro-class host.
3. **R version skew** — local **4.6.0** vs pinned receipt **4.5.3**; even after build, numbers would not be CI-comparable without matching toolchain (Totoro/CI).

## Smoke-first one cell

**Not attempted** — blocked at oracle prerequisite.

## Next owner (Codex / Totoro)

Execute Track A or Track B from handoff after **D-139 maintainer ack** (G0 Q3). Deliverables unchanged: measured `r_gradient_max` / `bfgs_r_gradient_max` for the three cells, receipt JSON, GitHub comment on **#323** — **no** issue close unless advisory-green + maintainer decision.

## Claims fence

- ≠ advisory-green / #323 closed
- ≠ DestB true parity or FINAL-REVIEW clearance
- ≠ evidence that Julia regressed (no cells executed)

## Verification

Static probe + filesystem checks only. **No** `julia --project=test/parity` parity run on this slice.
