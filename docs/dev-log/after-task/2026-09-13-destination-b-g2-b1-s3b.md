# After-task — Destination B G2 lines 1+2: B1 curvature + S3b consumer

**Date:** 2026-09-13
**Worktree:** `/private/tmp/destination-b-b1-integration-20260910`
**Branch:** `codex/destination-b-b1-integration-20260910`
**Oracle:** `gllvmTMB` 0.7.0 @ `b4d5fee64def88bc768dda1f1f77c29b295edd86`
**Authority:** Shinichi authorised **G2 lines 1+2** (B1 curvature; S3b
end-to-end consumer) and **push**. S4/line 3 explicitly NOT authorised.
Preceded by the G1 static audit at
`docs/dev-log/2026-09-13-destination-b-g1-audit-matrix.md` (HEAD `46ec66d8`
at session start).

## Scope

This session ran the two G2-authorised numerical lines only:

1. **Step A — push.** `git push -u origin HEAD` from the isolated worktree.
2. **Step B — B1 fixed-point-marginal curvature.** One authorised capture
   materialization, then one authorised `TMB::sdreport` evaluation attempt.
3. **Step C — S3b end-to-end adapter consumer.** Ran the existing (not
   previously executed) `test/test_destination_b_adapter_consumer.jl`.

S4/line 3, twin (R) testing beyond the frozen oracle, any second B1 attempt,
and any `AGENTS.md` snapshot edit were explicitly out of scope and not
attempted.

## Step A — push

