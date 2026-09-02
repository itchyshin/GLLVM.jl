# T8 — AGHQ policy rows: bind or reclassify

22 rows in `required-source-case-map.json` (`source_id` prefix `aghq/`, `disposition:
BLOCKED_SPEC_DEFECT`), defect: *"name an exact native policy call or same-model public
fit; helper source observation alone is insufficient."* 0/39 AGHQ rows have executable
receipts (`parity-panel-2026-09-01.md:15`). Frozen oracle: gllvmTMB 0.7.0 `b4d5fee6`,
`R/aghq-control.R`, `R/aghq-gate.R`, `R/fit-multi.R:6320-6400,9588-9611`.

## What's already drafted

`aghq-control-subset.json` (owner B6) already proposes an `r_call` for all 22 rows —
but every one calls an internal `.`-prefixed helper (`.gllvmTMB_aghq_k`,
`.aghq_auto_decide`, `.aghq_auto_gate`) directly, reachable only via `:::`. That IS the
defect: none of these 22 proposed calls are public. One exception:
`AGHQ-DEFAULT-OFF`'s call, `formals(gllvmTMBcontrol)$aghq`, is already fully public
(`gllvmTMBcontrol` is exported, `formals()` is base R) — it needs no reclassification,
just re-marking as bound.

## Production reachability (the actual test)

