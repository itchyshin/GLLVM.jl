# Destination B frozen R build receipt

An isolated local reference library was built on2026-09-07 from exact commit
`b4d5fee64def88bc768dda1f1f77c29b295edd86`. `git archive` exported only package
paths DESCRIPTION, NAMESPACE, LICENSE, R, src, man and inst into
`/private/tmp/destination-b-r070-build-l9Y1ri/source`. No source edits were made.
The frozen checkout remained clean; the installed user library was untouched.

Build command, working directory `/private/tmp/destination-b-r070-build-l9Y1ri`:

```sh
OPENBLAS_NUM_THREADS=1 MAKEFLAGS=-j1 /usr/local/bin/R CMD INSTALL \
  --library=/private/tmp/destination-b-r070-build-l9Y1ri/library \
  /private/tmp/destination-b-r070-build-l9Y1ri/source
```

Session41530 exited0 with `DONE (gllvmTMB)`, within the declared10minute limit.
Four compiler unused-variable/function warnings were retained in `install.log`.
This is compilation, not a fitting or recovery campaign.

Verification in a fresh R process loaded gllvmTMB0.7.0 from that private library,
with DLL `/private/tmp/destination-b-r070-build-l9Y1ri/library/gllvmTMB/libs/gllvmTMB.so`.
SHA256: `91bfa6d90fbf3e4f42e1f4160583f2607f51a7839bb54a02a209da6e31a59beb`.
Source `src/gllvmTMB.cpp` SHA256:
`d92e70ba28d91e26d5612b2c8c2d10f9c52c7c2f09625d89671f1e8c4afaf6cc`.

Environment: local macOS26.6.1 arm64; R4.6.0; Apple clang21.0.0,
`-arch arm64 -std=gnu++17`, default `-falign-functions=64 -Wall -g -O2`;
TMB1.9.21, RcppEigen0.3.4.0.2, BH1.90.0.1, fmesher0.8.0.
R loaded its standard Rblas/Rlapack (LAPACK3.12.1). Package experimental warning
was retained. Private build artifacts are temporary; this durable receipt does
not replace retaining any later paired output with its source/build provenance.

**No paired likelihood, fitted recovery, interval or R-admission claim follows
from a successful build.** The installed user gllvmTMB0.7.1 remains excluded as
the numerical oracle for this programme.
