## ADDED Requirements

### Requirement: Command-Line Entry Point

The system SHALL provide a command-line entry point for running ComplexBrowser workflows without launching Shiny.

#### Scenario: QC command

- **GIVEN** a valid proteomics input CSV
- **AND** valid condition, replicate, layout, q-value, log2, normalization, and design arguments
- **WHEN** the user runs the QC command
- **THEN** the command SHALL write an input-statistics CSV and QC result RDS
- **AND** exit with status 0

#### Scenario: Complex-analysis command

- **GIVEN** a valid proteomics input CSV
- **AND** valid QC arguments, database selection, and organism selection
- **WHEN** the user runs the complex-analysis command
- **THEN** the command SHALL write QC outputs, a complex result RDS, and a complex table CSV when matching complexes exist
- **AND** exit with status 0

### Requirement: CLI Uses Package APIs

The command-line workflows SHALL use documented package APIs for computation and SHALL NOT source Shiny application files.

#### Scenario: Headless execution

- **WHEN** a CLI workflow runs
- **THEN** it SHALL call package-level QC and complex-analysis functions
- **AND** it SHALL NOT require a Shiny session, browser, or reactive state

### Requirement: CLI Validation And Exit Codes

The command-line workflows SHALL fail non-interactively with clear diagnostics for invalid usage.

#### Scenario: Missing required argument

- **WHEN** a required CLI argument is missing
- **THEN** the command SHALL print an error identifying the missing argument
- **AND** return a nonzero status

#### Scenario: Invalid argument value

- **WHEN** a boolean, numeric, design, normalization, database, or organism argument is invalid
- **THEN** the command SHALL print an error identifying the invalid value
- **AND** return a nonzero status

### Requirement: CLI Output Compatibility

The command-line workflows SHALL write stable files that external software can consume.

#### Scenario: QC output files

- **WHEN** the QC command completes
- **THEN** `input_statistics.csv` SHALL contain the same columns and row order as the package QC merged table
- **AND** `qc_result.rds` SHALL contain the full QC result object

#### Scenario: Complex output files

- **WHEN** the complex-analysis command completes with matching complexes
- **THEN** `complex_table.csv` SHALL contain the same columns and row order as the package complex display table
- **AND** `complex_result.rds` SHALL contain the full complex result object

#### Scenario: No matching complexes

- **GIVEN** valid inputs and a database/organism combination with no matching complexes
- **WHEN** the complex-analysis command runs
- **THEN** the command SHALL write `complex_result.rds`
- **AND** it SHALL exit with status 0
