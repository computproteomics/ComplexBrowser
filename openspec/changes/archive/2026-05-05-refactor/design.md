## Context

The current app works as a Shiny application, but much of the behavior lives in broad files with mixed concerns: `server.R` owns reactive state and workflow orchestration, while `Functions.R` contains validation-adjacent logic, calculations, database handling, plotting helpers, and summary helpers. This makes it hard to test the existing behavior before refactoring and harder to expose the workflows to other software.

The first refactor should create a package boundary without changing scientific output. Full command-line execution is intentionally left for a follow-up change; this change creates the reusable functions and result objects that a CLI can later call.

## Goals / Non-Goals

**Goals:**

- Preserve current Shiny results for fixed inputs.
- Add regression fixtures before moving behavior.
- Move core computation and data preparation toward package functions callable without Shiny.
- Keep Shiny as an adapter over package APIs.
- Make the extracted code shorter, easier to test, and less deeply nested.
- Define stable result objects for QC/statistics and complex analysis.
- Establish `complexbrowser` as the package name.
- Move prepared database RDS files into package-managed `inst/extdata` assets.

**Non-Goals:**

- Do not change the statistical methods, thresholds, database content, or plot semantics.
- Do not implement the final command-line interface yet.
- Do not redesign the Shiny UI.
- Do not replace existing plotting libraries.

## Decisions

### 1. Characterize current behavior before extraction

Create fixture outputs from the current implementation using the bundled example data and selected complex-analysis settings. Store expected tables and compact metadata under test fixtures. Compare identifiers, column names, row counts, factor-like labels, and rounded display values exactly; compare unrounded numeric values with a 0.1% relative tolerance.

Alternative considered: refactor first and manually inspect results. That would make regressions hard to distinguish from intentional cleanup.

### 2. Extract package APIs in workflow-sized slices

Introduce package functions around natural workflow boundaries:

- Input reading and validation.
- Input layout preparation and column naming.
- QC/statistics calculation.
- Database loading/preparation and user database validation.
- Complex matching and complex-level scoring.
- Summary table/text preparation.
- Export table/report preparation.

The Shiny server should call these functions and assign returned objects to reactive state. Core functions should not read Shiny inputs directly, write files unexpectedly, call `update*Input()`, or mutate `reactiveValues`.

Alternative considered: move `Functions.R` wholesale into `R/`. That would create a package-shaped project but preserve the current long-function and mixed-side-effect problems.

### 3. Use explicit result objects

Use simple S3-friendly list objects with stable names, for example:

- `complexbrowser_qc_result`: prepared input, statistics list, merged display table, metadata for conditions/replicates/design/normalization.
- `complexbrowser_complex_result`: filtered statistics, filtered database, display table, complex scores, selected thresholds, species, and database metadata.

These objects should be serializable to RDS and convertible to CSV/TSV/JSON-friendly tables where relevant.

Alternative considered: return only data frames. That is convenient for a single table but loses metadata needed by Shiny, reports, and future CLI workflows.

### 4. Keep Shiny adapters thin

`server.R` should keep UI orchestration, progress reporting, downloads, and reactive wiring. It should delegate validation and computation to package functions and handle returned success/error objects consistently. Plot rendering may remain in Shiny initially, but data preparation for plots should move out when it is coupled to calculations.

Alternative considered: extract all plots immediately. That is broader than needed for result parity and increases the chance of UI regressions.

### 5. Code structure constraints

New or extracted functions should have one responsibility and use guard clauses for invalid input. As a working guideline, functions that exceed roughly 50 to 80 lines, require nesting deeper than two levels, or mix I/O with computation should be split before review. Shared helpers should be named for domain behavior, not for UI controls.

### 6. Package name

Use `complexbrowser` as the R package name. The repository and visible app branding can remain `ComplexBrowser`, but package metadata, namespaces, documentation examples, and future command-line entry points should use the lower-case package name.

Alternative considered: keep `ComplexBrowser` as the package name. Lower-case `complexbrowser` is easier to type in code, scripts, and command-line contexts.

### 7. Package database assets

Move prepared database RDS files used by the app into `inst/extdata` during this refactor and load them through package accessors. The database content should not change. Shiny should use the same package accessors as R scripts so future CLI workflows inherit the same database-loading behavior.

Alternative considered: leave RDS files at the repository root until a later packaging change. Moving them now reduces hidden file-path assumptions while the Shiny code is being rewired.

## Risks / Trade-offs

- Existing calculations may rely on implicit globals or Shiny state -> Characterization tests and explicit function arguments expose those dependencies before extraction.
- Numeric output may differ due to row ordering or coercion -> Preserve current ordering and column names, and compare fixtures with 0.1% relative tolerance for unrounded numeric values.
- Moving RDS files can break existing relative-path loads -> Add package accessors and update Shiny startup to use those accessors before removing root-path assumptions.
- Package extraction may create a large mechanical diff -> Move code in small slices and keep behavioral edits separate from file relocation.
- Test fixtures may overfit current bugs -> Document fixture scope and require explicit OpenSpec changes before intentionally changing scientific output.
- Plot object equality may be brittle -> Test plot data and key labels where possible, using browser/PDF checks only as smoke tests.

## Migration Plan

1. Generate current-output fixtures on the `refactor` branch before moving code.
2. Add `complexbrowser` package metadata and test infrastructure.
3. Move prepared database RDS files into `inst/extdata` and add package accessors.
4. Extract one workflow slice at a time into package functions.
5. Rewire the Shiny server to call extracted functions and package database accessors.
6. Run regression tests after each slice.
7. Keep old wrappers temporarily when needed to reduce Shiny churn, then remove wrappers once equivalent tests pass.

Rollback is straightforward while changes are sliced: revert the latest extraction slice and keep the fixtures/tests.

## CLI Follow-up Notes

The package functions created in this change are the intended API surface for a later command-line change. That follow-up should add a thin CLI layer over `complexbrowser_run_qc()`, `complexbrowser_run_complex_analysis()`, and the export helpers, with explicit arguments for input path, condition/replicate layout, database, organism, normalization, design, and output directory. The CLI should not read Shiny inputs, source `server.R`, or duplicate the scientific calculations.
