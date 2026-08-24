# Parity toolchain provenance — 2026-08-24

Recorded by the Stage-0 probe of the twin-parity catch-up arc, so every Δ quoted in
this wave can name the exact twin build that produced it.

**Why this file exists.** The 2026-08-24 handover declared the truncated_poisson and
lognormal light RCall Δ cells **OWED, not payable**, on the premise that no live R
twin was reachable. That premise was re-tested rather than inherited, and it did not
hold: R and `gllvmTMB` are both installed on this machine. This file is the evidence
for that reversal.

## Toolchain

| Item | Value | How verified |
|---|---|---|
| R | 4.6.0 (2026-04-24) | `rcopy(String, R"R.version.string")` from inside Julia |
| `R RHOME` | `/Library/Frameworks/R.framework/Resources` | `/usr/local/bin/R RHOME` |
| `RCall.Rhome` | `/Library/Frameworks/R.framework/Resources` | `using RCall; RCall.Rhome` |
| RCall ↔ R match | **yes** — identical paths, no rebuild required | comparison of the two rows above |
| `gllvmTMB` version | **0.7.0** | `packageVersion("gllvmTMB")` |
| Twin library | `/Users/z3437171/Library/R/arm64/4.6/library/gllvmTMB` | `find.package("gllvmTMB")` |
| fid 3 + fid 10 present | **true** | `all(c("lognormal","truncated_poisson") %in% names(gllvmTMB:::.valid_family))` |

`gllvmTMB:::.valid_family` enumerated live, ids 0–16:

```
gaussian 0 · binomial 1 · poisson 2 · lognormal 3 · Gamma 4 · nbinom2 5 · tweedie 6
Beta 7 · betabinomial 8 · student 9 · truncated_poisson 10 · truncated_nbinom2 11
delta_lognormal 12 · delta_gamma 13 · ordinal_probit 14 · nbinom1 15 · multinomial 16
```

## Library-path hazard (acted on)

`test/parity/parity_helpers.jl` defaults `_PARITY_TWIN_RLIB` to
`/tmp/R-gllvmtmb-x-parity-20260802`. **That directory no longer exists** — `/tmp` was
purged since the 2026-08-02 X-cohort runs. `_parity_prepend_twin_lib!()` therefore
returns early and silently falls back to `.libPaths()`, which *does* contain the twin
on this machine — so the suite still works, but by accident rather than by
construction.

Every run in this wave sets the path explicitly instead of relying on that fallback:

```sh
export GLLVM_PARITY_R_LIBS=/Users/z3437171/Library/R/arm64/4.6/library
```

## Project instantiation

`test/parity/` is a standalone Julia project with no committed `Manifest.toml`, so a
first run on a fresh machine needs `Pkg.instantiate()` before `using RCall` resolves.
This is expected (the isolation is deliberate — it keeps `test/runtests.jl` runnable
on machines with no R) and is not a defect.

## Canary — the regression baseline

Before writing any new cell, the **entire existing suite was re-run unchanged**. A new
number is only trustworthy if the old ones still reproduce on this toolchain.

`GLLVM_PARITY_TESTS=1 julia --project=test/parity test/parity/runparity.jl` → **exit 0**

| Cell | Pass/Total | Time |
|---|---|---|
| Gaussian | 30/30 | 5.6s |
| Binomial | 6/6 | 8.5s |
| Poisson | 6/6 | 3.6s |
| NB2 | 8/8 | 5.3s |
| Beta | 8/8 | 1.9s |
| Ordinal-probit (diagnostic) | 5/5 | 1.8s |
| Shared site-X cohort | 65/65 | 27.4s |
| Species-specific XB | 16/16 | 1.6s |
| **Total** | **144/144** | ~56s |

All Δ in the range ~1e-10 to ~1e-8 except NB2 at −2.58e-4 on a log-likelihood of
−820.415 — that is 3.1e-7 **relative**, well inside the locked `rtol = 1e-6`, and is
the expected size for a Laplace-vs-Laplace comparison. No tolerance was widened and no
seed was changed to obtain this baseline.

## Seed register

Seeds 42–49 and 420–431 are already consumed by existing cells (42 Gaussian, 43
Binomial, 44 Poisson, 45 NB2 **and** Beta, 46 Ordinal, 47 Ordinal+X, 48 NB1+X /
species-XB, 49 BetaBinomial+X / species-XB).

The catch-up plan had pre-registered 45/46 for the two new cells; both collide. They
were re-registered to **52 (lognormal)** and **53 (truncated_poisson)** *before either
cell had ever been executed* — a uniqueness fix for receipt legibility, **not** a
re-roll after seeing a Δ. Reserved for the next rung: 54 Gamma, 55 nb1, 56
betabinomial.
