# DRAC routing authorization and live connection check

User2026-08-31: up to five DRAC computers available; report connection failures.
Brain retrieval: shinichi-brain/tools/drac-setup (ask-brain MCP, all-project
search), then current socket/scheduler/account verification. The brain identifies
five general-purpose clusters; their live results, not historical hardware
claims, determine routing here. See drac-five-host-readiness.json for timestamp.

| Cluster | Existing socket | Scheduler/account readback |
|---|---|---|
| Fir | reachable | sbatch; def-snakagaw_cpu, def-snakagaw_gpu |
| Nibi | reachable | sbatch; def-snakagaw_cpu, def-snakagaw_gpu |
| Rorqual | reachable | sbatch; def-snakagaw_cpu, def-snakagaw_gpu |
| Trillium | reachable | sbatch; def-snakagaw |
| Narval | reachable | sbatch; def-snakagaw_cpu, def-snakagaw_gpu |

No fresh login, Duo, environment installation or compute was triggered.
The current user's queue readback was empty on all five. This proves access
at the recorded time, not available compute allocations, package environments,
module compatibility, node availability or a validated benchmark host.

Recheck the selected socket at dispatch with no fallback to a fresh login. If
it fails, report the host and stage immediately; distinguish sandbox EPERM,
expired socket, timeout and scheduler rejection. Do not restart an unobserved
job merely because a status query times out. No background connection monitor
was installed; the checks occur at actual dispatch and observation boundaries.

Use scheduled allocations only, with explicit time/account. Keep full run
source/environment/fixture pins and failures; arrays partition seeds/cases.
Use at most five authorized DRAC hosts concurrently, with independently stated
per-job node/core/memory requests. Five reachable clusters is not permission
to consume unbounded nodes per cluster. Totoro stays<=150cores for bounded
qualification; large evidence campaigns default to DRAC. No claim-bearing
scientific campaign on GitHub Actions. Runs>30min still require the sized
pre-run and user approval; this access authorization does not waive that gate.
