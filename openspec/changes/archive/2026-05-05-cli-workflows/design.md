## Context

The `refactor` change introduced reusable package functions:

- `complexbrowser_run_qc()`
- `complexbrowser_run_complex_analysis()`
- database accessors and CSV export helpers

The CLI should be a thin I/O and argument-validation layer over those functions. It should not source `server.R`, mutate Shiny state, or reimplement calculations.

## Command Shape

Add a package-level CLI function:

- `complexbrowser_cli(args = commandArgs(trailingOnly = TRUE))`

Add an installed executable script:

- `exec/complexbrowser`

Initial subcommands:

- `qc`: read input, run QC/statistics, write QC outputs.
- `complex`: read input, run QC/statistics, run complex analysis, write QC and complex outputs.

## Arguments

Common arguments:

- `--input`: required CSV input path.
- `--outdir`: required output directory; created when missing.
- `--conditions`: required positive integer.
- `--replicates`: required positive integer.
- `--grouped`: optional boolean, default `false`.
- `--log2`: optional boolean, default `true`.
- `--q-values`: optional boolean, default `true`.
- `--normalization`: optional value; `none`, `Total Intensity`, `Mean`, `Median`, or `Quantile`.
- `--design`: optional value; `unpaired` or `paired`, default `unpaired`.

Complex-analysis arguments:

- `--database`: required for `complex`; `CORUM`, `EBI Complex Portal`, or a user database CSV path.
- `--organism`: required for `complex`.
- `--database-name`: optional metadata label; defaults to `--database`.

## Outputs

`qc` writes:

- `input_statistics.csv`
- `qc_result.rds`

`complex` writes:

- `input_statistics.csv`
- `qc_result.rds`
- `complex_table.csv` when matching complexes exist.
- `complex_result.rds`

No-match complex analysis should still write `complex_result.rds` and exit successfully, because it is a valid analysis result.

## Error Handling

The CLI should:

- Print concise errors to stderr.
- Return status `2` for usage or validation errors.
- Return status `1` for unexpected runtime failures.
- Return status `0` on successful runs, including no-match complex analysis.

## Code Structure

Use small helpers for parsing, boolean coercion, path validation, directory creation, and writing outputs. Keep computation in the existing package APIs. Avoid nested command logic by dispatching subcommands to dedicated functions.

## Validation

Add unit tests for argument parsing and command execution with fixtures. Add smoke tests that run `complexbrowser_cli()` for both `qc` and `complex` against bundled example data. Run package tests, build/check, and OpenSpec validation.
