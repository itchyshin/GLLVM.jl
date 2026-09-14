# Destination B — G7 advisory Frozen R smoke (#323) scope + handoff

**Date:** 2026-09-14  
**Lane:** `cursor/honest-070-destb` @ `f3f09561`  
**Executor (G0 Q3):** **Codex on Totoro** — this Cursor slice is **scope + handoff only** (no SSH, no campaign).

## Problem statement

GitHub **#323** tracks three **advisory-red** R-side gradient-health cells on the
**Frozen R 0.7.0 family smoke** CI job (non-blocking; Julia 8/8 + Documenter remain
the merge gate). Failures are **not** Julia engine defects.

| Cell ID | Fixture | Predicate | Measured (2026-09-05 live R receipt) |
|---|---|---|---:|
| `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl` | `r_gradient_max ≤ 1e-4` | 1.348e-4 |
| `NATIVE-12-TRUNCATED-NB2` | `test/parity/test_truncated_nbinom2_parity.jl` (BFGS arm) | `bfgs_r_gradient_max ≤ 1e-4` | 6.466e-4 |
| `NATIVE-10-STUDENT` (fixed ν) | `test/parity/test_studentt_parity.jl` | `r_gradient_max ≤ 1e-4` | 2.508e-4 |

Prior disposition: [`advisory-smoke-fail-disposition-2026-09-05.md`](../core070/advisory-smoke-fail-disposition-2026-09-05.md) (#284).  
CI authority note: [`ci-oracle-reproducibility-finding.md`](../core070/ci-oracle-reproducibility-finding.md) — **retained pinned BUILD** is authority; CI **rebuilds source** and may red on R's own gradient even when Julia parity is fine.

## Frozen oracle pin (immutable for this programme)

| Field | Value |
|---|---|
| gllvmTMB git ref | `b4d5fee64def88bc768dda1f1f77c29b295edd86` |
| Contract | `docs/dev-log/core070/frozen-r070-contract.toml` (`reference_commit` same SHA) |
| R version (CI + receipts) | **4.5.3** |
| CRAN snapshot (CI) | Posit PPM `2026-08-31` noble (see `.github/workflows/CI.yml`) |

**Do not** edit gllvmTMB engine from GLLVM.jl lane. **Do not** widen Julia `@test` tolerances to absorb R gradient misses.

## CI job definition (mirror on Totoro)

Workflow: `.github/workflows/CI.yml` job **`test-parity`**  
Name: **Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)**  
Flags: `continue-on-error: true`

### Track A — full programme mirror (recommended receipt)

Reproduce the CI steps on Totoro (single Julia process; **D-50** — no concurrent heavy Julia).

```bash
# --- host prep (once per session) ---
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
cd /path/to/GLLVM.jl   # fetch origin/main or honest-070-destb after merge
git clone --depth 1 https://github.com/itchyshin/gllvmTMB.git .unlazy/r-source || true
cd .unlazy/r-source && git fetch origin b4d5fee64def88bc768dda1f1f77c29b295edd86 && git checkout b4d5fee64def88bc768dda1f1f77c29b295edd86 && cd ../..

# --- R oracle build (CI-equivalent; timeout 1200s in CI) ---
Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/2026-08-31")); install.packages("remotes"); remotes::install_deps(".unlazy/r-source", dependencies=c("Depends", "Imports", "LinkingTo"), upgrade="never")'
python3 tools/core070_build_oracle.py prepare --repo .unlazy/r-source --destination .unlazy/r-archive
python3 tools/core070_build_oracle.py build --archive .unlazy/r-archive/gllvmTMB-core070.tar --source-receipt .unlazy/r-archive/source.json --destination .unlazy/r-build --r-binary "$(command -v R)" --timeout 1200
python3 tools/core070_build_oracle.py verify --destination .unlazy/r-build

# --- Julia parity env ---
julia --project=test/parity -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); Pkg.build("RCall"); Pkg.precompile()'

mkdir -p .unlazy/core070-aghq/oracle-receipts .unlazy/core070-aghq/oracle-source
cp .unlazy/r-build/build.json .unlazy/core070-aghq/oracle-receipts/build.json
cp .unlazy/r-archive/source.json .unlazy/core070-aghq/oracle-source/source.json

export LD_PRELOAD="$(julia -e 'print(abspath(joinpath(Sys.BINDIR, "..", "lib", "julia", "libunwind.so.8")))')"
export GLLVM_PARITY_TESTS=1 CORE070_PARITY_REQUIRED=1
export GLLVM_PARITY_RECEIPT_DIR="$PWD/.unlazy/totoro-parity-receipts-$(date +%Y%m%d-%H%M%S)"
export R_LIBS="$PWD/.unlazy/r-build/library"
export GLLVM_PARITY_R_LIBS="$R_LIBS"
export GLLVM_PARITY_R_SOURCE_PIN="$R_LIBS/gllvmTMB/CORE070_SOURCE_PIN.toml"
export R_HOME="$(R RHOME)"
export LD_LIBRARY_PATH="$(R RHOME)/lib:$LD_LIBRARY_PATH"

julia --project=test/parity test/parity/runparity.jl
```

