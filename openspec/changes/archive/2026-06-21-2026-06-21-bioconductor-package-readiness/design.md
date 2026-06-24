## Context

The package already has the main workflow pieces in place. What is still missing for a Bioconductor submission is the package surface around those workflows: metadata, examples, vignettes, install-time layout, and check cleanliness. The goal here is to make the repo look and behave like a Bioconductor package without changing the analysis.

## Goals / Non-Goals

**Goals:**

- Make the package submission-ready for Bioconductor review.
- Keep the QC and complex-analysis results stable for fixed bundled inputs.
- Ensure exported functions are documented with runnable examples.
- Make the vignettes reproducible and self-contained.
- Keep the Shiny app packaged under `inst/shiny/`.
- Remove build and check noise from generated files and local artifacts.

**Non-Goals:**

- Do not redesign the scientific methods.
- Do not change default thresholds, database content, or output schemas.
- Do not add new analysis features just to satisfy packaging rules.
- Do not expand the CLI beyond what is already needed for installed-package use.

## Decisions

### 1. Freeze scientific behavior first, then package the edges

Keep the current workflow outputs as the reference. Bioconductor readiness work should preserve the existing tables, identifiers, and summary values. If a documentation or packaging change risks output drift, it is too broad for this change.

### 2. Treat package metadata as part of the contract

Update package metadata for Bioconductor conventions, including first-submission versioning, dependency declarations, and package fields that help review and build systems. This should be done once, directly, instead of layering in compatibility hacks.

### 3. Make documentation runnable, not just descriptive

Every exported function should have a short runnable example. Vignettes should show the two main workflows, use the installed package data, and end with session information. If an example is expensive, it should be made minimal rather than hidden behind a long `dontrun` block.

### 4. Keep the Shiny app packaged, thin, and installable

The app should stay under `inst/shiny/` and load from package-managed paths. The package-facing helper should be enough to launch it after install. Shiny should remain an adapter over package functions, not a second implementation of the workflows.

### 5. Keep the tree clean

Generated files, local check artifacts, backup files, and other transient outputs should be ignored or removed so they do not show up in source builds or review diffs.

### 6. Keep code short

Any new helper should stay small and single-purpose. Prefer guard clauses over nested branching. Split logic before it becomes hard to test or review.

## Risks / Trade-offs

- Bioconductor conventions may expose missing documentation or packaging fields -> address them directly rather than masking them.
- Vignettes can become slow -> keep them short and use bundled example data.
- App packaging changes can break file lookup -> use package-relative paths and add smoke checks.
- Cleaning build artifacts can conflict with tracked legacy files -> remove only generated files and keep historical sources under the agreed source directories.

## Migration Plan

1. Align package metadata and versioning with Bioconductor conventions.
2. Finish help pages for all exported functions, including examples.
3. Add or tighten vignette session info and reproducible workflow examples.
4. Verify the Shiny app resolves through `inst/shiny/` and installed-package helpers.
5. Clean source-tree artifacts and ignore transient build outputs.
6. Run package build, check, vignette, and BiocCheck validation.
