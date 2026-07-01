# After Task: LV arc next-target design, no compute

## Goal

Close the LV arc planning loop by defining the next defensible Phylo Gaussian
Model A target without launching compute.

## Implemented

Added a no-compute decision note for a possible future non-v1 Phylo Gaussian
Model A reopening. The note keeps v1 parked and recommends an eta-scale
realized/design-conditional slope target, with ADEMP sections, a Williams
11-item self-audit, host provenance rules, and explicit Totoro/DRAC non-use in
this slice.

## Mathematical Contract

No likelihood or fitter changed. The proposed future target is:

```text
B_eta_realized(r) = ((Xc_r' Xc_r)^(-1) Xc_r' Etac_lv_r)'
```

where `Eta_lv_r` is the noiseless latent-mediated trait surface for replicate
`r`. This is a conditional finite-sample target, not population
`B_lv = Lambda * alpha_lv'` recovery.

## Files Changed

- `docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md`
- `docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md`

## Tests Added

None. This was a design-only slice. The note defines a future Gate 0 test:
orientation and centering for `B_eta_realized` against an independent dense
calculation.

## Benchmark Numbers

N/A - no hot-path code changed.

## R-Parity Verdict

Parity: N/A - no likelihood, fitter, init path, or CI machinery changed.

## JET / Allocs / Aqua Verdicts

- JET: not run - docs/design only.
- Allocs: not run - no hot path changed.
- Aqua: not run - no package metadata changed.

## Checks Run

```sh
git diff --check -- docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md
rg -n "B_eta_realized|no compute|Totoro|DRAC|source-specific.*support|partial support|ready to scale" docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md docs/dev-log/decisions/2026-07-01-phylo-model-a-structural-redesign-fork.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-07-01-lv-arc-next-target-no-compute.md
```

Results: `git diff --check` returned no whitespace errors. The claim-audit
scan found the intended `B_eta_realized`, no-compute, Totoro, and DRAC gate
language. Hits for source-specific support and partial support were negative
guard wording, not support claims.

## Consistency Audit

The design keeps public source-specific phylo `lv` parked for v1, separates
`alpha_lv`, population `B_lv`, observed-response direct slopes, and the proposed
eta-scale realized target, and forbids compute until a future maintainer
approval.

## GitHub Issue Maintenance

No GitHub action was taken. PR #127 remains closed/parked; no push or PR reopen
was authorized.

## What Did Not Go Smoothly

The tempting observed-response direct-slope route remains diagnostic only
because it already failed its strict K = 1 no-miss canary at 96/100.

## Team Learning

Curie and Fisher should define the truth object and MCSE posture before Grace
spends any cores.

## Remaining Risks

- The eta-scale realized target may be scientifically too conditional for public
  source-specific grammar.
- No truth extractor or orientation unit test exists yet.
- No canary has been run for this new target.

## Known Limitations

This does not implement or validate Phylo Model A support. It does not touch
non-Gaussian models, mixed-family vectors, R grammar, PR #127, Totoro, or DRAC.

## Next Command

```sh
sed -n '1,220p' docs/dev-log/decisions/2026-07-01-phylo-model-a-next-target-no-compute.md
```

## Rose Verdict

Rose verdict: PASS WITH NOTES - the no-compute design is explicit, but future
work still needs a truth extractor, unit test, and maintainer-approved canary
before compute.
