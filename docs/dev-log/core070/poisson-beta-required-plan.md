# Original Poisson/Beta required-runner integration

This leaf implements the previously qualified original models without changing
engine code, original fixtures, samplers, native controls or the R reference.
The pre-implementation acceptance contract is in
`.unlazy/core070-aghq/poisson-beta-required-01/GATES.md`.

Parent owns the required registry, runner, shared evidence inventory and two
new wrappers. Each wrapper executes the exact qualified objective/health body,
retains the default R fit, and applies the explicit public `start_from`/nlminb
refinement in `poisson-beta-required-contract.json`. Sixteen real Julia assertions
per family exercise the health results; original required IDs are unchanged.
The required inventory includes original DGP fixtures, helper and policy bytes.

Verification commands (Python 3.13):

- `python3 tools/core070_verify_poisson_beta_required.py`: required runner,
  two original fixtures, 32 assertions, complete source/environment/process pins,
  raw R readback and equality with the qualified health packet.
- `python3 tools/core070_test_poisson_beta_required.py`: corrupt scratch receipts,
  reject standalone substitution, and retain the registry red/green evidence.
- `python3 tools/core070_verify_family_decomposition.py`: refreshed previously
  bound models/boundaries, current summaries, mapping regressions and freeze guard.

Before running, Totoro jobs were estimated below two minutes each, at most three
concurrent, with one Julia and BLAS thread per job. All five jobs finished within
estimate. No DRAC campaign or full package suite is part of this leaf.

Family-plan binding is scoped to four original native models, one NB2 formula
case and 16 boundary cases. It does not promote all family variants or freeze
any of the 698 nonexcluded source facts. Full programme completion remains open.
