# Destination B: frozen S3b shared Gaussian residual alignment

Reference: frozen gllvmTMB0.7.0 commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`,
`dev/stan-oracle-phylo/tmb-side-phylo.md` sections1 and(f), and
`dev/stan-oracle-phylo/tmb-side-phylo.R:105–119`.

Provenance distinction: the retained JSON and reconciliation were produced
with gllvmTMB0.6.0 (`meta.package_version`, reconciliation date2026-08-03 and
worktree`ff70b5e8`). Their presence in the frozen0.7.0 checkout does not make
them frozen0.7.0 numerical receipts. The shared-residual statement was checked
against the actual frozen source: `R/fit-multi.R:3488` calls the scalar helper
at8047–8051 and stores that value in `tmb_params$log_sigma_eps` at4584. The
special per-row diagonal suppression at5626 onward is inactive in this
loadings-only cell. New paired evidence must retain the actual frozen build.

The retained simplest reference is
`value ~ 0 + trait + phylo_latent(species, d=1, vcv=A)`, Gaussian, three
traits, eight tips, and two replicates per trait–tip cell. Its active parameter
blocks are three `b_fix`, one `log_sigma_eps`, three unconstrained rank-one
`theta_rr_phy` loadings, and eight Gaussian `g_phy` scores. Every ordinary
source and phylogenetic unique-variance block is mapped off. Julia's direct
rank-one loading packing agrees (`src/packing.jl`); no exponential diagonal
transform is to be introduced.

With Julia's trait-fast `y=vec(Y)`, the matching marginal model is

```
y ~ N(D*beta, (S*Q^-1*S') kron (L*L') + sigma_eps^2 * I_(p*n)).
```

`S` includes repeated observations and preserves the supplied augmented map.
`Q` and its determinant come from the canonical frozen-R ridge/inversion,
without another scale multiplication or covariance inversion in Julia.
Integrating the Gaussian score vector removes `g_phy` from the marginal
parameter vector; it does not omit its determinant/normalising contribution.

The original native consumer estimated `p` observation variances. That is a
different model and cannot qualify this reference cell merely because its
precision transport agrees. The implemented explicit `residual_mode=:shared`
now reaches the multivariate precision fitter and public forwarding/bridge
metadata, preserving existing `:trait` default behaviour. Shared mode packs one log-SD and
expands it to a length-p variance vector only at the existing kernel boundary;
the full marginal Hessian, labels and degrees of freedom use one coordinate.
Residual targets may report the common value for each trait, clearly labelled
as shared, without pretending those entries were estimated independently.

Before pairing, tests must compare the shared-mode objective with an
independently assembled dense Gaussian likelihood, check packed dimensions and
interval transformations, and retain existing trait-mode regressions. Mapping
the frozen long-format rows into Julia observations remains an explicit
fixture/provenance step. This record authorises no R engine edit or admission,
and does not claim that a retained joint-score objective is already a paired
marginal-likelihood receipt.
