## Why

ComplexBrowser currently exports several helpers that are internal plumbing rather than stable user-facing API. Trimming those exports will make the package surface smaller and easier to review for Bioconductor without changing workflow behavior.

## What Changes

- Remove exported status from helper functions that only support internal package workflows, Shiny wiring, CLI wiring, tests, or vignettes.
- Keep the main public workflow functions exported.
- Update package documentation and namespace generation to reflect the smaller exported surface.
- Do not change scientific calculations, outputs, or user-facing workflow entry points.

## Capabilities

### Modified Capabilities

- `package-api`: the exported surface becomes smaller and more intentional.
- `exports`: file-writing helpers and filename helpers remain available internally but are no longer part of the public API.
- `cli`: command-line behavior must continue to work through internal helpers.
- `input-qc` and `complex-analysis`: workflow entry points stay public and unchanged.

## Impact

- Affected code: `R/`, `NAMESPACE`, help pages, and any docs that reference the removed exports.
- Affected callers: package-internal code, Shiny, CLI, tests, and vignettes that use the removed helpers directly.
- Affected data: none.
- Compatibility: no scientific output changes; only API exposure changes.
