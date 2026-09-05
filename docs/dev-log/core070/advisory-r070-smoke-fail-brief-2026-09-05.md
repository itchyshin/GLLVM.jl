> **Ada recommendation:** accept advisory non-gating; merge [#294](https://github.com/itchyshin/GLLVM.jl/pull/294).
> Diagnosis: [Student-t Cell 9](advisory-studentt-cell9-fail-diagnose-2026-09-05.md) @ `3bef8e33` · [NB2 / truncated NB2](advisory-nb2-trunc-fail-diagnose-2026-09-05.md) @ `548b57c9`.

# Advisory R 0.7.0 smoke — nine fail brief (PR #294 CI)

**Date:** 2026-09-05  
**Run:** [CI 33979515590](https://github.com/itchyshin/GLLVM.jl/actions/runs/33979515590) · job `101342094437`  
**Job:** `Frozen R 0.7.0 family smoke (advisory; rebuilt oracle)` — **continue-on-error**  
**Tally:** **277 pass / 9 fail** / 0 errored (full parity suite on frozen oracle)

## Fail one-liners

| # | Cell | Test object | File:line |
|---:|---|---|---|
| 1 | `NATIVE-06-NB2` | NB2 GLLVM parity (1 assertion in 18) | `test_negbin_parity.jl:72` |
| 2 | `NATIVE-12-TRUNCATED-NB2` | explicit public R continuation and complete fit health | `test_truncated_nbinom2_parity.jl:80` |
| 3 | `NATIVE-10-STUDENT` | per-trait σ + per-trait estimated ν (twin default) — Cell 9 | `test_studentt_parity.jl:113` |
| 4 | same | per-trait σ + per-trait estimated ν (twin default) — Cell 9 | `test_studentt_parity.jl:114` |
| 5 | same | per-trait σ + per-trait estimated ν (twin default) — Cell 9 | `test_studentt_parity.jl:119` |
| 6 | same | log-likelihood agreement (estimated ν, \|Δ\| ≤ 0.001) | `test_studentt_parity.jl:146` |
| 7 | same | near-Gaussian estimated-ν diagnostic | `test_studentt_parity.jl:189` |
| 8 | same | near-Gaussian estimated-ν diagnostic | `test_studentt_parity.jl:190` |
| 9 | same | near-Gaussian estimated-ν diagnostic | `test_studentt_parity.jl:191` |

## Cell summary (from Test Summary block)

| Cell | Pass | Fail | Total |
|---|---:|---:|---:|
| `NATIVE-06-NB2` | 17 | 1 | 18 |
| `NATIVE-12-TRUNCATED-NB2` | 20 | 1 | 21 |
| `NATIVE-10-STUDENT` | 26 | 7 | 33 |

## Disposition pointer

Same family cluster as Option D live-R slice (`advisory-smoke-fail-disposition-2026-09-05.md`, `advisory-r-smoke-nb2-studentt-2026-09-05.md`). **advisory-red** — not a Julia CI gate; retained frozen oracle authority unchanged.

Per-cell diagnosis: [Student-t Cell 9](advisory-studentt-cell9-fail-diagnose-2026-09-05.md) (7 fails — A6 boundary-flat fixture) · [NB2 / truncated NB2](advisory-nb2-trunc-fail-diagnose-2026-09-05.md) (2 fails — boundary trajectory + CI oracle rebuild class). Both recommend **accept advisory-red**.

**Needs Shinichi:** merge #294 on Ada recommendation above, or override and triage first.
