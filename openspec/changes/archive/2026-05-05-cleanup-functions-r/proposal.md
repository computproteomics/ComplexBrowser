## Why

`Functions.R` remains as a legacy catch-all even after package APIs and CLI workflows were extracted. The app still sources it only because plotting and Shiny UI helpers have not yet been moved. Keeping the file makes ownership unclear and preserves obsolete database/statistics code beside the new package implementation.

## What Changes

- Move still-used Shiny plotting and UI helper functions out of `Functions.R` into focused app helper files.
- Remove `source("Functions.R")` from the Shiny startup path.
- Replace tests that source `Functions.R` with tests that use package fixtures and current package helpers.
- Delete the root `Functions.R` file after all references are removed.

## Compatibility

- Shiny plot behavior and table helper behavior should stay unchanged.
- Package QC, complex-analysis, export, and CLI APIs should stay unchanged.
- Scientific calculations and bundled database content are not changed.

## Non-Goals

- Do not redesign plots.
- Do not convert all plot helpers into public package APIs.
- Do not change Shiny UI layout.