**Success criteria (Track A):**

1. Capture **full Test summary** + `GLLVM_PARITY_RECEIPT_DIR` tree (all `cell-*.toml/json`).
2. Record `installed_tree_sha256` from `.unlazy/r-build/build.json` vs retained Totoro receipt (if available under `.unlazy/core070-aghq/`).
3. For the three holdout cells, record measured `r_gradient_max` (and truncated NB2 `bfgs_r_gradient_max`).
4. **Outcome classes:**
   - **advisory-green:** all three predicates pass on this build → append JSON + propose #323 close *with maintainer sign-off* (still non-blocking until workflow policy changes).
   - **advisory-red (stable):** same three fail, same order of magnitude as 2026-09-05 → update [`advisory-frozen-r-smoke-2026-09-14.md`](../owed/advisory-frozen-r-smoke-2026-09-14.md) + comment on #323; **do not** close as “fixed”.
   - **advisory-red (new):** additional cells fail → file new disposition row; **do not** claim Julia regression without Δ evidence.

### Track B — narrow R-only refresh (optional, faster)

Historical Option D path (live 0.7.1 worktree) is **documented only** — **not** frozen oracle. For frozen holdouts, prefer Track A or run **only** the three Julia fixtures then inspect R health hashes in parity receipts:

```bash
# After same oracle build as Track A:
export GLLVM_PARITY_TESTS=1 CORE070_PARITY_REQUIRED=1
# ... same R_LIBS / LD_PRELOAD / thread exports ...
julia --project=test/parity -e '
  include("test/parity/parity_helpers.jl")
  core070_execute_case!("NATIVE-06-NB2", "test/parity/test_negbin_parity.jl", () -> include("test/parity/test_negbin_parity.jl"))
  core070_execute_case!("NATIVE-12-TRUNCATED-NB2", "test/parity/test_truncated_nbinom2_parity.jl", () -> include("test/parity/test_truncated_nbinom2_parity.jl"))
  core070_execute_case!("NATIVE-10-STUDENT", "test/parity/test_studentt_parity.jl", () -> include("test/parity/test_studentt_parity.jl"))
'
```

Reference (advisory live-R, **not** frozen): [`advisory-r-smoke-nb2-studentt-2026-09-05.md`](../core070/advisory-r-smoke-nb2-studentt-2026-09-05.md).

## D-139 compute estimate (paste before Totoro spend)

| Track | Wall clock (Totoro, 1 core, BLAS=1) | Notes |
|---|---:|---|
| **A** full `runparity.jl` + oracle build | **~90–150 min** | Dominated by R dep compile + TMB build; matches CI job shape |
| **B** oracle build + 3 cells | **~60–90 min** | Same build cost; shorter Julia parity |

**Risk:** second concurrent Julia on 16 GB VM GC-thrashes — **one Julia process only** (AGENTS.md).

**Maintainer gate:** Shinichi must acknowledge this estimate (G0 Q3 + STOP fence “No Totoro without D-139”) before Codex launches Track A/B.

## What NOT to claim if advisory stays red

- ≠ DestB **true parity** certificate or **FINAL-REVIEW** clearance.
- ≠ Julia NB2 Wald / T14 fix validation (Julia-side; already receipted G5).
- ≠ “frozen smoke green” in README, capability-status, or registration narrative.
- ≠ warrant to **block merge** on advisory job (policy unchanged unless maintainer explicitly promotes).
- ≠ evidence that **0.7.1** live R matches frozen **0.7.0** build (build hash mismatch is expected on CI rebuild).

## Codex deliverables (post-run)

1. After-task under `docs/dev-log/after-task/YYYY-MM-DD-frozen-r-smoke-totoro.md` with numbers table + artifact paths.
2. Append or sibling JSON receipt next to [`advisory-r-smoke-nb2-studentt-2026-09-05.json`](../core070/advisory-r-smoke-nb2-studentt-2026-09-05.json) if measurements refresh.
3. GitHub comment on **#323** linking receipt (no issue close unless advisory-green + maintainer decision).
4. **No** gllvmTMB `src/` edits; **no** Julia tolerance widening.

## G9 / G10 fence (ultra-plan)

- **G9 S4:** push-only authorised (G0 Q2); **no probe** until second yes — independent of #323.
- **G10 FINAL-REVIEW:** may proceed **in parallel** with Codex smoke using existing DestB receipts; smoke outcome does not auto-block FINAL-REVIEW unless Rose says otherwise.

## Cursor slice verification

Static read of #323, CI.yml, ultra-plan G7/G9, prior dispositions. **No Totoro SSH.** **No push.**

## Issue #323 closure rule

| Action | Closes #323? |
|---|---|
| This handoff doc only | **No** |
| Maintainer decision: keep advisory non-gating forever | **Yes** (document in issue + decision note) |
| Codex frozen-oracle refresh → all three predicates pass | **Yes** (with receipt + maintainer ack) |
| Codex refresh → still advisory-red, stable | **No** — update owed doc; leave open or convert to “won’t fix / non-gating” via maintainer |
