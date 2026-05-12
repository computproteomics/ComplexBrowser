## 1. App Helper Split

- [x] 1.1 Add focused Shiny helper files for QC plots, complex plots, and UI helpers.
- [x] 1.2 Source the focused helper files from `ui.R`.
- [x] 1.3 Remove `source("Functions.R")` from `ui.R`.

## 2. Legacy Removal

- [x] 2.1 Rewrite tests that source `Functions.R`.
- [x] 2.2 Delete root `Functions.R`.
- [x] 2.3 Confirm no runtime or test references to `Functions.R` remain.

## 3. Validation

- [x] 3.1 Run unit tests and fixture parity tests.
- [x] 3.2 Run Shiny smoke tests for load example and complex analysis.
- [x] 3.3 Run package build/check.
- [x] 3.4 Validate OpenSpec specs and the cleanup change.
