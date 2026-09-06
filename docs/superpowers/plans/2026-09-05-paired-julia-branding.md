# Paired Julia Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add matched, original Julia-adjacent hex badges for GLLVM.jl and DRM.jl, and integrate the GLLVM.jl badge into its reader-first landing page with an honest optional-companion connection to gllvmTMB.

**Architecture:** Keep the identity system deliberately small and native to each documentation site: a project-local SVG master plus generated `logo.png` and `favicon.ico` derivatives. DocumenterVitepress auto-detects those conventional files, so its generated configuration remains untouched. The GLLVM landing page consumes its own mark through VitePress home markup and scoped CSS; DRM.jl receives its matching asset in a separate, clean worktree so its detached shared checkout is untouched.

**Tech Stack:** SVG, VitePress/DocumenterVitepress, Markdown, CSS, Julia local documentation builds.

---

### Task 1: Create the paired source marks

**Files:**
- Create: `GLLVM.jl/docs/src/assets/gllvmjl-mark.svg`
- Create: `GLLVM.jl/docs/src/assets/gllvmjl-favicon.svg`
- Create: `DRM.jl/docs/src/assets/drmjl-mark.svg`
- Create: `DRM.jl/docs/src/assets/drmjl-favicon.svg`

- [ ] **Step 1: Add the GLLVM.jl mark**

Use an original rounded hexagon, dark navy field, red/green/purple trim, a five-row response grid, and a single curved latent axis.  Do not include text, Julia's wordmark, or the official Julia dot arrangement.

- [ ] **Step 2: Add the DRM.jl mark**

Use the same hexagon, navy field, and trim, but replace the matrix grid with three nodes and two directed, arrow-ended dependency paths.  Retain a small highlighted conditional node so the two icons are recognisably paired but semantically distinct.

- [ ] **Step 3: Add favicon simplifications**

Retain the outer hexagon and only the primary internal cue: a single curved shared axis for GLLVM.jl and a two-arrow path for DRM.jl.  Use viewBox `0 0 128 128` and no text.

- [ ] **Step 4: Inspect source geometry at small scale**

Open both favicon SVGs at 16--32 px and confirm that their interior cues are visually distinguishable.  If detail collapses, remove secondary nodes/lines rather than shrinking strokes below 5 px in the 128 px master.

- [ ] **Step 5: Commit the asset-only change in each repository**

Run `git add docs/src/assets/*mark.svg docs/src/assets/*favicon.svg` in the relevant clean worktree and commit with `docs: add <package> hex identity assets`.

### Task 2: Integrate the GLLVM.jl identity

**Files:**
- Modify: `GLLVM.jl/docs/src/index.md`
- Modify: `GLLVM.jl/docs/src/.vitepress/theme/overrides.css`

- [ ] **Step 1: Add a decorative hero badge**

Immediately after the VitePress front matter in `docs/src/index.md`, add:

```html
<div class="gllvm-brand-mark" aria-hidden="true">
  <img src="/assets/gllvmjl-mark.svg" alt="" />
</div>
```

This is decorative; the visible `GLLVM.jl` title remains the page's accessible identity.

- [ ] **Step 2: Add scoped responsive styling**

Append CSS that places `.gllvm-brand-mark` at the right of the desktop hero,
sets the image to 12rem maximum width, and hides it below 960 px.  The existing
768--1100 px drawer-navigation guard must remain unchanged.

- [ ] **Step 3: Add conventional asset derivatives**

Generate `docs/src/assets/logo.png` and `docs/src/assets/favicon.ico` from the
approved SVG master. DocumenterVitepress auto-detects these conventional files,
so leave `docs/src/.vitepress/config.mts` exactly as generated.

- [ ] **Step 4: Add the companion link without widening claims**

In the hero feature titled `A companion, not a replacement`, link `gllvmTMB`
to `https://itchyshin.github.io/gllvmTMB/` and retain the sentence that GLLVM.jl
has partial parity.  Do not add a parity claim, an engine requirement, or a
promise that the Julia route replaces R.

- [ ] **Step 5: Commit the GLLVM.jl integration**

Run `git add docs/src/index.md docs/src/assets/logo.png docs/src/assets/favicon.ico docs/src/.vitepress/theme/overrides.css` and commit with `docs: integrate GLLVM hex identity`.

### Task 3: Validate locally and retain honest boundaries

**Files:**
- Modify: `GLLVM.jl/docs/dev-log/check-log.md`
- Create: `GLLVM.jl/docs/dev-log/after-task/2026-09-05-paired-julia-branding.md`

- [ ] **Step 1: Render GLLVM.jl docs locally**

Run `julia --project=docs docs/make.jl --local`.  Expected: successful local Documenter/Vitepress output with no favicon or asset resolution error.

- [ ] **Step 2: Inspect desktop and narrow layouts**

Check the rendered home at 1440 px and 768 px.  Expected: the badge sits beside the hero on desktop; at 768 px it is hidden and the existing drawer navigation remains available.

- [ ] **Step 3: Record evidence and non-claims**

Append the exact render command and result to `docs/dev-log/check-log.md`.  Write the after-task report stating that the assets are original, the Julia connection is visual rather than official affiliation, and no public deployment occurred.

- [ ] **Step 4: Commit validation documentation**

Run `git add docs/dev-log/check-log.md docs/dev-log/after-task/2026-09-05-paired-julia-branding.md` and commit with `docs: record paired branding validation`.

- [ ] **Step 5: Present local rendered evidence**

Show the rendered GLLVM.jl page and the two marks to the maintainer.  Do not push, create a PR, invoke Documenter deploy, or modify the live gllvmTMB/DRM.jl sites without explicit approval.
