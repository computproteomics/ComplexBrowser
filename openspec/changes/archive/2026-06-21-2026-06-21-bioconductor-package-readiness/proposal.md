## Why

ComplexBrowser is now close to a real R package, but it still needs Bioconductor-facing packaging work before submission. The remaining work is mostly about package structure, metadata, docs, vignettes, checks, and file hygiene. The scientific workflows should stay unchanged.

## What Changes

- Bring package metadata and versioning in line with Bioconductor expectations.
- Finish package documentation so exported functions have runnable examples and clear parameter docs.
- Make the vignettes reproducible and Bioconductor-friendly.
- Keep the Shiny app installable from `inst/shiny/` and package-safe.
- Make the repository pass `R CMD build`, `R CMD check`, and `BiocCheck` without package-owned warnings or notes.
- Remove or ignore generated files that would pollute package builds.
- Keep QC, complex-analysis, exports, and CLI behavior stable unless a separate change explicitly alters them.

## Capabilities

### Modified Capabilities

- `package-api`: package metadata, exported help pages, vignettes, package layout, and check hygiene need Bioconductor-level completion.
- `input-qc`: QC behavior must remain stable while documentation and examples are improved.
- `complex-analysis`: complex-analysis behavior must remain stable while documentation and examples are improved.
- `exports`: export filenames and tables must remain stable while the package is prepared for submission.
- `cli`: existing command-line workflows must remain compatible with package installation and checks.

## Impact

- Affected code: `DESCRIPTION`, `NAMESPACE`, `R/`, `inst/shiny/`, `vignettes/`, `tests/testthat/`, `.gitignore`, and package docs.
- Affected callers: R users, Shiny users, and any CLI callers that rely on installed-package behavior.
- Affected data: bundled example data and prepared databases stay functionally the same, but their package locations and references must be Bioconductor-safe.
- Compatibility: scientific outputs, table columns, thresholds, and bundled database content must not change in this change.
