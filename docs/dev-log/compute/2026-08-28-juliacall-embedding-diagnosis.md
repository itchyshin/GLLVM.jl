# JuliaCall embedding segfault on Totoro — diagnosed and repaired (2026-08-28)

Bounded diagnosis owned by the Claude lane on Codex's handoff: R 4.5.3 +
JuliaCall 0.17.6 exited with status 139 during `gllvmTMB::gllvm_julia_setup()`
under both Julia 1.12.6 and 1.10.10, before any model fit — the two-cell
bridge gate recorded `NO_RUN_SOURCE_CONTRACT`, 0/4 fits started.

## Verdict

**Shared-library conflict — NOT a Julia/JuliaCall version incompatibility and
NOT a gllvmTMB or GLLVM.jl initialization problem.** The system libunwind
binds into the embedded process where Julia's own patched libunwind is
required; the first Julia exception segfaults during stack unwinding.

## Evidence chain

1. **Minimal reproduction, no gllvm code involved**: a 10-line R script doing
   only `JuliaCall::julia_setup(JULIA_HOME = <versioned bin>)` with a private
   depot (`JULIA_DEPOT_PATH=~/jcall-diag-depot`) segfaults (exit 139) on BOTH
   Julia 1.12.6 and 1.10.10. `gllvm_julia_setup()` at gllvmTMB pin
   `86e95fff` is a thin wrapper (julia_setup → `Pkg.activate(jl_path);
   using GLLVM`), and the crash fires before `jl_path` is even read — so the
   fault is upstream of both packages by construction.
2. **Backtrace** (gdb, `R -d`): `SIGSEGV in
   _ULx86_64_dwarf_search_unwind_table () from
   /usr/lib/x86_64-linux-gnu/libunwind.so.8` — the SYSTEM libunwind (Ubuntu
   24.04.4), not Julia's shipped copy.
3. **Loader trace** (`LD_DEBUG=files`): `libunwind.so.8 ... needed by
   ~/.julia/juliaup/julia-1.12.6+0.x64.linux.gnu/bin/../lib/julia/
   libjulia-internal.so.1.12` resolves to
   `/usr/lib/x86_64-linux-gnu/libunwind.so.8`.
4. **Mechanism**: standalone `julia` works because the executable's RPATH
   puts `lib/julia` first for the whole process. Under R the executable is
   `/usr/lib/R/bin/exec/R` (no such RPATH), the loader binds the system
   libunwind for `libjulia-internal`'s dependency, and Julia's runtime —
   which registers JIT unwind tables against its own patched libunwind —
   crashes on the first exception. This also explains the earlier
   `✗ Pkg (serial)` precompile symptom: the failure path THREW, and the
   throw itself was the crash. Both Julia versions being affected equally is
   the signature of an environment fault, not a version-support fault.

## The repaired runtime combination (demonstrated, exit 0)

Launch R with Julia's own libunwind preloaded:

```sh
JH=$HOME/.julia/juliaup/julia-1.10.10+0.x64.linux.gnu   # or 1.12.6
LD_PRELOAD=$JH/lib/julia/libunwind.so.8 Rscript <script>.R
```

Demonstrated green on Totoro, both Julia versions, private depot:

- Minimal `julia_setup` + `julia_eval("1+1")`: exit 0 (was 139), the
  `✗ Pkg (serial)` symptom gone.
- **The full `gllvm_julia_setup()` sequence at the exact pins**: byte-exact
  GLLVM.jl checkout `00a2d7b7` (tree `8a243605` verified) at
  `~/GLLVM.jl-pin-00a2d7b7`, private depot instantiated; embedded
  `julia_setup → Pkg.activate(pin) → using GLLVM →
  GLLVM.bridge_capabilities()` all succeed under R on 1.10.10 AND 1.12.6.
  A deliberate Julia-side error now surfaces as a clean R error with a full
  Julia stack trace — the exact operation that previously segfaulted.

Julia 1.10.10 is the recommended gate runtime (closest to the 1.10.0 floor
the engine's verification suites ran on); 1.12.6 is equally demonstrated.

## Scope discipline

No GLLVM.jl model code, families, API, or estimators were changed. No model
fit was run — setup/capabilities only. The retained 0/4 gate denominator is
untouched; re-running the four-fit gate needs fresh approval and new pins
per the handoff contract.

## Artifacts on Totoro (`snakagaw@totoro`)

`~/jcall-min.R` (minimal repro), `~/route-val.R` (pin-route validation),
`~/jcall-fix.log` (both-versions green log), `~/pin-setup.log`,
`~/GLLVM.jl-pin-00a2d7b7` (byte-exact engine pin checkout),
`~/jcall-diag-depot` (private depot, instantiated at the pin).

## Residual risks / notes

- The preload must wrap the R PROCESS (`LD_PRELOAD` at launch); setting it
  inside R after startup cannot work.
- If the gate wrapper spawns R subprocesses, each needs the same preload.
- An alternative fix shape (`LD_LIBRARY_PATH=$JH/lib/julia`) is plausible
  but NOT tested here; the preload is the demonstrated combination.
- System-level remedies (removing/patching Ubuntu's libunwind) were not
  attempted: root-owned and riskier than the per-process fix.
