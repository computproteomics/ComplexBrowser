## Why

ComplexBrowser currently mixes Shiny state, data validation, statistical calculations, complex matching, plotting, and exports in large application files. Factoring the app into package-level APIs is needed before the same workflows can be reused reliably from R scripts, tests, other software, and later command-line entry points.

## What Changes

- Add a package API boundary for core workflows that can run without Shiny.
- Extract input validation, QC/statistics, complex matching, complex scoring, summaries, and export preparation behind stable R functions.
- Keep the Shiny app behavior-compatible by making server reactives call the extracted APIs.
- Add characterization fixtures and regression tests that prove refactoring preserves current QC and complex-analysis results.
- Add focused smoke tests for the Shiny workflows most likely to regress during extraction.
- Establish `complexbrowser` as the package name for the refactored R package.
- Move bundled prepared database RDS files into package-managed `inst/extdata` assets without changing their content.
- Do not rewrite scientific methods, change thresholds, change bundled databases, or introduce the final command-line interface in this change.

## Capabilities

### New Capabilities

- `package-api`: Reusable R package APIs for running ComplexBrowser workflows without Shiny while preserving current results.

### Modified Capabilities

- `input-qc`: QC and statistics behavior must remain equivalent when driven through extracted package functions.
- `complex-analysis`: Complex matching, complex scoring, summaries, and selected complex views must remain equivalent when driven through extracted package functions.
- `exports`: Existing Shiny exports must continue to use the same filenames, formats, and data content after package extraction.

## Impact

- Affected code: `Functions.R`, `server.R`, `ui.R`, `Global.R`, future `R/`, future `tests/testthat/`, and possibly package metadata such as `DESCRIPTION` and `NAMESPACE`.
- Affected callers: Shiny users first; R users and future CLI callers through the new package boundary.
- Affected data: bundled example CSV and prepared RDS databases are used as fixtures; prepared database RDS files move to `inst/extdata` but their content is not changed.
- Compatibility: existing CSV/TXT inputs, q-value semantics, generated table columns, and complex-analysis thresholds must remain stable unless a later OpenSpec change explicitly modifies them.
