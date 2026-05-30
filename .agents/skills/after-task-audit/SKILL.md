---
name: after-task-audit
description: >
  Mandatory closure routine for every completed GLLVM.jl task or phase. Writes a
  compact report to docs/dev-log/after-task/YYYY-MM-DD-<task>.md covering goal,
  files changed, tests added, benchmark numbers, R-parity verdict (vs gllvmTMB),
  JET/Allocs/Aqua verdicts, Rose audit verdict, remaining risks, and the next
  command. Enforces the drmTMB-grade Definition of Done the maintainer asked for:
  implementation + tests + docs + examples + check-log + after-task audit + Rose
  audit verdict.
---

# After-Task Audit

Use this skill before treating any meaningful `GLLVM.jl` task or phase as
complete. It is Rose's forest-and-trees checklist for the Julia port: make sure
the repository tells one coherent story after a change, that the speed claims
and likelihoods still match R `gllvmTMB` to machine precision, and that the
type-stability / allocation budget the package was tuned for has not regressed.

The task is **not closed** until the after-task report under
`docs/dev-log/after-task/YYYY-MM-DD-<task>.md` records what passed, what
remains uncertain, which docs / examples were synchronized, what went wrong or
felt clumsy, and which discipline or skill should improve next.

## Definition of Done

A task is closed only when *all* of the following exist:

1. **Implementation** — code lands under `src/`, follows the existing module
   layout (see CLAUDE.md "Source layout"), and respects the surgical-change rule.
2. **Tests** — at least one new test in `test/` that would have failed before the
   change. Run via `julia --project=. test/runtests.jl` (never `Pkg.test()` —
   the sandbox fails with `can not merge projects` on this repo).
3. **Docs** — docstrings updated; `docs/src/` updated if user-facing behaviour
   changed; `docs/PERF-plus-design.md` updated if a performance claim changed.
4. **Examples** — at least one runnable example (in a docstring, `docs/src/`,
   or a script) that exercises the new path end-to-end.
5. **Check log** — paste of the actual test tally, JET output, allocation
   counts, and any benchmark numbers from the local Mac. No "tests pass"
   without the number of passed/failed/errored tests.
6. **After-task audit** — the report described below, committed to
   `docs/dev-log/after-task/YYYY-MM-DD-<task>.md`.
7. **Rose audit verdict** — an explicit one-line verdict at the bottom of the
   report: `Rose verdict: PASS | PASS WITH NOTES | FAIL — <reason>`.

If any of these is missing, the task is **not** closed; surface the gap and
either fill it or hand it back.

## Required Audit (in order)

1. State the implemented claim in one sentence.
2. Read the code paths that implement the claim. Confirm they match the claim
   (not a paraphrase of it).
3. Check that the marginal log-likelihood, packing convention, and Λ orientation
   in the new code match the documented reference (Tipping & Bishop 1999;
   Hadfield & Nakagawa 2010; Felsenstein 1985; Kristensen et al. 2016 — see
   `CLAUDE.md` "Key references").
4. Check that examples and docstrings use supported syntax (Julia 1.10
   compatibility; no use of features added after 1.10 unless `compat` is bumped).
5. Check tests exercise the intended behaviour *and* at least one failure path
   (malformed input, boundary, or a comparison to an independent calculation).
6. Run targeted tests for touched behaviour:

   ```sh
   julia --project=. test/runtests.jl
   ```

   Paste the actual pass / fail tally.
7. Run broader package checks when practical:
   - `julia --project=. -e 'using JET; report_package(GLLVM)'` for type-stability
     regressions on touched files.
   - `julia --project=. -e 'using GLLVM; using BenchmarkTools; @benchmark <hot_path>'`
     for any change touching `likelihood.jl`, `fit.jl`, `sparse_phy.jl`,
     `em_phylo.jl`, or `lowrank_cholesky.jl`. Record the median time and
     allocation count.
   - `julia --project=. -e 'using Aqua, GLLVM; Aqua.test_all(GLLVM)'` if
     dependencies, exports, or `Project.toml` changed.
8. Run R-parity check against `gllvmTMB` for any change to the Gaussian
   marginal likelihood, profile-out, init path, or confidence intervals. The
   maintainer keeps a separate benchmark/comparison repo for this — record the
   parity verdict (machine-precision match / within tolerance / regression)
   here even though that repo is not in-tree.
9. Search for stale wording across docs, README, and the generated site:

   ```sh
   rg "Gaussian only|not yet implemented|planned next|TODO|FIXME" README.md docs CLAUDE.md
   rg "340.?x|machine precision|closed.?form" README.md docs/src docs/PERF-plus-design.md
   ```

   Record the exact `rg` patterns used; do not write only "stale-wording scans".
10. For changes that touch family support, link functions, the Laplace step
    (when it lands), or implemented-scope claims, check the status inventory
    explicitly:
    - `README.md` current status block
    - `CLAUDE.md` "Status" and "Planned next" sections
    - `docs/PERF-plus-design.md`
    - `docs/src/` index and any family-specific page
    - `Project.toml` version and compat bounds
11. Inspect overlapping open GitHub issues before closing. Prefer commenting on
    or updating an existing issue over opening a duplicate. Record issue
    comments, new issues, closures, or the reason no issue action was needed.
12. Update `CLAUDE.md` "Status", `docs/PERF-plus-design.md`, and any roadmap or
    known-limitations note when behaviour changed.
13. Write the compact after-task report under
    `docs/dev-log/after-task/YYYY-MM-DD-<task>.md`. Create the directory if it
    does not yet exist.

## Stale-Wording Searches

Use task-specific searches. Common `GLLVM.jl` patterns:

```sh
# Gaussian-only claims that may go stale once non-Gaussian families land
rg "Gaussian only|Gaussian.subset|identity link|closed.?form" README.md docs CLAUDE.md

# Sparse phylo / CHOLMOD / AD caveats
rg "CHOLMOD|Takahashi|selected.?inverse|forward.?mode AD|O\(p\)" src docs CLAUDE.md

# Performance claims
rg "340.?x|speedup|per.?fit|moderate.?to.?large p" README.md docs

# Reference-implementation caveats
rg "gllvmTMB|R reference|read.?only reference" README.md CLAUDE.md docs
```

Generated documentation pages can also contain stale text after a `Documenter`
build:

```sh
rg "Gaussian only|not yet implemented|planned" docs/build 2>/dev/null
```

Do not mechanically delete historical after-task notes. If an old note was true
when written, leave it; add the new after-task report to supersede it.

## Tests Of The Tests

For new tests, verify at least one of the following:

- the new test failed before the fix or feature;
- the test compares the likelihood to an independent calculation (Julia-side
  dense reference, R `gllvmTMB`, or a known closed-form);
- the test checks a boundary, malformed input, or missing-data path;
- the test combines the new feature with an already-supported neighbouring
  feature (e.g. phylo + low-rank Λ; profile-out + Wald CI).

Record which clause the new tests satisfy.

## Benchmark Numbers

For any change that touches a hot path, record:

- the file and function changed;
- median time before and after (from `@benchmark` or `@btime`);
- allocation count before and after;
- whether the change is a regression, neutral, or speedup;
- the machine the numbers were taken on (the maintainer's Mac is the reference
  bench).

If no benchmark applies, write `Benchmarks: N/A — no hot-path change` and
explain why in one sentence.

## R-Parity Verdict

For any change to the Gaussian marginal likelihood, profile-out, init, fitter,
or CI machinery, state the parity verdict against R `gllvmTMB`:

- `Parity: machine precision (≤ 1e-8 absolute on logℓ; ≤ 1e-6 on parameters)`
- `Parity: within tolerance (state the tolerance and why it is acceptable)`
- `Parity: regression — <describe>`
- `Parity: N/A — change does not touch the parity surface`

Cross-reference the comparison repo / ADEMP cell by name; do not duplicate the
numbers here. The benchmark repo is intentionally separate and is **not**
modified from this skill.

## JET / Allocs / Aqua Verdicts

State each as a one-liner. If a workflow did not run, say so and why.

- `JET: clean | <N> reports — <files>`
- `Allocs: stable | regression of <N> allocs in <function>`
- `Aqua: clean | <list of failing checks>`

## Rose Audit Verdict

Final one-line verdict that gates closure:

- `Rose verdict: PASS — all DoD items satisfied, no stale wording, no open
  questions.`
- `Rose verdict: PASS WITH NOTES — <one-sentence summary of the notes>.`
- `Rose verdict: FAIL — <reason>; task is not closed.`

A `PASS WITH NOTES` verdict requires every note to also appear under
"Remaining risks" in the report.

## After-Task Report Template

Write to `docs/dev-log/after-task/YYYY-MM-DD-<short-task-slug>.md`. Use today's
date in ISO form. Keep the slug terse (e.g. `2026-05-30-sparse-phy-grad-takahashi`).

```md
# After Task: <Title>

## Goal

<One sentence. What did this task set out to do?>

## Implemented

<One paragraph. What actually shipped, in plain English.>

## Mathematical Contract

<The equation or model statement the code now implements, with a reference to
the relevant paper from CLAUDE.md "Key references".>

## Files Changed

<List by name, grouped by `src/`, `test/`, `docs/`. One line each.>

## Tests Added

<Count + names. For each, state which "Tests Of The Tests" clause it satisfies.>

## Benchmark Numbers

<Median time / allocs before and after, on the maintainer's Mac. Or
`N/A — no hot-path change` with a one-sentence reason.>

## R-Parity Verdict

<One of the four parity verdicts above. Cross-reference the ADEMP cell by name.>

## JET / Allocs / Aqua Verdicts

- JET: ...
- Allocs: ...
- Aqua: ...

## Checks Run

<Paste the actual command lines and the test tally
(e.g. `256 passed, 0 failed, 0 errored`). No "tests pass" without numbers.>

## Consistency Audit

<Which `rg` patterns were run, and what they returned. README, CLAUDE.md,
docs/PERF-plus-design.md, and any user-facing doc page touched.>

## GitHub Issue Maintenance

<Issues commented on, closed, opened, or "no issue action needed because ...".>

## What Did Not Go Smoothly

<Honest reporting. If a result is mixed or negative, say so plainly.>

## Team Learning

<One sentence: which skill, discipline, or process should improve next.>

## Remaining Risks

<Bulleted. Each `PASS WITH NOTES` item from the Rose verdict must appear here.>

## Known Limitations

<Anything the new code does NOT do that a reasonable reader might assume it
does. Cross-reference CLAUDE.md "Planned next" if relevant.>

## Next Command

<The exact command the maintainer should run next, or `none — task fully
closed`.>

## Rose Verdict

Rose verdict: PASS | PASS WITH NOTES — <summary> | FAIL — <reason>
```

## Reminders

- **No `git add -A` / `git add .`** — stage by name. The maintainer runs
  multiple agents on disjoint files in parallel.
- **No push without explicit instruction.** Commit locally first; ask before
  pushing.
- **No engine surgery on R `gllvmTMB`** from this repo. It is a read-only
  reference.
- **Honest reporting.** Mixed or negative results must be stated plainly, not
  smoothed over.