Ran a clean lane-preflight check first (confirmed this branch as the
intended lane, and the HOLD JSON as the only pre-existing untracked file
before this session's own new artifacts), then, after Steps B and C below
(actual execution order in this session; the push itself does not depend on
B/C having run first):

```sh
git push -u origin HEAD
```

```
remote: Create a pull request for 'codex/destination-b-b1-integration-20260910' on GitHub by visiting:
remote:      https://github.com/itchyshin/GLLVM.jl/pull/new/codex/destination-b-b1-integration-20260910
To github.com:itchyshin/GLLVM.jl.git
 * [new branch]      HEAD -> codex/destination-b-b1-integration-20260910
branch 'codex/destination-b-b1-integration-20260910' set up to track 'origin/codex/destination-b-b1-integration-20260910'.
```

New branch, not behind, not rejected. No `--force`. No merge to `main`. No
PR opened (not asked for). The protected HOLD JSON stayed untracked and was
not pushed (this push carried only the 88 pre-existing local commits up to
`46ec66d8`; today's new artifacts were committed and pushed separately after
this, see "Files created / modified" below and the final commit log).

## Step B — B1 fixed-point-marginal curvature (line 1)

### Pre-flight

- Confirmed the local R/TMB toolchain matches the protocol's pinned hashes
  exactly (not merely "installed"): `TMB` 1.9.21 DESCRIPTION SHA-256
  `937932be51fc4e954ac25430756885f68a135260e263c5403e768315de73e49b`,
  `TMB.so` SHA-256 `8b387ebacb98a81c2d02b3aab701690ed4ed83b5fc46f6d0cd53d87577dd35d0`,
  frozen `gllvmTMB.so` SHA-256
  `3b6e7b63e072506d78ca5e468c1478758fa9aae333757b74c1f651cfab81da30`. All
  three matched `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.toml`
  and the tracked evaluator's own hardcoded pins bit-for-bit.
- Confirmed the tracked evaluator
  (`tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R`)
  still hashes to the protocol-pinned `58d7eeb16f69108a8974053b319ce1381e63179ab2a1adb97867cbc6dc58afb8`
  — it was read, never edited.

### Capture materialization (protocol-required; real, not invented)

The protocol's `[capture_rds]` block recorded
`materialization_status = "UNRESOLVED_NO_CAPTURE_MATERIALIZATION_AUTHORIZED"`
and `execution_ready = false` at session start — capture materialization had
never happened. Per the explicit instruction ("materialize capture only if
protocol requires and path is real — do not invent RDS/hash"):

1. **Safe structural probe first** (no optimizer, no theta_star evaluation):
   verified, via a throwaway interactive script
   (`/tmp/probe_makeadfun_env.R`, not retained as evidence), that
   `TMB::MakeADFun`'s object exposes `env$data`, `env$parameters`,
   `env$random`, `env$map`, `env$DLL` in exactly the shape the evaluator's
   `assert_frozen_capture()`/`reconstruct_frozen_object()` expect, and that
   `names(obj$par)` already matches `FIXED_RAW_NAMES` at construction time
   (a structural property of the formula+data, independent of the fitted
   point).
2. **Live materialization** (the actual authorised capture step): a new
   live-execution script outside the repo,
   `/private/tmp/b1-fixed-point-marginal-capture-materialize-20260913.R`
   (SHA-256 `ea6bcd9adf599719155e1d9dfeff8b7ca794bd9165a51fba050a07b77b02f5f6`),
   reproduces the exact fixture (seed `20260914L`, identical generative code
   to `tools/destination_b/b1_joint_gaussian_stationary_reference.R`),
   re-verifies `data_md5 == 8d61143f2ce6102bb8460fb1575cc249` before doing
   anything else, then uses the same `trace("MakeADFun", ..., exit = ...)`
   interception already used (and already reviewed/retained) for the earlier
   `fixed_coordinate` HOLD to stop `gllvmTMB::gllvmTMB()` **immediately after**
   `MakeADFun` returns and **before** any optimizer dispatch. Verified
   `outer_optimizer_calls = 0` structurally (the `stop()` inside the trace's
   `exit` hook fires before `gllvmTMB` can call `nlminb`/`optim`), plus
   `identical(names(obj$par), FIXED_RAW_NAMES)`, DLL name (`"gllvmTMB"`), and
   resolved DLL path identity.
3. Captured `data`, `parameters`, `DLL`, `dll_path`, `random`, `map` from
   `obj$env`; embedded `provenance = list(formula=, data_md5=, source_git_sha=)`
   and the **pre-registered, already-known** `raw_opt_par` (the frozen
   fixed point from the earlier stationary receipt — not derived from this
   run's own optimizer, since none ran).
4. Reserve-wrote (no clobber) the capture once at the protocol's
   `canonical_path`:
   `docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds`
   (8,348 bytes).
5. Computed three **real** hashes with the evaluator's own hash functions
   (`sha256_file`, `sha256_object` — `saveRDS(..., version = 2)` then
   SHA-256 the temp file):
   - `capture_sha256 = f8cf69e10f1374e40afc1e541942544c4499e89f3b054f94254d8183689374f4`
   - `data_sha256 = cd8b6a2a84c4cb042ae8865facd04709ea738871a0db5427114049d158260b62`
   - `map_sha256 = 80c96432589e315392219b9d2e36214bd605d743b6d110ebe8f7215155899cbf`

### Evaluator run (the one authorised sdreport attempt)

The git-tracked evaluator's three hash constants
(`FIXED_CAPTURE_RDS_SHA256`, `FIXED_CAPTURE_DATA_SHA256`,
`FIXED_CAPTURE_MAP_SHA256`) are literal
`"UNRESOLVED_PENDING_CAPTURE_MATERIALIZATION"` placeholders and were **not
edited in the repo** — they are a fail-closed pre-run contract that must stay
that way in the committed tree, matching the protocol's own
`execution_ready = false` invariant (never flipped). Instead, a
live-execution copy was made **outside the repo**, mirroring the precedent
already set by the `fixed_coordinate` pair's own evaluator path
(`/private/tmp/b1-fixed-coordinate-curvature-evaluate-20260910.R`):

- `/private/tmp/b1-fixed-point-marginal-curvature-evaluate-20260913.R`
  (SHA-256 `0062993ec9c910a858495ce358c1bed10f9994ef616da590b19fc08b231059c8`).
  `diff` against the tracked file confirmed **exactly three lines changed**
  (the three hash constants; nothing else).

Ran **exactly once**:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 \
  Rscript --vanilla /private/tmp/b1-fixed-point-marginal-curvature-evaluate-20260913.R \
  --capture docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds \
  --output docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json
```

Exit 0. Wall time ≈1.4 s (the evaluator's own `HARD_STOP_SECONDS <- 60` never
came close to firing).

### Result — FAILED, retained honestly

```json
{
  "status": "FAILED",
  "stage": "fixed_point_marginal_curvature",
  "failure": {
    "class": "simpleError",
    "message": "A map factor length must equal parameter length"
  }
}
```

Retained at
`docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json`.
No `outputs` (empty, per the schema's `FAILED` branch — `cov.fixed`,
`pdHess`, `gradient.fixed` were never computed). The error fires inside
`reconstruct_frozen_object()`, i.e. the plain
`TMB::MakeADFun(data=, parameters=, DLL=, random=, map=)` reconstruction of
the captured inputs — **one step earlier** than the direct-Hessian HOLD's
`obj$he()` failure. This is a genuine finding, not a bug to patch and rerun:
the captured `map` (a list of TMB `factor()` objects, built implicitly inside
`gllvmTMB::gllvmTMB()`'s own construction path) does not reconstruct
correctly through an independent, out-of-pipeline `MakeADFun()` call. Per
"NEVER retry", no second attempt was made, and none should be, without a
fresh, separate maintainer decision naming a different reconstruction
strategy (e.g. capturing `obj$env$last.par`/`parList` structure alongside the
map, or reconstructing via gllvmTMB's own internal builder rather than a bare
`MakeADFun` call).

**Disposition:** this receipt is now **PROTECTED**, exactly like the earlier
`fixed_coordinate` HOLD — never staged over, edited, deleted, or retried
without a fresh maintainer decision. It does **not** establish B1 Wald
inference, B1 qualification, or anything about curvature/singularity; like
its predecessor, it is an interface/reconstruction limitation.

The pre-existing
`docs/dev-log/core070/destination-b-b1/fixed-coordinate-curvature-diagnostic-20260910.json`
HOLD was confirmed untouched throughout (byte-identical, still untracked
until this session's commit intentionally leaves it that way).

## Step C — S3b end-to-end adapter consumer (line 2)

`test/test_destination_b_adapter_consumer.jl` had been positively identified
in the G1 audit as real (calls `GLLVM.bridge_fit(...)` with a live Julia
optimizer against tree/pedigree/dense-`vcv` fixtures) but had never been
executed. Ran it in an isolated ephemeral Julia environment
(`/tmp/s3b-consumer-env`, built via `Pkg.develop(path=...)` +
`Pkg.add(["JSON3","SHA"])`) so the repo's own `Project.toml`/`Manifest.toml`
were not modified (JSON3 is a test-only dependency declared in
`test/Project.toml`, normally merged only by the full `Pkg.test()` run).

```
Test Summary:                                 | Pass  Total  Time
Actual R adapter multivariate bridge consumer |   97     97  7.4s
```

**Versions/host:** Julia 1.10.0; macOS 26.6.2 (Darwin 25.6.0, arm64,
`w-kw3k3y6229.psych.ualberta.ca`).

No new artifact was written by the test itself
(`GLLVM_DESTINATION_B_BRIDGE_RECEIPT` env var was left unset, so its optional
receipt-dump branch did not fire).

**What this does and does not establish.** This is the first time this
session (or, per the G1 matrix, this worktree) that "the S3b consumer works"
has actual passing evidence behind it for the tree, pedigree-with-ancestors,
and dense-`vcv` fixtures — matched point estimates, log-likelihoods, and all
12 named Wald interval endpoints per fixture against frozen R-derived
fixtures, to the test's own tolerances (`atol`/`rtol` 1e-5 to 1e-8 depending
on the quantity). It does **not** by itself flip the `S3B-CONSUMER` ledger
gate to qualified — per the G1 matrix, that gate still needs a maintainer
sign-off pass on top of a passing run — and it remains adapter/test-only
per the 2026-09-08 authorisation (no `gllvmTMB` C++ or likelihood-engine
change; the frozen R fixtures were consumed, not regenerated).

## Files created / modified

- `docs/dev-log/core070/destination-b-b1/b1-fixed-point-marginal-capture.rds`
  (new, 8,348 bytes) — the materialized capture.
- `docs/dev-log/core070/destination-b-b1/fixed-point-marginal-curvature-diagnostic-20260913.json`
  (new) — the FAILED receipt. **PROTECTED going forward.**
- `docs/dev-log/check-log.md` — this session's entry appended.
- `docs/dev-log/after-task/2026-09-13-destination-b-g2-b1-s3b.md` — this
  report.
- `LOOP/checkpoint.md` — updated to reflect G2 lines 1+2 closure.
- **Not modified:** `tools/destination_b/b1_fixed_point_marginal_curvature_evaluator.R`,
  `docs/dev-log/protocols/b1-fixed-point-marginal-curvature-audit.toml`,
  `.unlazy/**` gate `CHECK`/`EVIDENCE` fields (no numerical gate flipped to
  qualified), `AGENTS.md`, any file under PR #314's lane, the pre-existing
  `fixed-coordinate-curvature-diagnostic-20260910.json` HOLD, `Project.toml`,
  `Manifest.toml`.
- Live-execution scripts (outside the repo, not committed, per the
  established `fixed_coordinate`-pair precedent):
  `/private/tmp/b1-fixed-point-marginal-capture-materialize-20260913.R`,
  `/private/tmp/b1-fixed-point-marginal-curvature-evaluate-20260913.R`.

## Ledger impact

No `.unlazy/destination-b-programme/GATES.md` gate is checked off by this
session. `B1-JOINT-STATIONARY`, `B1-JOINT-PAIR`, `B1-RECOVERY`, and
`S4-PUBLIC-FORMULA` remain exactly as before (pending / NOT AUTHORIZED); the
B1 curvature attempt was a narrower, separately-scoped diagnostic (per the
`b1-fixed-point-marginal-curvature-audit.toml` protocol) than any of those
three gates, and it FAILED. `S3B-CONSUMER` gains its first passing
end-to-end run but is left as "pending maintainer sign-off", not flipped to
qualified, per the instruction not to `--reverify --approve` any gate.

## Next ask for Shinichi

1. **B1 reconstruction strategy.** The `fixed_point_marginal` protocol's
   reconstruction approach (bare `MakeADFun` from a captured map/parameters)
   does not survive TMB's own map-factor validation outside gllvmTMB's own
   fitting pipeline. Is a redesigned capture/reconstruction protocol worth a
   fresh authorisation, or does this close the `fixed_point_marginal` line
   as a second confirmed interface limitation (alongside `fixed_coordinate`'s
   `obj$he()` gap)?
2. **S4/line 3?** Still not authorised this session; the S4 recorder
   `97214679c` remains physically absent from this worktree regardless.
3. **PR to `main`?** This branch is pushed; no PR opened this session (not
   asked for).
