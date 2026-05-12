## 1. OpenSpec

- [x] 1.1 Add CLI workflow proposal, design, tasks, and spec delta.
- [x] 1.2 Validate the `cli-workflows` change strictly.

## 2. CLI Implementation

- [x] 2.1 Add a package CLI module with subcommand dispatch and focused argument-parsing helpers.
- [x] 2.2 Implement the `qc` command over `complexbrowser_run_qc()`.
- [x] 2.3 Implement the `complex` command over `complexbrowser_run_qc()` and `complexbrowser_run_complex_analysis()`.
- [x] 2.4 Add an installed executable script under `exec`.
- [x] 2.5 Document the public CLI function and command usage.

## 3. Tests

- [x] 3.1 Add unit tests for missing arguments, invalid booleans, and unsupported commands.
- [x] 3.2 Add a QC CLI smoke test that verifies output files and table content.
- [x] 3.3 Add a complex-analysis CLI smoke test that verifies output files and complex table content.

## 4. Validation

- [x] 4.1 Run unit tests and fixture parity tests.
- [x] 4.2 Run command-line smoke tests through the package CLI function.
- [x] 4.3 Run `R CMD build` and `R CMD check`.
- [x] 4.4 Run OpenSpec validation for the change and canonical specs.
