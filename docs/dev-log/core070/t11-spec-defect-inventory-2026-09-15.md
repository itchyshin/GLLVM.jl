# T11 — `BLOCKED_SPEC_DEFECT` row register (22 @ `25af0c0f1`)

Machine-readable companion to
`docs/dev-log/after-task/2026-09-15-t11-spec-defect-inventory.md`.

```yaml
programme_head: 25af0c0f1
disposition: BLOCKED_SPEC_DEFECT
count: 22
fence: inventory_only_not_fix_not_covered
rows:
  - source_id: covariance/COV-ANIMAL-FOLDED-UNIQUE
    class: julia_mis_disposition
    theme: folded animal_latent unique=TRUE; formula plan exists
  - source_id: covariance/COV-SLOPE-F01-L0
    class: joint_ambiguity
    theme: binomial logit augmented slope; draft not in slopes annex
  - source_id: covariance/COV-SLOPE-F01-L1
    class: joint_ambiguity
    theme: binomial probit augmented slope; draft not in slopes annex
  - source_id: covariance/COV-SLOPE-F03-L0
    class: joint_ambiguity
    theme: lognormal augmented slope
  - source_id: covariance/COV-SLOPE-F04-L0
    class: joint_ambiguity
    theme: Gamma augmented slope
  - source_id: covariance/COV-SLOPE-F05-L0
    class: joint_ambiguity
    theme: NB2 augmented slope
  - source_id: covariance/COV-SLOPE-F07-L0
    class: joint_ambiguity
    theme: Beta augmented slope
  - source_id: covariance/COV-SLOPE-F08-L0
    class: joint_ambiguity
    theme: beta-binomial augmented slope
  - source_id: covariance/COV-SLOPE-F09-L0
    class: joint_ambiguity
    theme: Student-t augmented slope; bridge gate cross-ref r-side-defects B
  - source_id: covariance/COV-SLOPE-F14-L0
    class: joint_ambiguity
    theme: ordinal probit augmented slope
  - source_id: covariance/COV-SLOPE-F15-L0
    class: joint_ambiguity
    theme: NB1 augmented slope
  - source_id: postfit/POSTFIT-SURFACE-ordiplot
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-plot.gllvmTMBmesh
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-plot.sdmTMBmesh
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_Sigma_phy_slope
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_check_consistency
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_confint_inspect
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_coverage_study
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_identifiability
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_reportable_table
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-print.gllvmTMB_slope_ci
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
  - source_id: postfit/POSTFIT-SURFACE-tidy
    class: julia_mis_disposition
    reclassify_proposed: compatibility_adapter
top_actions:
  - rank: 1
    action: ledger_reclassify_11_postfit_compatibility_adapter
  - rank: 2
    action: author_slopes_annex_from_covariance_drafts
  - rank: 3
    action: retriage_COV_ANIMAL_FOLDED_UNIQUE_split_bind_vs_needs_surface
  - rank: 4
    action: gllvmtmb_T11_verify_slope_admission_vs_bridge_readonly
  - rank: 5
    action: docs_fence_SPEC_DEFECT_not_equal_engine_bugs
```
