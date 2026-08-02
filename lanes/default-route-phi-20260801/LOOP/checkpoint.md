# Checkpoint — default-route-phi-20260801

**STATE:** COMPLETE
**BRANCH:** `parity/default-route-phi-20260801`
**TIP:** `ccd55f1f`
**UPDATED:** 2026-08-01

## Done

- S0 call-site inventory
- S1 API B routing flip (`fit_gllvm` NB/Beta `nothing`→`:species`)
- S2 parity retarget to public `fit_gllvm` default
- S3 cascade tests/docs + postfit named-fitter honesty (NB/Beta/Ordinal)
- S4 live parity **63/63** on default path; check-log; after-task; Rose fence;
  coordination-board + AGENTS snapshot; core runtests **5063/1/0/3**
  (sole fail pre-existing one-group NB cell; engines unchanged vs base)

## In progress

None.

## Next

Maintainer ask required for push/PR (see Cursor handover
`docs/dev-log/handover/2026-08-01-cursor-handover-default-route-phi.md`).
Optional follow-up (separate lane): investigate
`test_grouped_dispersion.jl:61` one-group ≈ shared logLik gap.

## Open gate

- **No push** until maintainer asks.
- Pre-existing red cell: `fit_nb_gllvm_grouped` one-group ≈ `fit_nb_gllvm`
  (not introduced here; do not silent-widen).

## Where truth lives

- `lanes/default-route-phi-20260801/LOOP/GOAL.md`
- `docs/dev-log/after-task/2026-08-01-default-route-nb2-beta-pertrait-phi.md`
- Parity log: `/tmp/default-route-phi-parity.log`
- Core suite log: `/tmp/default-route-phi-runtests.log`

## RESUME

DONE — lane COMPLETE locally on `parity/default-route-phi-20260801` @ `ccd55f1f`.
Primary OWED after close: push+PR only when maintainer asks (handover above).
