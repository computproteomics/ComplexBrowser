## Context

The QC workflow currently computes q-values through the existing statistics path. That implementation is good enough for the current package refactor, but it is a distinct scientific choice and should be changed in isolation. This change should replace the statistical core while leaving the package shape and workflow wiring alone.

## Goals / Non-Goals

**Goals:**

- Replace the QC statistical test with `PolySTest`.
- Preserve the public workflow function names and result object shapes.
- Keep Shiny and CLI callers working through the same package entry points.
- Refresh tests and fixtures for the new statistical results.

**Non-Goals:**

- Do not refactor package layout.
- Do not change the database formats or file locations.
- Do not change exports, report templates, or help text unrelated to the statistical method.
- Do not alter the non-statistical QC calculations unless required by the new test.

## Decisions

### 1. Keep the public API stable

The package should still expose the same QC workflow entry points. Only the internal statistical engine changes.

### 2. Expose only workflow-level PolySTest controls

ComplexBrowser should not mirror the full PolySTest API. The public QC surface should stay at workflow level: input layout, normalization, paired versus unpaired design, and the significance threshold already used by the package workflow. Any PolySTest-specific tuning parameters that do not map cleanly onto existing ComplexBrowser concepts should remain internal defaults.

### 3. Rebaseline outputs deliberately

Because the test changes scientific output, the fixture data and regression expectations must be regenerated from a fixed example dataset and recorded as a new baseline.

### 4. Limit the change to statistical code paths

The implementation should touch the smallest number of files possible: QC/statistics code, any helper functions needed by `PolySTest`, and the tests that validate the results.

### 5. Preserve the rest of the workflow

Input validation, database selection, export naming, and Shiny/CLI wiring should remain unchanged unless the new test forces a small compatibility adjustment.

### 6. Map PolySTest onto the existing QC shape

The returned QC result object should keep the current fields and table shapes so downstream complex analysis and exports do not need a second round of structural changes. Only the statistical values inside those tables should change.

## Risks / Trade-offs

- New statistical output will not match prior fixtures -> update fixtures and document the expected difference.
- Package dependency changes may be needed -> prefer existing package dependencies where possible, and add only what the new method needs.
- Downstream complex-analysis filtering may shift because the QC input changes -> validate the main bundled workflow after the new test is in place.

## Migration Plan

1. Add or update the statistical helper functions that use `PolySTest`.
2. Recompute QC fixtures from the bundled example input.
3. Update the QC and complex-analysis regression tests to the new baseline.
4. Run the installed-package workflow checks and smoke-test the Shiny and CLI entry points.
