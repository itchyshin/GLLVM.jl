# Destination B — four-source fixed-parameter Gaussian invariance gate

Status: deterministic kernel verification only. No optimiser, recovery,
coverage, public capability, or new covariance-mode claim is exercised.

## Fixed model and independent dense oracle

For a two-trait, ten-observation response with a three-column full-rank mean
design `X`, fix

```math
r = \operatorname{vec}(Y)-X\gamma,
\qquad
V = \sigma_\epsilon^2 I + \sum_{s\in\{U,O,C,D\}} A_s\otimes B_s,
\qquad
\operatorname{NLL}=\tfrac12\{m\log(2\pi)+\log|V|+r'V^{-1}r\}.
```

The independent oracle builds every `A_s[i,j]` by label equality, not from a
production incidence matrix, and fills `V` entry-by-entry. The production side
uses `_grouped_gaussian_objective` and its sparse incidences at exactly the
same packed coordinates.

| source | actual labels | fitted mode | fixed trait covariance |
| --- | --- | --- | --- |
| `unit` | unequal sizes `(2,4,2,2)` | `:dep` | `L_U L_U'`, `L_U=[[.55,0],[.15,.42]]` |
| `unit_obs` | globally nested, all levels replicated twice; unit 2 has distinct `u2a/u2b` levels | `:dep` | `L_O L_O'`, `L_O=[[.40,0],[-.10,.36]]` |
| `cluster` | three crossed levels | `:dep` | `L_C L_C'`, `L_C=[[.30,0],[.12,.46]]` |
| `cluster2` | four crossed levels, non-alias map | `:indep` | `diag(.25^2,.35^2)` |

The packed mean is `gamma=(.20,-.35,.18)`, the three `:dep` blocks use the
listed lower-loading coordinates, `cluster2` uses `log(.25),log(.35)`, and
the residual coordinate is `log(.50)`.

## Predeclared gates

1. Dense `V` and NLL equal their sparse production counterparts at fixed
   coordinates.
   The unit and unit-observation incidence Gram matrices must be unequal, and
   each `unit_obs` label must map to exactly one unit.
2. A joint observation permutation applies the same trait-block row permutation
   to `Y`, every incidence label, and `X`; its dense and production objectives
   equal the original.
3. Independent bijective renaming of each source's labels leaves both dense and
   production values unchanged.
4. Swapping two *observations'* `cluster2` memberships while leaving `Y`, `X`,
   and every other source untouched is not a relabeling. It must change the
   dense and production objectives by a detectable amount, while those two
   wrong-map values still agree with one another.

This pure fixed-parameter check is estimated below one minute in MAIN. The
wrong-map receipt tests an actually altered sharing map, not an invariant
renaming or a permutation applied consistently to all inputs.

The earlier local n=9 draft used the same sharing partition for `unit` and
`unit_obs`; it was therefore only a weaker historical arithmetic check and is
not qualification for nested-source distinction. It was replaced before this
file was integrated.

## Fixed-parameter receipt

The qualified MAIN-project test passed 21/21 assertions in 4.2 seconds (8.3 seconds
fresh-process wall time). The independent label-equality covariance and dense
NLL agreed with the production packed covariance and sparse objective; the
joint observation/design permutation and four independent bijective renames
preserved that value. The deliberate `cluster2` observation-membership swap
changed the fixed objective from `19.70265930520765` to
`19.660698458102225` (absolute difference `0.04196084710542536`), while the
independent dense wrong-map oracle still agreed with production. This is the
expected sensitivity to changed sharing, not a fit result.
