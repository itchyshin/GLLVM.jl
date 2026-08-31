# Ordinary rank-one latent Gaussian model leaf

## Scope and ownership

Ada owns the frozen contract, executable gate, aggregate integration and evidence.
The numerical runner may add new harness files only. No Julia or R engine file is
owned by this leaf. The R reference is frozen at
`b4d5fee64def88bc768dda1f1f77c29b295edd86` and the prepared input is
`INPUT-GAUSS-LOADINGS` with SHA-256
`aab1742a88c5301f274206981f2f6a4d97062e0c4e31fa1d295c0a1ec5889cdc`.

## Model contract

For three traits and eighteen sites, fit

```text
Y[:, i] = beta + lambda * u[i] + epsilon[:, i]
u ~ Normal(0, I_18)
epsilon[:, i] ~ Normal(0, sigma_eps^2 I_3)
```

with rank one, `unique=false`, and a free common residual SD. The seven free
coordinates are three trait means, three signed loading coordinates, and one log
residual SD. Loading sign is not identified. Compare `lambda*lambda'`, residual
variance, trait means and the normalized marginal log likelihood; never require
raw loading equality.

The required routes are native Julia, Julia formula, and the frozen public R
`engine="julia"` bridge. The already verified shared-point evidence is a required
dependency and must still show an absolute likelihood difference at most `1e-8`.
Healthy independently started optimized fits must meet the frozen tolerances in
`latent-bare-model-contract.json`.

## Runnable gate

`OWNS`: `tools/core070_latent_bare_model.{R,jl}`,
`tools/core070_verify_latent_bare_model.py`, their exact tests, this leaf and the
latent-bare contract/evidence files.

`CHECK`:

```sh
python3 test/test_core070_latent_bare_contract.py
PYTHONPATH=tools python3 tools/core070_verify_latent_bare_model.py --self-test
```

The remote run executes the frozen R fit, native Julia fit, Julia formula fit and
public bridge fit under one Julia thread and one BLAS thread. It writes an
incremental attempt before any acceptance verdict.

`EXPECT`: the exact input and seven-coordinate model are reconstructed; the
shared-point evidence remains valid; both engines are healthy; all three routes
agree within frozen tolerances on invariant quantities; the bridge reports the
Julia engine and expected model dimensions. Eight negative controls fail for the
intended reason. The verifier rejects omitted routes, stale pins, raw-loading
comparisons, changed tolerances, nonzero process exits, missing receipts and
stale evidence.

`SOURCE/ENVIRONMENT`: bind the frozen R source, installed-tree marker, prepared
input, Julia source tree, contract, runners, R/Julia versions, package roots and
thread settings into the process receipt.

`TIMEOUT`: five minutes on Totoro. Expected elapsed time is one to four minutes.
No DRAC job is needed.

`FAILURE ACTION`: retain every attempt. Classify failures as model/data mismatch,
normalization, optimizer health, invariant comparison, formula construction or
bridge transport before repairing. Do not alter an engine merely to make the
harness pass.

## Negative controls

Prove that `unique=true` is a different model; reject rank above trait count,
asymmetric or non-positive source matrices, projection/group shape mismatch,
missing and duplicate long cells; and mutate a signed loading while preserving
its crossproduct to prove the acceptance rule does not depend on raw sign.

## Claim boundary

Passing this leaf earns one ordinary rank-one Gaussian latent model across three
interfaces. It does not earn other unique-variance modes, ranks, source kinds,
families, slopes, intervals, recovery, or AGHQ.
