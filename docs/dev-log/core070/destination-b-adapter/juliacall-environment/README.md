# Isolated JuliaCall environment receipt

Offline resolution5383 combined GLLVM, RCall0.14.13 and Suppressor0.2.8.
The global environment and package Project/Manifest were not changed.
Startup21684 asserts loaded LogExpFunctions0.3.29, its loglogistic symbol
and inverse-functions extension. Dense pilot45507 exits0 with raw transport
checks passing and no prior extension error. No installation or rebuild
was enabled in JuliaCall. The retained manifests are environment evidence,
not runtime package dependencies or instructions to use another checkout.

Runtime path: /private/tmp/destination-b-juliacall-env-IVmUVo.
ProjectSHA256 e466df8381c765835c97596c495d678f39e143a4ff47c427996be4ea025dd99d.
ManifestSHA256 942df6eb6897b95c7e5beab11e86bb9c195a5e086b5648dfe27d77d84079f972.

Cause evidence: previous startup used global LogExpFunctions0.3.26, then
activated GLLVM's0.3.29 environment. The latter extension references
loglogistic, absent in the earlier loaded module. Keeping one resolved
environment removes the observed failure. This is a pilot-level environment
repair, not a general public gllvm_julia_setup repair or deployment guarantee.
