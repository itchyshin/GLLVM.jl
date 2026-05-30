---
name: prose-style-review
description: Review and improve GLLVM.jl prose in README files, tutorials under docs/src/, Documenter pages, after-task reports, release notes, design docs, and manuscript-style text for clarity, concrete claims, stable terminology, citations, and reader fit.
---

# Prose Style Review

Use this skill for substantial prose, especially public documentation and
after-task reports. It is a compact GLLVM.jl adaptation inspired by
`yzhao062/agent-style`; do not copy that project into this repository or add a
package dependency.

## Reader First

Before editing, name the reader:

- applied ecology, evolution, or environmental-science user;
- adjacent-field graduate student;
- statistical method developer;
- Julia package contributor;
- reviewer of a paper, grant, or release.

Write for that reader's current knowledge. Explain a term when the reader
would otherwise have to infer it from context.

## Review Checklist

1. Lead with purpose before mechanics.
2. For model docs, pair symbolic equation, Julia syntax, and interpretation.
3. Replace vague nouns with concrete functions, parameters, files, equations,
   checks, or numerical results.
4. Use active voice when the actor matters.
5. Delete filler phrases such as "it is important to note that", "in order to",
   "various factors", "significant improvements", and "leverages".
6. Do not over-bullet. Use bullets for genuine lists; use prose for one or two
   connected ideas.
7. Keep terms stable: `Λ` (lower-triangular factor loadings), `σ_eps` (residual
   standard deviation, profiled out), `fit_gaussian_gllvm`, `gaussian_marginal_loglik`,
   `phylo()`, `sparse_phy`, `edge_incidence`. Say "fit object" not "model object",
   "exported function" not "user-facing function", "marginal log-likelihood" not
   "likelihood function" when the distinction matters. Use "loadings" for the
   columns of `Λ`; use "latent variables" or "scores" for the conditional means
   from the E-step, not "factors" alone. Reserve "phylogenetic precision" for the
   sparse augmented-state representation; reserve "contrasts" for the Felsenstein
   path; reserve "edge incidence" for the matrix-free `B·W·Bᵀ` path.
8. Support factual, statistical, or literature claims with citations, local
   evidence, check outputs, or a clear "design assumption" label.
9. For tutorials and error-message docs, tell the reader what to do next when a
   family, link, or representation is unsupported (e.g. the v0.1.0 Gaussian-only
   boundary).
10. Define location, scale, loading, latent dimension, and phylogenetic signal
    at first use. In particular, connect `Λ` to residual species covariance
    `Σ_y = ΛΛᵀ + σ_eps² I`, and connect `H²` to the phylogenetic share of
    trait variance.
11. End paragraphs with the point the reader should carry forward.
12. Avoid repeated sentence openings and repeated paragraph-summary closers.

## Role Guidance

- Pat checks whether an applied user can follow the prose, run the
  `@example` block, and interpret the output.
- Rose checks stale wording, unsupported claims, duplicated summaries, and
  contradictions with code, docs, tests, roadmap, or after-task notes.
- Documentation writers check `@example` blocks, headings, equations,
  citations, and Documenter navigation (tutorials under `docs/src/`,
  cross-references, sidebar) as one learning path.

## Output

For a review-only task, return:

- blocking confusion;
- important friction;
- small polish;
- suggested wording for the highest-impact fixes.

For an edit task, make the smallest prose edits that fix the problem, then
record what changed in the check log or after-task report when the task is
meaningful.
