## 1. Statistical Core

- [x] 1.1 Map the current QC inputs and outputs to the equivalent `PolySTest` inputs and outputs.
- [x] 1.2 Decide which QC controls stay public: normalization, paired versus unpaired design, and significance cutoff.
- [x] 1.3 Implement the `PolySTest` adapter in the QC statistics helper that currently calculates q-values.
- [x] 1.4 Keep the public QC function signatures and result object shapes stable.
- [x] 1.5 Verify the new calculation still produces the expected per-condition q-value columns and summary tables.

## 2. Regression Refresh

- [x] 2.1 Regenerate the QC fixture from the bundled example input with the new `PolySTest` baseline.
- [x] 2.2 Regenerate downstream complex-analysis fixtures that depend on the new QC values.
- [x] 2.3 Update the QC regression test to compare q-values, summary tables, and metadata against the new baseline.
- [x] 2.4 Update the complex-analysis regression test to compare only the rows and values that change because of the new QC baseline.

## 3. Validation

- [x] 3.1 Run package unit tests for QC, complex analysis, and export helpers.
- [x] 3.2 Run Shiny smoke checks on the bundled example workflow and confirm the analysis tabs still render.
- [x] 3.3 Run CLI smoke checks for both `qc` and `complex`.
- [x] 3.4 Run package check and record any new warnings or notes.
  - `R CMD check --no-manual --as-cran complexbrowser_0.99.1.tar.gz`: 0 warnings, 3 notes.
  - Notes are limited to unavailable network URL checks/current time verification in this sandbox, and examples taking more than 5 seconds.
