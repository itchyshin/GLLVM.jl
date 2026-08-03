# S2 — #175 → Gamma analogues

| #175 surface | Gamma analogue |
|---|---|
| `NBGroupedCovFit` / `BetaGroupedCovFit` | `GammaGroupedCovFit` (`α` vector) |
| `fit_nb/beta_gllvm_grouped_cov` | `fit_gamma_gllvm_grouped_cov` |
| export in `src/GLLVM.jl` | add both symbols |
| `_GroupedDispersionCovFit` Union | add `GammaGroupedCovFit` |
| `_family_ci(::NB/BetaGroupedCovFit)` | `_family_ci(::GammaGroupedCovFit)` |
| `_bridge_compute_ci_cov` Union | add Gamma |
| bridge X `negbinomial`/`beta` branch | add `gamma` → grouped_cov |
| `_bridge_assemble_grouped_cov` Union + disp branch | add Gamma `α` |
| `formula.jl` NB/Beta elseif | add `Gamma` |
| `test_nb_beta_x_identity.jl` | `test_gamma_x_identity.jl` |
| `test_bridge_x.jl` gamma shared oracle | move to grouped_cov oracle |
| docs response-families / parity / capability | mention Gamma API B under X |
