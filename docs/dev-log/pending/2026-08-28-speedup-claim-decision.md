# PENDING maintainer decision — the headline speedup figure (2026-08-28)

**Why this is a decision and not a fix:** the correction belongs in `AGENTS.md`
and `CLAUDE.md`, and the repo's own merge-authority rule puts edits to those
files beyond a Phase-state snapshot update behind maintainer approval. So this
slice STOPS at the finding. Nothing was edited.

## The finding

The repo currently asserts two different headline speedups, and the one in the
agent-instruction files is the one no reader can check.

| Surface | Claim | Status |
|---|---|---|
| `docs/src/benchmarks.md` | six cells: 161.2× 185.3× 194.9× 335.3× 398.8× 698.1× | **PUBLISHED, checkable** — median **265.1×**, mean 328.9× |
| `docs/src/gllvmtmb-parity.md:86-92` | names the same six cells and their 265.1× median; explicitly says *"Treat `~340×` as unverified in-repo pending publication of its source"* | already honest |
| `README.md:33` | "**161–698× faster**" on the Gaussian grid | already corrected 2026-08-26 (it used to read "10–100×", a range NO measured cell fell inside) |
| `docs/src/changelog.md:142` | `~340×` with a dated correction appended, entry left as published | acceptable — historical record + correction |
| **`AGENTS.md:13`** | "**Headline result: ~340× per-fit median speedup**" | ⚠️ **asserts as fact the figure the parity page calls unverified** |
| **`CLAUDE.md`** (What this package is) | same `~340×` framing | ⚠️ same |

The `~340×` figure is attributed to a "Gaussian + phylogenetic" grid that is
**not published in this repository**. The one grid that IS published has a
median of **265.1×**. The two are not reconcilable by a reader.

Why it matters more than a docs nit: `AGENTS.md` and `CLAUDE.md` are what every
future agent (Claude, Codex, Cursor) reads first. An unverified figure stated
there as "Headline result" propagates into every future summary, PR body, and
paper draft that agent writes. This is the same ledger-honesty class as the
curvature table (overstated, corrected today) and the L47 row (understated,
promoted today) — this one just happens to live behind an approval fence.

## Options

1. **Publish the source grid** for `~340×` (the Gaussian + phylogenetic
   benchmark), so the figure becomes checkable, then keep it. Best if that
   grid exists and is reproducible — it is a genuinely stronger claim.
2. **Re-baseline the headline to the published grid**: "median 265.1×
   (range 161–698×) on the published Gaussian grid". Immediately honest,
   loses the phylo path's stronger number until (1) is done.
3. **Keep `~340×` but mark it** in `AGENTS.md`/`CLAUDE.md` the way the parity
   page already does — as pending publication of its source.

Recommendation: **(1) if the grid can be published quickly, else (2)**.
Option 3 is the weakest — it preserves the number's prominence while conceding
it cannot be checked.

Whichever is chosen, the non-Gaussian caveat must ride with it wherever the
headline appears: measured lognormal ≈1280× (also closed-form), but
truncated_poisson ≈2.2× and Gamma ≈1.6× — the headline does NOT generalise.
`docs/src/benchmarks.md` already carries this as a warning admonition; the
instruction files do not.

## What was verified for this note

- The six published ratios and their median (265.1×), recomputed from
  `docs/src/benchmarks.md`'s own table.
- That `README.md`'s "10–100×" error is already fixed (2026-08-26).
- That `gllvmtmb-parity.md` already fences `~340×` as unverified.
- That `AGENTS.md:13` and `CLAUDE.md` do not carry that fence.
