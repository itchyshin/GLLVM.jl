# Covariance-mode contracts for the frozen reference

OWNS: test/parity/fixtures/core070_covariance_modes.R,
tools/core070_covariance_modes_points.R, tools/core070_verify_covariance_modes.py,
new covariance-modes developer records and existing shared check-log/checkpoint.
No production source, foreign checkout or R package source edits.

Nine cases: ordinary/animal/named-kernel x independent/common/dependent Gaussian
intercepts. p=3, n=18 observations per trait, six repeated source groups. Use
nonidentity SPD C_input=0.7I+0.3J for animal/kernel (names in exact group order).
Post-capture correction: the frozen dense-source paths use effective
C=C_input+1e-8I. Original pre-run leaf bytes remain in every source.tar; the first
point run failed its raw-C assertion and is retained as FAIL. This correction
documents observed source preprocessing; it does not add a loading ridge.
Fixed design 0+trait. Ordinary grouping is site; structured grouping is species.
Capture actual MakeADFun data/parameters/map/random through unchanged capture
runner, then compare at two predeclared parameter vectors without optimization.

For observation o, trait t[o], group g[o], residual sigma:
V[o,v] = sigma^2 delta[o=v] + C[g[o],g[v]] * U[t[o],t[v]].
Ordinary C=I on site groups. Independent U=diag(s^2), common U=s^2 I,
dependent U=L L', packed raw diagonal followed by below-diagonal columns.
For structured sources C means the effective matrix above. Ordinary DEP leaves
both full U and residual variance free; U+sigma^2I is identified but its split
is not in this fixture. Raw loadings also have column-sign symmetry. The two
positive-diagonal points cannot establish unique fitted coordinates or recovery.
A common variance is not a shared random draw: U=s^2 ones(p,p) is a negative
control. Residual mapping is captured, not silently changed; if fixed, keep
its exact reference value and omit it from the free coordinate vector.

Two points: beta=(.2,-.1,.3) / (-.1,.25,.05); independent SD=(.4,.7,.9) /
(.6,.35,.8); common SD=.65 / .45; raw lower-Cholesky coordinates
(.8,.7,.6,.15,-.2,.1) / (.55,.9,.65,-.1,.25,-.15);
free residual SD=.8 / .55. These are density/derivative contracts, not recovery.

Acceptance for fixed points: finite R marginal objective and gradients; dense
independent Gaussian nll delta<=1e-6 with constants; finite-difference gradient
relative error<=1e-5 (central step1e-5, max(1,abs(each gradient))). Retain all
attempts and malformed-map failures. No optimization/fit/interval/bridge parity
promotion. If captured maps differ from expected, retain and diagnose before
running any point evaluation. Never reinterpret a rejected case as passed.

Compute: Totoro, existing socket, one BLAS/OMP thread; preparation estimate
under2min, cap120s; point evaluation estimate under3min, cap180s. Oracle verify
before/after each. DRAC and >30min campaigns are unnecessary for this leaf.

CHECK: python3 tools/core070_verify_covariance_modes.py
EXPECT: CORE070_COVARIANCE_MODES_CONTRACT_VERIFIED
The eventual check binds exact case inventory, source pins, process exits,
fixture hashes, captured parameter maps, point values/gradients and raw artifacts.
