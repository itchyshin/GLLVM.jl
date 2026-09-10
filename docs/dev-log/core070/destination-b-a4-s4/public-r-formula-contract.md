# S4 public R-formula paired-receipt contract

This is a structural scaffold, not a parity result. Earlier A4/S4 records are
private and admission-closed; they cannot be converted into this receipt.

## Frozen 0.7.0 public formula

The qualifying R-side public call is the wide `traits()` grammar, not `cbind()`:

```r
gllvmTMB::gllvmTMB(
  traits(trait_1, trait_2) ~ 1 + phylo_dep(1 | species, tree = tree),
  data = d_wide,
  unit = "individual",
  cluster = "species",
  family = gaussian(),
  silent = TRUE
)
```

`d_wide` has repeated `individual` rows for each of the three `species` tree
tips. `tree` has three tips, is ultrametric, and has root-to-tip distance other
than one (a non-unit ultrametric tree). `traits()` resolves to
the equivalent long-form fixed-effect and full phylogenetic covariance design:

```r
value ~ 0 + trait + phylo_dep(0 + trait | species, tree = tree)
```

The seven observed-marginal transformed-Wald targets remain exactly:

```
beta[1], beta[2], phylo_cov[1,1], phylo_cov[2,1], phylo_cov[2,2],
residual_var_shared[1], residual_var_shared[2]
```

`beta` is the two `0 + trait` intercepts; `phylo_cov` is the lower triangle of
`extract_Sigma(fit, level = "phy", part = "total", link_residual = "none")$Sigma`;
and both residual targets are the same Gaussian `sigma_eps^2` scalar. The
receipt must state that this residual variance is shared across traits.

The former `cbind(trait_1, trait_2) ~ 1` probe is retained only as an invalid
formula diagnostic (exit status 1; elapsed 0.62 seconds). In frozen 0.7.0,
`cbind()` is the multi-trial binomial response grammar and does not establish a
wide multivariate Gaussian trait model. It is not a receipt or a timing result
for the valid model.

An initial valid-formula probe using a non-ultrametric tree is also retained as
a failed feasibility diagnostic (exit status 1; elapsed 1.25 seconds). Frozen
0.7.0 rejects it before fitting because the phylogenetic correlation tree must
be ultrametric. Neither diagnostic is numerical evidence.

## Julia boundary

Frozen 0.7.0 maps `phylo_dep()` to the explicit
`GJL-GATE-STRUCTURED-TERMS` rejection for `engine = "julia"`. It has no
structured-fit payload and no bridge-level phylogenetic covariance interval
mapping. Therefore this contract deliberately remains
`awaiting_structured_julia_transport`: it must not be filled, validated as
paired, or promoted until a separately authorised structured Julia transport
and interval implementation exists.

The next permitted operation is a single native-TMB feasibility/timing probe
of the public formula above. It may verify formula evaluation and report a
runtime estimate, but must not create a paired receipt, claim endpoint parity,
or evade the Julia gate.

The structural check is intentionally available without R:

```sh
/Users/z3437171/.juliaup/bin/julia --project=. test/test_destination_b_a4_s4_public_r_formula_receipt.jl
```

It validates the exact schema and mutation failures with an explicitly tagged
synthetic in-memory fixture. The validator rejects that fixture by default;
the test must opt in with `allow_synthetic = true`, and its result is labelled
synthetic rather than a fresh receipt. A non-synthetic structural receipt must
also name a retained evidence artifact, but this validator does not load or
authenticate it. It does not run R, load `gllvmTMB`, or fit either
implementation.
