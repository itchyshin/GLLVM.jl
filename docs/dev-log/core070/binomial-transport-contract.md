# Binomial oracle transport contract

The frozen R reference b4d5fee64def88bc768dda1f1f77c29b295edd86 accepts
binomial logit/probit/cloglog (R/fit-multi.R865–880) and interprets positive
finite weights as trial counts (2755–2768). Successes must be between zero and
trials (3224–3231). The test oracle additionally restricts its complete-data
fixtures to exactly representable integer counts; it does not redefine R's
whole missing-response or fractional-weight admission domain.

Both fit_gllvmtmb_parity_loglik and its shared-X counterpart now accept
binomial_link=:logit/:probit/:cloglog and preserve supplied N as R weights.
The original omitted-N Bernoulli path retains weights=NULL. Beta-binomial still
requires N; noncount N and non-binomial nondefault link fail before R startup.
A common pure helper validates dimensions, finite integer counts, exact
Float64 representation and 0<=y<=N. Trials are copied, never mutated in place.

The original R blocks fail20 assertions (68pass) for link/trial loss. Repaired
R blocks pass127 assertions covering default/common/varying trials, both
routes, all three links, response/unit/trait order, shared-X replication and
neighbor-family weights. The R fitter is replaced by an argument-capturing
function; no tape or optimizer is constructed. Pure Julia validation56pass
plus actual production function prefixes up to R startup24pass establish
keyword and validation wiring, not embedding. Final checks:127+80pass.

Receipt binding now includes parity_trial_inputs.jl in both producer and
aggregate verifier. The aggregate verifier self-test passes; six scoped
negative controls reject corrupted/overclaimed transport evidence. Original
failures and all intermediate snapshots are retained. Exact source and process
pins are in binomial-transport-evidence.json and ignored runtime storage.

No engine, DGP, existing likelihood tolerance or frozen R source changed.
Paired binomial probit/cloglog and multi-trial fits remain unpaid. In particular
cloglog's curvature/saturation behavior requires its own model contract; correct
transport does not prove numerical parity. Formula, public R bridge, fitted
health, fullsuite and independent review remain unpaid. Other species-X helper
has no N/link controls and was not widened silently. Master manifest DRAFT,
M1 PARTIAL. Previous helper-bound receipts remain historical until replayed.
