# Issue #323 — Totoro launch pack (Frozen R smoke, D-139)

**Date:** 2026-09-14  
**Status:** **READY** — awaits maintainer **`ack Totoro D-139`** (option **(A)** in [`2026-09-14-advisory-frozen-r-smoke-323-pending.md`](../decisions/2026-09-14-advisory-frozen-r-smoke-323-pending.md); **not** waived)  
**Issue:** [#323](https://github.com/itchyshin/GLLVM.jl/issues/323)  
**Executor:** Codex on **Totoro** (G0 Q3; Cursor lane does **not** SSH)  
**Upstream scope:** [`2026-09-14-destb-g7-frozen-r-smoke-handoff.md`](2026-09-14-destb-g7-frozen-r-smoke-handoff.md)

---

## Invoke pattern (compute-routing + D-139)

Per **compute-routing** skill §1 and vault **D-139**:

1. **Estimate first** (table below) — already recorded; maintainer reads before spend.
2. **>30 min** → full run requires maintainer approval **before** Codex launches.
3. **One-line ack** in chat (exact phrases below) — authorizes Totoro only; **≠** `waive #323`.
4. Codex runs the **Runner block** on Totoro; **one Julia process**; **D-50** (no GitHub Actions campaigns).
5. If wall clock exceeds the stated band by **>50%**, stop and re-report (D-139 overrun rule).

### Maintainer ack (paste one line)

| Intent | Paste exactly |
|---|---|
| **Default — full CI mirror (recommended)** | `ack Totoro D-139 #323 Track A` |
| **Narrow — oracle + 3 holdout cells only** | `ack Totoro D-139 #323 Track B` |
| **Minimal (Codex chooses Track A)** | `ack Totoro D-139` |

Until one of these lines appears in maintainer chat, **do not** SSH Totoro or start the oracle build.

---

## D-139 compute estimate (Totoro)

Standing conventions: **`OPENBLAS_NUM_THREADS=1`**, **`OMP_NUM_THREADS=1`**, **`JULIA_NUM_THREADS=1`**, **single Julia process** (second Julia on a 16 GB host GC-thrashes).

| Track | Wall clock (1 effective CPU for parity) | Core·hours (budget) | Dominant cost |
|---|---:|---:|---|
| **A** — full `runparity.jl` + oracle build | **~90–150 min** | **~1.5–2.5** | R `remotes::install_deps` + TMB compile (~45–90 min); full parity (~30–60 min) |
| **B** — same oracle build + 3 cells | **~60–90 min** | **~1.0–1.5** | Same build; Julia holdouts ~5–15 min |

**Note:** R package compilation may briefly use more than one core on the host; budget rows assume **one BLAS/Julia thread** for the parity phase (matches `.github/workflows/CI.yml` `test-parity`).

**Pre-run validation (optional, ~15–25 min, local or Totoro):** `python3 tools/core070_build_oracle.py verify --destination .unlazy/r-build` only after a prior successful build — not a substitute for Track A/B receipts.

---

## Frozen oracle pin (immutable)

| Field | Value |
|---|---|
| gllvmTMB git ref | `b4d5fee64def88bc768dda1f1f77c29b295edd86` |
| Contract | `docs/dev-log/core070/frozen-r070-contract.toml` (`reference_commit` same SHA) |
| R version | **4.5.3** (`R RHOME` must match) |
| CRAN snapshot | Posit PPM `https://packagemanager.posit.co/cran/__linux__/noble/2026-08-31` |

**Do not** edit gllvmTMB `src/` from the GLLVM.jl lane. **Do not** widen Julia `@test` tolerances for R gradient misses.

---

## Holdout cells (#323)

| Cell ID | Fixture | Pass predicate | 2026-09-05 baseline (advisory-red) |
|---|---|---|---:|
| `NATIVE-06-NB2` | `test/parity/test_negbin_parity.jl` | `r_gradient_max ≤ 1e-4` | 1.348e-4 |
| `NATIVE-12-TRUNCATED-NB2` | `test/parity/test_truncated_nbinom2_parity.jl` | `bfgs_r_gradient_max ≤ 1e-4` | 6.466e-4 |
| `NATIVE-10-STUDENT` | `test/parity/test_studentt_parity.jl` | `r_gradient_max ≤ 1e-4` | 2.508e-4 |

Prior disposition: [`advisory-smoke-fail-disposition-2026-09-05.md`](../core070/advisory-smoke-fail-disposition-2026-09-05.md) (#284).

---

## Codex runner (Totoro)

**Workspace (adjust if your clone differs):**

```bash
export GLLVM_ROOT="${GLLVM_ROOT:-$HOME/hsq_work/GLLVM.jl}"
export TRACK="${TRACK:-A}"   # set B for narrow run
export RECEIPT_STAMP="$(date +%Y%m%d-%H%M%S)"
```

**0 — Host prep (once per session)**

```bash
set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1

cd "$GLLVM_ROOT"
git fetch origin main
git checkout origin/main   # pin to merge SHA that contains this launch pack

# Ubuntu geo stack (CI-equivalent; skip if already installed)
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends \
    libudunits2-dev libgdal-dev libgeos-dev libproj-dev
fi
```

**1 — Frozen R source @ pin**

```bash
cd "$GLLVM_ROOT"
mkdir -p .unlazy
if [[ ! -d .unlazy/r-source/.git ]]; then
  git clone https://github.com/itchyshin/gllvmTMB.git .unlazy/r-source
fi
cd .unlazy/r-source
git fetch origin b4d5fee64def88bc768dda1f1f77c29b295edd86
git checkout b4d5fee64def88bc768dda1f1f77c29b295edd86
cd "$GLLVM_ROOT"
```

**2 — Build isolated oracle (CI mirror; timeout 1200s)**

```bash
cd "$GLLVM_ROOT"
Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/2026-08-31")); install.packages("remotes"); remotes::install_deps(".unlazy/r-source", dependencies=c("Depends", "Imports", "LinkingTo"), upgrade="never")'

python3 tools/core070_build_oracle.py prepare \
  --repo .unlazy/r-source --destination .unlazy/r-archive
python3 tools/core070_build_oracle.py build \
  --archive .unlazy/r-archive/gllvmTMB-core070.tar \
  --source-receipt .unlazy/r-archive/source.json \
  --destination .unlazy/r-build \
  --r-binary "$(command -v R)" \
  --timeout 1200
python3 tools/core070_build_oracle.py verify --destination .unlazy/r-build
```

**3 — Julia parity env + staged receipts**

```bash
cd "$GLLVM_ROOT"
julia --project=test/parity -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); Pkg.build("RCall"); Pkg.precompile()'

mkdir -p .unlazy/core070-aghq/oracle-receipts .unlazy/core070-aghq/oracle-source
cp .unlazy/r-build/build.json .unlazy/core070-aghq/oracle-receipts/build.json
cp .unlazy/r-archive/source.json .unlazy/core070-aghq/oracle-source/source.json
```

**4 — Parity env exports**

```bash
cd "$GLLVM_ROOT"
export LD_PRELOAD="$(julia -e 'print(abspath(joinpath(Sys.BINDIR, "..", "lib", "julia", "libunwind.so.8")))')"
export GLLVM_PARITY_TESTS=1
export CORE070_PARITY_REQUIRED=1
export GLLVM_PARITY_RECEIPT_DIR="$GLLVM_ROOT/.unlazy/totoro-parity-receipts-${RECEIPT_STAMP}"
export R_LIBS="$GLLVM_ROOT/.unlazy/r-build/library"
export GLLVM_PARITY_R_LIBS="$R_LIBS"
export GLLVM_PARITY_R_SOURCE_PIN="$R_LIBS/gllvmTMB/CORE070_SOURCE_PIN.toml"
export R_HOME="$(R RHOME)"
export LD_LIBRARY_PATH="$(R RHOME)/lib:${LD_LIBRARY_PATH:-}"
mkdir -p "$GLLVM_PARITY_RECEIPT_DIR"
```

**5a — Track A (full programme)**

```bash
cd "$GLLVM_ROOT"
julia --project=test/parity test/parity/runparity.jl | tee "$GLLVM_PARITY_RECEIPT_DIR/runparity.log"
```

**5b — Track B (three holdouts only)**

```bash
cd "$GLLVM_ROOT"
julia --project=test/parity -e '
  include("test/parity/parity_helpers.jl")
  for (id, fix) in (
    ("NATIVE-06-NB2", "test/parity/test_negbin_parity.jl"),
    ("NATIVE-12-TRUNCATED-NB2", "test/parity/test_truncated_nbinom2_parity.jl"),
    ("NATIVE-10-STUDENT", "test/parity/test_studentt_parity.jl"),
  )
    core070_execute_case!(id, fix, () -> include(joinpath("test/parity", basename(fix))))
  end
' | tee "$GLLVM_PARITY_RECEIPT_DIR/track-b.log"
```

---

## Success / fail predicates

### Campaign **FAIL** (stop; file after-task as blocked)

- `core070_build_oracle.py verify` exits non-zero.
- Julia/RCall fails to precompile or `runparity.jl` / Track B throws before receipts exist.
- `R` version ≠ **4.5.3** or gllvmTMB checkout ≠ **`b4d5fee6`**.

### Outcome classes (after receipts exist)

| Class | Condition | #323 action |
|---|---|---|
| **advisory-green** | All three holdouts meet **≤ 1e-4** on this build | Append receipt + GitHub comment; propose close **with maintainer sign-off** (CI job still `continue-on-error` until policy changes). |
| **advisory-red (stable)** | Same three cells fail; magnitudes within **~0.5–2×** of 2026-09-05 table | Update [`advisory-frozen-r-smoke-2026-09-14.md`](../owed/advisory-frozen-r-smoke-2026-09-14.md); comment on #323; **do not** close as fixed. |
| **advisory-red (new)** | Additional cells fail or magnitudes **>10×** drift | New disposition row in core070 advisory docs; **no** Julia regression claim without Δ evidence. |

Extract holdout metrics from parity receipts:

```bash
rg -n 'r_gradient_max|bfgs_r_gradient_max' "$GLLVM_PARITY_RECEIPT_DIR"
# and/or per-cell TOML:
ls "$GLLVM_PARITY_RECEIPT_DIR"/cell-*.toml 2>/dev/null || ls "$GLLVM_PARITY_RECEIPT_DIR"/*.toml
```

Record `installed_tree_sha256` from `.unlazy/r-build/build.json` (compare to retained Totoro receipt under `.unlazy/core070-aghq/oracle-receipts/` if present).

---

## Artifact paths (retain and scp back)

| Artifact | Path |
|---|---|
| Parity receipt tree | `$GLLVM_PARITY_RECEIPT_DIR/` (env set in step 4) |
| Oracle build receipt | `$GLLVM_ROOT/.unlazy/r-build/build.json` |
| Oracle source receipt | `$GLLVM_ROOT/.unlazy/r-archive/source.json` |
| R install log | `$GLLVM_ROOT/.unlazy/r-build/install.log` |
| Run log | `$GLLVM_PARITY_RECEIPT_DIR/runparity.log` or `track-b.log` |
| JSON sibling (refresh) | `docs/dev-log/core070/advisory-r-smoke-nb2-studentt-2026-09-05.json` (append dated sibling, do not overwrite) |

**Pull example (from laptop, after Codex run):**

```bash
scp -r totoro:"$GLLVM_PARITY_RECEIPT_DIR" ./docs/dev-log/core070/totoro-receipts-issue323-${RECEIPT_STAMP}/
```

---

## Codex deliverables (post-run)

1. After-task: `docs/dev-log/after-task/YYYY-MM-DD-frozen-r-smoke-totoro.md` — numbers table + artifact paths + outcome class.
2. GitHub comment on **#323** linking receipts (no close unless **advisory-green** + maintainer decision).
3. Optional JSON refresh next to [`advisory-r-smoke-nb2-studentt-2026-09-05.json`](../core070/advisory-r-smoke-nb2-studentt-2026-09-05.json).
4. **No** gllvmTMB engine edits; **no** Julia tolerance widening.

---

## Rose fences (unchanged)

- ≠ DestB **true parity** or FINAL-REVIEW clearance by smoke alone.
- ≠ “frozen smoke green” on `main` unless measured values cross **1e-4** (or predicates revised elsewhere).
- ≠ warrant to block merge on advisory CI (Julia **8/8 + Documenter** remain gate).

---

## Cursor slice record

- **Built:** executable launch pack for #323; **no** Totoro SSH; **no** waiver.
- **Verification:** static alignment with G7 handoff, `CI.yml` `test-parity`, pending decision **(A)/(B)/(C)**.
