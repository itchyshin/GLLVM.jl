# Choose R, Julia, or the bridge

```@raw html
<div class="gllvm-route gllvm-route--start">
  <div>
    <span class="gllvm-route__eyebrow">Pick a route</span>
    <p>These are companions with partial parity, not interchangeable copies of the same workflow.</p>
  </div>
</div>
```

GLLVM.jl is the matrix-first Julia companion to R `gllvmTMB`. The R package
remains the formula-first model surface and the richer applied article set.
The packages share core estimands; they do not offer identical workflows, and
they are not a menu of interchangeable Julia optimisers.

## Use R (`gllvmTMB`)

Start in R when you want the formula-first teaching route or the applied
article set.

- Get started: [R get-started guide](https://itchyshin.github.io/gllvmTMB/articles/gllvmTMB.html)
- What that route currently supports: [current limits](https://itchyshin.github.io/gllvmTMB/articles/current-limits.html)

Those limits belong to the R package. Calling Julia does not lift them.

## Use Julia (`GLLVM.jl`)

Start in Julia when you already have a response matrix and want the
matrix-first companion. Responses are rows and sites are columns
($p \times n$). Parity is partial: some families and extractors are admitted,
and ledger closure is not true parity.

- First fit and the R ⟷ Julia conversion table: [Quick start](quickstart.md)
- Live catch-up scoreboard: [Capability parity](gllvmtmb-parity.md)

## Use the bridge (one-way R → Julia only)

The bridge is `gllvmTMB(..., engine = "julia")`. It sends a subset of
cross-sectional reduced-rank models from R into Julia through JuliaCall. It
is one-way: **R → Julia**. It does not run Julia models back through R, and
it does not cover phylogeny, spatial, animal, kernel, or iSDM structure, nor
the full `traits()` formula grammar.

Status lives on the open tracker, not on this page:

- [R-bridge: run gllvmTMB models through Julia (`engine="julia"`)](https://github.com/itchyshin/GLLVM.jl/issues/10)

This page links that issue. It does not close it or replace it. For the
admitted bridge surface versus the wider engine, see
[Capability parity](gllvmtmb-parity.md).

## What this page does not claim

- Universal parity, or that every R workflow has an identical Julia counterpart.
- Calibrated interval coverage on either side.
- Ownership of the separate `gllvmtmb-navigation-renewal` lane (R site
  navigation stays there).

Related trackers that stay independent:
[#11](https://github.com/itchyshin/GLLVM.jl/issues/11) (roadmap),
[#13](https://github.com/itchyshin/GLLVM.jl/issues/13) (cross-project
learning),
[#276](https://github.com/itchyshin/GLLVM.jl/issues/276)
(comparator-fixture index), and
[#302](https://github.com/itchyshin/GLLVM.jl/issues/302)
(this reader-journey tracker).
