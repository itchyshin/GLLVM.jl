# Noether — original Poisson/Beta qualification review

Requested routing: existing native reviewer, gpt-5.6-terra/high; fresh bounded
public-source brief followed by one repair-review message. No production child
or full-programme completion panel. Parent owns implementation and runtime.

The review confirmed the original source-block DGP extraction, Poisson14/Beta15
parameter counts, R b_fix/Lambda_B/log_phi_beta mapping, same-point likelihood
comparison and appropriate curvature. It found a valid pre-run omission: fixture
and contract hashes were checked after execution but should also fail before fits.
Fixed contract/fixture/DGP SHA locks now run before GLLVM/RCall loading; no-fit
--check tests include both valid policies and four corrupt/unknown-policy cases.
The final pinned Totoro replay still passes32 checks.

An initial P0 that failed checks could emit success was retracted. record_case!
marks any failed count as a failed cell; finish_run! rejects such cells and throws
before the success marker. The original default run's exit1 and28pass/2fail
independently demonstrate that path. No redundant source change was made.

The follow-up review checked frozen public R source: fit-multi.R applies
start_from around5051, passes optArgs to default nlminb around6124, and merges
user controls into stats::nlminb around8063; init-warmstart.R applies copied
blocks around394. Thus the public refinement is an actual callable policy.
The initial optimizer-controls caveat was withdrawn after this source check.

Final bounded verdict: **no outstanding P0–P2 findings after source-lock repair**.
Noether executed no fits or source commands. The parent independently ran all
runtime and corruption checks. This is not a Rose programme verdict, recovery
result or default required-runner integration proof.
