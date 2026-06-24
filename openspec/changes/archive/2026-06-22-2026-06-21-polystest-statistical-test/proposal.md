## Why

The current QC statistical workflow uses the existing LIMMA-based path for q-value calculation. A later scientific-method change will switch that test to `PolySTest` so the package can use the newer statistical approach without conflating it with packaging or refactoring work.

## What Changes

- Replace the current QC statistical test implementation with a `PolySTest`-based workflow.
- Keep the package API boundary intact so Shiny, CLI, and R callers still invoke the same public workflow functions.
- Expose only the QC controls that already belong to the ComplexBrowser workflow: normalization choice, paired versus unpaired design, and the significance cutoff used by the workflow.
- Keep lower-level `PolySTest` tuning parameters internal unless a concrete ComplexBrowser use case requires them later.
- Update regression expectations for q-values, derived QC summaries, and any downstream tables that depend on the statistical test.
- Add tests that characterize the new statistical output against fixed example data.
- Do not change input parsing, database handling, exports, or the Shiny/CLI entry points in this change.

## Capabilities

### Modified Capabilities

- `package-api`: QC statistics calculation changes, but the public workflow shape should remain stable.
- `input-qc`: q-value and summary behavior changes because the statistical test changes.
- `complex-analysis`: downstream workflows that consume QC statistics may observe different input q-values and filtered results.

## Impact

- Affected code: QC/statistics functions in `R/`, regression fixtures, and tests.
- Affected callers: R users, Shiny users, and CLI callers that rely on QC-derived statistics.
- Affected data: bundled example inputs stay the same; expected outputs will change where the statistical test changes results.
- Compatibility: input formats, database assets, and workflow entry points should stay compatible.