`fit-multi.R:6330-6340` shows the REAL fit-time call site: `.gllvmTMB_aghq_k(control,
d_B, family=family, n_traits=n_traits)`, `.aghq_gate(obj, tmb_data)`, then
`.aghq_auto_gate(control, aghq_block, n_traits, d_B, NA_integer_)` — note the LAST
argument (`n`) is hard-coded `NA_integer_` at the only production call site
(comment at `fit-multi.R:6365-6367`: *"`n` is part of .aghq_auto_decide()'s signature
but its body does not use it... NA is passed rather than inventing a value here"*).
Result (`aghq_info$k`/`used`/`reason`) is attached to the returned fit object — a
public field on an exported function's return value. So: any row whose scenario can
be produced by (a) a real `family`, (b) a real `n_traits` count, (c) `control$aghq`
∈ {`FALSE`, numeric, `"auto"`} is bindable via a same-model public fit (`unique =
FALSE`, single `z_B` random block — Stage 1a eligibility, `fit-multi.R:6346-6349`).
Any row whose scenario needs a value `.aghq_auto_decide`/`.aghq_gate` never actually
receives from a real fit (forced `n`≠`NA`, `gate_table=NULL`/empty/column-dropped,
`treewidth` forced `NA`, `route` forced `"laplace"`) is **not** reachable publicly —
it tests the helper's own defensive contract, not a policy a user's fit can exercise.

## Table

| row | public R call (same-model fit unless noted) | action | risk |
|---|---|---|---|
| AGHQ-AUTO-K-BINOMIAL | `gllvmTMB(family=binomial(), ...latent(...,unique=FALSE)..., control=gllvmTMBcontrol(aghq="auto"))`; read `fit$aghq$k` | bind | low |
| AGHQ-AUTO-K-POISSON | same, `family=poisson()` | bind | low |
| AGHQ-AUTO-K-GAUSSIAN | same, `family=gaussian()` | bind | low |
| AGHQ-AUTO-K-NB2 | same, `family=negative.binomial()`/nbinom2 constructor | bind | low |
| AGHQ-AUTO-K-ORDINAL | same, `family=ordinal_probit()` (or `ordinal_logit()`) | bind | medium (link choice affects the string match) |
| AGHQ-AUTO-K-DELTA | same, `family=delta_gamma()` (exported, `NAMESPACE`) | bind | medium (Stage 1a + delta family combo untested; smoke-fit first) |
| AGHQ-AUTO-K-TWEEDIE | same, `family=tweedie()` (exported, `NAMESPACE`) | bind | medium (same untested-combo caveat) |
| AGHQ-DEFAULT-OFF | `formals(gllvmTMBcontrol)$aghq` (no fit needed) | bind (already public as drafted) | none |
| AGHQ-POLICY-OFF | same-model fit, `control=gllvmTMBcontrol(aghq=FALSE)`; read `fit$aghq$used==FALSE` | bind | low |
| AGHQ-POLICY-EXPLICIT | same-model fit, `control=gllvmTMBcontrol(aghq=3L)`; read `fit$aghq$k==3` | bind | low |
| AGHQ-POLICY-EXPLICIT-BYPASS-CUTOFF | same-model fit, `aghq=9L` (explicit) with `n_traits>=20`; confirm AGHQ still runs (explicit bypasses the cutoff per `fit-multi.R:6371-6372`) | bind | medium (needs a >=20-trait fixture) |
| AGHQ-POLICY-AUTO-ENFORCE-CUTOFF | same-model fit, `aghq="auto"`, `n_traits=20`; read `fit$aghq$reason` contains the Pinheiro & Chao cutoff text | bind | medium (fixture size) |
| AGHQ-POLICY-TRAITS19 | same route, `n_traits=19`; confirm AGHQ stays on | bind | medium |
| AGHQ-POLICY-TRAITS20 | same route as AUTO-ENFORCE-CUTOFF (duplicate boundary check) | bind | medium |
| AGHQ-POLICY-BAD-COLUMNS | none — forces a hand-truncated `gate[,"route",drop=FALSE]`; `.aghq_gate()` never returns a column-dropped table from a real fit | reclassify | — |
| AGHQ-POLICY-BAD-DIMENSION | none — forces `q=NA_real_`; `d_B` is always a real integer at the production call site | reclassify | — |
| AGHQ-POLICY-BAD-TRAITS | none — forces `n_traits=NA_real_`; always a real count in a real fit | reclassify | — |
| AGHQ-POLICY-EMPTY-GATE | none — forces `gate[FALSE,]`; a real Stage-1a-eligible fit always has ≥1 block (the `z_B` block itself) | reclassify | — |
| AGHQ-POLICY-MISSING-GATE | none — forces `gate_table=NULL`, i.e. `.aghq_gate` "not existing"; can't occur in a normal install | reclassify | — |
| AGHQ-POLICY-NO-QUADRATURE | none — forces `route="laplace"` on an otherwise-real gate; genuine non-quadrature routing needs a dense prior (`propto()`/`kernel_*()`) or REML, both of which are excluded by the EARLIER "random must be exactly z_B" eligibility check, so this combination cannot arise from a public fit | reclassify | — |
| AGHQ-POLICY-SITES-INDEPENDENT | none — exercises `n=100000`, but production always passes `n=NA_integer_` (dead parameter, `fit-multi.R:6365-6367`); no public fit can populate a real `n` here | reclassify | — |
| AGHQ-POLICY-UNRESOLVED-WIDTH | none — forces `treewidth=NA_real_`; `.aghq_treewidth_upper_bound()` always returns a real integer | reclassify | — |

## Counts

**14 bindable** (AUTO-K-BINOMIAL/POISSON/GAUSSIAN/NB2/ORDINAL/DELTA/TWEEDIE,
DEFAULT-OFF, POLICY-OFF, POLICY-EXPLICIT, POLICY-EXPLICIT-BYPASS-CUTOFF,
POLICY-AUTO-ENFORCE-CUTOFF, POLICY-TRAITS19, POLICY-TRAITS20).
**8 reclassify** (BAD-COLUMNS, BAD-DIMENSION, BAD-TRAITS, EMPTY-GATE, MISSING-GATE,
NO-QUADRATURE, SITES-INDEPENDENT, UNRESOLVED-WIDTH) — propose moving these out of the
required set with reason `"no public R surface"`, since each forces an internal-data
shape the real `.aghq_gate()`/`.aghq_auto_decide()` call sites never produce.

## Question for the maintainer

Reclassifying these 8 removes them from the required-parity count entirely (they'd
stop appearing in any future receipt tally) rather than leaving them permanently
`BLOCKED_SPEC_DEFECT` — is that the intended disposition, or should they instead be
kept as a separate, explicitly-labelled "internal-contract, non-parity" bucket so the
0/39 AGHQ denominator visibly shrinks to 0/31 rather than silently losing 8 rows?
