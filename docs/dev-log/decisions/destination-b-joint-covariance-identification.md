# Joint phylogenetic-plus-grouped covariance identification

**Status:** fixed-parameter covariance-component diagnostic. It does not alter
the valid joint Gaussian likelihood or claim fitted-component recovery,
interval coverage, or a public API.

## Tangent-space contract

For trait-fast `vec(Y)`, the covariance is

\[
V = K_{phy}\mathbin\otimes(LL^\top+\operatorname{diag}u)
  + \sum_g (Z_gZ_g^\top)\mathbin\otimes\operatorname{diag}(v_g)
  + I_n\mathbin\otimes\operatorname{diag}(\psi),
\]

where \(K_{phy}=S Q^{-1} S^\top\). The diagnostic uses only actual free
covariance derivatives:

- residual trait \(j\): \(I_n\otimes E_{jj}\);
- ordinary independent source \(g,j\):
  \((Z_gZ_g^\top)\otimes E_{jj}\);
- packed loading coordinate \(a\):
  \(K_{phy}\otimes(\dot L_aL^\top+L\dot L_a^\top)\);
- explicit phylogenetic unique trait \(j\):
  \(K_{phy}\otimes(2u_jE_{jj})\).

Ordinary/residual log-SD derivatives differ from these natural-variance
columns by a nonzero scalar at an interior point, so they have the same rank.
Zero or nonfinite tangents are reported as invalid rather than normalized.
The loading tangent is deliberately **not** replaced by an unrestricted
phylogenetic trait-covariance basis: that would falsely declare identifiable
reduced-rank factor models nonidentifiable.

For separable derivatives, the normalized Gram matrix uses
\(\langle A\otimes B,C\otimes D\rangle=\operatorname{tr}(A^\top C)
\operatorname{tr}(B^\top D)\). Its rank threshold matches the grouped-profile
foundation: `dimension * _GROUPED_PROFILE_RANK_EPS * maximum(abs,eigenvalues)`.

`Kphy` products use sparse precision solves and never materialize the full
`p*n` response covariance. In particular, \(\|K_{phy}\|_F^2\) is accumulated
by column/batched solves, retaining only linear-size work vectors; repeated
tip observations are counted in every trace and Frobenius sum.

## Consequences

The diagnostic catches identity ordinary incidence versus residual, duplicate
ordinary kernels, and phylogenetic-versus-ordinary aliases that occur in the
actual tangent model. A detected alias does not invalidate a fixed-parameter
kernel evaluation. It means component interpretation and component inference
must report `:nonidentifiable`; the parent fit/inference layer owns that gate.

The bounded unit test includes a p=3 rank-one-plus-diagonal-residual
`Kphy=I` control, a p=1 exact phylo/ordinary/residual alias, ordinary/residual
and duplicate-ordinary aliases, and a zero-tangent invalid diagnostic. It is
estimated below one minute and preserves the existing 64-tip interior fixture.
