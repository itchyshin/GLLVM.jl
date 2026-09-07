# Plan vs actual — M3-PHY-S3-ANIMAL pedigree Ainv fixture

Plan: parent brief M3-PHY-S3-ANIMAL (Destination B hygiene; diagnostic only)
Unlazy: `.unlazy/m3-phy-s3-animal/GATES.md`
Worktree: `~/local-scratch/lanes/GLLVM.jl-m3-phy-s3-animal-20260907`
Branch: `cursor/m3-phy-s3-animal-20260907`
Base: `origin/main` @ `5d1c9a6c` (#312)

## Planned

Second design fixture: 12-individual pedigree / sparse `Ainv` as raw
triplets → admit via PrecisionPhy → likelihood replay (and fit if
natural) versus the existing animal/Ainv path if one exists.

## Actual

| Item | Planned | Actual |
|---|---|---|
| Fixture | 12-id pedigree from `animal-keyword.R` | Exact `i1`..`i12` founder-pair example. F = 0 (named example); two-parent Mendelian branch still runs. |
| Ainv | raw triplets | Test-only Henderson `A` + Quaas `Ainv`. No `src/` pedigree parser. |
| Admit | PrecisionPhy path | Relaxed `n_aug ≥ n_leaves`. Tree `2p − 2` still admitted; `n_aug < n_leaves` still DIM. |
| Replay | vs existing animal path | Dense Henderson `A` / `relatedness_cov(; jitter=0)`. Abs Δ ≤ 7e-15. |
| Fit | if natural | `fit_phylo_gaussian(::PrecisionPhy)` + `bridge_fit` consume hook. |
| Ancestors | implied by design | Full 12×12 precision with 10-tip map vs `A[tips,tips]`; subsetted Ainv is a negative control. |
| Receipt | diagnostic only | `docs/dev-log/core070/phylo-transport-s3-animal-fixture.md` |
| Tests | new file | `test/test_phylo_precision_animal.jl` (43 assertions). S3a DIM case updated. |

## Deviations

1. **Admit DIM rule.** S3a required `n_aug == 2p − 2`. Animal tip-only is
   `n_aug = p`. The gate is now `n_aug ≥ n_leaves`. S3a's `n_aug + 1`
   case would have become a false DIM reject of a legal ancestor size;
   it now uses `n_aug = p − 1`.
2. **F = 0.** The design sketch said "F > 0". The named R example is
   two-generation with unrelated founders, so F = 0. Recorded honestly.
3. **Collapsed MLE `σ²_eps`.** The 12-id one-replicate draw sits on the
   residual-variance boundary. Interior matched-parameter nll is the
   non-boundary oracle (same lesson as S3-FIT).

## Not done / next

- R-side `phylo_rr` gate lift (S3b) — not authorised.
- Kernel slice — waits on animal green (this leaf is the diagnostic).
- M2-R2, NB2 A11 promotion, true-parity / public claim — fenced.
- Full `Pkg.test()` left to CI Julia shards.

## Verdict

Local S3-ANIMAL is **PASS** on admit + dense-A replay + ancestor
negative control. Programme status remains diagnostic-only; NB2 A11
stays **partial**.
