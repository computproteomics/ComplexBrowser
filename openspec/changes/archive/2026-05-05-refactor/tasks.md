## 1. Characterization Baseline

- [x] 1.1 Add test infrastructure for package-level tests without changing app behavior.
- [x] 1.2 Generate fixture outputs from the current bundled example workflow for QC statistics and the merged input statistics table.
- [x] 1.3 Generate fixture outputs for complex analysis using a fixed database, species, thresholds, and selected complex rows.
- [x] 1.4 Add tests that compare current function outputs to the fixtures with exact checks for identifiers/columns and 0.1% relative tolerance for unrounded numeric values.
- [x] 1.5 Add Shiny smoke tests for app startup, load example, QC table rendering, complex table rendering, and download-control availability.

## 2. Package Boundary

- [x] 2.1 Add minimal `complexbrowser` R package metadata and load/install checks.
- [x] 2.2 Create focused `R/` modules for input, QC/statistics, databases, complex analysis, summaries, exports, and Shiny adapters.
- [x] 2.3 Move prepared database RDS files into `inst/extdata` without changing their content.
- [x] 2.4 Add package accessors for prepared CORUM and EBI Complex Portal databases.
- [x] 2.5 Move package-callable helpers from `Functions.R` into focused modules without changing behavior.
- [x] 2.6 Add documentation stubs for public package functions, database accessors, and expected result objects.

## 3. Extract Input And QC

- [x] 3.1 Implement package functions for file/table validation, condition/replicate layout, and column naming.
- [x] 3.2 Implement package functions for QC/statistics calculation and normalization.
- [x] 3.3 Rewire Shiny QC flows to call the package functions while preserving current error messages and table outputs.
- [x] 3.4 Run QC fixture tests and Shiny smoke tests.

## 4. Extract Complex Analysis

- [x] 4.1 Implement package functions for database selection, user database preparation, species filtering, and complex matching.
- [x] 4.2 Implement package functions for complex scoring, summaries, and display-table preparation.
- [x] 4.3 Rewire `Global.R` and Shiny complex-analysis flows to load prepared databases through package accessors.
- [x] 4.4 Rewire Shiny complex-analysis flows to call the package functions while preserving current table columns, thresholds, and no-match behavior.
- [x] 4.5 Run complex-analysis fixture tests and Shiny smoke tests.

## 5. Exports And Reports

- [x] 5.1 Route statistics-table and complex-table exports through stable package result objects.
- [x] 5.2 Verify exported CSV filenames, columns, and row content match current behavior.
- [x] 5.3 Verify QC report rendering still uses the same data content after QC extraction.
- [x] 5.4 Smoke-test figure downloads for non-empty PDF output where plots are touched.

## 6. Code Quality And Review

- [x] 6.1 Split extracted functions that exceed the agreed short-function guideline or contain deep nesting.
- [x] 6.2 Replace nested validation branches with guard clauses and small named helpers where behavior stays unchanged.
- [x] 6.3 Remove temporary compatibility wrappers once Shiny and package tests pass.
- [x] 6.4 Run package load/install checks, unit tests, fixture parity tests, and Shiny smoke tests.
- [x] 6.5 Document remaining follow-up work for command-line entry points.
