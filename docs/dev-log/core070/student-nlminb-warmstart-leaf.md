# Original Student-t fixed-to-free nlminb check

Ada owns tools/core070_student_nlminb_warmstart.jl and its dedicated verifier,
records and ignored runtime. No production engine or frozen R source changes.

Hypothesis: the successful fixed-df warm model gives nlminb an initialization
that avoids the large-df numerical drift of the tested free BFGS route. This
experiment discriminates optimizer path dependence; it cannot repair the frozen
reference density calculation or prove all initialization policies healthy.

Preserve seed71,p5,K1,n130, exact data and fixture SHA, all20 final free
parameters, original TMB data/map and native400iteration fit. Fixed warm df
[100000,5,4,4,10] is used only for initialization. Final model estimates all
per-trait df and scales. No df cap, loading ridge or model replacement.
Final public control: start_from=warm_fit,n_init=1,se=FALSE, nlminb with
rel.tol=1e-12,sing.tol=1e-12,eval.max=2000,iter.max=1500.

CHECK: original retained BFGS receipt remains failed under its verifier.
CHECK: new original-fixture R/native fit with all13 existing checks unchanged.
EXPECT: code0 and both raw gradients<=1e-4; absolute delta logLik<=0.001;
same-point density discrepancy<=1e-6; finite/domain/data/map/parameter checks.
If any check fails, retain exit1 and all artifacts; do not relabel the case.
If all pass, require independent review before promoting a general start policy.

Totoro only, one Julia and BLAS thread. Estimate1–3minutes,300second supervisor
limit. Oracle hashes before/after; fresh source snapshot and durable readback.
No installation or DRAC submission. Preserve all previous failures.
