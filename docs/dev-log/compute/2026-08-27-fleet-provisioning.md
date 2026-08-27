# Compute fleet provisioning for GLLVM.jl (2026-08-27)

One-time setup that unlocks the parallel-verification and campaign workflows
in the completion roadmap. All hosts reached through existing ControlMaster
sockets (no Duo triggered, per D-64).

| Host | Checkout | Depot | Julia | Account |
|---|---|---|---|---|
| Totoro | `~/GLLVM.jl-lane` | default (`~/.julia`) | juliaup | — (≤150 cores, D-143) |
| Fir | `~/GLLVM.jl-lane` | `~/gllvm_julia_depot` | module `julia/1.11.3` | `def-snakagaw_cpu` |
| Narval | `/project/def-snakagaw/snakagaw/GLLVM.jl-lane` | `/project/def-snakagaw/snakagaw/julia_depot` | module `julia/1.11.3` | `def-snakagaw_cpu` |
| Rorqual | `~/GLLVM.jl-lane` | `~/gllvm_julia_depot` | module `julia/1.11.3` | `def-snakagaw_cpu` |
| Nibi | `/project/def-snakagaw/snakagaw/GLLVM.jl-lane` | `/project/def-snakagaw/snakagaw/julia_depot` | module `julia/1.11.3` | `def-snakagaw_cpu` |

Verified live (2026-08-27): julia modules 1.11.3 / 1.12.5 on all four GP
clusters; `def-snakagaw_cpu` + `def-snakagaw_gpu` associations on all four;
`GLLVM` precompiles and `using GLLVM` succeeds on every host (Rorqual's
instantiate emitted transient libc frames from a precompile subprocess crash
that Pkg recovered from — load verified afterwards).

Known issues found during provisioning:

- **`/project/def-snakagaw` is over quota on Fir and Rorqual** — first setup
  attempt failed there with "Disk quota exceeded"; those two hosts fall back
  to `$HOME`. Two partial directories from the failed attempts remain at
  `/project/def-snakagaw/snakagaw/{GLLVM.jl-lane,julia_depot}` on both hosts,
  flagged to the maintainer for deletion (guard-blocked for the agent).
- Killarney has no CPU association (AI cluster, `aip-` only) — excluded from
  the CPU-campaign pool.

Division of labour (roadmap, "replan three workflows"): Totoro = no-queue
fast loop (parallel `Pkg.test()` per lane, quick campaigns); the four GP
clusters = SLURM job-array campaigns (quadrature adjudication, ADEMP
recovery), tasks ≤3 h, throttled arrays, results to `/project` where quota
allows. D-139 estimate-first + pre-run test still gate every campaign.

Update path: each checkout tracks `claude/lane-beyond-20260824`; `git pull`
before a run, or clone a specific branch for lane-parallel verification.
