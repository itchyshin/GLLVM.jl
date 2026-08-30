# Student-t parity boundary

Student-t fits use a location-scale t likelihood with an identity link. A
numeric `nu` fixes the degrees of freedom. The public default `nu = nothing`
estimates degrees of freedom, and `disp_group = :species` estimates one scale
and one degree-of-freedom parameter for each trait.

The two calls answer different questions:

```julia
# Fixed degrees of freedom control
fit_studentt_gllvm(Y; K = 1, nu = 4.0, disp_group = :species)

# Public estimated-degrees-of-freedom route
fit_studentt_gllvm(Y; K = 1, nu = nothing, disp_group = :species)
```

The fixed call is useful for checking that both engines evaluate the same
scale-grouped model. It does not replace evidence for the estimated-ν route.
When a trait approaches the Gaussian limit, the likelihood can be very flat in
ν: two healthy fits can have very different large ν values while having nearly
the same log likelihood. Parity therefore compares fit health and the common
log likelihood; it does not force ν estimates to be equal.

For the preserved seed-71 core fixture, the fixed-ν control agrees to machine
precision and the estimated-ν log likelihood is within `0.001`. The frozen R
fit currently reports `nlminb` code 1 (`false convergence (8)`) on that public
estimated-ν target. This remains a visible evidence boundary: the target is
not promoted until both engines are healthy.

The numerical record and exact oracle provenance are in
[`2026-08-30-core070-studentt.md`](../dev-log/decisions/2026-08-30-core070-studentt.md).
