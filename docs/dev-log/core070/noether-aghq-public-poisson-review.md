# Noether — public Poisson AGHQ review

Fresh native dispatch /root/noether_public_poisson_review, planned and requested
Terra/high, fresh context. Read-only numerical implementation review, no fits,
no private histories, no production child or milestone completion panel.

Initial findings:
1. P1 bootstrap omitted the caller's Laplace warm-start controls. Repaired by
   copying base_controls into AGHQFitInfo and replaying them through
   _poisson_aghq_refit_kwargs, with fitted K/node/control/mask/offset overrides.
   Tests check explicit iterations=37, same controls and nonaliased mask.
2. P2 hessian was accepted but ignored by observed AGHQ adaptation. Eligible
   requests now reject an explicit non-observed selector, with regression.

One allowed repair follow-up inspected both changes and reported no remaining
concrete blocker within those findings. The masked-offset prediction correction
was inspected as internally coherent. This is source-review evidence, not full
Core070 parity or numerical/recovery sign-off. Tool model override was Terra/high;
no independent provider-side model receipt or aggregate hours invented.
