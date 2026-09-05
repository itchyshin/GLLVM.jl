"""Frozen gllvmTMB oracle pins for GLLVM.jl parity tools (P13 / D-220).

Export-surface parity reads R's ``NAMESPACE`` at ``DEFAULT_R_REF`` (frozen
gllvmTMB 0.7.0). Capability-status CLOSURE uses ``gllvmTMB/tools/parity_ledger.R``
with ``CAPABILITY_LEDGER_REF`` on both sides — ``docs/design/capability-status.md``
post-dates the oracle commit and is absent at ``DEFAULT_R_REF``.
"""

# frozen gllvmTMB 0.7.0 export oracle (CI + programme qualification pin)
FROZEN_GLLVMTMB_ORACLE = "b4d5fee64def88bc768dda1f1f77c29b295edd86"
FROZEN_GLLVMTMB_VERSION = "0.7.0"
FROZEN_GLLVMTMB_SHORT = FROZEN_GLLVMTMB_ORACLE[:8]

# Default R-side git ref for NAMESPACE / export parity (not working tree, not live main)
DEFAULT_R_REF = FROZEN_GLLVMTMB_ORACLE

# Capability ledger join: file landed after the frozen oracle (see r-ref-closure-receipt)
CAPABILITY_LEDGER_REF = "origin/main"
