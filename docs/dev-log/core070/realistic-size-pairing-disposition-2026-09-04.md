# Realistic-size idx 9 & 17 — pairing disposition (2026-09-04)

## Finding

Archived Totoro R summaries for two cells do **not** match the Julia (Nibi) seed in
`tools/core070_realistic_size_cells.tsv`:

| idx | family | grid seed | Julia summary seed | R summary seed | |ΔlogLik| |
|---|---|---:|---:|---:|---:|
| 9 | poisson | 1009 | 1009 | **1002** | 287.6 |
| 17 | nb2 | 1017 | 1017 | **1003** | 241.4 |

Collector (`core070_realistic_size_collect.py`) now sets `seed_match=false` and
`pairing_disposition=wrong_r_seed_in_archive_not_optima_divergence`.

## Interpretation

This is **not** evidence of divergent local optima on the same dataset. The R-side
artifact filenames (`poisson_p20_n500_K1`, `nb2_p20_n500_K1`) were paired with Julia
outputs, but the embedded R run used the wrong seed label and (by logLik) a different
response matrix than Julia's authoritative CSV for that idx.

## Remediation

- **Do not** count idx 9/17 in second-order pass/fail tallies until R is re-run with the
  Julia-written `data/<tag>.csv` for seeds 1009 and 1017.
- Re-run locally or on Totoro when CM socket available; no laptop R oracle rebuild in this slice.

## Counting rule (2026-09-04)

Realistic grid second-order gate uses **22/24** first-order paired cells excluding idx 9 & 17
(seed mismatch), not "22/24 with two optima failures."
